import Foundation

/// Decides what a key event means for the recording (design.md → Abläufe).
///
/// Pure logic without AppKit or CoreGraphics and without a clock of its own:
/// every event carries a monotonic time, e.g. an offset from a fixed
/// `ContinuousClock` instant. The hotkey monitor feeds it real key events,
/// the recording controller acts on the decisions and calls `reset()` once a
/// recording is finished or cancelled.
public struct KeyInterpreter: Sendable {
    /// One thing that happened on the keyboard, or a moment passing.
    public enum Event: Equatable, Sendable {
        /// A modifier key went down (one side of the keyboard).
        case modifierDown(ModifierKey)
        /// A modifier key went up.
        case modifierUp(ModifierKey)
        /// A non-modifier key went down; `modifiers` are the families held with it.
        case keyDown(keyCode: UInt16, modifiers: ModifierSet, isRepeat: Bool)
        /// A non-modifier key went up.
        case keyUp(keyCode: UInt16)
        /// Time passes; sent regularly while something is pending (e.g. every 50 ms).
        case tick
        /// The real key state reported by the system (EC-5): modifier keys held
        /// right now and whether the combination's main key is really down.
        case stateCheck(heldModifiers: Set<ModifierKey>, isMainKeyDown: Bool)
    }

    /// What the controller has to do.
    public enum Action: Equatable, Sendable {
        case none
        /// Open the microphone, a recording starts.
        case open
        /// End the recording normally and hand it on; length and silence rules apply.
        case finish
        /// Drop the recording silently (another key turned it into a shortcut like ⌘C).
        case discard
        /// Esc during a recording; the controller decides between cancel and "press again".
        case escape
    }

    /// The action plus whether the key event must be swallowed.
    public struct Decision: Equatable, Sendable {
        public let action: Action
        /// `true`: the event must not reach the app in front.
        public let consume: Bool

        public init(action: Action, consume: Bool) {
            self.action = action
            self.consume = consume
        }

        /// Nothing to do, the event reaches the app in front.
        public static let pass = Decision(action: .none, consume: false)
        /// Nothing to do, but the event is swallowed.
        public static let swallow = Decision(action: .none, consume: true)
    }

    /// Where the interpreter stands.
    public enum Phase: Equatable, Sendable {
        case idle
        /// Hold mode, lone modifier: held alone since `since`, microphone still closed.
        case waiting(since: Duration)
        /// A recording is running (from `open` until `finish`, `discard` or `reset()`).
        case active
    }

    /// Hardware key code of Esc (kVK_Escape).
    public static let escapeKeyCode: UInt16 = 53

    public private(set) var shortcut: Shortcut
    public private(set) var mode: ShortcutMode
    public private(set) var phase: Phase = .idle
    /// Modifier keys currently held, as far as the events (and state checks) tell.
    public private(set) var heldModifiers: Set<ModifierKey> = []

    /// Toggle mode, lone modifier: when the key went down for a possible tap.
    private var tapStart: Duration?
    /// Keys whose key-down was swallowed; their repeats and key-up are swallowed too.
    private var swallowedKeys: Set<UInt16> = []

    public init(shortcut: Shortcut, mode: ShortcutMode) {
        self.shortcut = shortcut
        self.mode = mode
    }

    public var isRecording: Bool { phase == .active }

    /// A new shortcut or mode is in effect; back to idle.
    public mutating func configure(shortcut: Shortcut, mode: ShortcutMode) {
        self.shortcut = shortcut
        self.mode = mode
        reset()
    }

    /// The modifier keys macOS reports as held with a key event. Event flags
    /// are exact at that moment; a lost key-up must not block the shortcut.
    public mutating func noteHeldModifiers(_ held: Set<ModifierKey>) {
        heldModifiers = held
    }

    /// The controller finished or cancelled the recording; back to idle.
    /// Physically held keys stay known.
    public mutating func reset() {
        phase = .idle
        tapStart = nil
    }

    /// Handles one event that happened at `time`.
    public mutating func handle(_ event: Event, at time: Duration) -> Decision {
        switch event {
        case .modifierDown(let key): modifierDown(key, at: time)
        case .modifierUp(let key): modifierUp(key, at: time)
        case .keyDown(let keyCode, let modifiers, let isRepeat):
            keyDown(keyCode, modifiers: modifiers, isRepeat: isRepeat)
        case .keyUp(let keyCode): keyUp(keyCode)
        case .tick: tick(at: time)
        case .stateCheck(let held, let isMainKeyDown): stateCheck(held: held, isMainKeyDown: isMainKeyDown)
        }
    }

    // MARK: - Modifier keys (never swallowed)

