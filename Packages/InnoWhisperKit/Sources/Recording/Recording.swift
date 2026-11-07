import Foundation

/// Recording by shortcut (PROJ-5): watching the shortcut, opening the
/// microphone, writing the audio file and handing finished recordings on in
/// the order they were spoken.
public enum RecordingInfo {
    /// A lone modifier (e.g. right ⌘) must be held this long before the
    /// microphone opens, so ⌘C never starts a recording (EC-1, design.md).
    public static let holdDelay: Duration = .milliseconds(250)
    /// Shorter recordings are dropped without a notice (AC-10).
    public static let minimumDuration: Duration = .milliseconds(500)
    /// Share of "voiced" audio below which a recording counts as silent (AC-11).
    public static let minimumVoicedFraction = 0.05
    /// Level that counts a piece of audio as voiced (AC-11).
    public static let voicedThresholdDecibels: Float = -35
    /// Quiet speech counts too: a chunk is voiced when it is this far above the
    /// background noise of the same recording (live test 07.11.: quiet speech
    /// peaked at −35 dB and was dropped with the fixed −35 dB rule).
    public static let voicedMarginDecibels: Float = 12
    /// Never count chunks below this as speech, however quiet the room.
    public static let voicedLowerLimitDecibels: Float = -65
    /// Without real audio after this long the start is cancelled (AC-14).
    public static let noSoundTimeout: Duration = .seconds(1)
    /// Up to this length one Esc cancels; after it a second Esc is needed (AC-8, AC-9).
    public static let singleEscapeLimit: Duration = .seconds(30)
    /// Time window for the second Esc (AC-9).
    public static let secondEscapeWindow: Duration = .seconds(3)
    /// Recording ends below this much free disk space (EC-4).
    public static let minimumFreeBytes: Int64 = 200 * 1024 * 1024
    /// How often free disk space is checked while recording (EC-4).
    public static let diskCheckInterval: Duration = .seconds(10)
    /// The Mac is kept awake only while speech was heard within this time (BUG-12).
    public static let awakeWithoutSpeech: Duration = .seconds(120)
    /// How often the time since the last speech is checked (BUG-12).
    public static let speechCheckInterval: Duration = .seconds(30)
    /// Speech keeps the Mac awake when it is this far above the room's
    /// running background noise; steady noise does not (BUG-16).
    public static let awakeSpeechMarginDecibels = 10.0
    /// How fast the running background noise may rise, in dB per second (BUG-16).
    public static let awakeBackgroundRisePerSecond = 0.5
    /// Without keyboard or mouse input for this long the Mac may sleep and lock
    /// even while sound continues (BUG-16, Timur 07.11.2026: 20 minutes).
    public static let awakeWithoutInput: Duration = .seconds(20 * 60)
    /// How often the real key state is checked while recording (EC-5).
    public static let keyStateCheckInterval: Duration = .milliseconds(500)
    /// Audio format of the recording file (design.md → Datenmodell).
    public static let sampleRate: Double = 16_000
    /// Folder of the recording files below Application Support/InnoWhisper.
    public static let folderName = "Recordings"
    /// Onboarding step: fixed id and position after the permissions (PROJ-3 design).
    public static let stepID = "shortcut"
    public static let stepOrder = 60
    /// Settings keys (design.md → Datenmodell).
    public static let shortcutDefaultsKey = "recording.shortcut"
    public static let modeDefaultsKey = "recording.mode"
    public static let microphoneDefaultsKey = "recording.microphoneID"
}
