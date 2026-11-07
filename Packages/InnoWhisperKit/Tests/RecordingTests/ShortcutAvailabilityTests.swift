import Carbon.HIToolbox
import Testing

@testable import Recording

/// AC-18: a shortcut already used by macOS or another app is refused.
@Suite struct ShortcutAvailabilityTests {
    let space = UInt16(kVK_Space)
    let f5 = UInt16(kVK_F5)

    func entry(enabled: Bool, keyCode: Int, flags: Int) -> [String: Any] {
        ["enabled": enabled, "value": ["parameters": [65535, keyCode, flags], "type": "standard"]]
    }

    @Test func spotlightIsTakenEvenWhenMacOSStoresNothing() {
        let check = ShortcutAvailability(systemShortcuts: { nil }, probe: { _, _ in true })
        #expect(!check.isFree(.combination(keyCode: space, modifiers: .command)))
        #expect(check.isFree(.combination(keyCode: space, modifiers: .option)))
    }

    @Test func switchedOffSystemShortcutIsFree() {
        let stored: [String: Any] = ["64": entry(enabled: false, keyCode: 49, flags: 1 << 20)]
        let check = ShortcutAvailability(systemShortcuts: { stored }, probe: { _, _ in true })
        #expect(check.isFree(.combination(keyCode: space, modifiers: .command)))
    }

    @Test func changedSystemShortcutIsReadFromTheStore() {
        // Spotlight moved to ⌃⌥ F5
        let stored: [String: Any] = ["64": entry(enabled: true, keyCode: Int(f5), flags: (1 << 18) | (1 << 19))]
        let check = ShortcutAvailability(systemShortcuts: { stored }, probe: { _, _ in true })
        #expect(!check.isFree(.combination(keyCode: f5, modifiers: [.control, .option])))
        #expect(check.isFree(.combination(keyCode: space, modifiers: .command)))
    }

    @Test func combinationHeldByAnotherAppIsTaken() {
        let check = ShortcutAvailability(
            systemShortcuts: { [:] }, probe: { code, mods in !(code == 0 && mods == .option) })
        #expect(!check.isFree(.combination(keyCode: 0, modifiers: .option)))
        #expect(check.isFree(.combination(keyCode: 1, modifiers: .option)))
    }

    // BUG-3 (QA 07.11.): the standard shortcuts every program uses are taken
    @Test func standardProgramShortcutsAreTaken() {
        let check = ShortcutAvailability(systemShortcuts: { [:] }, probe: { _, _ in true })
        for key in [kVK_ANSI_C, kVK_ANSI_V, kVK_ANSI_X, kVK_ANSI_Z, kVK_ANSI_Q, kVK_ANSI_W, kVK_ANSI_A, kVK_Tab] {
            #expect(!check.isFree(.combination(keyCode: UInt16(key), modifiers: .command)))
        }
        #expect(!check.isFree(.combination(keyCode: UInt16(kVK_ANSI_Z), modifiers: [.command, .shift])))
        #expect(!check.isFree(.combination(keyCode: UInt16(kVK_LeftArrow), modifiers: .command)))
        // ⌘F5 switches VoiceOver on and off (BUG-3, second round): taken.
        #expect(!check.isFree(.combination(keyCode: UInt16(kVK_F5), modifiers: .command)))
        #expect(check.isFree(.combination(keyCode: UInt16(kVK_F6), modifiers: .command)))
        #expect(check.isFree(.combination(keyCode: UInt16(kVK_F13), modifiers: .command)))
        #expect(check.isFree(.combination(keyCode: UInt16(kVK_ANSI_D), modifiers: [.control, .option])))
    }

    // BUG-3 second round: Apple's shortcuts with ⌥⌘ and ⌃⌘ and unchanged macOS shortcuts are taken
    @Test func appleShortcutsWithOptionOrControlCommandAreTaken() {
        let check = ShortcutAvailability(systemShortcuts: { [:] }, probe: { _, _ in true })
        let taken: [(Int, ModifierSet)] = [
            (kVK_ANSI_H, [.option, .command]), (kVK_ANSI_M, [.option, .command]), (kVK_ANSI_W, [.option, .command]),
            (kVK_ANSI_D, [.option, .command]), (kVK_ANSI_F, [.control, .command]), (kVK_Space, [.control, .command]),
            (kVK_ANSI_Q, [.control, .command]),
        ]
        for (key, modifiers) in taken {
            #expect(!check.isFree(.combination(keyCode: UInt16(key), modifiers: modifiers)))
        }
        #expect(check.isFree(.combination(keyCode: UInt16(kVK_ANSI_K), modifiers: [.option, .command])))
        #expect(check.isFree(.combination(keyCode: UInt16(kVK_ANSI_K), modifiers: [.control, .command])))
    }

    @Test func loneModifierIsNeverChecked() {
        let check = ShortcutAvailability(systemShortcuts: { [:] }, probe: { _, _ in false })
        #expect(check.isFree(.modifierOnly(.rightCommand)))
    }

    @Test func eventFlagsBecomeModifierFamilies() {
        #expect(ShortcutAvailability.modifierSet(fromEventFlags: 1 << 17) == .shift)
        #expect(ShortcutAvailability.modifierSet(fromEventFlags: (1 << 18) | (1 << 20)) == [.control, .command])
        #expect(ShortcutAvailability.modifierSet(fromEventFlags: 1 << 19) == .option)
    }
}
