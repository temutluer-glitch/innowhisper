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
    @ObservationIgnored private let keepChecksRunning: @MainActor () -> NSObjectProtocol
    @ObservationIgnored private var backgroundActivity: NSObjectProtocol?
    @ObservationIgnored private var accessibilityListObserver: AccessibilityListObserver?
    /// When to check Accessibility again outside the app after the list changed.
    @ObservationIgnored var recheckDelays: [Duration] = [.milliseconds(500), .seconds(2)]
    /// How often the check outside the app runs without any message (QA BUG-11).
    static let outsideCheckInterval: Duration = .seconds(30)
    /// The running sequence of checks after a list change; a new change replaces it (QA BUG-8).
    @ObservationIgnored private(set) var listChangeTask: Task<Void, Never>?
    @ObservationIgnored private var lastOutsideCheck: ContinuousClock.Instant

    public init(
        checker: PermissionChecking,
        problems: ProblemCenter,
        links: SystemSettingsLinks = SystemSettingsLinks(),
        onboardingFinishedOnce: @escaping @MainActor () -> Bool,
        now: @escaping @MainActor () -> ContinuousClock.Instant = { ContinuousClock.now },
        keepChecksRunning: @escaping @MainActor () -> NSObjectProtocol = PermissionMonitor.preventAppNap
    ) {
        self.checker = checker
        self.problems = problems
        self.links = links
        self.onboardingFinishedOnce = onboardingFinishedOnce
        self.now = now
        self.keepChecksRunning = keepChecksRunning
        self.lastOutsideCheck = now()
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

    /// A menu bar app sits in the background almost all the time. Without this,
    /// macOS puts it to sleep (App Nap) and the checks stop, so a revoked
    /// permission went unnoticed for minutes (AC-15, AC-16; QA BUG-1).
    /// Idle system sleep stays allowed; a check costs next to nothing.
    public static func preventAppNap() -> NSObjectProtocol {
        ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep, reason: "Watching microphone and accessibility permissions")
    }

    /// Starts the regular checks plus the immediate ones on app activation and
    /// on changes to the Accessibility list.
    public func start() {
        guard loop == nil else { return }
        backgroundActivity = keepChecksRunning()
        loop = Task { [weak self] in
            while !Task.isCancelled {
                guard let interval = self?.interval else { return }
                try? await Task.sleep(for: interval)
                self?.refresh()
                await self?.checkOutsideIfDue()
            }
        }
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.appBecameActive() }
            })
        accessibilityListObserver = AccessibilityListObserver { [weak self] in
            self?.accessibilityListChanged()
        }
    }

    /// The Accessibility list changed. Inside the running app macOS sometimes
    /// keeps the old answer (measured 05.11.2026, design.md → Bau-Notizen), so
    /// a fresh check outside the app follows shortly after (QA BUG-1). A new
    /// change replaces a sequence still waiting, so a burst of messages from
    /// any program starts one sequence, not one per message (QA BUG-8).
    func accessibilityListChanged() {
        refresh()
        listChangeTask?.cancel()
        listChangeTask = Task { [weak self, recheckDelays] in
            for delay in recheckDelays {
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
                await self?.checkOutside()
            }
        }
    }

    /// Runs the check outside the app when the last one is 30 seconds old, in
    /// case a list change went by without a message (QA BUG-11).
    func checkOutsideIfDue() async {
        guard now() - lastOutsideCheck >= Self.outsideCheckInterval else { return }
        await checkOutside()
    }

    private func checkOutside() async {
        lastOutsideCheck = now()
        await checker.recheckAccessibility()
        refresh()
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

/// Listens for changes to the Accessibility list. AppKit holds distributed
/// notifications back while the app is not in front; this one has to arrive
/// immediately, because InnoWhisper is almost never in front (QA BUG-1).
@MainActor
private final class AccessibilityListObserver: NSObject {
    private let onChange: @MainActor () -> Void

    init(onChange: @escaping @MainActor () -> Void) {
        self.onChange = onChange
        super.init()
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(listChanged), name: Notification.Name("com.apple.accessibility.api"),
            object: nil, suspensionBehavior: .deliverImmediately)
    }

    @objc private func listChanged(_ notification: Notification) {
        onChange()
    }
}
