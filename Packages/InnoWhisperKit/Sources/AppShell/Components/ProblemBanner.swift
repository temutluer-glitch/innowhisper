import SwiftUI

/// The one hint style for problems (AC-10, AC-23): warning symbol, one
/// sentence, one solving button.
public struct ProblemBanner: View {
    let problem: Problem

    public init(problem: Problem) {
        self.problem = problem
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(problem.message)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(problem.actionTitle) { problem.action() }
                .controlSize(.regular)
        }
        .padding(12)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Problem: \(problem.message)")
    }
}
