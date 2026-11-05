import AppShell
import Foundation
import Testing

@testable import Permissions

@MainActor
final class FakeChecker: PermissionChecking {
    var states: [PermissionKind: PermissionState] = [.microphone: .notDetermined, .accessibility: .denied]
    var microphoneRequests = 0
    var accessibilityRegistrations = 0

    func state(of kind: PermissionKind) -> PermissionState { states[kind]! }
    func requestMicrophone() async {
        microphoneRequests += 1
        states[.microphone] = .granted
    }
    func registerForAccessibility() { accessibilityRegistrations += 1 }

    /// What a fresh check outside the app reports; nil = no change.
    var freshAccessibility: PermissionState?
    var accessibilityRechecks = 0
    func recheckAccessibility() async {
        accessibilityRechecks += 1
        if let freshAccessibility { states[.accessibility] = freshAccessibility }
    }
}

@MainActor
final class FakeClock {
    var instant = ContinuousClock.now
    func advance(_ duration: Duration) { instant += duration }
}

@MainActor
@Suite struct PermissionMonitorTests {
    let checker = FakeChecker()
    let problems = ProblemCenter()
    let clock = FakeClock()
    var opened: [URL] = []

    func makeMonitor(
        finished: Bool,
        keepAwake: @escaping @MainActor () -> NSObjectProtocol = { NSObject() },
        opened: @escaping @MainActor (URL) -> Void = { _ in }
    ) -> PermissionMonitor {
        PermissionMonitor(
            checker: checker,
            problems: problems,
            links: SystemSettingsLinks { url in
                opened(url)
                return true
            },
            onboardingFinishedOnce: { finished },
            now: { [clock] in clock.instant },
            keepChecksRunning: keepAwake)
    }

    @Test func intervalIsOneSecondDuringOnboardingElseThree() {
        let monitor = makeMonitor(finished: false)
        monitor.onboardingIsOpen = true
        #expect(monitor.interval == .seconds(1))
        monitor.onboardingIsOpen = false
        #expect(monitor.interval == .seconds(3))
    }

    @Test func grantIsRecognizedOnNextCheck() {
        let monitor = makeMonitor(finished: false)
        #expect(!monitor.isGranted(.accessibility))
        checker.states[.accessibility] = .granted
        monitor.refresh()
        #expect(monitor.isGranted(.accessibility))
    }

    @Test func noProblemsBeforeOnboardingIsFinished() {
        _ = makeMonitor(finished: false)
        #expect(!problems.hasProblems)
    }

    @Test func missingPermissionsAreReportedAfterOnboardingWithOwnButton() throws {
        _ = makeMonitor(finished: true)
        let mic = try #require(problems.problems.first { $0.id == "permission.microphone" })
        #expect(mic.message == "Mikrofon nicht erlaubt.")
        #expect(mic.actionTitle == "Jetzt erlauben")
        #expect(mic.section == .access)
        #expect(!mic.opensSettingsFromPanel)
        #expect(problems.isReported(id: "permission.accessibility"))
    }

    @Test func problemDisappearsWhenPermissionComesBack() {
        let monitor = makeMonitor(finished: true)
        checker.states[.accessibility] = .granted
        monitor.refresh()
        #expect(!problems.isReported(id: "permission.accessibility"))
        checker.states[.accessibility] = .denied
        monitor.refresh()
        #expect(problems.isReported(id: "permission.accessibility"))
    }

    @Test func noProblemsWhileOnboardingIsOpen() {
        let monitor = makeMonitor(finished: true)
        monitor.onboardingIsOpen = true
        #expect(!problems.hasProblems)
        monitor.onboardingIsOpen = false
        #expect(problems.hasProblems)
    }

    @Test func undeterminedMicrophoneAsksMacOS() async {
        let monitor = makeMonitor(finished: false)
        monitor.requestPermission(.microphone)
        for _ in 0..<50 where !monitor.isGranted(.microphone) { await Task.yield() }
        #expect(checker.microphoneRequests == 1)
        #expect(monitor.isGranted(.microphone))
    }

    @Test func deniedMicrophoneOpensSystemSettings() {
        checker.states[.microphone] = .denied
        var urls: [URL] = []
        let monitor = makeMonitor(finished: false, opened: { urls.append($0) })
        monitor.requestPermission(.microphone)
        #expect(checker.microphoneRequests == 0)
        #expect(
            urls.map(\.absoluteString) == ["x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"]
        )
    }

    @Test func accessibilityRegistersAndOpensSystemSettings() {
        var urls: [URL] = []
        let monitor = makeMonitor(finished: false, opened: { urls.append($0) })
        monitor.requestPermission(.accessibility)
        #expect(checker.accessibilityRegistrations == 1)
        #expect(urls.count == 1)
    }

    @Test func restartIsOfferedTenSecondsAfterReturningWithoutGrant() {
        let monitor = makeMonitor(finished: false)
        monitor.requestPermission(.accessibility)
        monitor.appBecameActive()
        clock.advance(.seconds(9))
        monitor.refresh()
        #expect(monitor.restartOffered.isEmpty)
        clock.advance(.seconds(1))
        monitor.refresh()
        #expect(monitor.restartOffered == [.accessibility])
        checker.states[.accessibility] = .granted
        monitor.refresh()
        #expect(monitor.restartOffered.isEmpty)
    }

    @Test func noRestartOfferWithoutVisitToSystemSettings() {
        let monitor = makeMonitor(finished: false)
        monitor.appBecameActive()
        clock.advance(.seconds(30))
        monitor.refresh()
        #expect(monitor.restartOffered.isEmpty)
    }

    // BUG-1 (QA 05.11.): in the background macOS throttled the checks, so a
    // revoked permission went unnoticed. Starting the watcher keeps them running.
    @Test func startKeepsTheChecksRunningInTheBackground() {
        var activities = 0
        let monitor = makeMonitor(
            finished: true,
            keepAwake: {
                activities += 1
                return NSObject()
            })
        #expect(activities == 0)
        monitor.start()
        monitor.start()
        #expect(activities == 1)
    }

    // BUG-1 (QA 05.11., live): inside the running app macOS sometimes keeps
    // the old Accessibility answer after the switch changes. A change of the
    // list therefore triggers a fresh check outside the app.
    @Test func listChangeTriggersAFreshAccessibilityCheck() async {
        checker.states = [.microphone: .granted, .accessibility: .granted]
        let monitor = makeMonitor(finished: true)
        monitor.recheckDelays = [.zero]
        checker.freshAccessibility = .denied
        await monitor.accessibilityListChanged()
        #expect(checker.accessibilityRechecks == 1)
        #expect(monitor.state(of: .accessibility) == .denied)
        #expect(problems.isReported(id: PermissionKind.accessibility.problemID))
    }
}
