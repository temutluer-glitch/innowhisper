import Carbon.HIToolbox
import Foundation
import Testing

@testable import Recording

/// AC-16: what the settings field records; AC-19: the hint text.
@Suite struct ShortcutFieldTests {
    @Test func loneModifierPressedAndReleasedIsRecorded() {
        var recording = ShortcutRecording()
        #expect(recording.modifiersChanged(to: [.rightCommand]) == .waiting)
        #expect(recording.modifiersChanged(to: []) == .recorded(.modifierOnly(.rightCommand)))
    }

    @Test func modifierWithKeyBecomesACombination() {
        var recording = ShortcutRecording()
        _ = recording.modifiersChanged(to: [.leftOption])
        let outcome = recording.keyDown(keyCode: UInt16(kVK_Space), families: .option)
        #expect(outcome == .recorded(.combination(keyCode: UInt16(kVK_Space), modifiers: .option)))
        // Releasing ⌥ afterwards must not record "linke ⌥".
        #expect(recording.modifiersChanged(to: []) == .waiting)
    }

    @Test func twoModifiersAreNotALoneModifier() {
        var recording = ShortcutRecording()
        _ = recording.modifiersChanged(to: [.rightCommand])
        _ = recording.modifiersChanged(to: [.rightCommand, .rightShift])
        _ = recording.modifiersChanged(to: [.rightCommand])
        #expect(recording.modifiersChanged(to: []) == .waiting)
    }

    @Test func plainKeyNeedsAModifierAndEscCancels() {
        var recording = ShortcutRecording()
        #expect(recording.keyDown(keyCode: UInt16(kVK_ANSI_A), families: []) == .needsModifier)
        #expect(recording.keyDown(keyCode: UInt16(kVK_Escape), families: []) == .cancelled)
        #expect(recording.keyDown(keyCode: UInt16(kVK_Escape), families: .command) == .needsModifier)
    }

    @Test func hintFollowsShortcutAndMode() {
        #expect(ShortcutHint.text(for: .factory, mode: .hold) == "Halte die rechte ⌘-Taste und sprich.")
        #expect(
            ShortcutHint.text(for: .modifierOnly(.leftOption), mode: .toggle)
                == "Drücke die linke ⌥-Taste zum Starten und noch einmal zum Beenden.")
        #expect(
            ShortcutHint.text(for: .combination(keyCode: UInt16(kVK_Space), modifiers: .option), mode: .hold)
                == "Halte ⌥ Leertaste und sprich.")
    }

    @MainActor
    @Test func microphoneChoiceKeepsIdAndName() {
        let defaults = UserDefaults(suiteName: "MicChoice-\(UUID().uuidString)")!
        let store = MicrophoneChoiceStore(defaults: defaults)
        #expect(store.chosen == nil)
        store.choose(Microphone(id: "usb-1", name: "Shure MV6"))
        let again = MicrophoneChoiceStore(defaults: defaults)
        #expect(again.chosen?.id == "usb-1")
        #expect(again.chosen?.name == "Shure MV6")
        again.choose(nil)
        #expect(MicrophoneChoiceStore(defaults: defaults).chosen == nil)
    }
}
