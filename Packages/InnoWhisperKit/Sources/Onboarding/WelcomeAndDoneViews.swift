import SwiftUI

/// Page "Willkommen" (AC-3).
struct WelcomePageView: View {
    var body: some View {
        OnboardingPageLayout(
            symbol: "waveform",
            title: "Willkommen bei InnoWhisper.",
            text: """
                Tastenkürzel drücken, sprechen, und dein Text erscheint dort, wo du gerade schreibst. \
                Damit das klappt, braucht InnoWhisper zwei Erlaubnisse von dir.
                """
        ) { EmptyView() }
    }
}

/// Page "Fertig" (AC-4).
struct DonePageView: View {
    var body: some View {
        OnboardingPageLayout(
            symbol: "checkmark.circle.fill",
            title: "Alles bereit.",
            text: "Du findest InnoWhisper ab jetzt oben rechts in der Menüleiste."
        ) { EmptyView() }
    }
}

/// The common look of one onboarding page: symbol, heading, explanation and
/// an optional area below (used by the permission steps too).
public struct OnboardingPageLayout<Extra: View>: View {
    let symbol: String
    let title: String
    let text: String
    let extra: Extra

    public init(symbol: String, title: String, text: String, @ViewBuilder extra: () -> Extra) {
        self.symbol = symbol
        self.title = title
        self.text = text
        self.extra = extra()
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 44))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            extra
        }
        .frame(maxWidth: 400)
    }
}
