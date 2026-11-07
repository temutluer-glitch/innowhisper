import SwiftUI

/// The capsule: symbol of the kind and the text (AC-2, AC-7).
struct NoticeView: View {
    let notice: Notice
    let onClick: @MainActor () -> Void
    var onAction: @MainActor () -> Void = {}

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: notice.kind.symbolName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(notice.text)
                .font(.callout)
                .foregroundStyle(.primary)
                .lineLimit(1)
            if let action = notice.action {
                Button(action.title, action: onAction)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            if reduceTransparency {
                Capsule().fill(Color(nsColor: .windowBackgroundColor))
            }
        }
        .modifier(GlassUnlessReduced(reduceTransparency: reduceTransparency))
        .fixedSize()
        .contentShape(Capsule())
        .onTapGesture { onClick() }
        .accessibilityElement(children: notice.action == nil ? .combine : .contain)
        .accessibilityLabel(notice.text)
    }

    private var tint: Color {
        switch notice.kind {
        case .info: .accentColor
        case .success: .green
        case .error: .orange
        }
    }
}

private struct GlassUnlessReduced: ViewModifier {
    let reduceTransparency: Bool

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
        } else {
            content.glassEffect(.regular, in: Capsule())
        }
    }
}
