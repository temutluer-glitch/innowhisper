import Diagnostics

/// All settings sections, in the fixed order of `docs/app-shell.md`.
/// A section only appears in the sidebar once its feature registers it.
public enum SettingsSection: String, CaseIterable, Sendable, Identifiable, LogValue {
    case general
    case access
    case hotkeys
    case transcription
    case prompts
    case vocabulary
    case history
    case about

    public var id: String { rawValue }

    public var logDescription: String { rawValue }

    /// Position in the sidebar (1-based).
    public var order: Int {
        (Self.allCases.firstIndex(of: self) ?? 0) + 1
    }

    public var title: String {
        switch self {
        case .general: "Allgemein"
        case .access: "Zugang & Erlaubnisse"
        case .hotkeys: "Tastenkürzel"
        case .transcription: "Umwandlung"
        case .prompts: "KI-Vorlagen"
        case .vocabulary: "Wörterbuch"
        case .history: "Verlauf"
        case .about: "Info & Updates"
        }
    }

    public var symbolName: String {
        switch self {
        case .general: "gearshape"
        case .access: "key"
        case .hotkeys: "keyboard"
        case .transcription: "text.bubble"
        case .prompts: "sparkles"
        case .vocabulary: "character.book.closed"
        case .history: "clock.arrow.circlepath"
        case .about: "info.circle"
        }
    }
}
