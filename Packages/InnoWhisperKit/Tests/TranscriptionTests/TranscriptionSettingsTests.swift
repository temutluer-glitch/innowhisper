import Diagnostics
import Foundation
import Testing

@testable import Transcription

@MainActor
@Suite struct TranscriptionSettingsTests {
    let defaults = UserDefaults(suiteName: "TranscriptionSettings-\(UUID().uuidString)")!

    // AC-2: fresh install → "Schnell" and "Deutsch"
    @Test func freshInstallUsesFastAndGerman() {
        let settings = TranscriptionSettings(defaults: defaults)
        #expect(settings.model == .fast)
        #expect(settings.model.groqName == "whisper-large-v3-turbo")
        #expect(settings.language == .german)
        #expect(settings.language.groqCode == "de")
    }

    // AC-2: all choices offered, with their labels
    @Test func choicesAndLabels() {
        #expect(TranscriptionModel.allCases.map(\.title) == ["Schnell", "Genauer"])
        #expect(TranscriptionModel.accurate.groqName == "whisper-large-v3")
        #expect(TranscriptionLanguage.allCases.map(\.title) == ["Deutsch", "Englisch", "Automatisch"])
        #expect(TranscriptionLanguage.automatic.groqCode == nil)
        #expect(TranscriptionLanguage.english.groqCode == "en")
    }

    // AC-4: a change is stored and survives a restart
    @Test func changesAreStored() {
        let settings = TranscriptionSettings(defaults: defaults)
        settings.setModel(.accurate)
        settings.setLanguage(.automatic)
        let reloaded = TranscriptionSettings(defaults: defaults)
        #expect(reloaded.model == .accurate)
        #expect(reloaded.language == .automatic)
    }

    // design.md: an unknown stored value falls back to the factory choice
    @Test func unknownValuesFallBack() {
        defaults.set("whisper-large-v2", forKey: TranscriptionInfo.modelDefaultsKey)
        defaults.set("fr", forKey: TranscriptionInfo.languageDefaultsKey)
        let settings = TranscriptionSettings(defaults: defaults)
        #expect(settings.model == .fast)
        #expect(settings.language == .german)
    }

    @Test func fixedValuesMatchTheDesign() {
        #expect(TranscriptionInfo.pieceLength == .seconds(300))
        #expect(TranscriptionInfo.maximumParallelRequests == 3)
        #expect(TranscriptionInfo.silentRetryDelays == [.seconds(1), .seconds(3)])
        #expect(TranscriptionInfo.longestSelfWait == .seconds(120))
        #expect(TranscriptionInfo.keptRecordings == 50)
        #expect(TranscriptionInfo.requestTimeout(for: .seconds(300)) == .seconds(70))
        #expect(TranscriptionInfo.requestTimeout(for: .seconds(30)) == .seconds(25))
        #expect(LogCategory.transcription.name == "transcription")
    }

    // AC-14: wait shown in whole minutes, rounded up
    @Test func limitTextRoundsUp() {
        #expect(
            TranscriptionTexts.limitReached(wait: .seconds(300))
                == "Groq-Grenze erreicht. Versuche es in 5 Minuten erneut.")
        #expect(
            TranscriptionTexts.limitReached(wait: .seconds(61))
                == "Groq-Grenze erreicht. Versuche es in 2 Minuten erneut.")
        #expect(
            TranscriptionTexts.limitReached(wait: .seconds(30))
                == "Groq-Grenze erreicht. Versuche es in 1 Minute erneut.")
        #expect(TranscriptionTexts.notConverted(count: 1) == "1 Diktat nicht umgewandelt.")
        #expect(TranscriptionTexts.notConverted(count: 3) == "3 Diktate nicht umgewandelt.")
    }
}