    private mutating func modifierDown(_ key: ModifierKey, at time: Duration) -> Decision {
        // A real key-down event is the truth: the key was up before, even if an
        // earlier state check still counted it as held (live test 07.11.).
        heldModifiers.insert(key)
        guard case .modifierOnly(let lone) = shortcut else { return .pass }
        let othersHeld = heldModifiers.count > 1
        if key == lone {
            guard !othersHeld else { return .pass }
            switch mode {
            case .hold:
                if phase == .idle { phase = .waiting(since: time) }
            case .toggle:
                tapStart = time
            }
            return .pass
        }
        return anotherKeyWithLoneModifier()
    }

    private mutating func modifierUp(_ key: ModifierKey, at time: Duration) -> Decision {
        heldModifiers.remove(key)
        switch shortcut {
        case .modifierOnly(let lone):
            guard key == lone else { return .pass }
            switch mode {
            case .hold:
                return loneModifierReleased()
            case .toggle:
                guard let start = tapStart else { return .pass }
                tapStart = nil
                guard time - start <= RecordingInfo.minimumDuration else { return .pass }
                if phase == .active {
                    phase = .idle
                    return Decision(action: .finish, consume: false)
                }
                phase = .active
                return Decision(action: .open, consume: false)
            }
        case .combination(_, let required):
            guard mode == .hold, phase == .active, required.contains(key.family),
                !Self.families(of: heldModifiers).contains(key.family)
            else { return .pass }
            phase = .idle
            return Decision(action: .finish, consume: false)
        }
    }

    /// Hold mode, lone modifier released (or found released by a state check).
    private mutating func loneModifierReleased() -> Decision {
        switch phase {
        case .idle:
            return .pass
        case .waiting:
            phase = .idle
            return .pass
        case .active:
            phase = .idle
            return Decision(action: .finish, consume: false)
        }
    }

    // MARK: - Other keys

    private mutating func keyDown(_ keyCode: UInt16, modifiers: ModifierSet, isRepeat: Bool) -> Decision {
        if isRepeat, swallowedKeys.contains(keyCode) { return .swallow }
        if !isRepeat { swallowedKeys.remove(keyCode) }

        if keyCode == Self.escapeKeyCode, phase == .active {
            tapStart = nil
            // A held Esc must not count as the second press (AC-9).
            guard !isRepeat else { return .swallow }
            swallowedKeys.insert(keyCode)
            return Decision(action: .escape, consume: true)
        }

        switch shortcut {
        case .modifierOnly:
            return anotherKeyWithLoneModifier()
        case .combination(let mainKey, let required):
            guard keyCode == mainKey, modifiers == required, !isRepeat else { return .pass }
            swallowedKeys.insert(keyCode)
            switch (mode, phase) {
            case (.hold, .active):
                // Lost key-up; never a second recording (EC-8).
                return .swallow
            case (.toggle, .active):
                phase = .idle
                return Decision(action: .finish, consume: true)
            default:
                phase = .active
                return Decision(action: .open, consume: true)
            }
        }
    }

    private mutating func keyUp(_ keyCode: UInt16) -> Decision {
        guard swallowedKeys.remove(keyCode) != nil else { return .pass }
        if case .combination(let mainKey, _) = shortcut, keyCode == mainKey, mode == .hold, phase == .active {
            phase = .idle
            return Decision(action: .finish, consume: true)
        }
        return .swallow
    }

    /// Lone-modifier shortcut: another key or modifier turns it into a shortcut
    /// like ⌘C, which always reaches the app in front (EC-1).
    private mutating func anotherKeyWithLoneModifier() -> Decision {
        switch mode {
        case .hold:
            switch phase {
            case .idle:
                return .pass
            case .waiting:
                phase = .idle
                return .pass
            case .active:
                phase = .idle
                return Decision(action: .discard, consume: false)
            }
        case .toggle:
            tapStart = nil
            return .pass
        }
    }

    // MARK: - Time and real key state

    private mutating func tick(at time: Duration) -> Decision {
        guard mode == .hold, case .modifierOnly(let lone) = shortcut, case .waiting(let since) = phase,
            time - since >= RecordingInfo.holdDelay
        else { return .pass }
        guard heldModifiers == [lone] else {
            phase = .idle
            return .pass
        }
        phase = .active
        return Decision(action: .open, consume: false)
    }

    private mutating func stateCheck(held: Set<ModifierKey>, isMainKeyDown: Bool) -> Decision {
        heldModifiers = held
        switch shortcut {
        case .modifierOnly(let lone):
            guard mode == .hold, !held.contains(lone) else { return .pass }
            return loneModifierReleased()
        case .combination(let mainKey, let required):
            if !isMainKeyDown { swallowedKeys.remove(mainKey) }
            guard mode == .hold, phase == .active else { return .pass }
            guard !isMainKeyDown || !Self.families(of: held).isSuperset(of: required) else { return .pass }
            phase = .idle
            return Decision(action: .finish, consume: false)
        }
    }

    private static func families(of keys: Set<ModifierKey>) -> ModifierSet {
        keys.reduce(into: ModifierSet()) { $0.formUnion($1.family) }
    }
}
