import Foundation

/// The finished text of one recording plus what the filter removed, for the
/// log (design.md → AC-15 bis AC-17). The counts never carry dictated content.
public struct FilteredTranscript: Equatable, Sendable {
    /// The text to pass on; empty when nothing usable remained.
    public let text: String
    /// Segments dropped because Groq marked them as probably no speech.
    public let droppedSegments: Int
    /// Subtitle sentences removed anywhere in the text.
    public let removedSubtitleSentences: Int
    /// `true` when the whole remaining text was only a known invented phrase.
    public let wasOnlyInventedPhrase: Bool

    public init(text: String, droppedSegments: Int, removedSubtitleSentences: Int, wasOnlyInventedPhrase: Bool) {
        self.text = text
        self.droppedSegments = droppedSegments
        self.removedSubtitleSentences = removedSubtitleSentences
        self.wasOnlyInventedPhrase = wasOnlyInventedPhrase
    }
}

/// Filters Groq's segments and joins the pieces of one recording into one
/// text (AC-7, AC-15, AC-16, AC-17, EC-1). Pure: no I/O, no state.
public enum TranscriptFilter {
    /// Phrases Whisper invents in silence. Removed only when they are the
    /// whole result, so a spoken "Vielen Dank." at the end of a longer
    /// dictation stays (spec → Produktentscheidungen). Compared normalised.
    public static let inventedPhrases: [String] = [
        "thank you", "thanks", "thanks for watching", "thank you for watching", "thank you very much", "you",
        "danke", "vielen dank", "tschüss", "bye", "music", "[music]", "♪♪", "...", ".",
        "vielen dank fürs zuschauen", "danke fürs zuschauen", "bis zum nächsten mal",
    ]

    private static let normalisedInventedPhrases = Set(inventedPhrases.map(normalised))

    private static let closingPunctuation: Set<Character> = [
        ".", "!", "?", "…", ";", "“", "”", "\"", "»", "«", ")", "]",
    ]
    private static let trailingStrip: Set<Character> = [
        ".", "!", "?", "…", ",", ";", ":", "\"", "'", "„", "“", "”", "‚", "‘", "’", "«", "»",
    ]
    private static let quotes: Set<Character> = ["\"", "'", "„", "“", "”", "‚", "‘", "’", "«", "»"]

    /// Whether a segment stays: it is dropped only when Groq reports both
    /// "no speech" above 0.6 and an average log probability below −1.0.
    public static func keeps(_ segment: TranscriptSegment) -> Bool {
        guard let noSpeech = segment.noSpeechProbability,
            let logProbability = segment.averageLogProbability
        else { return true }
        return
            !(noSpeech > TranscriptionInfo.noSpeechThreshold
            && logProbability < TranscriptionInfo.lowConfidenceThreshold)
    }

    /// Filters each piece's segments, joins the pieces in the given order,
    /// removes subtitle sentences and empties a result that is only an
    /// invented phrase.
    public static func filter(pieces: [[TranscriptSegment]]) -> FilteredTranscript {
        var dropped = 0
        var creditSections = 0
        var pieceTexts: [String] = []
        for segments in pieces {
            let kept = segments.filter(keeps)
            dropped += segments.count - kept.count
            var texts = kept.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            // A Groq section that is exactly a credit line goes as a whole (BUG-16).
            let beforeCredits = texts.count
            texts.removeAll(where: isCreditLine)
            creditSections += beforeCredits - texts.count
            if !texts.isEmpty { pieceTexts.append(texts.joined(separator: " ")) }
        }
        let joined = tidy(pieceTexts.joined(separator: " "))
        let (withoutSubtitles, creditSentences) = removingSubtitleSentences(from: joined)
        let removed = creditSections + creditSentences

        guard !withoutSubtitles.isEmpty else {
            return FilteredTranscript(
                text: "", droppedSegments: dropped, removedSubtitleSentences: removed, wasOnlyInventedPhrase: false)
        }
        if normalisedInventedPhrases.contains(normalised(withoutSubtitles)) {
            return FilteredTranscript(
                text: "", droppedSegments: dropped, removedSubtitleSentences: removed, wasOnlyInventedPhrase: true)
        }
        return FilteredTranscript(
            text: withoutSubtitles, droppedSegments: dropped, removedSubtitleSentences: removed,
            wasOnlyInventedPhrase: false)
    }

