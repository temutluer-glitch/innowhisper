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

/// Shared, observable holder of the current dictation activity.
@MainActor
@Observable
public final class ActivityCenter {
    public var activity: DictationActivity

    public init(activity: DictationActivity = .idle) {
        self.activity = activity
    }
}
