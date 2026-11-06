import SwiftUI

/// Fixed texts of the key screens (AC-1, AC-3, AC-7, AC-13).
enum KeyTexts {
    static let title = "Zugangsschlüssel"
    static let explanation = "InnoWhisper braucht deinen Groq-Schlüssel, um deine Aufnahmen in Text umzuwandeln."
    static let help =
        "So bekommst du deinen Schlüssel: 1. Melde dich auf console.groq.com an oder lege ein Konto an. "
        + "2. Klicke links auf „API Keys“ und dann auf „Create API Key“. "
        + "3. Kopiere den Schlüssel und füge ihn hier ein."
    static let helpLinkTitle = "Groq-Seite für Schlüssel öffnen"
    static let helpURL = URL(string: "https://console.groq.com/keys")!
    static let takeoverHint =
        "Du hast InnoWhisper schon benutzt. Wir übernehmen deinen Schlüssel von dort. "
        + "Gleich fragt macOS nach deinem Mac-Passwort; das kommt von InnoWhisper."
    static let takeoverButton = "Schlüssel übernehmen"
    static let removeQuestion = "Schlüssel wirklich entfernen? Ohne Schlüssel kann InnoWhisper nicht diktieren."
    static let fieldLabel = "Groq-Schlüssel"
}

/// The shared key field: hidden input, "Prüfen" with progress, result line
/// (AC-4 to AC-6, EC-1 to EC-3). Used by the onboarding step and the settings.
struct KeyEntryView: View {
    let model: GroqKeyModel
    @State private var input = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                SecureField(KeyTexts.fieldLabel, text: $input, prompt: Text("gsk_…"))
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(KeyTexts.fieldLabel)
                    .onSubmit(check)
                Button(action: check) {
                    if model.isChecking {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Prüfen")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(!model.canCheck(input))
                .accessibilityLabel(model.isChecking ? "Schlüssel wird geprüft" : "Prüfen")
            }
            if let result = model.lastResult {
                KeyResultLine(result: result)
            }
        }
        .onChange(of: input) { _, new in
            if !new.isEmpty { model.clearResult() }
        }
        .onChange(of: model.lastResult) { _, result in
            if let result { AccessibilityNotification.Announcement(result.message).post() }
            if result == .works || result == .savedUnchecked { input = "" }
        }
    }

    private func check() {
        let value = input
        Task { await model.submit(value) }
    }
}

/// Green check mark for success, otherwise an explanation (AC-4).
struct KeyResultLine: View {
    let result: KeyEntryResult

    var body: some View {
        Label {
            Text(result.message)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(result.isSuccess ? .green : .orange)
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }
}

/// "Schlüssel funktioniert" / "Noch nicht geprüft" / … plus the last 4 characters (AC-11).
struct KeyStatusLabel: View {
    let model: GroqKeyModel

    var body: some View {
        HStack(spacing: 8) {
            Label {
                Text(model.status.title)
            } icon: {
                Image(systemName: model.status == .valid ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(model.status == .valid ? .green : .secondary)
            }
            if let lastFour = model.lastFour {
                Text("•••• \(lastFour)")
                    .font(.body.monospaced())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("endet auf \(lastFour)")
            }
        }
        .accessibilityElement(children: .combine)
    }
}
