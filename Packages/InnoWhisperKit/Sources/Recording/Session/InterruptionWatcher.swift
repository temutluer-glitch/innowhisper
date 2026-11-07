import AppKit

/// Reports sleep, screen lock and a switch to another user while the app
/// runs (EC-3); the controller ends a running recording normally then.
@MainActor
public final class InterruptionWatcher {
    private let onInterruption: @MainActor () -> Void
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    public init(onInterruption: @escaping @MainActor () -> Void) {
        self.onInterruption = onInterruption
    }

    /// System sleep and switching to another user. The screen merely going
    /// dark is no interruption; a screen lock is (EC-3).
    static let workspaceNotifications: [Notification.Name] = [
        NSWorkspace.willSleepNotification, NSWorkspace.sessionDidResignActiveNotification,
    ]

    public func start() {
        guard observers.isEmpty else { return }
        let workspace = NSWorkspace.shared.notificationCenter
        for name in Self.workspaceNotifications {
            observe(workspace, name)
        }
        observe(DistributedNotificationCenter.default(), Notification.Name("com.apple.screenIsLocked"))
    }

    public func stop() {
        for (center, token) in observers { center.removeObserver(token) }
        observers.removeAll()
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.onInterruption() }
        }
        observers.append((center, token))
    }
}

/// Keeps the Mac and its screen from going to sleep on their own while a
/// recording runs, so a long dictation without typing is not cut off (BUG-10).
@MainActor
public final class KeepAwake {
    private var activity: NSObjectProtocol?

    public init() {}

    public func set(_ awake: Bool) {
        if awake, activity == nil {
            activity = ProcessInfo.processInfo.beginActivity(
                options: [.idleDisplaySleepDisabled, .idleSystemSleepDisabled], reason: "Diktat läuft")
        } else if !awake, let activity {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }
    }
}
