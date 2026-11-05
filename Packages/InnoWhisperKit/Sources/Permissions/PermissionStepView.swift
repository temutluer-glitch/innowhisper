import Onboarding
import SwiftUI

/// One permission step (AC-6 to AC-11, AC-21, EC-1, EC-3).
struct PermissionStepView: View {
    let kind: PermissionKind
    let monitor: PermissionMonitor
    let relauncher: AppRelauncher

    var body: some View {
        let state = monitor.state(of: kind)
        OnboardingPageLayout(symbol: kind.symbol, title: kind.title, text: kind.explanation) {
            VStack(spacing: 12) {
                PermissionStatusLabel(granted: state.isGranted)
                if !state.isGranted {
                    Button(kind.requestTitle(for: state)) { monitor.requestPermission(kind) }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    if let hint = kind.hint(for: state) {
                        Text(hint)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if monitor.restartOffered.contains(kind) {
                        Text("Schon erlaubt, aber hier steht noch „Nicht erlaubt“?")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Button("InnoWhisper neu starten") { relauncher.relaunch() }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                    }
                }
            }
        }
        .onChange(of: state.isGranted) { _, granted in
            guard granted else { return }
            AccessibilityNotification.Announcement("\(kind.title) erlaubt").post()
        }
    }
}

/// "Erlaubt" with a green check mark, or "Nicht erlaubt" (AC-8, AC-17).
struct PermissionStatusLabel: View {
    let granted: Bool

    var body: some View {
        Label {
            Text(granted ? "Erlaubt" : "Nicht erlaubt")
        } icon: {
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(granted ? .green : .secondary)
        }
        .font(.headline)
        .accessibilityElement(children: .combine)
    }
}
