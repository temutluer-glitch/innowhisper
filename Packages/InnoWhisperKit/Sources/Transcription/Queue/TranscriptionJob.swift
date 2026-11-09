import Diagnostics
import Foundation

/// Why a job gave up for now; it stays until "Erneut versuchen" (AC-11 to AC-14).
/// Ordered by priority: when pieces fail differently, the first case wins.
public enum JobFailure: Equatable, Sendable, LogValue {
    case keyMissing
    case keyRejected
    case rateLimited(wait: Duration)
    case noInternet
    case failed

    var priority: Int {
        switch self {
        case .keyMissing: 0
        case .keyRejected: 1
        case .rateLimited: 2
        case .noInternet: 3
        case .failed: 4
        }
    }

    public var logDescription: StaticString {
        switch self {
        case .keyMissing: "keyMissing"
        case .keyRejected: "keyRejected"
        case .rateLimited: "rateLimited"
        case .noInternet: "noInternet"
        case .failed: "failed"
        }
    }
}

/// One recording on its way to text (design.md → Aufträge). Lives only in memory.
///
/// Allowed moves: waiting → converting → ready → handedOn; converting → failed
/// → (retry) converting; converting → handedOn without text (nothing
/// recognised, damaged file). Nothing ever leaves `handedOn`.
@MainActor
final class TranscriptionJob {
    enum State: Equatable {
        case waiting
        case converting
        case ready(String)
        case failed(JobFailure)
        case handedOn
    }

    /// Position in the queue; recovered jobs come before live ones.
    let order: Int
    let fileName: String
    let fileURL: URL
    let duration: Duration
    /// Fixed when the recording arrived (AC-4).
    let model: TranscriptionModel
    let language: TranscriptionLanguage
    /// Recovered at start: always to the clipboard (AC-20).
    let recovered: Bool

    var state: State = .waiting
    /// Pieces of the recording once split; kept while a retry may need them (EC-3).
    var pieces: AudioPieces?
    /// Segments of every finished piece, by piece index (EC-3).
    var finished: [Int: [TranscriptSegment]] = [:]
    var startedAt: ContinuousClock.Instant?

    init(
        order: Int, fileName: String, fileURL: URL, duration: Duration, model: TranscriptionModel,
        language: TranscriptionLanguage, recovered: Bool
    ) {
        self.order = order
        self.fileName = fileName
        self.fileURL = fileURL
        self.duration = duration
        self.model = model
        self.language = language
        self.recovered = recovered
    }

    var isBusy: Bool { state == .waiting || state == .converting }

    var isFailed: Bool {
        if case .failed = state { return true }
        return false
    }
}
