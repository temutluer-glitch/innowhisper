import AppShell
import Observation

/// Composition root: creates the shared objects once and wires the features.
@MainActor
@Observable
final class AppEnvironment {
    /// Hidden until launch checks pass, so a second instance never shows an icon.
    var showsMenuBarItem = false

    @ObservationIgnored let activity = ActivityCenter()
    @ObservationIgnored let problems = ProblemCenter()
    @ObservationIgnored let registry = SettingsRegistry()
    @ObservationIgnored let runningApps = SystemRunningApplications()
    @ObservationIgnored let loginItems: LoginItemController
    @ObservationIgnored let settingsWindow: SettingsWindowController
    @ObservationIgnored let legacyGuard: LegacyAppGuard

    init() {
        loginItems = LoginItemController(service: SystemLoginItemService(), problems: problems)
        settingsWindow = SettingsWindowController(registry: registry, problems: problems)
        legacyGuard = LegacyAppGuard(apps: runningApps, problems: problems, presenter: LegacyAlerts.presenter)

        let registry = registry
        let loginItems = loginItems
        registry.register(SettingsPane(section: .general) { GeneralPane(registry: registry, loginItems: loginItems) })
    }
}
