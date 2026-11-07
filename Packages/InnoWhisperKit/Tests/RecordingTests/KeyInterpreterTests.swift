import Carbon.HIToolbox
import Testing

@testable import Recording

@Suite struct KeyInterpreterTests {
    typealias Decision = KeyInterpreter.Decision

    let keyC = UInt16(kVK_ANSI_C)
    let keyV = UInt16(kVK_ANSI_V)
    let keyA = UInt16(kVK_ANSI_A)
    let space = UInt16(kVK_Space)
    let escape = UInt16(kVK_Escape)
    let open = Decision(action: .open, consume: false)
    let finish = Decision(action: .finish, consume: false)
    let discard = Decision(action: .discard, consume: false)

    var optionSpace: Shortcut { .combination(keyCode: space, modifiers: .option) }

    func ms(_ value: Int) -> Duration { .milliseconds(value) }

    /// Right ⌘ held for `holdDelay`: the recording is open.
    func openedRightCommandHold() -> KeyInterpreter {
        var keys = KeyInterpreter(shortcut: .factory, mode: .hold)
        _ = keys.handle(.modifierDown(.rightCommand), at: ms(0))
        _ = keys.handle(.tick, at: ms(250))
        return keys
    }

    // AC-2: right ⌘ alone opens only after 0.25 s and ends on release
    @Test func rightCommandHoldOpensAfterDelayAndFinishesOnRelease() {
        var keys = KeyInterpreter(shortcut: .factory, mode: .hold)
        #expect(keys.handle(.modifierDown(.rightCommand), at: ms(0)) == .pass)
        #expect(keys.phase == .waiting(since: ms(0)))
        #expect(keys.handle(.tick, at: ms(200)) == .pass)
        #expect(keys.phase == .waiting(since: ms(0)))
        #expect(keys.handle(.tick, at: ms(250)) == open)
        #expect(keys.isRecording)
        #expect(keys.handle(.tick, at: ms(300)) == .pass)
        #expect(keys.handle(.modifierUp(.rightCommand), at: ms(4000)) == finish)
        #expect(keys.phase == .idle)
    }

    // EC-1: ⌘C (or ⌘ with another modifier) before 0.25 s never opens the microphone
    @Test func commandCBeforeDelayNeverOpens() {
        var keys = KeyInterpreter(shortcut: .factory, mode: .hold)
        _ = keys.handle(.modifierDown(.rightCommand), at: ms(0))
        #expect(keys.handle(.keyDown(keyCode: keyC, modifiers: .command, isRepeat: false), at: ms(100)) == .pass)
        #expect(keys.phase == .idle)
        #expect(keys.handle(.keyUp(keyCode: keyC), at: ms(150)) == .pass)
        #expect(keys.handle(.tick, at: ms(300)) == .pass)
        #expect(keys.handle(.tick, at: ms(1000)) == .pass)
        #expect(keys.handle(.modifierUp(.rightCommand), at: ms(1200)) == .pass)
        #expect(keys.phase == .idle)

        // Another modifier while waiting
        _ = keys.handle(.modifierDown(.rightCommand), at: ms(2000))
        #expect(keys.handle(.modifierDown(.leftShift), at: ms(2100)) == .pass)
        #expect(keys.handle(.tick, at: ms(2500)) == .pass)
        #expect(keys.phase == .idle)
        _ = keys.handle(.modifierUp(.leftShift), at: ms(2600))
        _ = keys.handle(.modifierUp(.rightCommand), at: ms(2700))

        // Right ⌘ pressed while another modifier is already held never waits
        _ = keys.handle(.modifierDown(.leftOption), at: ms(3000))
        #expect(keys.handle(.modifierDown(.rightCommand), at: ms(3100)) == .pass)
        #expect(keys.phase == .idle)
        #expect(keys.handle(.tick, at: ms(3600)) == .pass)
        #expect(keys.phase == .idle)
    }

