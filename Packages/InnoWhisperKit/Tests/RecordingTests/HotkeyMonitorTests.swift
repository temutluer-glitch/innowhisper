import Carbon.HIToolbox
import CoreGraphics
import Diagnostics
import IOKit.hidsystem
import Testing

@testable import Recording

/// Stand-in for the macOS event tap and the real key state.
@MainActor
final class FakeKeyEventTap: KeyEventTapping {
    var installSucceeds = true
    var installCount = 0
    var enableCount = 0
    var removeCount = 0
    var flags: CGEventFlags = []
    var keysDown: Set<UInt16> = []
    private var handler: (@MainActor (KeyTapEvent) -> Bool)?

    func install(handler: @escaping @MainActor (KeyTapEvent) -> Bool) -> Bool {
        installCount += 1
        guard installSucceeds else { return false }
        self.handler = handler
        return true
    }

    func enable() { enableCount += 1 }

    func remove() {
        removeCount += 1
        handler = nil
    }

    func currentFlags() -> CGEventFlags { flags }
    func isKeyDown(_ keyCode: UInt16) -> Bool { keysDown.contains(keyCode) }

    /// Sends one event as macOS would; returns `true` when it was swallowed.
    func send(_ event: KeyTapEvent) -> Bool {
        handler?(event) ?? false
    }
}

@MainActor
final class FakeTicker: HotkeyTicking {
    private var tick: (@MainActor () -> Void)?
    private(set) var interval: Duration?

    var isRunning: Bool { tick != nil }

    func start(every interval: Duration, _ tick: @escaping @MainActor () -> Void) {
        self.interval = interval
        self.tick = tick
    }

    func stop() { tick = nil }

    func fire() { tick?() }
}

@MainActor
final class FakeClock {
    var time: Duration = .zero
}

@MainActor
@Suite struct HotkeyMonitorTests {
    let tap = FakeKeyEventTap()
    let ticker = FakeTicker()
    let clock = FakeClock()
    let recorder = Recorder()

    let keyC = UInt16(kVK_ANSI_C)
    let space = UInt16(kVK_Space)
    let escape = UInt16(kVK_Escape)

    @MainActor
    final class Recorder {
        var actions: [KeyInterpreter.Action] = []
        var logs: [String] = []
    }

    func makeMonitor(shortcut: Shortcut = .factory, mode: ShortcutMode = .hold) -> HotkeyMonitor {
        let clock = clock
        let recorder = recorder
        let monitor = HotkeyMonitor(
            shortcut: shortcut, mode: mode, tap: tap, ticker: ticker, now: { clock.time },
            deliver: { $0() }, log: { message, _ in recorder.logs.append(message.text) })
        monitor.onAction = { recorder.actions.append($0) }
        return monitor
    }

    func started(shortcut: Shortcut = .factory, mode: ShortcutMode = .hold) -> HotkeyMonitor {
        let monitor = makeMonitor(shortcut: shortcut, mode: mode)
        #expect(monitor.start())
        return monitor
    }

    /// Device-independent family bit plus the key's own device-dependent bit.
    func flags(_ keys: ModifierKey...) -> CGEventFlags {
        var flags = CGEventFlags()
        for key in keys {
            flags.insert(CGEventFlags(rawValue: HotkeyMonitor.deviceFlag(of: key)))
            switch key.family {
            case .command: flags.insert(.maskCommand)
            case .option: flags.insert(.maskAlternate)
            case .control: flags.insert(.maskControl)
            default: flags.insert(.maskShift)
            }
        }
        return flags
    }

    func advance(to milliseconds: Int) {
        clock.time = .milliseconds(milliseconds)
        ticker.fire()
    }

    // MARK: - Pure conversion

    // AC-2, EC-1: the device bits are the ones of IOKit's IOLLEvent.h (NX_DEVICE…KEYMASK)
    @Test func deviceFlagsMatchTheSystemHeader() {
        #expect(HotkeyMonitor.deviceFlag(of: .leftControl) == UInt64(NX_DEVICELCTLKEYMASK))
        #expect(HotkeyMonitor.deviceFlag(of: .leftShift) == UInt64(NX_DEVICELSHIFTKEYMASK))
        #expect(HotkeyMonitor.deviceFlag(of: .rightShift) == UInt64(NX_DEVICERSHIFTKEYMASK))
        #expect(HotkeyMonitor.deviceFlag(of: .leftCommand) == UInt64(NX_DEVICELCMDKEYMASK))
        #expect(HotkeyMonitor.deviceFlag(of: .rightCommand) == UInt64(NX_DEVICERCMDKEYMASK))
        #expect(HotkeyMonitor.deviceFlag(of: .leftOption) == UInt64(NX_DEVICELALTKEYMASK))
        #expect(HotkeyMonitor.deviceFlag(of: .rightOption) == UInt64(NX_DEVICERALTKEYMASK))
        #expect(HotkeyMonitor.deviceFlag(of: .rightControl) == UInt64(NX_DEVICERCTLKEYMASK))
    }

