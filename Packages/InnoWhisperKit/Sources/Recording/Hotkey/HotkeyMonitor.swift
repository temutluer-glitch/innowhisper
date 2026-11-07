import CoreGraphics
import Diagnostics
import Foundation

/// One keyboard event as the macOS event tap delivers it, already reduced to
/// the few fields the monitor needs (no CGEvent, so tests can build it).
enum KeyTapEvent: Equatable, Sendable {
    /// A modifier key (or Caps Lock, Fn) changed; `flags` is the state after the change.
    case flagsChanged(keyCode: UInt16, flags: CGEventFlags)
    case keyDown(keyCode: UInt16, flags: CGEventFlags, isRepeat: Bool)
    case keyUp(keyCode: UInt16)
    /// macOS switched the tap off (too slow, or by user input).
    case tapDisabled(TapDisableReason)
}

/// Why macOS switched the event tap off. Logged as fixed text.
enum TapDisableReason: Equatable, Sendable, LogValue {
    case timeout
    case userInput

    var logDescription: StaticString {
        switch self {
        case .timeout: "timeout"
        case .userInput: "user input"
        }
    }
}

/// The macOS-specific part behind the monitor: the event tap and the real
/// key state. The real one talks to CoreGraphics; tests use a stand-in.
@MainActor
protocol KeyEventTapping: AnyObject {
    /// Creates and enables the tap. Every event goes to `handler`, which
    /// returns `true` when the event must be swallowed. `false` when macOS
    /// refuses the tap (no Accessibility permission).
    func install(handler: @escaping @MainActor (KeyTapEvent) -> Bool) -> Bool
    /// Switches an installed tap on again.
    func enable()
    func remove()
    /// Device-dependent and -independent modifier flags held right now.
    func currentFlags() -> CGEventFlags
    /// Whether the key with this hardware code is down right now.
    func isKeyDown(_ keyCode: UInt16) -> Bool
}

/// A repeating timer; the real one runs on the main run loop.
@MainActor
protocol HotkeyTicking: AnyObject {
    var isRunning: Bool { get }
    func start(every interval: Duration, _ tick: @escaping @MainActor () -> Void)
    func stop()
}

/// Watches the shortcut through one active macOS event tap and turns key
/// events into recording actions (design.md → Abläufe; AC-2, AC-3, AC-8,
/// EC-1, EC-5). The decisions come from `KeyInterpreter`; this class only
/// feeds it events, time and the real key state, swallows what it says and
/// hands every action to `onAction`.
@MainActor
public final class HotkeyMonitor {
    /// How often time passes for the interpreter while it waits or records
    /// (the 0.25 s hold delay needs a fine step).
    static let tickInterval: Duration = .milliseconds(50)

    /// Receives every action other than `.none`, in the order they happened.
    public var onAction: (@MainActor (KeyInterpreter.Action) -> Void)?
    public private(set) var isRunning = false
    public private(set) var isPaused = false

    private var interpreter: KeyInterpreter
    private let tap: any KeyEventTapping
    private let ticker: any HotkeyTicking
    private let now: @MainActor () -> Duration
    private let deliver: @MainActor (@escaping @MainActor () -> Void) -> Void
    private let log: @MainActor (LogMessage, Log.Level) -> Void
    private var lastStateCheck: Duration = .zero

    public convenience init(shortcut: Shortcut, mode: ShortcutMode) {
        let origin = ContinuousClock.now
        self.init(
            shortcut: shortcut, mode: mode, tap: SystemKeyEventTap(), ticker: RunLoopTicker(),
            now: { ContinuousClock.now - origin },
            // Actions leave the tap callback first: macOS switches off a tap
            // whose callback is slow, and opening the microphone takes time.
            // The main queue keeps them in order.
            deliver: { work in DispatchQueue.main.async { MainActor.assumeIsolated { work() } } },
            log: { message, level in Log.write(message, category: .recording, level: level) })
    }

    init(
        shortcut: Shortcut, mode: ShortcutMode, tap: any KeyEventTapping, ticker: any HotkeyTicking,
        now: @escaping @MainActor () -> Duration,
        deliver: @escaping @MainActor (@escaping @MainActor () -> Void) -> Void,
        log: @escaping @MainActor (LogMessage, Log.Level) -> Void
    ) {
        interpreter = KeyInterpreter(shortcut: shortcut, mode: mode)
        self.tap = tap
        self.ticker = ticker
        self.now = now
        self.deliver = deliver
        self.log = log
    }

    /// Where the interpreter stands (idle, waiting for the hold delay, recording).
    public var phase: KeyInterpreter.Phase { interpreter.phase }
    public var shortcut: Shortcut { interpreter.shortcut }
    public var mode: ShortcutMode { interpreter.mode }

