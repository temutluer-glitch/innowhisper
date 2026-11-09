import Diagnostics
import Foundation
import Observation

/// Transcription (PROJ-6): turns finished recordings into text via Groq,
/// in spoken order, with long recordings split into pieces and a filter
/// against invented text.
public enum TranscriptionInfo {
    /// Target length of one piece of a long recording (design.md).
    public static let pieceLength: Duration = .seconds(5 * 60)
    /// Recordings up to this length are sent in one piece.
    public static let singlePieceLimit: Duration = .seconds(5 * 60 + 30)
    /// A cut is searched this far before and after each piece mark.
    public static let cutSearchWindow: Duration = .seconds(20)
    /// Length of the quiet stretch a cut is placed in.
    public static let quietStretch: Duration = .milliseconds(500)
    /// At most this many requests to Groq at the same time (AC-6).
    public static let maximumParallelRequests = 3
    /// Time limit of one request: base plus a share per minute of audio.
    public static let requestBaseTimeout: Duration = .seconds(20)
    public static let requestTimeoutPerMinute: Duration = .seconds(10)
    /// Pauses before the two silent retries (AC-10).
    public static let silentRetryDelays: [Duration] = [.seconds(1), .seconds(3)]
    /// Groq's limit wait is sat out up to this long, then the user is told (AC-14).
    public static let longestSelfWait: Duration = .seconds(120)
    /// This many converted recordings are kept (AC-19).
    public static let keptRecordings = 50
    /// Longest text accepted from Groq for one piece (SEC-07).
    public static let maximumPieceCharacters = 20_000
    /// A segment counts as "no speech" above this value…
    public static let noSpeechThreshold = 0.6
    /// …together with an average log probability below this one (design.md).
    public static let lowConfidenceThreshold = -1.0
    /// Groq's transcription endpoint.
    public static let endpoint = URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!
    /// Settings keys (design.md → Datenmodell).
    public static let modelDefaultsKey = "transcription.model"
    public static let languageDefaultsKey = "transcription.language"
    public static let recordingsDefaultsKey = "transcription.recordings"

    /// Time limit for one piece of the given length.
    public static func requestTimeout(for audio: Duration) -> Duration {
        let minutes = Double(audio.components.seconds) / 60 + Double(audio.components.attoseconds) / 6e19
        return requestBaseTimeout + requestTimeoutPerMinute * minutes
    }
}

/// Which Groq model transcribes (AC-2).
public enum TranscriptionModel: String, CaseIterable, Sendable, LogValue {
    case fast
    case accurate

    /// Default for a fresh install (Timur, 07.11.2026, after ADR-003).
    public static let factory = TranscriptionModel.fast

    /// The model name Groq expects.
    public var groqName: String {
        switch self {
        case .fast: "whisper-large-v3-turbo"
        case .accurate: "whisper-large-v3"
        }
    }

    /// Label in the settings.
    public var title: String {
        switch self {
        case .fast: "Schnell"
        case .accurate: "Genauer"
        }
    }

    public var logDescription: StaticString {
        switch self {
        case .fast: "fast"
        case .accurate: "accurate"
        }
    }
}

/// Which language Groq should expect (AC-2).
public enum TranscriptionLanguage: String, CaseIterable, Sendable, LogValue {
    case german = "de"
    case english = "en"
    case automatic = "auto"

    public static let factory = TranscriptionLanguage.german

    /// The language code sent to Groq; `nil` lets Groq detect it.
    public var groqCode: String? {
        switch self {
        case .german: "de"
        case .english: "en"
        case .automatic: nil
        }
    }

    /// Label in the settings.
    public var title: String {
        switch self {
        case .german: "Deutsch"
        case .english: "Englisch"
        case .automatic: "Automatisch"
        }
    }

    public var logDescription: StaticString {
        switch self {
        case .german: "de"
        case .english: "en"
        case .automatic: "auto"
        }
    }
}

/// Model and language chosen in the settings; an unknown stored value falls
/// back to the factory choice (design.md → Datenmodell).
@MainActor
@Observable
public final class TranscriptionSettings {
    public private(set) var model: TranscriptionModel
    public private(set) var language: TranscriptionLanguage

    @ObservationIgnored private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        model =
            defaults.string(forKey: TranscriptionInfo.modelDefaultsKey).flatMap(TranscriptionModel.init)
            ?? .factory
        language =
            defaults.string(forKey: TranscriptionInfo.languageDefaultsKey).flatMap(TranscriptionLanguage.init)
            ?? .factory
    }

    public func setModel(_ new: TranscriptionModel) {
        guard new != model else { return }
        defaults.set(new.rawValue, forKey: TranscriptionInfo.modelDefaultsKey)
        model = new
        Log.write("Transcription model changed to \(new)", category: .transcription)
    }

    public func setLanguage(_ new: TranscriptionLanguage) {
        guard new != language else { return }
        defaults.set(new.rawValue, forKey: TranscriptionInfo.languageDefaultsKey)
        language = new
        Log.write("Transcription language changed to \(new)", category: .transcription)
    }
}

/// One section of Groq's answer for one piece (design.md → Abläufe). Shared
/// by the Groq adapter (T5), which produces it, and the text filter (T6),
/// which decides what stays.
public struct TranscriptSegment: Equatable, Sendable {
    /// The recognised text of the section, already checked by the adapter.
    public let text: String
    /// Groq's estimate that the section holds no speech (0…1); `nil` when absent.
    public let noSpeechProbability: Double?
    /// Average log probability of the section's tokens; `nil` when absent.
    public let averageLogProbability: Double?

    public init(text: String, noSpeechProbability: Double? = nil, averageLogProbability: Double? = nil) {
        self.text = text
        self.noSpeechProbability = noSpeechProbability
        self.averageLogProbability = averageLogProbability
    }
}
