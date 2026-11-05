import AppShell
import Testing

@testable import Permissions

@MainActor
@Suite struct PermissionStepsTests {
    let checker = FakeChecker()

    func makeMonitor() -> PermissionMonitor {
        PermissionMonitor(checker: checker, problems: ProblemCenter(), onboardingFinishedOnce: { false })
    }

    @Test func stepsHaveFixedIdsOrderAndAutoCompletion() {
        let steps = PermissionSteps.make(monitor: makeMonitor())
        #expect(steps.map(\.id) == ["microphone", "accessibility"])
        #expect(steps.map(\.order) == [30, 40])
        #expect(steps.map(\.completesAutomatically) == [true, true])
    }

    @Test func stepIsSatisfiedOnlyWhenGranted() {
        let monitor = makeMonitor()
        let steps = PermissionSteps.make(monitor: monitor)
        #expect(!steps[0].isSatisfied())
        checker.states[.microphone] = .granted
        monitor.refresh()
        #expect(steps[0].isSatisfied())
        #expect(!steps[1].isSatisfied())
    }

    @Test func buttonTitlesFollowTheState() {
        #expect(PermissionKind.microphone.requestTitle(for: .notDetermined) == "Mikrofon erlauben")
        #expect(PermissionKind.microphone.requestTitle(for: .denied) == "In den Systemeinstellungen erlauben")
        #expect(PermissionKind.accessibility.requestTitle(for: .denied) == "In den Systemeinstellungen erlauben")
    }

    @Test func hintsExplainWhatToDo() {
        #expect(PermissionKind.microphone.hint(for: .notDetermined) == nil)
        #expect(PermissionKind.microphone.hint(for: .denied)?.range(of: "nur noch in den Systemeinstellungen") != nil)
        #expect(PermissionKind.microphone.hint(for: .restricted) != nil)
        #expect(PermissionKind.accessibility.hint(for: .denied) == "Schalte dort InnoWhisper ein.")
        #expect(PermissionKind.accessibility.hint(for: .granted) == nil)
    }

    @Test func explanationsSayWhyItIsNeeded() {
        #expect(PermissionKind.microphone.explanation.range(of: "Stimme aufzunehmen") != nil)
        #expect(PermissionKind.accessibility.explanation.range(of: "Eingabefeld zu finden") != nil)
    }

    @Test func relaunchPassesPathAsArgumentThenQuits() {
        var ran: [(String, [String])] = []
        var quit = false
        let relauncher = AppRelauncher(
            bundlePath: "/Applications/Inno \"x\".app", run: { ran.append(($0, $1)) }, quit: { quit = true })
        relauncher.relaunch()
        #expect(ran.first?.0 == "/bin/sh")
        #expect(ran.first?.1 == ["-c", "sleep 1; /usr/bin/open \"$0\"", "/Applications/Inno \"x\".app"])
        #expect(quit)
    }

    @Test func failedRelaunchDoesNotQuit() {
        struct Failure: Error {}
        var quit = false
        let relauncher = AppRelauncher(bundlePath: "/x.app", run: { _, _ in throw Failure() }, quit: { quit = true })
        relauncher.relaunch()
        #expect(!quit)
    }
}
