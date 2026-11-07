import Carbon.HIToolbox
import Foundation
import Testing

@testable import Recording

@MainActor
@Suite struct ShortcutTests {
    let defaults = UserDefaults(suiteName: "ShortcutTests-\(UUID().uuidString)")!

    // AC-1
    @Test func factorySettingIsRightCommandHeld() {
        let store = ShortcutStore(defaults: defaults)
        #expect(store.shortcut == .modifierOnly(.rightCommand))
        #expect(store.mode == .hold)
        #expect(store.shortcut.displayName == "rechte ⌘")
    }

    // AC-16: allowed and forbidden entries
    @Test func onlyAllowedShortcutsAreSaved() {
        let store = ShortcutStore(defaults: defaults)
        let space = UInt16(kVK_Space)
        #expect(store.setShortcut(.combination(keyCode: space, modifiers: [])) == .needsModifier)
        #expect(store.setShortcut(.combination(keyCode: UInt16(kVK_Escape), modifiers: .option)) == .escapeNotAllowed)
        #expect(store.setShortcut(.combination(keyCode: UInt16(kVK_Shift), modifiers: .command)) == .modifierAsMainKey)
        #expect(
            store.setShortcut(.combination(keyCode: UInt16(kVK_Function), modifiers: .command)) == .modifierAsMainKey)
        #expect(store.shortcut == .factory)
        #expect(store.setShortcut(.combination(keyCode: space, modifiers: .option)) == nil)
        #expect(store.shortcut == .combination(keyCode: space, modifiers: .option))
        #expect(store.shortcut.displayName == "⌥ Leertaste")
        #expect(store.setShortcut(.modifierOnly(.leftOption)) == nil)
        #expect(store.shortcut.displayName == "linke ⌥")
    }

    // AC-16, AC-17: saved values survive a restart
    @Test func shortcutAndModeAreKeptAcrossLaunches() {
        let first = ShortcutStore(defaults: defaults)
        first.setShortcut(.combination(keyCode: UInt16(kVK_F5), modifiers: [.control, .shift]))
        first.setMode(.toggle)
        let second = ShortcutStore(defaults: defaults)
        #expect(second.shortcut == .combination(keyCode: UInt16(kVK_F5), modifiers: [.control, .shift]))
        #expect(second.mode == .toggle)
        #expect(second.shortcut.displayName == "⌃⇧ F5")
    }

    // design.md → Datenmodell: unreadable or forbidden stored value falls back
    @Test func brokenStoredValueFallsBackToFactory() throws {
        defaults.set(Data("kaputt".utf8), forKey: RecordingInfo.shortcutDefaultsKey)
        defaults.set("quatsch", forKey: RecordingInfo.modeDefaultsKey)
        var store = ShortcutStore(defaults: defaults)
        #expect(store.shortcut == .factory)
        #expect(store.mode == .hold)
        let forbidden = try JSONEncoder().encode(Shortcut.combination(keyCode: 49, modifiers: []))
        defaults.set(forbidden, forKey: RecordingInfo.shortcutDefaultsKey)
        store = ShortcutStore(defaults: defaults)
        #expect(store.shortcut == .factory)
    }

    @Test func modifierKeysKnowTheirCodesAndFamilies() {
        #expect(ModifierKey(keyCode: 54) == .rightCommand)
        #expect(ModifierKey(keyCode: 55) == .leftCommand)
        #expect(ModifierKey.rightOption.family == .option)
        #expect(ModifierKey.allCases.count == 8)
        #expect(Set(ModifierKey.allCases.map(\.keyCode)).count == 8)
    }
}
