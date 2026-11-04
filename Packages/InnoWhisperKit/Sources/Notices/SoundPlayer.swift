import AppKit
import Diagnostics
import Foundation

/// The two sounds (AC-9).
public enum SystemSound: String, Sendable, LogValue {
    case start = "Tink"
    case end = "Pop"

    public var logDescription: String { rawValue }
}

/// Plays sounds. Replaced by a fake in tests.
@MainActor
public protocol SoundOutput: AnyObject {
    /// Returns false when the sound does not exist on this Mac.
    @discardableResult func play(_ sound: SystemSound, volume: Float) -> Bool
    func stop()
}

/// Real output via `NSSound` and the macOS system sounds.
@MainActor
public final class SystemSoundOutput: SoundOutput {
    private var playing: NSSound?

    public init() {}

    public func play(_ sound: SystemSound, volume: Float) -> Bool {
        guard let nsSound = NSSound(named: NSSound.Name(sound.rawValue))?.copy() as? NSSound else { return false }
        nsSound.volume = volume
        playing = nsSound
        return nsSound.play()
    }

    public func stop() {
        playing?.stop()
        playing = nil
    }
}

/// Start/end sounds with the "Töne bei Start und Ende" switch (AC-9, AC-10, EC-5).
@MainActor
@Observable
public final class SoundPlayer {
    static let enabledKey = "sounds.enabled"
    public static let volume: Float = 0.4

    @ObservationIgnored private let output: SoundOutput
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored public var onMissingSound: (@MainActor (SystemSound) -> Void)?

    /// On after installation (AC-10).
    public var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Self.enabledKey) }
    }

    public init(output: SoundOutput, defaults: UserDefaults = .standard) {
        self.output = output
        self.defaults = defaults
        isEnabled = defaults.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    public func playStart() { play(.start) }
    public func playEnd() { play(.end) }

    private func play(_ sound: SystemSound) {
        guard isEnabled else { return }
        output.stop()  // never two sounds at once (EC-5)
        if !output.play(sound, volume: Self.volume) {
            onMissingSound?(sound)
        }
    }
}
