import SwiftUI

/// The window that opens from the menu bar icon (AC-3, AC-4, AC-18, AC-21 to AC-23).
/// `quickAccess` is the slot PROJ-13 fills; empty in PROJ-1.
public struct MenuBarPanel<QuickAccess: View>: View {
    let problems: ProblemCenter
    let openSettings: @MainActor (SettingsSection?) -> Void
    let quit: @MainActor () -> Void
    let quickAccess: QuickAccess

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(
        problems: ProblemCenter,
        openSettings: @escaping @MainActor (SettingsSection?) -> Void,
        quit: @escaping @MainActor () -> Void,
        @ViewBuilder quickAccess: () -> QuickAccess
    ) {
        self.problems = problems
        self.openSettings = openSettings
        self.quit = quit
        self.quickAccess = quickAccess()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(problems.problems) { problem in
                ProblemBanner(problem: panelVersion(of: problem))
            }
            quickAccess
            buttonBar
        }
        .padding(16)
        .frame(width: 360)
        .onExitCommand { dismiss() }
    }

    @ViewBuilder
    private var buttonBar: some View {
        if reduceTransparency {
            HStack(spacing: 8) {
                settingsButton.buttonStyle(.borderedProminent)
                Spacer(minLength: 8)
                quitButton.buttonStyle(.bordered)
            }
        } else {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    settingsButton.buttonStyle(.glassProminent)
                    Spacer(minLength: 8)
                    quitButton.buttonStyle(.glass)
                }
            }
        }
    }

    private var settingsButton: some View {
        Button("Einstellungen …") {
            dismiss()
            openSettings(nil)
        }
        .keyboardShortcut(",", modifiers: .command)
        .controlSize(.regular)
    }

    private var quitButton: some View {
        Button("InnoWhisper beenden") { quit() }
            .keyboardShortcut("q", modifiers: .command)
            .controlSize(.regular)
    }

    /// A problem that belongs to a settings section is solved there (AC-11);
    /// one without a section keeps its own action (AC-18).
    private func panelVersion(of problem: Problem) -> Problem {
        guard let section = problem.section else { return problem }
        return Problem(
            id: problem.id,
            section: section,
            message: problem.message,
            actionTitle: "Einstellungen öffnen",
            action: { [openSettings, dismiss] in
                dismiss()
                openSettings(section)
            }
        )
    }
}
