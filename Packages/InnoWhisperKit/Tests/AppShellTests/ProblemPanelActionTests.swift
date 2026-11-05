import Testing

@testable import AppShell

@MainActor
@Suite struct ProblemPanelActionTests {
    @Test func sectionProblemOpensSettingsFromPanelByDefault() {
        let problem = Problem(id: "x", section: .access, message: "m", actionTitle: "a") {}
        #expect(problem.opensSettingsFromPanel)
    }

    @Test func problemCanKeepItsOwnButtonInPanel() {
        let problem = Problem(
            id: "permission.microphone", section: .access, message: "Mikrofon nicht erlaubt.",
            actionTitle: "Jetzt erlauben", keepsOwnActionInPanel: true
        ) {}
        #expect(!problem.opensSettingsFromPanel)
    }

    @Test func problemWithoutSectionKeepsItsButton() {
        let problem = Problem(id: "legacy", section: nil, message: "m", actionTitle: "a") {}
        #expect(!problem.opensSettingsFromPanel)
    }
}
