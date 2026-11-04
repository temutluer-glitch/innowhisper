import AppKit
import Foundation
import Observation

/// "Start beim Anmelden" (AC-13 to AC-15, EC-4). Reads the real state from
/// macOS and reports `autostartUnavailable` when macOS refuses.
@MainActor
@Observable
public final class LoginItemController {
    public static let problemID = "autostartUnavailable"
    static let firstLaunchKey = "autostart.firstLaunchDone"
    /// The user deliberately switched autostart off. Their intent, not the
    /// macOS state: a refusal hint is never shown against this choice (EC-4).
    static let userTurnedOffKey = "autostart.userTurnedOff"

    /// Mirrors macOS; never stored by the app.
    public private(set) var isEnabled = false

    @ObservationIgnored private let service: LoginItemService
    @ObservationIgnored private let problems: ProblemCenter
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let bundleURL: URL
    @ObservationIgnored private let homeDirectory: URL
    @ObservationIgnored private var lastAttemptFailed = false

    public init(
        service: LoginItemService,
        problems: ProblemCenter,
        defaults: UserDefaults = .standard,
        bundleURL: URL = Bundle.main.bundleURL,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        self.service = service
        self.problems = problems
        self.defaults = defaults
        self.bundleURL = bundleURL
        self.homeDirectory = homeDirectory
    }

    /// On the very first launch, switch autostart on once (AC-13). Later
    /// launches never touch it, so a deliberate "off" is kept (AC-14).
    public func performFirstLaunchSetup() {
        if !defaults.bool(forKey: Self.firstLaunchKey) {
            defaults.set(true, forKey: Self.firstLaunchKey)
            attemptRegister()
        }
        refresh()
    }

    /// Called by the switch in "Allgemein".
    public func setEnabled(_ enabled: Bool) {
        defaults.set(!enabled, forKey: Self.userTurnedOffKey)
        if enabled {
            attemptRegister()
        } else {
            lastAttemptFailed = false
            do {
                try service.unregister()
            } catch {
                AppShellLog.system.error("Autostart off failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        refresh()
    }

    /// Re-reads macOS (AC-15): on opening "Allgemein" and when the app becomes active.
    public func refresh() {
        let status = service.status
        AppShellLog.system.notice("Login item status: \(String(describing: status), privacy: .public)")
        isEnabled = status == .enabled
        switch status {
        case .enabled:
            lastAttemptFailed = false
            problems.withdraw(id: Self.problemID)
        case .requiresApproval:
            problems.report(
                Problem(
                    id: Self.problemID,
                    section: .general,
                    message: "macOS muss den automatischen Start noch erlauben.",
                    actionTitle: "Anmeldeobjekte öffnen",
                    action: { [service] in service.openSystemSettings() }
                ))
        case .notFound:
            if defaults.bool(forKey: Self.userTurnedOffKey) {
                problems.withdraw(id: Self.problemID)
            } else {
                reportRefusal()
            }
        case .notRegistered:
            if lastAttemptFailed {
                reportRefusal()
            } else {
                problems.withdraw(id: Self.problemID)
            }
        }
    }

    /// True when the app lives in /Applications or ~/Applications.
    var isInApplicationsFolder: Bool {
        let path = bundleURL.standardizedFileURL.path
        let userApps = homeDirectory.appendingPathComponent("Applications").standardizedFileURL.path
        return path.hasPrefix("/Applications/") || path.hasPrefix(userApps + "/")
    }

    private func attemptRegister() {
        do {
            try service.register()
            lastAttemptFailed = service.status != .enabled && service.status != .requiresApproval
        } catch {
            lastAttemptFailed = true
            AppShellLog.system.error("Autostart on failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func reportRefusal() {
        if isInApplicationsFolder {
            problems.report(
                Problem(
                    id: Self.problemID,
                    section: .general,
                    message: "macOS hat den automatischen Start abgelehnt. Bitte schalte ihn später erneut ein.",
                    actionTitle: "Erneut versuchen",
                    action: { [weak self] in self?.setEnabled(true) }
                ))
        } else {
            problems.report(
                Problem(
                    id: Self.problemID,
                    section: .general,
                    message: "Verschiebe InnoWhisper in den Ordner Programme, dann klappt der automatische Start.",
                    actionTitle: "Im Finder zeigen",
                    action: { [bundleURL] in NSWorkspace.shared.activateFileViewerSelecting([bundleURL]) }
                ))
        }
    }
}
