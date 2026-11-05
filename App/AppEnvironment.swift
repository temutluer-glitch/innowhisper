import AppShell
import Diagnostics
import Notices
import Observation
import Onboarding
import Permissions

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
    @ObservationIgnored let onboardingStore = OnboardingProgressStore()
    @ObservationIgnored let onboardingWindow = OnboardingWindowController()
    @ObservationIgnored let permissions: PermissionMonitor
    @ObservationIgnored private var onboardingFlow: OnboardingFlow?

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
        let onboardingStore = onboardingStore
        permissions = PermissionMonitor(
            checker: SystemPermissionChecker(),
            problems: problems,
            onboardingFinishedOnce: { onboardingStore.finishedOnce }
        )
        sounds.onMissingSound = { Log.write("Sound missing: \($0)", category: .notices, level: .error) }

        let registry = registry
        let loginItems = loginItems
        let sounds = sounds
        let logFile = logFile
        let permissions = permissions
        registry.register(SettingsPane(section: .access) { AccessPane(monitor: permissions) })
        registry.register(SettingsPane(section: .general) { GeneralPane(registry: registry, loginItems: loginItems) })
        registry.register(
            GeneralSettingsGroup(id: "sounds", title: "Töne", order: 20) { SoundSettingsGroup(player: sounds) })
        registry.register(
            GeneralSettingsGroup(id: "log", title: "Fehlerprotokoll", order: 90) { LogSettingsGroup(logFile: logFile) })
    }

    /// Starts everything that runs in the background.
    func start() {
        noticePanel.start()
        permissions.start()
        observeActivity()
    }

    /// The one way to open the settings (PROJ-3 AC-14): while the onboarding
    /// is open, it comes to the front instead.
    func openSettings(_ section: SettingsSection? = nil) {
        if onboardingWindow.isOpen {
            Log.write("Settings requested during onboarding, onboarding brought to front", category: .onboarding)
            onboardingWindow.bringToFront()
            return
        }
        settingsWindow.open(section: section)
    }

    /// Shows the onboarding if steps are open (AC-1, AC-13, AC-18) and calls
    /// `then` once it is finished, or right away if none is needed (EC-4).
    func startOnboardingIfNeeded(then: @escaping @MainActor () -> Void) {
        let steps = PermissionSteps.make(monitor: permissions)
        let flow = OnboardingFlow.start(steps: steps, store: onboardingStore) { [weak self] in
            guard let self else { return }
            onboardingWindow.close()
            onboardingFlow = nil
            permissions.onboardingIsOpen = false
            then()
        }
        guard let flow else {
            then()
            return
        }
        onboardingFlow = flow
        permissions.onboardingIsOpen = true
        onboardingWindow.show(flow)
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
