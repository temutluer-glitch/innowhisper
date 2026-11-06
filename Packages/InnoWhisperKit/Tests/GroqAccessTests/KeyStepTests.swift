import AppShell
import Foundation
import Testing

@testable import GroqAccess

@MainActor
@Suite struct KeyStepTests {
    let defaults = UserDefaults(suiteName: "KeyStepTests-\(UUID().uuidString)")!

    func makeModel(store: FakeStore = FakeStore(), checker: FakeChecker = FakeChecker()) -> GroqKeyModel {
        GroqKeyModel(
            store: store, legacy: FakeLegacy(), checker: checker, defaults: defaults,
            problems: ProblemCenter(), onboardingFinishedOnce: { false })
    }

    // AC-1, EC-7: before the microphone (30), done by itself with a stored key
    @Test func stepComesFirstAndCompletesByItself() {
        let step = KeyStep.make(model: makeModel())
        #expect(step.id == "groq-key")
        #expect(step.order == 10)
        #expect(step.order < 30)
        #expect(step.completesAutomatically)
        #expect(step.title == "Zugangsschlüssel")
    }

    // AC-2, AC-5, AC-10
    @Test func weiterIsFreeOnlyWithAWorkingOrUncheckedKey() async {
        let checker = FakeChecker(.rejected)
        let model = makeModel(checker: checker)
        let step = KeyStep.make(model: model)
        #expect(!step.isSatisfied())
        await model.submit("gsk_wrong001")
        #expect(!step.isSatisfied())
        checker.answer(.unreachable)
        await model.submit("gsk_later002")
        #expect(step.isSatisfied())
    }

    // EC-7: a key stored before counts at once
    @Test func storedKeySatisfiesTheStep() {
        let step = KeyStep.make(model: makeModel(store: FakeStore(key: "gsk_stored03")))
        #expect(step.isSatisfied())
    }

    // AC-1, AC-3, AC-7, AC-13: texts as in the spec
    @Test func textsMatchTheSpec() {
        #expect(
            KeyTexts.explanation == "InnoWhisper braucht deinen Groq-Schlüssel, um deine Aufnahmen in Text umzuwandeln."
        )
        #expect(KeyTexts.help.hasPrefix("So bekommst du deinen Schlüssel: 1. Melde dich auf console.groq.com an"))
        #expect(KeyTexts.help.contains("2. Klicke links auf „API Keys“ und dann auf „Create API Key“."))
        #expect(KeyTexts.help.hasSuffix("3. Kopiere den Schlüssel und füge ihn hier ein."))
        #expect(KeyTexts.helpURL.host == "console.groq.com")
        #expect(
            KeyTexts.takeoverHint.contains("Gleich fragt macOS nach deinem Mac-Passwort; das kommt von InnoWhisper."))
        #expect(
            KeyTexts.removeQuestion == "Schlüssel wirklich entfernen? Ohne Schlüssel kann InnoWhisper nicht diktieren.")
        #expect(KeyEntryResult.works.message == "Schlüssel funktioniert.")
        #expect(
            KeyEntryResult.rejected.message
                == "Groq lehnt diesen Schlüssel ab. Prüfe, ob du ihn vollständig kopiert hast.")
        #expect(
            KeyEntryResult.savedUnchecked.message
                == "Groq ist gerade nicht erreichbar. Der Schlüssel wird gespeichert und später geprüft.")
    }
}