    /// Creates the event tap. Without the Accessibility permission macOS
    /// refuses it: returns `false` and logs it; call again once the
    /// permission arrives.
    @discardableResult
    public func start() -> Bool {
        guard !isRunning else { return true }
        let installed = tap.install { [weak self] event in
            self?.handle(event) ?? false
        }
        guard installed else {
            log("Event tap could not be created, Accessibility permission missing", .error)
            return false
        }
        isRunning = true
        log("Event tap started", .notice)
        synchronizeWithRealState()
        return true
    }

    /// Removes the tap; the interpreter goes back to idle.
    public func stop() {
        guard isRunning else { return }
        tap.remove()
        ticker.stop()
        interpreter.reset()
        isRunning = false
        log("Event tap stopped", .notice)
    }

    /// The controller finished or cancelled a recording.
    public func reset() {
        interpreter.reset()
        updateTicker()
    }

    /// A new shortcut or mode is in effect.
    public func update(shortcut: Shortcut, mode: ShortcutMode) {
        interpreter.configure(shortcut: shortcut, mode: mode)
        updateTicker()
    }

    /// While paused (the settings field records a new shortcut) every event
    /// passes untouched and no action is reported.
    public func setPaused(_ paused: Bool) {
        guard paused != isPaused else { return }
        isPaused = paused
        interpreter.reset()
        if paused {
            ticker.stop()
        } else {
            // Keys may have gone up or down unseen while paused.
            synchronizeWithRealState()
        }
    }

    // MARK: - Events

    /// Called for every tap event; returns `true` to swallow it. Keep it tiny.
    func handle(_ event: KeyTapEvent) -> Bool {
        if case .tapDisabled(let reason) = event {
            tap.enable()
            log("Event tap re-enabled after \(reason)", .error)
            // Key events may have been lost while the tap was off (EC-5).
            if !isPaused { synchronizeWithRealState() }
            return false
        }
        guard !isPaused, let keyEvent = Self.interpreterEvent(for: event) else { return false }
        if case .flagsChanged(let keyCode, let flags) = event, let key = ModifierKey(keyCode: keyCode) {
            // Everything held besides the changed key, as the event says.
            interpreter.noteHeldModifiers(Self.heldModifiers(in: flags).subtracting([key]))
        }
        let consume = apply(keyEvent)
        if case .modifierDown(let key) = keyEvent, interpreter.shortcut == .modifierOnly(key),
            interpreter.mode == .hold, interpreter.phase == .idle
        {
            log("Shortcut key press not counted: another modifier is held", .notice)
        }
        return consume
    }

    private func apply(_ event: KeyInterpreter.Event) -> Bool {
        let decision = interpreter.handle(event, at: now())
        if decision.action != .none {
            let action = decision.action
            deliver { [weak self] in self?.onAction?(action) }
        }
        updateTicker()
        return decision.consume
    }

    // MARK: - Time and real key state

    /// Ticks run only while the interpreter waits or records.
    private func updateTicker() {
        guard isRunning, !isPaused, interpreter.phase != .idle else {
            ticker.stop()
            return
        }
        guard !ticker.isRunning else { return }
        lastStateCheck = now()
        ticker.start(every: Self.tickInterval) { [weak self] in self?.tick() }
    }

    private func tick() {
        guard isRunning, !isPaused else { return }
        _ = apply(.tick)
        let time = now()
        guard interpreter.phase != .idle, time - lastStateCheck >= RecordingInfo.keyStateCheckInterval else { return }
        lastStateCheck = time
        _ = apply(realStateEvent())
    }

    private func synchronizeWithRealState() {
        guard isRunning else { return }
        _ = apply(realStateEvent())
    }

    private func realStateEvent() -> KeyInterpreter.Event {
        let held = Self.heldModifiers(in: tap.currentFlags())
        var isMainKeyDown = false
        if case .combination(let keyCode, _) = interpreter.shortcut {
            isMainKeyDown = tap.isKeyDown(keyCode)
        }
        return .stateCheck(heldModifiers: held, isMainKeyDown: isMainKeyDown)
    }

    // MARK: - Pure conversion

    /// Device-dependent flag bit of each modifier key (IOKit `IOLLEvent.h`,
    /// NX_DEVICE…KEYMASK); tells left from right.
    nonisolated static func deviceFlag(of key: ModifierKey) -> UInt64 {
        switch key {
        case .leftControl: 0x0000_0001
        case .leftShift: 0x0000_0002
        case .rightShift: 0x0000_0004
        case .leftCommand: 0x0000_0008
        case .rightCommand: 0x0000_0010
        case .leftOption: 0x0000_0020
        case .rightOption: 0x0000_0040
        case .rightControl: 0x0000_2000
        }
    }

    /// The modifier keys whose device-dependent bit is set.
    nonisolated static func heldModifiers(in flags: CGEventFlags) -> Set<ModifierKey> {
        Set(ModifierKey.allCases.filter { flags.rawValue & deviceFlag(of: $0) != 0 })
    }

