import AppKit

/// A running app as seen by InnoWhisper.
public struct RunningApp: Sendable, Equatable {
    public let pid: pid_t
    public let bundleIdentifier: String?

    public init(pid: pid_t, bundleIdentifier: String?) {
        self.pid = pid
        self.bundleIdentifier = bundleIdentifier
    }
}

/// Access to the list of running apps. Replaced by a fake in tests.
@MainActor
public protocol RunningApplicationsProviding: AnyObject {
    func runningApps() -> [RunningApp]
    /// Asks the app to quit normally. Returns false if the request could not be sent.
    @discardableResult func terminate(pid: pid_t) -> Bool
    /// Quits the app immediately.
    @discardableResult func forceTerminate(pid: pid_t) -> Bool
    /// Calls `handler` whenever an app launches or quits.
    func observeChanges(_ handler: @escaping @MainActor () -> Void)
}

/// The real list, via `NSWorkspace`.
@MainActor
public final class SystemRunningApplications: RunningApplicationsProviding {
    private var observations: [NSKeyValueObservation] = []

    public init() {}

    public func runningApps() -> [RunningApp] {
        NSWorkspace.shared.runningApplications.map {
            RunningApp(pid: $0.processIdentifier, bundleIdentifier: $0.bundleIdentifier)
        }
    }

    public func terminate(pid: pid_t) -> Bool {
        NSRunningApplication(processIdentifier: pid)?.terminate() ?? false
    }

    public func forceTerminate(pid: pid_t) -> Bool {
        NSRunningApplication(processIdentifier: pid)?.forceTerminate() ?? false
    }

    /// Watches the list of running apps itself (key-value observing). The
    /// launch/terminate notifications of `NSWorkspace` are not sent for
    /// menu-bar-only apps (LSUIElement) such as the old app (QA BUG-1);
    /// changes of `runningApplications` are.
    public func observeChanges(_ handler: @escaping @MainActor () -> Void) {
        observations.append(
            NSWorkspace.shared.observe(\.runningApplications, options: [.new, .old]) { _, _ in
                Task { @MainActor in handler() }
            })
    }
}
