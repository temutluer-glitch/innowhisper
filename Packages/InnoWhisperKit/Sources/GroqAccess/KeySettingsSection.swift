import SwiftUI

/// Group "Groq-Schlüssel" in "Zugang & Erlaubnisse" (AC-11 to AC-13). The
/// form around it and the problem hint above it come from the app frame.
public struct KeySettingsSection: View {
    @Bindable var model: GroqKeyModel
    @State private var confirmRemove = false

    public init(model: GroqKeyModel) {
        self.model = model
    }

    public var body: some View {
        Section("Groq-Schlüssel") {
            LabeledContent {
                KeyStatusLabel(model: model)
            } label: {
                Text("Stand")
                Text(KeyTexts.explanation)
            }
            if model.status == .missing {
                KeyEntryView(model: model)
            } else {
                HStack(spacing: 8) {
                    Button("Prüfen") { Task { await model.checkStored(showResult: true) } }
                        .disabled(model.isChecking)
                    Button(model.wantsEdit ? "Abbrechen" : "Ändern") {
                        model.wantsEdit.toggle()
                        model.clearResult()
                    }
                    Button("Entfernen", role: .destructive) { confirmRemove = true }
                        .disabled(model.isChecking)
                    if model.isChecking {
                        ProgressView().controlSize(.small)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                if model.wantsEdit {
                    KeyEntryView(model: model)
                } else if let result = model.lastResult {
                    KeyResultLine(result: result)
                }
            }
        }
        .confirmationDialog(KeyTexts.removeQuestion, isPresented: $confirmRemove) {
            Button("Entfernen", role: .destructive) { model.remove() }
            Button("Abbrechen", role: .cancel) {}
        }
    }
}
