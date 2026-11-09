import Testing

@testable import Transcription

@Suite struct TranscriptFilterTests {
    private func segment(_ text: String, _ noSpeech: Double? = nil, _ logProbability: Double? = nil)
        -> TranscriptSegment
    {
        TranscriptSegment(text: text, noSpeechProbability: noSpeech, averageLogProbability: logProbability)
    }

    // AC-17: a segment is dropped only when both "no speech" > 0.6 and log probability < −1.0
    @Test func segmentRuleNeedsBothConditions() {
        #expect(!TranscriptFilter.keeps(segment("x", 0.61, -1.01)))
        #expect(!TranscriptFilter.keeps(segment("x", 0.95, -2.5)))
        #expect(TranscriptFilter.keeps(segment("x", 0.95, -0.2)))
        #expect(TranscriptFilter.keeps(segment("x", 0.1, -2.5)))
    }

    // AC-17: the boundary values 0.6 and −1.0 themselves are kept
    @Test func segmentRuleBoundariesAreKept() {
        #expect(TranscriptFilter.keeps(segment("x", 0.6, -1.5)))
        #expect(TranscriptFilter.keeps(segment("x", 0.9, -1.0)))
        #expect(TranscriptFilter.keeps(segment("x", 0.6, -1.0)))
    }

    // design.md: missing values keep the segment
    @Test func segmentRuleKeepsMissingValues() {
        #expect(TranscriptFilter.keeps(segment("x")))
        #expect(TranscriptFilter.keeps(segment("x", 0.99, nil)))
        #expect(TranscriptFilter.keeps(segment("x", nil, -3.0)))
    }

    // AC-17: dropped segments vanish from the text and are counted
    @Test func droppedSegmentsLeaveTheText() {
        let result = TranscriptFilter.filter(pieces: [
            [segment("Hallo Jasmin,", 0.01, -0.2), segment("bitte ruf mich an.", 0.02, -0.3)],
            [segment("Das hat keiner gesagt.", 0.9, -1.8)],
        ])
        #expect(result.text == "Hallo Jasmin, bitte ruf mich an.")
        #expect(result.droppedSegments == 1)
        #expect(!result.wasOnlyInventedPhrase)
    }

    // AC-7: pieces are joined in order with single spaces, ends tidied
    @Test func joinsPiecesInOrder() {
        let result = TranscriptFilter.filter(pieces: [
            [segment("  Erster Teil, "), segment("\tnoch erster.  ")],
            [segment("Zweiter   Teil.")],
            [segment(" Dritter\t\tTeil. ")],
        ])
        #expect(result.text == "Erster Teil, noch erster. Zweiter Teil. Dritter Teil.")
        #expect(result.droppedSegments == 0)
        #expect(result.removedSubtitleSentences == 0)
    }

    // AC-7: line breaks inside a segment stay, spaces around them go
    @Test func keepsLineBreaks() {
        let result = TranscriptFilter.filter(pieces: [[segment("Liebe Grüße \n Timur")]])
        #expect(result.text == "Liebe Grüße\nTimur")
    }

    // EC-1: a silent middle piece contributes nothing and leaves no double spaces
    @Test func silentMiddlePieceAddsNothing() {
        let result = TranscriptFilter.filter(pieces: [
            [segment("Anfang.", 0.05, -0.2)],
            [segment("Vielen Dank.", 0.92, -1.4), segment("Tschüss.", 0.88, -1.9)],
            [segment(" ", 0.1, -0.1)],
            [segment("Ende.", 0.05, -0.3)],
        ])
        #expect(result.text == "Anfang. Ende.")
        #expect(!result.text.contains("  "))
        #expect(result.droppedSegments == 2)
    }