    /// The modifier families from the device-independent flags.
    nonisolated static func families(in flags: CGEventFlags) -> ModifierSet {
        var families = ModifierSet()
        if flags.contains(.maskControl) { families.insert(.control) }
        if flags.contains(.maskAlternate) { families.insert(.option) }
        if flags.contains(.maskShift) { families.insert(.shift) }
        if flags.contains(.maskCommand) { families.insert(.command) }
        return families
    }

    /// What a tap event means for the interpreter; `nil` for events it
    /// ignores (Caps Lock, Fn, a disabled tap).
    nonisolated static func interpreterEvent(for event: KeyTapEvent) -> KeyInterpreter.Event? {
        switch event {
        case .flagsChanged(let keyCode, let flags):
            guard let key = ModifierKey(keyCode: keyCode) else { return nil }
            return flags.rawValue & deviceFlag(of: key) != 0 ? .modifierDown(key) : .modifierUp(key)
        case .keyDown(let keyCode, let flags, let isRepeat):
            return .keyDown(keyCode: keyCode, modifiers: families(in: flags), isRepeat: isRepeat)
        case .keyUp(let keyCode):
            return .keyUp(keyCode: keyCode)
        case .tapDisabled:
            return nil
        }
    }

    /// Reduces a CGEvent from the tap callback to a `KeyTapEvent`.
    nonisolated static func tapEvent(type: CGEventType, event: CGEvent) -> KeyTapEvent? {
        let keyCode = UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
        switch type {
        case .flagsChanged: return .flagsChanged(keyCode: keyCode, flags: event.flags)
        case .keyDown:
            let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            return .keyDown(keyCode: keyCode, flags: event.flags, isRepeat: isRepeat)
        case .keyUp: return .keyUp(keyCode: keyCode)
        case .tapDisabledByTimeout: return .tapDisabled(.timeout)
        case .tapDisabledByUserInput: return .tapDisabled(.userInput)
        default: return nil
        }
    }
}

// MARK: - The real event tap

/// Session event tap at the head of the queue, active so events can be
/// swallowed, on the main run loop. Needs the Accessibility permission.
@MainActor
final class SystemKeyEventTap: KeyEventTapping {
    private var port: CFMachPort?
    private var source: CFRunLoopSource?
    fileprivate var handler: (@MainActor (KeyTapEvent) -> Bool)?

    func install(handler: @escaping @MainActor (KeyTapEvent) -> Bool) -> Bool {
        guard port == nil else { return true }
        let types: [CGEventType] = [.flagsChanged, .keyDown, .keyUp]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        guard
            let port = CGEvent.tapCreate(
                tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                eventsOfInterest: mask, callback: keyEventTapCallback,
                userInfo: Unmanaged.passUnretained(self).toOpaque())
        else { return false }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        self.port = port
        self.source = source
        self.handler = handler
        return true
    }

    func enable() {
        guard let port else { return }
        CGEvent.tapEnable(tap: port, enable: true)
    }

    func remove() {
        if let port {
            CGEvent.tapEnable(tap: port, enable: false)
            CFMachPortInvalidate(port)
        }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        port = nil
        source = nil
        handler = nil
    }

    func currentFlags() -> CGEventFlags {
        var flags = CGEventSource.flagsState(.combinedSessionState)
        // A key also counts as held when its own state says so; one source
        // alone must never end a recording that is still held (EC-5).
        for key in ModifierKey.allCases where CGEventSource.keyState(.combinedSessionState, key: key.keyCode) {
            flags.insert(CGEventFlags(rawValue: HotkeyMonitor.deviceFlag(of: key)))
        }
        return flags
    }

    func isKeyDown(_ keyCode: UInt16) -> Bool {
        CGEventSource.keyState(.combinedSessionState, key: keyCode)
    }
}

/// C callback of the event tap. Runs on the main run loop; bridges to the
/// main actor and passes or swallows the event.
private func keyEventTapCallback(
    proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    let passed = Unmanaged.passUnretained(event)
    guard let userInfo, let tapEvent = HotkeyMonitor.tapEvent(type: type, event: event) else { return passed }
    let tap = Unmanaged<SystemKeyEventTap>.fromOpaque(userInfo).takeUnretainedValue()
    let swallow = MainActor.assumeIsolated { tap.handler?(tapEvent) ?? false }
    return swallow ? nil : passed
}

// MARK: - The real timer

@MainActor
final class RunLoopTicker: HotkeyTicking {
    private var timer: Timer?

    var isRunning: Bool { timer != nil }

    func start(every interval: Duration, _ tick: @escaping @MainActor () -> Void) {
        stop()
        let seconds = Double(interval.components.seconds) + Double(interval.components.attoseconds) / 1e18
        let timer = Timer(timeInterval: seconds, repeats: true) { _ in
            MainActor.assumeIsolated { tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