    // AC-2: every modifier key goes down when its own bit is set and up when it is not,
    // even while the same family stays held on the other side
    @Test(arguments: ModifierKey.allCases)
    func flagsChangedBecomesModifierDownAndUp(key: ModifierKey) {
        let down = KeyTapEvent.flagsChanged(keyCode: key.keyCode, flags: flags(key))
        #expect(HotkeyMonitor.interpreterEvent(for: down) == .modifierDown(key))

        let otherSide = ModifierKey.allCases.first { $0.family == key.family && $0 != key }!
        let up = KeyTapEvent.flagsChanged(keyCode: key.keyCode, flags: flags(otherSide))
        #expect(HotkeyMonitor.interpreterEvent(for: up) == .modifierUp(key))
        #expect(HotkeyMonitor.interpreterEvent(for: .flagsChanged(keyCode: key.keyCode, flags: [])) == .modifierUp(key))
    }

    // EC-5: the real state maps device bits to the keys held
    @Test func heldModifiersComeFromTheDeviceBits() {
        #expect(HotkeyMonitor.heldModifiers(in: flags(.rightCommand, .leftShift)) == [.rightCommand, .leftShift])
        #expect(HotkeyMonitor.heldModifiers(in: [.maskCommand]).isEmpty)
        #expect(HotkeyMonitor.heldModifiers(in: flags(.rightControl)) == [.rightControl])
    }

    // AC-2: Caps Lock and Fn changes are ignored, also through the monitor
    @Test func capsLockAndFnAreIgnored() {
        let capsLock = KeyTapEvent.flagsChanged(keyCode: UInt16(kVK_CapsLock), flags: [.maskAlphaShift])
        let function = KeyTapEvent.flagsChanged(keyCode: UInt16(kVK_Function), flags: [.maskSecondaryFn])
        #expect(HotkeyMonitor.interpreterEvent(for: capsLock) == nil)
        #expect(HotkeyMonitor.interpreterEvent(for: function) == nil)

        let monitor = started()
        #expect(!tap.send(capsLock))
        #expect(!tap.send(function))
        #expect(monitor.phase == .idle)
        #expect(!ticker.isRunning)
    }