    // EC-1: ⌘C after the microphone opened drops the recording, ⌘C reaches the app
    @Test func commandCAfterOpenDiscards() {
        var keys = openedRightCommandHold()
        #expect(keys.handle(.keyDown(keyCode: keyC, modifiers: .command, isRepeat: false), at: ms(600)) == discard)
        #expect(keys.phase == .idle)
        #expect(keys.handle(.keyUp(keyCode: keyC), at: ms(650)) == .pass)
        #expect(keys.handle(.modifierUp(.rightCommand), at: ms(700)) == .pass)

        // Another modifier after open discards too
        keys = openedRightCommandHold()
        #expect(keys.handle(.modifierDown(.leftShift), at: ms(600)) == discard)
        #expect(keys.phase == .idle)
    }

    // AC-10: a tap shorter than the delay opens nothing
    @Test func tapShorterThanDelayDoesNothing() {
        var keys = KeyInterpreter(shortcut: .factory, mode: .hold)
        _ = keys.handle(.modifierDown(.rightCommand), at: ms(0))
        #expect(keys.handle(.tick, at: ms(150)) == .pass)
        #expect(keys.handle(.modifierUp(.rightCommand), at: ms(200)) == .pass)
        #expect(keys.phase == .idle)
        #expect(keys.handle(.tick, at: ms(300)) == .pass)
        #expect(keys.phase == .idle)

        // Released after the delay but before any tick: the microphone never opened
        _ = keys.handle(.modifierDown(.rightCommand), at: ms(1000))
        #expect(keys.handle(.modifierUp(.rightCommand), at: ms(1300)) == .pass)
        #expect(keys.handle(.tick, at: ms(1350)) == .pass)
        #expect(keys.phase == .idle)
    }

    // AC-3: toggle mode, a tap starts and the next tap stops
    @Test func toggleTapStartsAndNextTapStops() {
        var keys = KeyInterpreter(shortcut: .factory, mode: .toggle)
        #expect(keys.handle(.modifierDown(.rightCommand), at: ms(0)) == .pass)
        #expect(keys.phase == .idle)
        #expect(keys.handle(.modifierUp(.rightCommand), at: ms(150)) == open)
        #expect(keys.isRecording)
        #expect(keys.handle(.keyDown(keyCode: keyA, modifiers: [], isRepeat: false), at: ms(1000)) == .pass)
        #expect(keys.handle(.keyUp(keyCode: keyA), at: ms(1050)) == .pass)
        #expect(keys.isRecording)
        _ = keys.handle(.modifierDown(.rightCommand), at: ms(5000))
        #expect(keys.handle(.modifierUp(.rightCommand), at: ms(5500)) == finish)
        #expect(keys.phase == .idle)
    }

    // AC-3, EC-1: ⌘V during a toggle recording cancels the tap, the recording keeps running
    @Test func toggleTapCancelledByCommandVKeepsRecording() {
        var keys = KeyInterpreter(shortcut: .factory, mode: .toggle)
        _ = keys.handle(.modifierDown(.rightCommand), at: ms(0))
        _ = keys.handle(.modifierUp(.rightCommand), at: ms(100))
        #expect(keys.isRecording)
        _ = keys.handle(.modifierDown(.rightCommand), at: ms(3000))
        #expect(keys.handle(.keyDown(keyCode: keyV, modifiers: .command, isRepeat: false), at: ms(3050)) == .pass)
        #expect(keys.handle(.keyUp(keyCode: keyV), at: ms(3100)) == .pass)
        #expect(keys.handle(.modifierUp(.rightCommand), at: ms(3200)) == .pass)
        #expect(keys.isRecording)

        // Idle: ⌘C never starts a toggle recording
        keys.reset()
        _ = keys.handle(.modifierDown(.rightCommand), at: ms(4000))
        _ = keys.handle(.keyDown(keyCode: keyC, modifiers: .command, isRepeat: false), at: ms(4050))
        #expect(keys.handle(.modifierUp(.rightCommand), at: ms(4100)) == .pass)
        #expect(keys.phase == .idle)
    }

