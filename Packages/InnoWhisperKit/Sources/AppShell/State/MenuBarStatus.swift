/// The state the menu bar icon shows (AC-2). Derived, never stored.
public enum MenuBarStatus: Sendable, Equatable {
    case ready
    case recording
    case transcribing
    case problem

    /// Priority: recording > transcribing > problem > ready. A running
    /// recording deliberately hides a problem until it ends.
    public static func resolve(activity: DictationActivity, hasProblems: Bool) -> MenuBarStatus {
        switch activity {
        case .recording: return .recording
        case .transcribing: return .transcribing
        case .idle: return hasProblems ? .problem : .ready
        }
    }

    /// SF Symbol shown in the menu bar.
    public var symbolName: String {
        switch self {
        case .ready: "mic"
        case .recording: "mic.fill"
        case .transcribing: "waveform"
        case .problem: "exclamationmark.triangle"
        }
    }

    /// Text VoiceOver reads for the icon.
    public var accessibilityLabel: String {
        switch self {
        case .ready: "InnoWhisper bereit"
        case .recording: "InnoWhisper nimmt auf"
        case .transcribing: "InnoWhisper wandelt um"
        case .problem: "InnoWhisper: Problem, Details im Menü"
        }
    }
}
