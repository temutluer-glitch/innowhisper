import Foundation

/// Fixed user-facing texts of recording by shortcut (PROJ-5).
public enum RecordingTexts {
    /// AC-8
    public static let cancelled = "Aufnahme abgebrochen."
    /// AC-9
    public static let pressEscapeAgain = "Nochmal Esc drücken zum Abbrechen."
    /// AC-11
    public static let nothingHeard = "Nichts gehört, Aufnahme verworfen."
    /// AC-14
    public static let noSound = "Das Mikrofon liefert keinen Ton. Prüfe, ob es angeschlossen ist."
    /// AC-15
    public static let microphoneNotAllowed = "Mikrofon nicht erlaubt."
    /// AC-15: button of the notice above.
    public static let allowNow = "Jetzt erlauben"
    /// EC-2
    public static let microphoneDisconnected = "Mikrofon getrennt, Aufnahme beendet."
    /// EC-4
    public static let diskFull = "Kein Speicherplatz mehr, Aufnahme beendet."
    /// design.md: the recording file cannot be created or written.
    public static let recordingFailed = "Aufnahme fehlgeschlagen. Bitte versuche es noch einmal."
    /// AC-18
    public static let shortcutTaken = "Dieses Kürzel ist schon belegt. Wähle ein anderes."
    /// AC-20
    public static let probeWorked = "Klappt. Dein Mikrofon funktioniert."

    /// AC-13: the chosen microphone is missing and the system microphone is used instead.
    public static func microphoneMissing(wanted: String, using: String) -> String {
        "\(wanted) nicht gefunden, nehme \(using)."
    }
}