    // AC-3: holding longer than 0.5 s in toggle mode does nothing
    @Test func longPressInToggleModeDoesNothing() {
        var keys = KeyInterpreter(shortcut: .factory, mode: .toggle)
        _ = keys.handle(.modifierDown(.rightCommand), at: ms(0))
        #expect(keys.handle(.tick, at: ms(300)) == .pass)
        #expect(keys.handle(.modifierUp(.rightCommand), at: ms(501)) == .pass)
        #expect(keys.phase == .idle)

        // Exactly 0.5 s still counts as a tap
        _ = keys.handle(.modifierDown(.rightCommand), at: ms(1000))
        #expect(keys.handle(.modifierUp(.rightCommand), at: ms(1500)) == open)

        // A long press while recording keeps it running
        _ = keys.handle(.modifierDown(.rightCommand), at: ms(3000))
        #expect(keys.handle(.modifierUp(.rightCommand), at: ms(4000)) == .pass)
        #expect(keys.isRecording)
    }

    // AC-2: combination held — opens at once, repeats and release are swallowed
    @Test func combinationHoldSwallowsRepeatsAndFinishesOnRelease() {
        var keys = KeyInterpreter(shortcut: optionSpace, mode: .hold)
        #expect(keys.handle(.keyDown(keyCode: space, modifiers: [], isRepeat: false), at: ms(0)) == .pass)
        #expect(keys.handle(.keyUp(keyCode: space), at: ms(50)) == .pass)
        #expect(
            keys.handle(.keyDown(keyCode: space, modifiers: [.option, .command], isRepeat: false), at: ms(100))
                == .pass)
        #expect(keys.handle(.keyUp(keyCode: space), at: ms(150)) == .pass)
        #expect(keys.phase == .idle)

