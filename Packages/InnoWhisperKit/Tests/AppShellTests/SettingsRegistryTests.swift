import Foundation
import SwiftUI
import Testing

@testable import AppShell

@MainActor
struct SettingsRegistryTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    // AC-7: fixed order from docs/app-shell.md
    @Test func sectionOrderMatchesAppShell() {
        #expect(
            SettingsSection.allCases.map(\.rawValue) == [
                "general", "access", "hotkeys", "transcription", "prompts", "vocabulary", "history", "about",
            ])
        #expect(SettingsSection.general.order == 1)
        #expect(SettingsSection.about.order == 8)
        #expect(Set(SettingsSection.allCases.map(\.symbolName)).count == 8)
        #expect(SettingsSection.access.title == "Zugang & Erlaubnisse")
    }

    // AC-8: only registered sections appear, in fixed order regardless of registration order
    @Test func onlyRegisteredSectionsInFixedOrder() {
        let registry = SettingsRegistry(defaults: freshDefaults())
        #expect(registry.availableSections.isEmpty)
        registry.register(SettingsPane(section: .history) { Text("h") })
        registry.register(SettingsPane(section: .general) { Text("g") })
        #expect(registry.availableSections == [.general, .history])
    }

    // AC-9: first open shows "Allgemein"
    @Test func firstOpenShowsGeneral() {
        let registry = SettingsRegistry(defaults: freshDefaults())
        registry.register(SettingsPane(section: .general) { Text("g") })
        registry.register(SettingsPane(section: .history) { Text("h") })
        #expect(registry.initialSection == .general)
    }

    // AC-9: last used section is restored, also by a new registry on the same defaults
    @Test func lastSectionIsRestored() {
        let defaults = freshDefaults()
        let registry = SettingsRegistry(defaults: defaults)
        registry.register(SettingsPane(section: .general) { Text("g") })
        registry.register(SettingsPane(section: .history) { Text("h") })
        registry.rememberSelection(.history)
        let reopened = SettingsRegistry(defaults: defaults)
        reopened.register(SettingsPane(section: .general) { Text("g") })
        reopened.register(SettingsPane(section: .history) { Text("h") })
        #expect(reopened.initialSection == .history)
    }

    // AC-9: stored section that is no longer registered or invalid falls back to "Allgemein"
    @Test(arguments: ["history", "kaputt"])
    func unknownStoredSectionFallsBack(stored: String) {
        let defaults = freshDefaults()
        defaults.set(stored, forKey: SettingsRegistry.lastSectionKey)
        let registry = SettingsRegistry(defaults: defaults)
        registry.register(SettingsPane(section: .general) { Text("g") })
        #expect(registry.initialSection == .general)
    }

    @Test func generalGroupsSortedAndReplacedById() {
        let registry = SettingsRegistry(defaults: freshDefaults())
        registry.register(GeneralSettingsGroup(id: "sounds", title: "Töne", order: 20) { Text("t") })
        registry.register(GeneralSettingsGroup(id: "system", title: "System", order: 10) { Text("s") })
        registry.register(GeneralSettingsGroup(id: "sounds", title: "Töne neu", order: 5) { Text("t") })
        #expect(registry.generalGroups.map(\.id) == ["sounds", "system"])
        #expect(registry.generalGroups.first?.title == "Töne neu")
    }
}
