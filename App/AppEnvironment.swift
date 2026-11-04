import AppShell
import Diagnostics
import Notices
import Observation

/// Composition root: creates the shared objects once and wires the features.
@MainActor
@Observable
final class AppEnvironment {
    /// Hidden until launch checks pass, so a second instance never shows an icon.
    var showsMenuBarItem = false

    @ObservationIgnored let logFile: LogFile
    @ObservationIgnored let activity = ActivityCenter()
    @ObservationIgnored let problems = ProblemCenter()
    @ObservationIgnored let registry = SettingsRegistry()
    @ObservationIgnored let runningApps = SystemRunningApplications()
    @ObservationIgnored let notices = NoticeCenter()
    @ObservationIgnored let noticePanel: NoticePanelController
    @ObservationIgnored let sounds = SoundPlayer(output: SystemSoundOutput())
    @ObservationIgnored let loginItems: LoginItemController
    @ObservationIgnored let settingsWindow: SettingsWindowController
    @ObservationIgnored let legacyGuard: LegacyAppGuard

    init() {
        logFile = LogFile()
        Log.configure(file: logFile)

        noticePanel = NoticePanelController(center: notices)
        loginItems = LoginItemController(service: SystemLoginItemService(), problems: problems)
        settingsWindow = SettingsWindowController(registry: registry, problems: problems)
        let notices = notices
        legacyGuard = LegacyAppGuard(
            apps: runningApps,
            problems: problems,
            presenter: LegacyAppGuard.Presenter(
                askWhatToDo: { LegacyAlerts.askWhatToDo() },
                showTerminated: { notices.show(.success, "Die alte Version wurde beendet.") },
                showManualInstructions: { LegacyAlerts.showManualInstructions($0) }
            )
        )
        sounds.onMissingSound = { Log.write("Sound missing: \($0)", category: .notices, level: .error) }

        let registry = registry
        let loginItems = loginItems
        let sounds = sounds
        let logFile = logFile
        registry.register(SettingsPane(section: .general) { GeneralPane(registry: registry, loginItems: loginItems) })
        registry.register(
            GeneralSettingsGroup(id: "sounds", title: "Töne", order: 20) { SoundSettingsGroup(player: sounds) })
        registry.register(
            GeneralSettingsGroup(id: "log", title: "Fehlerprotokoll", order: 90) { LogSettingsGroup(logFile: logFile) })
    }

    /// Starts everything that runs in the background.
    func start() {
        noticePanel.start()
        observeActivity()
    }

    /// A new dictation closes an error notice (AC-4).
    private func observeActivity() {
        let current = withObservationTracking {
            activity.activity
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeActivity() }
        }
        if current == .recording { notices.dictationStarted() }
    }
}