        _ = keys.handle(.modifierDown(.leftOption), at: ms(1000))
        #expect(
            keys.handle(.keyDown(keyCode: space, modifiers: .option, isRepeat: false), at: ms(1100))
                == Decision(action: .open, consume: true))
        #expect(keys.isRecording)
        #expect(keys.handle(.keyDown(keyCode: space, modifiers: .option, isRepeat: true), at: ms(1600)) == .swallow)
        #expect(keys.handle(.keyDown(keyCode: space, modifiers: .option, isRepeat: true), at: ms(1650)) == .swallow)
        #expect(keys.handle(.keyDown(keyCode: keyA, modifiers: .option, isRepeat: false), at: ms(2000)) == .pass)
        #expect(keys.handle(.keyUp(keyCode: keyA), at: ms(2050)) == .pass)
        #expect(keys.isRecording)
        #expect(keys.handle(.keyUp(keyCode: space), at: ms(3000)) == Decision(action: .finish, consume: true))
        #expect(keys.phase == .idle)
    }

    // AC-2: releasing a required modifier family ends a held combination
    @Test func releasingRequiredFamilyFinishesCombination() {
        var keys = KeyInterpreter(shortcut: optionSpace, mode: .hold)
        _ = keys.handle(.modifierDown(.leftOption), at: ms(0))
        _ = keys.handle(.modifierDown(.rightOption), at: ms(10))
        _ = keys.handle(.keyDown(keyCode: space, modifiers: .option, isRepeat: false), at: ms(100))
        // The other ⌥ still holds the family
        #expect(keys.handle(.modifierUp(.rightOption), at: ms(500)) == .pass)
        #expect(keys.isRecording)
        #expect(keys.handle(.modifierUp(.leftOption), at: ms(1000)) == finish)
        #expect(keys.phase == .idle)
        // The main key's release still belongs to the swallowed press
        #expect(keys.handle(.keyUp(keyCode: space), at: ms(1100)) == .swallow)
    }

    // AC-3: toggle combination — first press starts, second stops, both presses swallowed
    @Test func toggleCombinationStartsAndStops() {
        var keys = KeyInterpreter(shortcut: optionSpace, mode: .toggle)
        let swallowOpen = Decision(action: .open, consume: true)
        #expect(keys.handle(.keyDown(keyCode: space, modifiers: .option, isRepeat: false), at: ms(0)) == swallowOpen)
        #expect(keys.handle(.keyDown(keyCode: space, modifiers: .option, isRepeat: true), at: ms(400)) == .swallow)
        #expect(keys.handle(.keyUp(keyCode: space), at: ms(500)) == .swallow)
        #expect(keys.handle(.modifierUp(.leftOption), at: ms(600)) == .pass)
        #expect(keys.isRecording)
        #expect(keys.handle(.keyDown(keyCode: keyA, modifiers: [], isRepeat: false), at: ms(1000)) == .pass)
        #expect(
            keys.handle(.keyDown(keyCode: space, modifiers: .option, isRepeat: false), at: ms(5000))
                == Decision(action: .finish, consume: true))
        #expect(keys.handle(.keyUp(keyCode: space), at: ms(5100)) == .swallow)
        #expect(keys.phase == .idle)
    }

    // AC-8 (handed to the controller): Esc is swallowed only while a recording runs
    @Test func escapeIsSwallowedOnlyWhileActive() {
        var keys = KeyInterpreter(shortcut: .factory, mode: .hold)
        #expect(keys.handle(.keyDown(keyCode: escape, modifiers: [], isRepeat: false), at: ms(0)) == .pass)
        #expect(keys.handle(.keyUp(keyCode: escape), at: ms(50)) == .pass)

        // While waiting Esc is just another key: no recording, Esc reaches the app
        _ = keys.handle(.modifierDown(.rightCommand), at: ms(1000))
        #expect(keys.handle(.keyDown(keyCode: escape, modifiers: .command, isRepeat: false), at: ms(1100)) == .pass)
        #expect(keys.phase == .idle)
        _ = keys.handle(.keyUp(keyCode: escape), at: ms(1150))
        _ = keys.handle(.modifierUp(.rightCommand), at: ms(1200))

        keys = openedRightCommandHold()
        let escapeDecision = Decision(action: .escape, consume: true)
        #expect(
            keys.handle(.keyDown(keyCode: escape, modifiers: .command, isRepeat: false), at: ms(600)) == escapeDecision)
        #expect(keys.isRecording)
        #expect(keys.handle(.keyDown(keyCode: escape, modifiers: .command, isRepeat: true), at: ms(1200)) == .swallow)
        #expect(keys.handle(.keyUp(keyCode: escape), at: ms(1300)) == .swallow)
        #expect(keys.isRecording)

        // Toggle combination: the same
        var toggle = KeyInterpreter(shortcut: optionSpace, mode: .toggle)
        _ = toggle.handle(.keyDown(keyCode: space, modifiers: .option, isRepeat: false), at: ms(0))
        #expect(toggle.handle(.keyDown(keyCode: escape, modifiers: [], isRepeat: false), at: ms(800)) == escapeDecision)
        #expect(toggle.isRecording)
        toggle.reset()
        #expect(toggle.handle(.keyDown(keyCode: escape, modifiers: [], isRepeat: false), at: ms(2000)) == .pass)
    }

    // EC-5: a lost key-up is repaired by the real key state
    @Test func lostKeyUpIsRepairedByStateCheck() {
        var keys = openedRightCommandHold()
        #expect(keys.handle(.stateCheck(heldModifiers: [.rightCommand], isMainKeyDown: false), at: ms(500)) == .pass)
        #expect(keys.isRecording)
        #expect(keys.handle(.stateCheck(heldModifiers: [], isMainKeyDown: false), at: ms(1000)) == finish)
        #expect(keys.phase == .idle)

        // Waiting: the press ends without opening
        var waiting = KeyInterpreter(shortcut: .factory, mode: .hold)
        _ = waiting.handle(.modifierDown(.rightCommand), at: ms(0))
        #expect(waiting.handle(.stateCheck(heldModifiers: [], isMainKeyDown: false), at: ms(100)) == .pass)
        #expect(waiting.handle(.tick, at: ms(300)) == .pass)
        #expect(waiting.phase == .idle)

        // Held combination: main key or a required family really released
        var combination = KeyInterpreter(shortcut: optionSpace, mode: .hold)
        _ = combination.handle(.modifierDown(.leftOption), at: ms(0))
        _ = combination.handle(.keyDown(keyCode: space, modifiers: .option, isRepeat: false), at: ms(10))
        #expect(
            combination.handle(.stateCheck(heldModifiers: [.leftOption], isMainKeyDown: true), at: ms(500)) == .pass)
        #expect(
            combination.handle(.stateCheck(heldModifiers: [.leftOption], isMainKeyDown: false), at: ms(1000)) == finish)
        #expect(combination.phase == .idle)
        _ = combination.handle(.keyDown(keyCode: space, modifiers: .option, isRepeat: false), at: ms(2000))
        #expect(combination.handle(.stateCheck(heldModifiers: [], isMainKeyDown: true), at: ms(2500)) == finish)

        // Toggle mode ignores the state check
        var toggle = KeyInterpreter(shortcut: .factory, mode: .toggle)
        _ = toggle.handle(.modifierDown(.rightCommand), at: ms(0))
        _ = toggle.handle(.modifierUp(.rightCommand), at: ms(100))
        #expect(toggle.handle(.stateCheck(heldModifiers: [], isMainKeyDown: false), at: ms(600)) == .pass)
        #expect(toggle.isRecording)
    }

    // EC-8: never a second `open` while a recording runs
    @Test func noSecondOpenWhileActive() {
        // Hold, lone modifier: a repeated key-down of right ⌘ and further ticks
        var keys = openedRightCommandHold()
        #expect(keys.handle(.modifierDown(.rightCommand), at: ms(400)) == .pass)
        #expect(keys.handle(.tick, at: ms(900)) == .pass)
        #expect(keys.isRecording)

        // Hold, combination: a fresh key-down of the main key after a lost key-up
        var combination = KeyInterpreter(shortcut: optionSpace, mode: .hold)
        _ = combination.handle(.keyDown(keyCode: space, modifiers: .option, isRepeat: false), at: ms(0))
        #expect(
            combination.handle(.keyDown(keyCode: space, modifiers: .option, isRepeat: false), at: ms(800)) == .swallow)
        #expect(combination.isRecording)

        // Toggle: the second press always finishes
        var toggle = KeyInterpreter(shortcut: optionSpace, mode: .toggle)
        _ = toggle.handle(.keyDown(keyCode: space, modifiers: .option, isRepeat: false), at: ms(0))
        _ = toggle.handle(.keyUp(keyCode: space), at: ms(100))
        #expect(
            toggle.handle(.keyDown(keyCode: space, modifiers: .option, isRepeat: false), at: ms(800)).action == .finish)
    }

    // AC-17: a new shortcut or mode starts from idle
    @Test func changingShortcutOrModeResetsToIdle() {
        var keys = openedRightCommandHold()
        keys.configure(shortcut: optionSpace, mode: .hold)
        #expect(keys.phase == .idle)
        #expect(keys.handle(.modifierUp(.rightCommand), at: ms(600)) == .pass)

        var waiting = KeyInterpreter(shortcut: .factory, mode: .hold)
        _ = waiting.handle(.modifierDown(.rightCommand), at: ms(0))
        waiting.configure(shortcut: .factory, mode: .toggle)
        #expect(waiting.phase == .idle)
        #expect(waiting.handle(.tick, at: ms(300)) == .pass)
        #expect(waiting.phase == .idle)
    }
}
