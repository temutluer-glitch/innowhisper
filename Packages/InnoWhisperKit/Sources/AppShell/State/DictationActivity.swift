import Observation

/// What the dictation pipeline is doing right now. Set by PROJ-5 (recording)
/// and PROJ-6 (transcription); read by the menu bar and the quit rule.
public enum DictationActivity: Sendable, Equatable {
    case idle
    case recording
    case transcribing

    /// True while a dictation would be lost by quitting.
    public var isActive: Bool { self != .idle }
}

/// Shared, observable holder of the current dictation activity. Recording
/// (PROJ-5) and transcription (PROJ-6) each set their own fact, so the end of
/// a new recording never hides a transcription still running (PROJ-6 design).
@MainActor
@Observable
public final class ActivityCenter {
    /// Set by the recording while the microphone is open.
    public var isRecording = false
    /// Set by the transcription while at least one dictation waits or converts.
    public var isTranscribing = false

    public init() {}

    /// What is shown: recording before transcribing before idle.
    public var activity: DictationActivity {
        if isRecording { return .recording }
        if isTranscribing { return .transcribing }
        return .idle
    }
}
