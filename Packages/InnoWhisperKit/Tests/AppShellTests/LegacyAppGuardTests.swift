import Foundation
import Testing

@testable import AppShell

@MainActor
final class FakeRunningApps: RunningApplicationsProviding {
    var apps: [RunningApp]
    var quitsOnTerminate = true
    var quitsOnForce = true
    var terminateCalls: [pid_t] = []
    var forceCalls: [pid_t] = []
    var changeHandler: (@MainActor () -> Void)?

    init(_ apps: [RunningApp]) { self.apps = apps }

    func runningApps() -> [RunningApp] { apps }

    func terminate(pid: pid_t) -> Bool {
        terminateCalls.append(pid)
        if quitsOnTerminate { apps.removeAll { $0.pid == pid } }
        return true
    }

    func forceTerminate(pid: pid_t) -> Bool {
        forceCalls.append(pid)
        if quitsOnForce { apps.removeAll { $0.pid == pid } }
        return true
    }

    func observeChanges(_ handler: @escaping @MainActor () -> Void) { changeHandler = handler }
}

@MainActor
final class PresenterLog {
    var prompts = 0
    var terminatedShown = 0
    var instructionsShown = 0
    var choice: LegacyPromptChoice = .later
}

@MainActor
struct LegacyAppGuardTests {
    let old = RunningApp(pid: 100, bundleIdentifier: "com.innosolv.WhisperDictation")
    let beta = RunningApp(pid: 101, bundleIdentifier: "com.innosolv.WhisperDictation.beta")
    let other = RunningApp(pid: 200, bundleIdentifier: "com.apple.Safari")

    private func make(_ apps: FakeRunningApps, log: PresenterLog, slept: @escaping (Duration) -> Void = { _ in })
        -> (LegacyAppGuard, ProblemCenter)
    {
        let problems = ProblemCenter()
        let presenter = LegacyAppGuard.Presenter(
            askWhatToDo: {
                log.prompts += 1
                return log.choice
            },
            showTerminated: { log.terminatedShown += 1 },
            showManualInstructions: { log.instructionsShown += 1 })
        let guardian = LegacyAppGuard(apps: apps, problems: problems, presenter: presenter, sleep: { slept($0) })
        return (guardian, problems)
    }

    // AC-16: no old app → no prompt, no problem
    @Test func noLegacyAppNoPrompt() async {
        let log = PresenterLog()
        let (guardian, problems) = make(FakeRunningApps([other]), log: log)
        await guardian.check()
        #expect(log.prompts == 0)
        #expect(!problems.hasProblems)
    }

    // AC-16, AC-17: old app found → prompt → terminate → confirmation
    @Test func promptAndTerminate() async {
        let log = PresenterLog()
        log.choice = .terminate
        let apps = FakeRunningApps([old, other])
        let (guardian, problems) = make(apps, log: log)
        await guardian.check()
        #expect(log.prompts == 1)
        #expect(apps.terminateCalls == [100])
        #expect(apps.forceCalls.isEmpty)
        #expect(log.terminatedShown == 1)
        #expect(!problems.hasProblems)
    }

    // Beta counts as old app too
    @Test func betaIsDetected() async {
        let log = PresenterLog()
        let (guardian, _) = make(FakeRunningApps([beta]), log: log)
        await guardian.check()
        #expect(log.prompts == 1)
    }

    // AC-18: "Später" → problem without section; cleared when the old app is gone
    @Test func laterReportsProblemUntilGone() async {
        let log = PresenterLog()
        let apps = FakeRunningApps([old])
        let (guardian, problems) = make(apps, log: log)
        await guardian.check()
        #expect(problems.isReported(id: LegacyAppGuard.problemID))
        #expect(problems.problems.first?.section == nil)
        #expect(problems.problems.first?.actionTitle == "Alte Version beenden")
        apps.apps = []
        await guardian.check()
        #expect(!problems.hasProblems)
    }

    // EC-2: old app launched later → prompt again; same instance → no second prompt
    @Test func launchedLaterPromptsOncePerInstance() async {
        let log = PresenterLog()
        let apps = FakeRunningApps([])
        let (guardian, _) = make(apps, log: log)
        await guardian.check()
        #expect(log.prompts == 0)
        apps.apps = [old]
        await guardian.check()
        await guardian.check()
        #expect(log.prompts == 1)
    }

    // EC-3: polite quit ignored → force after 2 s
    @Test func forceAfterTwoSeconds() async {
        let log = PresenterLog()
        let apps = FakeRunningApps([old])
        apps.quitsOnTerminate = false
        var slept: Duration = .zero
        let (guardian, _) = make(apps, log: log, slept: { slept += $0 })
        let outcome = await guardian.terminateLegacyApps()
        #expect(outcome == .terminated)
        #expect(apps.forceCalls == [100])
        #expect(slept >= .seconds(2) && slept <= .milliseconds(2500))
    }

    // EC-3: nothing works → instructions after 5 s, problem stays
    @Test func instructionsAfterFiveSeconds() async {
        let log = PresenterLog()
        let apps = FakeRunningApps([old])
        apps.quitsOnTerminate = false
        apps.quitsOnForce = false
        var slept: Duration = .zero
        let (guardian, problems) = make(apps, log: log, slept: { slept += $0 })
        let outcome = await guardian.terminateLegacyApps()
        #expect(outcome == .stillRunning)
        #expect(slept == .seconds(5))
        #expect(log.instructionsShown == 1)
        #expect(log.terminatedShown == 0)
        #expect(problems.isReported(id: LegacyAppGuard.problemID))
    }
}
