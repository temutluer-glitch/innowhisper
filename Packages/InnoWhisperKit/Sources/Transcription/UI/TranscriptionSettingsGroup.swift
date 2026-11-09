import SwiftUI

/// Section "Umwandlung" in the area "Aufnahme" (AC-2, AC-4): model and
/// language. Same building blocks as the sections "Tastenkürzel" and
/// "Mikrofon" above it (global rule 39: one size per surface).
public struct TranscriptionSettingsGroup: View {
    let settings: TranscriptionSettings

    public init(settings: TranscriptionSettings) {
        self.settings = settings
    }

    public var body: some View {
        Section(TranscriptionTexts.settingsGroup) {
            Picker(TranscriptionTexts.modelLabel, selection: modelBinding) {
                ForEach(TranscriptionModel.allCases, id: \.self) { model in
                    Text(model.title).tag(model)
                }
            }
            .pickerStyle(.segmented)
            Picker(TranscriptionTexts.languageLabel, selection: languageBinding) {
                ForEach(TranscriptionLanguage.allCases, id: \.self) { language in
                    Text(language.title).tag(language)
                }
            }
        }
    }

    private var modelBinding: Binding<TranscriptionModel> {
        Binding(get: { settings.model }, set: { settings.setModel($0) })
    }

    private var languageBinding: Binding<TranscriptionLanguage> {
        Binding(get: { settings.language }, set: { settings.setLanguage($0) })
    }
}
