import Foundation

/// What happens to a finished recording (AC-10, AC-11).
public enum RecordingVerdict: Equatable, Sendable {
    /// Hand the recording on.
    case keep
    /// Too short: drop it without a notice (AC-10).
    case discardSilently
    /// Nothing was said: drop it and show `RecordingTexts.nothingHeard` (AC-11).
    case discardAsSilent
}

/// What one Esc press means during a recording (AC-8, AC-9).
public enum EscapeDecision: Equatable, Sendable {
    /// Cancel the recording and delete it.
    case cancel
    /// Keep recording and show `RecordingTexts.pressEscapeAgain`.
    case askAgain
}

/// Pure rules of a recording, free of macOS so they can be tested with fixed values.
public enum RecordingRules {
    /// Keep or drop a finished recording (AC-10, AC-11).
    ///
    /// The "too short" rule only applies when the user ended the recording; a
    /// recording cut short by an interruption (microphone unplugged, sleep,
    /// screen lock, disk full) keeps what was said (EC-2, EC-3, EC-4).
    public static func verdict(duration: Duration, voicedFraction: Double, interrupted: Bool) -> RecordingVerdict {
        if !interrupted && duration < RecordingInfo.minimumDuration {
            return .discardSilently
        }
        if voicedFraction < RecordingInfo.minimumVoicedFraction {
            return .discardAsSilent
        }
        return .keep
    }

    /// `true` when the microphone delivered no real signal within `noSoundTimeout` after opening (AC-14).
    public static func isSoundMissing(sinceOpened elapsed: Duration, hasSignal: Bool) -> Bool {
        !hasSignal && elapsed >= RecordingInfo.noSoundTimeout
    }

    /// `true` when there is enough free disk space to start or keep recording (EC-4).
    public static func hasEnoughDiskSpace(freeBytes: Int64) -> Bool {
        freeBytes >= RecordingInfo.minimumFreeBytes
    }
}

/// Measures incoming audio one chunk at a time: level for the level bar,
/// share of voiced chunks (AC-11) and whether any real signal arrived (AC-14).
public struct AudioMeter: Equatable, Sendable {
    /// Power reported for a chunk of pure digital silence.
    public static let silenceDecibels: Float = -160
    /// Power that maps to an empty level bar; 0 dB maps to a full one.
    public static let levelFloorDecibels: Float = -60

    /// Average power of the last chunk in dB.
    public private(set) var lastDecibels: Float = AudioMeter.silenceDecibels
    /// Level of the last chunk as 0…1 for a level bar (−60 dB…0 dB, clamped).
    public private(set) var level: Double = 0
    /// `true` once any sample was not exactly 0; zero-only chunks are digital silence (AC-14).
    public private(set) var hasSignal = false
    private var chunkCount = 0
    private var voicedChunkCount = 0

    public init() {}

    /// Share of chunks above `voicedThresholdDecibels`, 0 before the first chunk (AC-11).
    public var voicedFraction: Double {
        chunkCount == 0 ? 0 : Double(voicedChunkCount) / Double(chunkCount)
    }

    /// Adds one chunk of samples in −1…1. An empty chunk changes nothing.
    public mutating func add(_ samples: [Float]) {
        guard !samples.isEmpty else { return }
        let decibels = Self.averagePower(of: samples)
        lastDecibels = decibels
        level = Self.level(forDecibels: decibels)
        chunkCount += 1
        if decibels > RecordingInfo.voicedThresholdDecibels {
            voicedChunkCount += 1
        }
        if !hasSignal && samples.contains(where: { $0 != 0 }) {
            hasSignal = true
        }
    }

    /// Average power (RMS) of a chunk in dB, at least `silenceDecibels`.
    public static func averagePower(of samples: [Float]) -> Float {
        guard !samples.isEmpty else { return silenceDecibels }
        let sumOfSquares = samples.reduce(Float(0)) { $0 + $1 * $1 }
        let rms = (sumOfSquares / Float(samples.count)).squareRoot()
        guard rms > 0 else { return silenceDecibels }
        return max(silenceDecibels, 20 * log10(rms))
    }

    /// Maps a power in dB linearly to 0…1 between `levelFloorDecibels` and 0 dB, clamped.
    public static func level(forDecibels decibels: Float) -> Double {
        let share = Double((decibels - levelFloorDecibels) / -levelFloorDecibels)
        return min(1, max(0, share))
    }
}

/// Decides what an Esc press means and remembers a pending first Esc (AC-8, AC-9).
///
/// Times are recording ages, i.e. time since the recording started, so the
/// rule needs no clock of its own. Call `reset()` for every new recording.
public struct EscapeRule: Equatable, Sendable {
    private var firstEscapeAge: Duration?

    public init() {}

    /// Up to `singleEscapeLimit` one Esc cancels. After it the first Esc asks
    /// again, a second Esc within `secondEscapeWindow` cancels, and a later
    /// one counts as a first Esc again.
    public mutating func escape(atAge age: Duration) -> EscapeDecision {
        if age <= RecordingInfo.singleEscapeLimit {
            firstEscapeAge = nil
            return .cancel
        }
        if let first = firstEscapeAge, age - first <= RecordingInfo.secondEscapeWindow {
            firstEscapeAge = nil
            return .cancel
        }
        firstEscapeAge = age
        return .askAgain
    }

    /// Forgets a pending first Esc.
    public mutating func reset() {
        firstEscapeAge = nil
    }
}
