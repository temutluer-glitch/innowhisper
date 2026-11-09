import Testing

@testable import AppShell

@MainActor
struct StateTests {
    private func problem(_ id: String, section: SettingsSection? = nil, message: String = "Text") -> Problem {
        Problem(id: id, section: section, message: message, actionTitle: "Lösen", action: {})
    }

    // AC-2: priority recording > transcribing > problem > ready
    @Test(arguments: [
        (DictationActivity.recording, true, MenuBarStatus.recording),
        (.recording, false, .recording),
        (.transcribing, true, .transcribing),
        (.transcribing, false, .transcribing),
        (.idle, true, .problem),
        (.idle, false, .ready),
    ])
    func statusPriority(activity: DictationActivity, hasProblems: Bool, expected: MenuBarStatus) {
        #expect(MenuBarStatus.resolve(activity: activity, hasProblems: hasProblems) == expected)
    }

    // AC-2: every state has its own symbol and a spoken label
    @Test func everyStatusHasDistinctSymbolAndLabel() {
        let all: [MenuBarStatus] = [.ready, .recording, .transcribing, .problem]
        #expect(Set(all.map(\.symbolName)).count == all.count)
        #expect(all.allSatisfy { !$0.accessibilityLabel.isEmpty })
        #expect(MenuBarStatus.recording.symbolName == "mic.fill")
        #expect(MenuBarStatus.problem.accessibilityLabel.contains("Problem"))
    }

    // PROJ-6 AC-1: recording and transcribing are separate facts; recording is shown first
    @Test func activityCombinesRecordingAndTranscribing() {
        let center = ActivityCenter()
        #expect(center.activity == .idle)
        center.isTranscribing = true
        #expect(center.activity == .transcribing)
        center.isRecording = true
        #expect(center.activity == .recording)
        center.isRecording = false
        #expect(center.activity == .transcribing)
        center.isTranscribing = false
        #expect(center.activity == .idle)
    }

    @Test func onlyIdleIsInactive() {
        #expect(!DictationActivity.idle.isActive)
        #expect(DictationActivity.recording.isActive)
        #expect(DictationActivity.transcribing.isActive)
    }

    // AC-10: reporting the same id replaces, keeps position
    @Test func reportingSameIdReplaces() {
        let center = ProblemCenter()
        center.report(problem("a", message: "alt"))
        center.report(problem("b"))
        center.report(problem("a", message: "neu"))
        #expect(center.problems.map(\.id) == ["a", "b"])
        #expect(center.problems.first?.message == "neu")
    }

    // AC-10, AC-18: withdrawing removes; unknown ids are ignored
    @Test func withdrawRemovesAndIgnoresUnknown() {
        let center = ProblemCenter()
        center.report(problem("a"))
        center.withdraw(id: "unbekannt")
        #expect(center.hasProblems)
        center.withdraw(id: "a")
        #expect(!center.hasProblems)
        #expect(!center.isReported(id: "a"))
    }

    // AC-10: problems are filtered by section; nil-section problems stay out of every section
    @Test func problemsPerSection() {
        let center = ProblemCenter()
        center.report(problem("x", section: .general))
        center.report(problem("y", section: .access))
        center.report(problem("z", section: nil))
        #expect(center.problems(in: .general).map(\.id) == ["x"])
        #expect(center.problems(in: .access).map(\.id) == ["y"])
        #expect(center.problems(in: .history).isEmpty)
    }
}