    // AC-3, AC-8: key-down carries the families from the device-independent flags and the repeat flag
    @Test func keyDownCarriesFamiliesAndRepeat() {
        let event = KeyTapEvent.keyDown(
            keyCode: space, flags: [.maskAlternate, .maskShift, .maskSecondaryFn, .maskNumericPad], isRepeat: true)
        #expect(
            HotkeyMonitor.interpreterEvent(for: event)
                == .keyDown(keyCode: space, modifiers: [.option, .shift], isRepeat: true))
        #expect(
            HotkeyMonitor.interpreterEvent(for: .keyDown(keyCode: keyC, flags: [.maskCommand], isRepeat: false))
                == .keyDown(keyCode: keyC, modifiers: .command, isRepeat: false))
        #expect(HotkeyMonitor.interpreterEvent(for: .keyUp(keyCode: keyC)) == .keyUp(keyCode: keyC))
        #expect(HotkeyMonitor.interpreterEvent(for: .tapDisabled(.timeout)) == nil)
    }

    // AC-3: a real CGEvent is reduced to key code, flags and repeat flag
    @Test func cgEventIsReducedToTapEvent() throws {
        let down = try #require(CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(space), keyDown: true))
        down.flags = [.maskAlternate]
        down.setIntegerValueField(.keyboardEventAutorepeat, value: 1)
        #expect(
            HotkeyMonitor.tapEvent(type: .keyDown, event: down)
                == .keyDown(keyCode: space, flags: [.maskAlternate], isRepeat: true))

        let up = try #require(CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(space), keyDown: false))
        #expect(HotkeyMonitor.tapEvent(type: .keyUp, event: up) == .keyUp(keyCode: space))

        let modifier = try #require(
            CGEvent(keyboardEventSource: nil, virtualKey: ModifierKey.rightCommand.keyCode, keyDown: true))
        modifier.type = .flagsChanged
        modifier.flags = flags(.rightCommand)
        let tapEvent = try #require(HotkeyMonitor.tapEvent(type: .flagsChanged, event: modifier))
        #expect(HotkeyMonitor.interpreterEvent(for: tapEvent) == .modifierDown(.rightCommand))

        #expect(HotkeyMonitor.tapEvent(type: .tapDisabledByTimeout, event: up) == .tapDisabled(.timeout))
        #expect(HotkeyMonitor.tapEvent(type: .tapDisabledByUserInput, event: up) == .tapDisabled(.userInput))
        #expect(HotkeyMonitor.tapEvent(type: .mouseMoved, event: up) == nil)
    }

    // MARK: - Through the monitor

    // AC-2: right ⌘ held opens after 0.25 s and finishes on release; ticks run only meanwhile
    @Test func rightCommandHoldOpensAfterDelayAndFinishesOnRelease() {
        let monitor = started()
        #expect(!ticker.isRunning)
        #expect(!tap.send(.flagsChanged(keyCode: ModifierKey.rightCommand.keyCode, flags: flags(.rightCommand))))
        #expect(ticker.isRunning)
        #expect(ticker.interval == .milliseconds(50))
        tap.flags = flags(.rightCommand)

        advance(to: 200)
        #expect(recorder.actions.isEmpty)
        advance(to: 250)
        #expect(recorder.actions == [.open])
        #expect(monitor.phase == .active)
        advance(to: 800)
        #expect(recorder.actions == [.open])

        #expect(!tap.send(.flagsChanged(keyCode: ModifierKey.rightCommand.keyCode, flags: [])))
        #expect(recorder.actions == [.open, .finish])
        #expect(monitor.phase == .idle)
        #expect(!ticker.isRunning)
    }

    // EC-1: ⌘C passes through to the app and never opens the microphone
    @Test func commandCPassesThroughAndNeverOpens() {
        let monitor = started()
        _ = tap.send(.flagsChanged(keyCode: ModifierKey.rightCommand.keyCode, flags: flags(.rightCommand)))
        tap.flags = flags(.rightCommand)
        advance(to: 100)
        #expect(!tap.send(.keyDown(keyCode: keyC, flags: flags(.rightCommand), isRepeat: false)))
        #expect(!tap.send(.keyUp(keyCode: keyC)))
        #expect(!ticker.isRunning)
        for time in stride(from: 150, through: 1000, by: 50) { advance(to: time) }
        #expect(!tap.send(.flagsChanged(keyCode: ModifierKey.rightCommand.keyCode, flags: [])))
        #expect(recorder.actions.isEmpty)
        #expect(monitor.phase == .idle)
    }

    // AC-3: the main key of a combination is swallowed and opens; its key-up finishes
    @Test func combinationMainKeyIsSwallowed() {
        let monitor = started(shortcut: .combination(keyCode: space, modifiers: .option))
        _ = tap.send(.flagsChanged(keyCode: ModifierKey.leftOption.keyCode, flags: flags(.leftOption)))
        #expect(tap.send(.keyDown(keyCode: space, flags: flags(.leftOption), isRepeat: false)))
        #expect(recorder.actions == [.open])
        #expect(tap.send(.keyDown(keyCode: space, flags: flags(.leftOption), isRepeat: true)))
        #expect(tap.send(.keyUp(keyCode: space)))
        #expect(recorder.actions == [.open, .finish])
        #expect(monitor.phase == .idle)
        // Space without ⌥ reaches the app
        #expect(!tap.send(.keyDown(keyCode: space, flags: [], isRepeat: false)))
    }

    // AC-8: Esc is swallowed only while a recording runs
    @Test func escapeIsSwallowedOnlyWhileActive() {
        let monitor = started(shortcut: .combination(keyCode: space, modifiers: .option), mode: .toggle)
        #expect(!tap.send(.keyDown(keyCode: escape, flags: [], isRepeat: false)))
        #expect(!tap.send(.keyUp(keyCode: escape)))
        #expect(recorder.actions.isEmpty)

        #expect(tap.send(.keyDown(keyCode: space, flags: [.maskAlternate], isRepeat: false)))
        #expect(monitor.phase == .active)
        #expect(tap.send(.keyDown(keyCode: escape, flags: [], isRepeat: false)))
        #expect(tap.send(.keyUp(keyCode: escape)))
        #expect(recorder.actions == [.open, .escape])

        monitor.reset()
        #expect(monitor.phase == .idle)
        #expect(!ticker.isRunning)
        #expect(!tap.send(.keyDown(keyCode: escape, flags: [], isRepeat: false)))
        #expect(recorder.actions == [.open, .escape])
    }

    // EC-5: a lost key-up is caught by the real key state every 0.5 s
    @Test func lostReleaseIsCaughtByStateCheck() {
        let monitor = started()
        _ = tap.send(.flagsChanged(keyCode: ModifierKey.rightCommand.keyCode, flags: flags(.rightCommand)))
        tap.flags = flags(.rightCommand)
        advance(to: 250)
        #expect(recorder.actions == [.open])
        tap.flags = []  // released, but the event never came
        advance(to: 300)
        advance(to: 450)
        #expect(recorder.actions == [.open])
        advance(to: 500)
        #expect(recorder.actions == [.open, .finish])
        #expect(monitor.phase == .idle)
        #expect(!ticker.isRunning)
    }

    // EC-5: a combination whose main key is really up ends at the state check
    @Test func combinationMainKeyUpIsCaughtByStateCheck() {
        let monitor = started(shortcut: .combination(keyCode: space, modifiers: .option))
        tap.flags = flags(.leftOption)
        tap.keysDown = [space]
        _ = tap.send(.keyDown(keyCode: space, flags: flags(.leftOption), isRepeat: false))
        advance(to: 500)
        #expect(recorder.actions == [.open])
        tap.keysDown = []
        advance(to: 1000)
        #expect(recorder.actions == [.open, .finish])
        #expect(monitor.phase == .idle)
    }

    // Reliability: a tap macOS switched off is switched on again at once and logged
    @Test func disabledTapIsReenabledAndLogged() {
        let monitor = started()
        recorder.logs.removeAll()
        #expect(!tap.send(.tapDisabled(.timeout)))
        #expect(tap.enableCount == 1)
        #expect(!tap.send(.tapDisabled(.userInput)))
        #expect(tap.enableCount == 2)
        #expect(
            recorder.logs == [
                "Event tap re-enabled after timeout", "Event tap re-enabled after user input",
            ])
        #expect(monitor.isRunning)
    }

    // AC-16: while paused every event passes and nothing is reported
    @Test func pausedPassesEverything() {
        let monitor = started(shortcut: .combination(keyCode: space, modifiers: .option))
        monitor.setPaused(true)
        #expect(monitor.isPaused)
        #expect(!tap.send(.keyDown(keyCode: space, flags: [.maskAlternate], isRepeat: false)))
        #expect(!tap.send(.keyUp(keyCode: space)))
        _ = tap.send(.flagsChanged(keyCode: ModifierKey.rightCommand.keyCode, flags: flags(.rightCommand)))
        #expect(!tap.send(.keyDown(keyCode: escape, flags: [], isRepeat: false)))
        #expect(recorder.actions.isEmpty)
        #expect(monitor.phase == .idle)
        #expect(!ticker.isRunning)
        // The tap is still switched on again while paused
        #expect(!tap.send(.tapDisabled(.timeout)))
        #expect(tap.enableCount == 1)

        monitor.setPaused(false)
        #expect(tap.send(.keyDown(keyCode: space, flags: [.maskAlternate], isRepeat: false)))
        #expect(recorder.actions == [.open])
    }

    // Pausing during a hold wait drops the wait; after the pause right ⌘ works again
    @Test func pauseDropsPendingWait() {
        let monitor = started()
        _ = tap.send(.flagsChanged(keyCode: ModifierKey.rightCommand.keyCode, flags: flags(.rightCommand)))
        monitor.setPaused(true)
        #expect(monitor.phase == .idle)
        #expect(!ticker.isRunning)
        // Released while paused: unseen by the monitor
        _ = tap.send(.flagsChanged(keyCode: ModifierKey.rightCommand.keyCode, flags: []))
        tap.flags = []
        monitor.setPaused(false)

        clock.time = .milliseconds(1000)
        _ = tap.send(.flagsChanged(keyCode: ModifierKey.rightCommand.keyCode, flags: flags(.rightCommand)))
        tap.flags = flags(.rightCommand)
        advance(to: 1250)
        #expect(recorder.actions == [.open])
    }

    // A new shortcut is in effect at once
    @Test func updateSwitchesShortcut() {
        let monitor = started()
        monitor.update(shortcut: .combination(keyCode: space, modifiers: .option), mode: .toggle)
        #expect(monitor.shortcut == .combination(keyCode: space, modifiers: .option))
        #expect(monitor.mode == .toggle)
        #expect(tap.send(.keyDown(keyCode: space, flags: [.maskAlternate], isRepeat: false)))
        #expect(recorder.actions == [.open])
    }

    // Without the Accessibility permission the tap cannot be created: false, logged, retry later works
    @Test func failedTapCreationReturnsFalseAndCanBeRetried() {
        tap.installSucceeds = false
        let monitor = makeMonitor()
        #expect(!monitor.start())
        #expect(!monitor.isRunning)
        #expect(recorder.logs == ["Event tap could not be created, Accessibility permission missing"])

        tap.installSucceeds = true
        #expect(monitor.start())
        #expect(monitor.isRunning)
        #expect(tap.installCount == 2)
        #expect(monitor.start())
        #expect(tap.installCount == 2)

        monitor.stop()
        #expect(!monitor.isRunning)
        #expect(tap.removeCount == 1)
    }
}
