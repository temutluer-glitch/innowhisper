import Testing

@testable import GroqAccess

/// Written by /qa: the user-facing wording the spec fixes and no other test pins.
@Suite struct KeyTextsQATests {
    // AC-11: the four states in the settings group
    @Test func statusTitlesMatchTheSpec() {
        #expect(KeyStatus.valid.title == "Schlüssel funktioniert")
        #expect(KeyStatus.unchecked.title == "Noch nicht geprüft")
        #expect(KeyStatus.invalid.title == "Ungültig")
        #expect(KeyStatus.missing.title == "Kein Schlüssel")
    }

    // AC-4, AC-9, EC-8: result lines below the field
    @Test func resultMessagesMatchTheSpec() {
        #expect(KeyEntryResult.works.message == "Schlüssel funktioniert.")
        #expect(
            KeyEntryResult.rejected.message
                == "Groq lehnt diesen Schlüssel ab. Prüfe, ob du ihn vollständig kopiert hast.")
        #expect(
            KeyEntryResult.savedUnchecked.message
                == "Groq ist gerade nicht erreichbar. Der Schlüssel wird gespeichert und später geprüft.")
        #expect(
            KeyEntryResult.takeoverFailed.message
                == "Übernahme hat nicht geklappt. Füge deinen Schlüssel einfach unten ein.")
        #expect(
            KeyEntryResult.saveFailed.message
                == "Der Schlüssel konnte nicht gespeichert werden. Bitte versuche es noch einmal.")
    }

    // AC-4: only "works" carries the green check mark
    @Test func onlyWorksCountsAsSuccess() {
        let all: [KeyEntryResult] = [
            .works, .rejected, .savedUnchecked, .saveFailed, .removeFailed, .takeoverFailed, .notReachable,
        ]
        #expect(all.filter(\.isSuccess) == [.works])
    }

    // AC-7, AC-13: takeover hint and remove question
    @Test func hintAndQuestionMatchTheSpec() {
        #expect(
            KeyTexts.takeoverHint
                == "Du hast InnoWhisper schon benutzt. Wir übernehmen deinen Schlüssel von dort. "
                + "Gleich fragt macOS nach deinem Mac-Passwort; das kommt von InnoWhisper.")
        #expect(
            KeyTexts.removeQuestion == "Schlüssel wirklich entfernen? Ohne Schlüssel kann InnoWhisper nicht diktieren.")
    }
}