    /// Collapses runs of spaces and tabs, keeps line breaks, trims the ends.
    static func tidy(_ text: String) -> String {
        text.replacing(/[ \t]+/, with: " ")
            .replacing(/[ ]?\n[ ]?/, with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Removes every sentence that is, as a whole, a subtitle credit line
    /// (AC-16, BUG-16). Nothing is ever cut from inside a sentence, so a
    /// spoken sentence that mentions subtitles, funk, the ZDF or Amara.org
    /// stays (BUG-3).
    static func removingSubtitleSentences(from text: String) -> (text: String, removed: Int) {
        var removed = 0
        var kept = ""
        for sentence in sentences(of: text) {
            if isCreditLine(sentence) {
                removed += 1
            } else {
                kept += sentence
            }
        }
        return removed == 0 ? (text, 0) : (tidy(kept), removed)
    }

    /// Credit lines are short; anything longer is never one, which also keeps
    /// the check cheap on hostile model output (BUG-19).
    static let longestCreditLine = 160

    /// Whether `candidate` is exactly a credit line Whisper invents from
    /// subtitled training data: who made the subtitles (the ZDF with "im
    /// Auftrag", "für funk" or a year, or the Amara.org community). Quotes,
    /// brackets, a leading dash and closing punctuation around it are ignored.
    /// The short "Untertitel vom ZDF" alone is spoken German and stays.
    static func isCreditLine(_ candidate: String) -> Bool {
        guard candidate.count <= longestCreditLine else { return false }
        let line = creditCore(of: candidate)
        guard !line.isEmpty else { return false }
        return creditWordings.contains { line.wholeMatch(of: $0) != nil }
    }

    /// Lowercased, Unicode-composed, whitespace collapsed, and stripped of
    /// surrounding quotes, brackets, dashes and punctuation; no regular
    /// expression runs over the raw text (BUG-19).
    static func creditCore(of candidate: String) -> String {
        let words = candidate.precomposedStringWithCanonicalMapping.lowercased()
            .split(whereSeparator: { $0.isWhitespace })
        var line = words.joined(separator: " ")
        while let first = line.first, creditWrapping.contains(first) || first == " " { line.removeFirst() }
        while let last = line.last, creditWrapping.contains(last) || last == " " { line.removeLast() }
        return line
    }

    private static let creditWrapping: Set<Character> = [
        "-", "–", "—", "\"", "'", "„", "“", "”", "‚", "‘", "’", "«", "»", "(", ")", "[", "]",
        ".", "!", "?", "…", ";", ":", ",",
    ]

    /// The credit wordings, each matched against the whole normalised line.
    nonisolated(unsafe) private static let creditWordings: [Regex<Substring>] = [
        /untertitel(?:ung)? im auftrag (?:des|von|vom) zdf(?: für funk)?(?:,? \d{4})?/,
        /untertitel(?:ung)? (?:des|vom|von) zdf für funk(?:,? \d{4})?/,
        /untertitel(?:ung)? (?:des|vom|von) zdf,? \d{4}/,
        /untertitel(?:ung)? ?: ?zdf(?: für funk)?(?:,? \d{4})?/,
        /(?:untertitel(?:ung)? (?:der|von der|durch die|aufgrund der) )?amara ?\. ?org[ -]?community/,
        /subtitles (?:created )?by the amara ?\. ?org community/,
    ]

    /// Splits text into sentences for the credit check. A sentence ends after
    /// closing punctuation, a closing quote or bracket followed by whitespace
    /// or the end, and at every line break, so "Amara.org" and "20.10.2020"
    /// stay whole. Splitting too often is harmless: only whole credit lines
    /// are removed, everything else is put back unchanged. Leading whitespace belongs to the next
    /// sentence; concatenating all parts gives back the input.
    static func sentences(of text: String) -> [String] {
        var result: [String] = []
        var current = ""
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            current.append(character)
            let next = text.index(after: index)
            if character.isNewline
                || (closingPunctuation.contains(character) && (next == text.endIndex || text[next].isWhitespace))
            {
                result.append(current)
                current = ""
            }
            index = next
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    /// Lowercased, whitespace collapsed, surrounding quotes and trailing
    /// punctuation removed; punctuation-only text becomes empty.
    static func normalised(_ text: String) -> String {
        var value = text.lowercased().replacing(/\s+/, with: " ").trimmingCharacters(in: .whitespaces)
        while let last = value.last, trailingStrip.contains(last) || last == " " { value.removeLast() }
        while let first = value.first, quotes.contains(first) || first == " " { value.removeFirst() }
        return value
    }
}
