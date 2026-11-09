import Diagnostics
import Foundation

/// Why one piece could not be transcribed (design.md → "Fehlerarten an der
/// Groq-Schnittstelle"). The adapter translates every raw answer into one of
/// these; nothing raw reaches the queue.
public enum TranscriptionFailure: Equatable, Sendable, LogValue {
    /// Groq refuses the key (401, 403): no further attempt (AC-13).
    case keyRejected
    /// Groq's limit is reached (429). `wait` is Groq's `retry-after`, `nil`
    /// when Groq named no usable wait (AC-14).
    case rateLimited(wait: Duration?)
    /// No connection: no network, network lost, host not resolvable (AC-10).
    case noInternet
    /// Time limit, 5xx or another network error: silent retries (AC-10).
    case temporary
    /// Our own request is wrong (400, 413, 415, other 4xx): a programming
    /// error, no silent retry. `status` is `nil` when the request could not
    /// even be built (piece file not readable).
    case ownError(status: Int?)
    /// 200 with an answer that fails the checks: no JSON, text missing, text
    /// over `TranscriptionInfo.maximumPieceCharacters` (SEC-07). Counts as an
    /// attempt like a temporary failure.
    case unusable

    public var logDescription: StaticString {
        switch self {
        case .keyRejected: "keyRejected"
        case .rateLimited: "rateLimited"
        case .noInternet: "noInternet"
        case .temporary: "temporary"
        case .ownError: "ownError"
        case .unusable: "unusable"
        }
    }
}

/// The answer for one piece: checked sections, or why there are none.
public enum TranscriptionPieceResult: Equatable, Sendable, LogValue {
    case success([TranscriptSegment])
    case failure(TranscriptionFailure)

    public var logDescription: StaticString {
        switch self {
        case .success: "success"
        case .failure(let failure): failure.logDescription
        }
    }
}

/// Turns one piece of a recording into text. The real adapter talks to Groq
/// (`GroqTranscriber`); tests use a stand-in.
public protocol Transcribing: Sendable {
    /// - Parameters:
    ///   - piece: The audio file of the piece (flac or wav).
    ///   - duration: Length of the piece; sets the time limit.
    ///   - model: The chosen model (AC-2).
    ///   - language: The chosen language; "automatic" is not sent (AC-2).
    ///   - key: The Groq key from the keychain; only sent as header.
    func transcribe(
        piece: URL, duration: Duration, model: TranscriptionModel, language: TranscriptionLanguage, key: String
    ) async -> TranscriptionPieceResult
}
