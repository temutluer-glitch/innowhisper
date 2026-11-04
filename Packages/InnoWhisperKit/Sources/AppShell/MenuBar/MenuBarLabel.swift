import SwiftUI

/// The menu bar icon (AC-1, AC-2). Bound directly to the state, so a change
/// shows immediately.
public struct MenuBarLabel: View {
    let activity: ActivityCenter
    let problems: ProblemCenter

    public init(activity: ActivityCenter, problems: ProblemCenter) {
        self.activity = activity
        self.problems = problems
    }

    public var body: some View {
        let status = MenuBarStatus.resolve(activity: activity.activity, hasProblems: problems.hasProblems)
        Image(systemName: status.symbolName)
            .accessibilityLabel(status.accessibilityLabel)
    }
}
