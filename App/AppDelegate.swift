import AppKit
import AppShell
import Diagnostics

/// Hooks into launch, reopen, quit and shutdown (AC-6, AC-19, AC-20, EC-1, EC-5).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let environment = AppEnvironment()
    private var systemIsShuttingDown = false
    private var observers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        let ownID = Bundle.main.bundleIdentifier ?? AppShellInfo.bundleIdentifier
        if SingleInstanceGuard.otherInstance(
            ownPID: ProcessInfo.processInfo.processIdentifier,
            bundleIdentifier: ownID,
            running: environment.runningApps.runningApps()
        ) != nil {
            Log.write("Second instance detected, handing over", category: .app)
            SingleInstanceGuard.askRunningInstanceToOpenSettings()
            NSApplication.shared.terminate(nil)
            return
        }

        environment.showsMenuBarItem = true
        Log.write("Launch checks passed, menu bar item shown", category: .app)
        logStart()
        environment.start()
        observers.append(
            SingleInstanceGuard.observeOpenSettingsRequests { [environment] in environment.openSettings() })
        observers.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.willPowerOffNotification, object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.systemIsShuttingDown = true }
            })
        environment.loginItems.performFirstLaunchSetup()
        // The check for the old app waits until the onboarding is done (PROJ-3 EC-4).
        environment.startOnboardingIfNeeded { [environment] in environment.legacyGuard.start() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        environment.openSettings()
        return false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        environment.loginItems.refresh()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        switch QuitPolicy.decide(activity: environment.activity.activity, systemIsShuttingDown: systemIsShuttingDown) {
        case .quitNow:
            return .terminateNow
        case .askFirst:
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = QuitPolicy.confirmationTitle
            alert.informativeText = QuitPolicy.confirmationMessage
            alert.addButton(withTitle: QuitPolicy.cancelTitle)
            let quit = alert.addButton(withTitle: QuitPolicy.quitTitle)
            quit.hasDestructiveAction = true
            NSApplication.shared.activate()
            return alert.runModal() == .alertSecondButtonReturn ? .terminateNow : .terminateCancel
        }
    }

    private func logStart() {
        let build = Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") ?? 0
        let os = ProcessInfo.processInfo.operatingSystemVersion
        Log.write(
            "App started, build \(build), macOS \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)",
            category: .app)
    }
}
