import AppKit
import AppShell
import Diagnostics
import Observation

/// Watches Microphone and Accessibility (design.md → Erlaubnis-Wächter):
/// checks regularly, logs every change, reports missing permissions as
/// problems once the onboarding is done, and offers a restart when a grant
/// is not recognized (AC-8, AC-10, AC-15, AC-16, AC-20, EC-3).
@MainActor
@Observable
public final class PermissionMonitor {
    /// Time after returning from System Settings before the restart button appears (EC-3).
    static let restartOfferDelay: Duration = .seconds(10)

    public private(set) var states: [PermissionKind: PermissionState] = [:]
    /// Permissions for which "InnoWhisper neu starten" is offered (EC-3).
    public private(set) var restartOffered: Set<PermissionKind> = []

    /// Set by the app while the onboarding window is open.
    public var onboardingIsOpen = false {
        didSet {
            guard onboardingIsOpen != oldValue else { return }
            updateProblems()
        }
    }

    @ObservationIgnored private let checker: PermissionChecking
    @ObservationIgnored private let problems: ProblemCenter
    @ObservationIgnored private let links: SystemSettingsLinks
    @ObservationIgnored private let onboardingFinishedOnce: @MainActor () -> Bool
    @ObservationIgnored private let now: @MainActor () -> ContinuousClock.Instant
    @ObservationIgnored private var sentToSettings: Set<PermissionKind> = []
    @ObservationIgnored private var returnedAt: ContinuousClock.Instant?
    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    public init(
        checker: PermissionChecking,
        problems: ProblemCenter,
        links: SystemSettingsLinks = SystemSettingsLinks(),
        onboardingFinishedOnce: @escaping @MainActor () -> Bool,
        now: @escaping @MainActor () -> ContinuousClock.Instant = { ContinuousClock.now }
    ) {
        self.checker = checker
        self.problems = problems
        self.links = links
        self.onboardingFinishedOnce = onboardingFinishedOnce
        self.now = now
        refresh()
    }

    public func state(of kind: PermissionKind) -> PermissionState {
        states[kind] ?? .denied
    }

    public func isGranted(_ kind: PermissionKind) -> Bool {
        state(of: kind).isGranted
    }

    /// How long to wait until the next check.
    var interval: Duration {
        onboardingIsOpen ? PermissionsInfo.onboardingInterval : PermissionsInfo.backgroundInterval
    }

    /// Starts the regular checks plus the immediate ones on app activation and
    /// on changes to the Accessibility list.
    public func start() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            while !Task.isCancelled {
                guard let interval = self?.interval else { return }
                try? await Task.sleep(for: interval)
                self?.refresh()
            }
        }
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.appBecameActive() }
            })
        observers.append(
            DistributedNotificationCenter.default().addObserver(
                forName: Notification.Name("com.apple.accessibility.api"), object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            })
    }

    /// Reads every permission from macOS once.
    public func refresh() {
        for kind in PermissionKind.allCases {
            let new = checker.state(of: kind)
            if let old = states[kind] {
                if old != new {
                    Log.write("Permission changed: \(kind) \(old) -> \(new)", category: .permissions)
                }
            } else {
                Log.write("Permission at start: \(kind) \(new)", category: .permissions)
            }
            if states[kind] != new { states[kind] = new }
        }
        updateRestartOffer()
        updateProblems()
    }

    /// The button of a permission step or of the problem hint: asks macOS
    /// (microphone, never asked) or opens System Settings at the right place.
    public func requestPermission(_ kind: PermissionKind) {
        switch (kind, state(of: kind)) {
        case (.microphone, .notDetermined):
            Log.write("Microphone permission requested", category: .permissions)
            Task { [weak self] in
                await self?.checker.requestMicrophone()
                self?.refresh()
            }
        case (.accessibility, _):
            checker.registerForAccessibility()
            openSettings(for: kind)
        default:
            openSettings(for: kind)
        }
    }

    /// InnoWhisper came to the front again, e.g. back from System Settings.
    func appBecameActive() {
        if !sentToSettings.isEmpty { returnedAt = now() }
        refresh()
    }

    private func openSettings(for kind: PermissionKind) {
        sentToSettings.insert(kind)
        returnedAt = nil
        links.open(kind)
    }

    private func updateRestartOffer() {
        for kind in sentToSettings where isGranted(kind) {
            sentToSettings.remove(kind)
            restartOffered.remove(kind)
        }
        guard let returnedAt, now() - returnedAt >= Self.restartOfferDelay else { return }
        let offer = sentToSettings.filter { !isGranted($0) }
        if !offer.isSubset(of: restartOffered) {
            for kind in offer.subtracting(restartOffered) {
                Log.write("Restart offered, permission not recognized: \(kind)", category: .permissions)
            }
            restartOffered.formUnion(offer)
        }
    }

    private func updateProblems() {
        let reports = onboardingFinishedOnce() && !onboardingIsOpen
        for kind in PermissionKind.allCases {
            if reports && !isGranted(kind) {
                guard !problems.isReported(id: kind.problemID) else { continue }
                problems.report(
                    Problem(
                        id: kind.problemID,
                        section: .access,
                        message: kind.missingMessage,
                        actionTitle: "Jetzt erlauben",
                        keepsOwnActionInPanel: true
                    ) { [weak self] in self?.requestPermission(kind) })
            } else if problems.isReported(id: kind.problemID) {
                problems.withdraw(id: kind.problemID)
            }
        }
    }
}
