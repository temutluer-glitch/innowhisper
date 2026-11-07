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

    public func start() {
        guard observers.isEmpty else { return }
        let workspace = NSWorkspace.shared.notificationCenter
        for name in [
            NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification,
            NSWorkspace.sessionDidResignActiveNotification,
        ] {
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
