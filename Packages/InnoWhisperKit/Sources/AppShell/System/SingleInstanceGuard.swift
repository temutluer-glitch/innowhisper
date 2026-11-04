import Foundation

/// Ensures only one InnoWhisper runs (EC-1).
public enum SingleInstanceGuard {
    /// Distributed notification a second instance sends to the first. Carries no data.
    public static let openSettingsNotification = Notification.Name("com.innosolv.InnoWhisper.openSettings")

    /// Another running instance with the same bundle id, if any.
    public static func otherInstance(ownPID: pid_t, bundleIdentifier: String, running: [RunningApp]) -> RunningApp? {
        running.first { $0.bundleIdentifier == bundleIdentifier && $0.pid != ownPID }
    }

    /// Asks the running instance to open its settings window.
    public static func askRunningInstanceToOpenSettings(center: DistributedNotificationCenter = .default()) {
        center.postNotificationName(openSettingsNotification, object: nil, userInfo: nil, deliverImmediately: true)
    }

    /// Listens for the request of a second instance. Only the name counts;
    /// object and userInfo are ignored (SEC-02).
    public static func observeOpenSettingsRequests(
        center: DistributedNotificationCenter = .default(),
        handler: @escaping @MainActor () -> Void
    ) -> NSObjectProtocol {
        center.addObserver(forName: openSettingsNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { handler() }
        }
    }
}