    // AC-16: subtitle sentences are removed in the middle, at the end and alone
    @Test func removesSubtitleSentencesAnywhere() {
        let middle = TranscriptFilter.filter(pieces: [
            [segment("Erster Satz. Untertitel der Amara.org-Community. Zweiter Satz.")]
        ])
        #expect(middle.text == "Erster Satz. Zweiter Satz.")
        #expect(middle.removedSubtitleSentences == 1)

        let end = TranscriptFilter.filter(pieces: [
            [segment("Das Angebot geht heute raus.")], [segment("Untertitelung des ZDF für funk, 2017")],
        ])
        #expect(end.text == "Das Angebot geht heute raus.")
        #expect(end.removedSubtitleSentences == 1)

        let alone = TranscriptFilter.filter(pieces: [[segment("Untertitel im Auftrag des ZDF, 2020.")]])
        #expect(alone.text.isEmpty)
        #expect(alone.removedSubtitleSentences == 1)
        #expect(!alone.wasOnlyInventedPhrase)

        let english = TranscriptFilter.filter(pieces: [
            [segment("Bitte prüfen. Subtitles by the Amara.org community")]
        ])
        #expect(english.text == "Bitte prüfen.")
    }

    // AC-16: removal is case-insensitive; a sentence that merely mentions subtitles stays
    @Test func subtitleMatchIsCaseInsensitiveAndNarrow() {
        let shouting = TranscriptFilter.filter(pieces: [[segment("Gut. UNTERTITEL IM AUFTRAG DES ZDF! Weiter.")]])
        #expect(shouting.text == "Gut. Weiter.")
        let real = TranscriptFilter.filter(pieces: [[segment("Die Untertitel im Video fehlen noch.")]])
        #expect(real.text == "Die Untertitel im Video fehlen noch.")
        #expect(real.removedSubtitleSentences == 0)
    }

    // AC-15: a result that is only a known invented phrase becomes empty
    @Test(arguments: [
        "Vielen Dank!", "  thanks for watching. ", "Danke.", "Tschüss.", "Thank you.", "„Vielen Dank.“",
        "Vielen  Dank fürs Zuschauen!", "...", ".", "♪♪", "[Music]", "Bis zum nächsten Mal.",
    ])
    func wholeInventedPhraseBecomesEmpty(_ text: String) {
        let result = TranscriptFilter.filter(pieces: [[segment(text)]])
        #expect(result.text.isEmpty)
        #expect(result.wasOnlyInventedPhrase)
    }

    // AC-15: an invented phrase left over after removing a subtitle sentence is emptied too
    @Test func phraseLeftAfterSubtitleRemovalBecomesEmpty() {
        let result = TranscriptFilter.filter(pieces: [[segment("Vielen Dank. Untertitel der Amara.org-Community")]])
        #expect(result.text.isEmpty)
        #expect(result.wasOnlyInventedPhrase)
        #expect(result.removedSubtitleSentences == 1)
    }

    // AC-16: a spoken "Vielen Dank." at the end of a longer dictation stays
    @Test func longerTextEndingWithThanksStays() {
        let text = "Hallo Herr Jolmes, anbei das Angebot für die Glasreiniger. Vielen Dank."
        let result = TranscriptFilter.filter(pieces: [[segment(text)]])
        #expect(result.text == text)
        #expect(!result.wasOnlyInventedPhrase)
    }

    // EC-1: empty input and whitespace-only segments give an empty, non-invented result
    @Test func emptyInputGivesEmptyText() {
        let none = TranscriptFilter.filter(pieces: [])
        #expect(
            none
                == FilteredTranscript(
                    text: "", droppedSegments: 0, removedSubtitleSentences: 0, wasOnlyInventedPhrase: false))
        let blank = TranscriptFilter.filter(pieces: [[], [segment("  \n ")]])
        #expect(blank.text.isEmpty)
        #expect(!blank.wasOnlyInventedPhrase)
    }

    // AC-16: splitting keeps dotted words whole and gives back the input
    @Test func sentenceSplitKeepsDottedWords() {
        let text = "Termin am 20.10.2020 bei Amara.org! Gut?  Ja"
        let parts = TranscriptFilter.sentences(of: text)
        #expect(parts == ["Termin am 20.10.2020 bei Amara.org!", " Gut?", "  Ja"])
        #expect(parts.joined() == text)
    }
}
