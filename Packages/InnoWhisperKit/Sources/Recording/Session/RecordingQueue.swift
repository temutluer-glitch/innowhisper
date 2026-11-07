import Diagnostics
import Foundation

/// One finished recording, ready for transcription (design.md → Datenmodell
/// "Aufnahme"). Only the sequence number, duration, microphone kind and
/// start time describe it; the audio lives in the file.
public struct FinishedRecording: Equatable, Sendable {
    /// Which microphone recorded it: the system default or the one the user chose.
    public enum Microphone: Equatable, Sendable, LogValue {
        case system
        case chosen

        public var logDescription: StaticString {
            switch self {
            case .system: "system"
            case .chosen: "chosen"
            }
        }
    }

    /// Position in spoken order, from 1 per app launch (AC-7).
    public let sequence: Int
    /// The CAF file inside the recordings folder.
    public let fileURL: URL
    public let duration: Duration
    public let microphone: Microphone
    public let startedAt: Date

    public init(sequence: Int, fileURL: URL, duration: Duration, microphone: Microphone, startedAt: Date) {
        self.sequence = sequence
        self.fileURL = fileURL
        self.duration = duration
        self.microphone = microphone
        self.startedAt = startedAt
    }
}

/// Why a recording file is thrown away instead of handed on.
public enum RecordingDiscardReason: Equatable, Sendable, LogValue {
    /// Esc pressed (AC-8, AC-9).
    case cancelled
    /// Shorter than half a second (AC-10).
    case tooShort
    /// Nothing was said (AC-11).
    case silent
    /// Probe recording of the onboarding step (AC-20).
    case probe
    /// The start failed, e.g. no sound from the microphone (AC-14).
    case failedStart

    public var logDescription: StaticString {
        switch self {
        case .cancelled: "cancelled"
        case .tooShort: "too-short"
        case .silent: "silent"
        case .probe: "probe"
        case .failedStart: "failed-start"
        }
    }
}

/// Takes finished recordings in spoken order. PROJ-6 (transcription)
/// implements it; until then `PlaceholderConsumer` stands in.
@MainActor
public protocol RecordingConsumer: AnyObject {
    func receive(_ recording: FinishedRecording)
}

/// Stand-in until PROJ-6: keeps only the latest recording and deletes the
/// file of the one before (data minimisation, design.md → Datenmodell).
@MainActor
public final class PlaceholderConsumer: RecordingConsumer {
    private let storage: RecordingStorage
    /// The one recording currently kept.
    public private(set) var latest: FinishedRecording?

    public init(storage: RecordingStorage) {
        self.storage = storage
    }

    public func receive(_ recording: FinishedRecording) {
        if let previous = latest, previous.fileURL != recording.fileURL {
            storage.delete(previous.fileURL)
        }
        latest = recording
        Log.write(
            "Recording kept for transcription (placeholder): #\(recording.sequence), \(recording.duration)",
            category: .recording)
    }
}

/// Hands finished recordings to the consumer in the order they were spoken
/// (AC-7) and throws away cancelled, silent and probe recordings (AC-8, AC-11).
///
/// Order guarantee: only one recording runs at a time, so spoken order is the
/// order in which the controller reports finished files. Numbers are assigned
/// here, on the main actor, synchronously inside `finish`, from a counter that
/// only ever grows; the consumer is called in the same step. A number is never
/// reused, and a discarded recording consumes none.
@MainActor
public final class RecordingQueue {
    private let storage: RecordingStorage
    /// Receives every finished recording; PROJ-6 swaps in the transcription.
    public var consumer: any RecordingConsumer
    /// Number of the last recording handed on; 0 before the first one.
    public private(set) var lastSequence = 0

    public init(storage: RecordingStorage, consumer: any RecordingConsumer) {
        self.storage = storage
        self.consumer = consumer
    }

    /// Numbers a finished recording and hands it on (AC-6, AC-7).
    @discardableResult
    public func finish(
        fileURL: URL, duration: Duration, microphone: FinishedRecording.Microphone, startedAt: Date
    ) -> FinishedRecording {
        lastSequence += 1
        let recording = FinishedRecording(
            sequence: lastSequence, fileURL: fileURL, duration: duration, microphone: microphone,
            startedAt: startedAt)
        Log.write(
            "Recording handed on: #\(recording.sequence), \(duration), microphone \(microphone)",
            category: .recording)
        consumer.receive(recording)
        return recording
    }

    /// Deletes the file of a recording that is not handed on; no number is
    /// consumed (AC-8, AC-11).
    public func discard(fileURL: URL, reason: RecordingDiscardReason) {
        let deleted = storage.delete(fileURL)
        Log.write("Recording discarded: \(reason), file deleted \(deleted)", category: .recording)
    }
}
