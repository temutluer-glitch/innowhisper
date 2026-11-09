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

    private static let closingPunctuation: Set<Character> = [".", "!", "?", "…"]
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
        var pieceTexts: [String] = []
        for segments in pieces {
            let kept = segments.filter(keeps)
            dropped += segments.count - kept.count
            let texts = kept.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            if !texts.isEmpty { pieceTexts.append(texts.joined(separator: " ")) }
        }
        let joined = tidy(pieceTexts.joined(separator: " "))
        let (withoutSubtitles, removed) = removingSubtitleSentences(from: joined)

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

    /// Removes every complete subtitle credit line, wherever it stands
    /// (AC-16): in quotes or brackets, after a dash or a comma, or glued to a
    /// piece without full stop (BUG-16). Only the whole credit wording counts
    /// and it must end the sentence, so a spoken sentence that merely
    /// mentions subtitles, funk, the ZDF or Amara.org stays (BUG-3).
    static func removingSubtitleSentences(from text: String) -> (text: String, removed: Int) {
        let range = NSRange(text.startIndex..., in: text)
        let removed = creditPattern.numberOfMatches(in: text, range: range)
        guard removed > 0 else { return (text, 0) }
        let kept = creditPattern.stringByReplacingMatches(in: text, range: range, withTemplate: " ")
        return (tidy(kept), removed)
    }

    /// A credit line Whisper invents from subtitled training data: who made the
    /// subtitles (ZDF, also "für funk", with an optional year, or the
    /// Amara.org community), with optional quotes, brackets or a dash around
    /// it, and closed by punctuation, a closing quote or the end of the text.
    static let creditPattern: NSRegularExpression = {
        let opening = #"(?:[-–—]\s*)?[„“"'«»(\[]?\s*"#
        let zdf =
            #"untertitel(?:ung)?(?:\s*:\s*|\s+(?:im\s+auftrag\s+)?(?:des|vom|von)\s+)zdf(?:\s+für\s+funk)?(?:,?\s*\d{4})?"#
        let amara =
            #"(?:untertitel(?:ung)?\s+(?:der|von\s+der)\s+|subtitles\s+by\s+the\s+)?amara\s*\.\s*org[\s-]*community"#
        let closing = #"(?:\s*[.!]+[“”"'«»)\]]*|[“”"'«»)\]]+|\s*$)"#
        let pattern = #"(?<![\p{L}\p{N}])"# + opening + "(?:" + zdf + "|" + amara + ")" + closing + #"(?=\s|$)"#
        // The pattern is a fixed literal; a failure here is a programming error.
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()

    /// Splits text into sentences. A sentence ends after a run of closing
    /// punctuation followed by whitespace or the end, so "Amara.org" and
    /// "20.10.2020" stay whole. Leading whitespace belongs to the next
    /// sentence; concatenating all parts gives back the input.
    static func sentences(of text: String) -> [String] {
        var result: [String] = []
        var current = ""
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            current.append(character)
            let next = text.index(after: index)
            if closingPunctuation.contains(character),
                next == text.endIndex || text[next].isWhitespace
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
