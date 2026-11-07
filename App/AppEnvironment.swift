import AppShell
import Diagnostics
import GroqAccess
import Notices
import Observation
import Onboarding
import Permissions
import Recording
import SwiftUI

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
    @ObservationIgnored let groqKey: GroqKeyModel
    @ObservationIgnored let shortcuts = ShortcutStore()
    @ObservationIgnored let microphoneChoice = MicrophoneChoiceStore()
    @ObservationIgnored let microphones = MicrophoneList()
    @ObservationIgnored let recordingStorage = RecordingStorage()
    @ObservationIgnored let hotkeyMonitor: HotkeyMonitor
    @ObservationIgnored let recording: RecordingController
    @ObservationIgnored let shortcutProbe = ShortcutProbe()
    @ObservationIgnored let keepAwake = KeepAwake()
    @ObservationIgnored private var interruptions: InterruptionWatcher?
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
        groqKey = GroqKeyModel(problems: problems, onboardingFinishedOnce: { onboardingStore.finishedOnce })
        sounds.onMissingSound = { Log.write("Sound missing: \($0)", category: .notices, level: .error) }

        hotkeyMonitor = HotkeyMonitor(shortcut: shortcuts.shortcut, mode: shortcuts.mode)
        let microphoneChoice = microphoneChoice
        let recordingSounds = sounds
        let keepAwake = keepAwake
        recording = RecordingController(
            hotkeys: hotkeyMonitor,
            services: RecordingServices(
                capture: MicrophoneCapture(),
                storage: recordingStorage,
                queue: RecordingQueue(
                    storage: recordingStorage, consumer: PlaceholderConsumer(storage: recordingStorage)),
                activity: activity,
                chosenMicrophone: { microphoneChoice.chosen },
                microphoneAllowed: { [permissions] in permissions.isGranted(.microphone) },
                requestMicrophone: { [permissions] in permissions.requestPermission(.microphone) },
                notify: { kind, text, action in notices.show(kind, text, action: action) },
                dictationStarted: { notices.dictationStarted() },
                playStart: { recordingSounds.playStart() },
                playEnd: { recordingSounds.playEnd() },
                keepAwake: { keepAwake.set($0) }))

        let registry = registry
        let loginItems = loginItems
        let sounds = sounds
        let logFile = logFile
        let permissions = permissions
        let groqKey = groqKey
        // "Zugang & Erlaubnisse" = Groq key (PROJ-4) above the permissions (PROJ-3).
        registry.register(
            SettingsPane(section: .access) {
                Form {
                    KeySettingsSection(model: groqKey)
                    AccessPane(monitor: permissions)
                }
                .formStyle(.grouped)
            })
        registry.register(SettingsPane(section: .general) { GeneralPane(registry: registry, loginItems: loginItems) })
        let shortcuts = shortcuts
        let microphones = microphones
        let hotkeyMonitor = hotkeyMonitor
        registry.register(
            SettingsPane(section: .hotkeys) {
                RecordingSettingsPane(
                    shortcuts: shortcuts, microphone: microphoneChoice, microphones: microphones,
                    onRecordingShortcut: { hotkeyMonitor.setPaused($0) })
            })
        registry.register(
            GeneralSettingsGroup(id: "sounds", title: "Töne", order: 20) { SoundSettingsGroup(player: sounds) })
        registry.register(
            GeneralSettingsGroup(id: "log", title: "Fehlerprotokoll", order: 90) { LogSettingsGroup(logFile: logFile) })
    }

    /// Starts everything that runs in the background.
    func start() {
        noticePanel.start()
        permissions.start()
        groqKey.showSettings = { [weak self] in self?.openSettings(.access) }
        groqKey.start()
        startRecording()
        observeActivity()
    }

    /// Recording by shortcut (PROJ-5): leftovers of a crash go, the shortcut
    /// watcher starts (again once Accessibility is allowed), sleep and screen
    /// lock end a running recording.
    private func startRecording() {
        recordingStorage.removeLeftovers()
        startHotkeys()
        observeShortcutChanges()
        let recording = recording
        let watcher = InterruptionWatcher { recording.interrupt(.systemSleepOrLock) }
        watcher.start()
        interruptions = watcher
    }

    /// Without Accessibility macOS refuses the tap; retried when it is allowed.
    private func startHotkeys() {
        let granted = withObservationTracking {
            permissions.isGranted(.accessibility)
        } onChange: { [weak self] in
            Task { @MainActor in self?.startHotkeys() }
        }
        if granted, !hotkeyMonitor.isRunning { hotkeyMonitor.start() }
    }

    /// A new shortcut or mode from the settings takes effect at once (AC-16, AC-17).
    private func observeShortcutChanges() {
        let (shortcut, mode) = withObservationTracking {
            (shortcuts.shortcut, shortcuts.mode)
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeShortcutChanges() }
        }
        if shortcut != hotkeyMonitor.shortcut || mode != hotkeyMonitor.mode {
            hotkeyMonitor.update(shortcut: shortcut, mode: mode)
        }
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
        let steps =
            [KeyStep.make(model: groqKey)] + PermissionSteps.make(monitor: permissions) + [
                ShortcutStep.make(
                    controller: recording, probe: shortcutProbe, shortcuts: shortcuts,
                    microphone: microphoneChoice, microphones: microphones)
            ]
        let flow = OnboardingFlow.start(steps: steps, store: onboardingStore) { [weak self] in
            guard let self else { return }
            onboardingWindow.close()
            onboardingFlow = nil
            permissions.onboardingIsOpen = false
            groqKey.onboardingIsOpen = false
            recording.gate = .normal
            then()
        }
        guard let flow else {
            then()
            return
        }
        onboardingFlow = flow
        permissions.onboardingIsOpen = true
        groqKey.onboardingIsOpen = true
        recording.gate = .blocked
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
