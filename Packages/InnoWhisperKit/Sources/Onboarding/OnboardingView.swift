import SwiftUI

/// The frame around every page: position, page content and the button bar
/// (AC-2, AC-5, AC-7, AC-21, AC-22).
struct OnboardingView: View {
    let flow: OnboardingFlow
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(spacing: 0) {
            Text(flow.positionText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.top, 20)
            Spacer(minLength: 16)
            page
            Spacer(minLength: 16)
            buttonBar
                .padding(20)
        }
        .frame(width: OnboardingWindowController.size.width, height: OnboardingWindowController.size.height)
    }

    @ViewBuilder
    private var page: some View {
        switch flow.currentPage {
        case .welcome: WelcomePageView()
        case .step(let step): step.content()
        case .done: DonePageView()
        }
    }

    private var primaryTitle: String {
        switch flow.currentPage {
        case .welcome: "Los geht's"
        case .step: "Weiter"
        case .done: "Fertig"
        }
    }

    @ViewBuilder
    private var buttonBar: some View {
        if reduceTransparency {
            HStack(spacing: 8) {
                backButton.buttonStyle(.bordered)
                Spacer(minLength: 8)
                primaryButton.buttonStyle(.borderedProminent)
            }
        } else {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    backButton.buttonStyle(.glass)
                    Spacer(minLength: 8)
                    primaryButton.buttonStyle(.glassProminent)
                }
            }
        }
    }

    @ViewBuilder
    private var backButton: some View {
        if flow.canGoBack {
            Button("Zurück") { flow.goBack() }
                .controlSize(.regular)
        }
    }

    private var primaryButton: some View {
        Button(primaryTitle) { flow.advance() }
            .controlSize(.regular)
            .keyboardShortcut(.defaultAction)
            .disabled(!flow.canAdvance)
            .accessibilityHint(flow.canAdvance ? "" : "Erst nach der Erlaubnis möglich")
    }
}
