import Onboarding
import SwiftUI

/// The onboarding step "Zugangsschlüssel" (AC-1 to AC-10, EC-7, EC-9).
public enum KeyStep {
    @MainActor
    public static func make(model: GroqKeyModel) -> OnboardingStep {
        OnboardingStep(
            id: GroqAccessInfo.stepID, logName: "groq-key", order: GroqAccessInfo.stepOrder, title: KeyTexts.title,
            completesAutomatically: true,
            isSatisfied: { model.isUsable },
            content: { KeyStepView(model: model) })
    }
}

struct KeyStepView: View {
    let model: GroqKeyModel

    var body: some View {
        OnboardingPageLayout(symbol: "key.fill", title: KeyTexts.title, text: KeyTexts.explanation) {
            VStack(alignment: .leading, spacing: 12) {
                if model.isUsable && model.lastResult == nil {
                    KeyStatusLabel(model: model)
                }
                if model.legacyKeyAvailable && !model.isUsable {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(KeyTexts.takeoverHint)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                        Button(KeyTexts.takeoverButton) { Task { await model.takeOver() } }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .disabled(model.isChecking)
                    }
                }
                KeyEntryView(model: model)
                VStack(alignment: .leading, spacing: 4) {
                    Text(KeyTexts.help)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Link(KeyTexts.helpLinkTitle, destination: KeyTexts.helpURL)
                        .font(.callout)
                }
            }
            .frame(maxWidth: 420)
        }
        .onAppear { model.lookForLegacyKey() }
    }
}
