import Foundation

/// Fixed user-facing texts of the transcription (PROJ-6).
public enum TranscriptionTexts {
    /// AC-3
    public static let textInClipboard = "Text in der Zwischenablage."
    /// AC-20
    public static let recoveredInClipboard = "Nachgeholtes Diktat in der Zwischenablage."
    /// AC-11
    public static let failed = "Umwandlung fehlgeschlagen. Die Aufnahme ist gespeichert."
    /// AC-11, without internet
    public static let noInternet = "Keine Internetverbindung. Die Aufnahme ist gespeichert."
    /// AC-11 to AC-14: button of the notice and of the problem.
    public static let retry = "Erneut versuchen"
    /// AC-12
    public static let keyMissing = "Kein Groq-Zugangsschlüssel eingetragen."
    /// AC-12: button.
    public static let enterKey = "Schlüssel eintragen"
    /// AC-13
    public static let keyRejected = "Groq lehnt den Zugangsschlüssel ab."
    /// AC-13: button.
    public static let checkKey = "Schlüssel prüfen"
    /// AC-15
    public static let nothingRecognized = "Nichts erkannt, kein Text eingefügt."
    /// EC-4
    public static let damaged = "Aufnahme beschädigt, kann nicht umgewandelt werden."
    /// Settings group title (design.md).
    public static let settingsGroup = "Umwandlung"
    public static let modelLabel = "Modell"
    public static let languageLabel = "Sprache"

    /// AC-14: Groq's limit, with the wait rounded up to whole minutes.
    public static func limitReached(wait: Duration) -> String {
        let seconds = max(1, wait.components.seconds)
        let minutes = Int((seconds + 59) / 60)
        let unit = minutes == 1 ? "1 Minute" : "\(minutes) Minuten"
        return "Groq-Grenze erreicht. Versuche es in \(unit) erneut."
    }

    /// design.md → Menüleiste und Problem.
    public static func notConverted(count: Int) -> String {
        count == 1 ? "1 Diktat nicht umgewandelt." : "\(count) Diktate nicht umgewandelt."
    }
}
