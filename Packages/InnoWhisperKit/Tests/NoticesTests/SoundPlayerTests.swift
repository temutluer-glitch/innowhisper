import Foundation
import Testing

@testable import Notices

@MainActor
final class FakeSoundOutput: SoundOutput {
    var events: [String] = []
    var available = true

    func play(_ sound: SystemSound, volume: Float) -> Bool {
        events.append("play \(sound.rawValue) \(volume)")
        return available
    }

    func stop() { events.append("stop") }
}

@MainActor
struct SoundPlayerTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    // AC-9: start and end sounds, quiet
    @Test func playsStartAndEnd() {
        let output = FakeSoundOutput()
        let player = SoundPlayer(output: output, defaults: freshDefaults())
        player.playStart()
        player.playEnd()
        #expect(output.events == ["stop", "play Tink 0.4", "stop", "play Pop 0.4"])
    }

    // EC-5: the previous sound is stopped before the next plays
    @Test func stopsPreviousSound() {
        let output = FakeSoundOutput()
        let player = SoundPlayer(output: output, defaults: freshDefaults())
        player.playStart()
        player.playStart()
        #expect(output.events.filter { $0 == "stop" }.count == 2)
        #expect(output.events.last == "play Tink 0.4")
    }

    // AC-10: on by default; off stays off after relaunch and plays nothing
    @Test func switchIsOnByDefaultAndPersists() {
        let defaults = freshDefaults()
        let output = FakeSoundOutput()
        let player = SoundPlayer(output: output, defaults: defaults)
        #expect(player.isEnabled)
        player.isEnabled = false
        let relaunched = SoundPlayer(output: output, defaults: defaults)
        #expect(!relaunched.isEnabled)
        relaunched.playStart()
        #expect(output.events.isEmpty)
    }

    @Test func missingSoundIsReported() {
        let output = FakeSoundOutput()
        output.available = false
        let player = SoundPlayer(output: output, defaults: freshDefaults())
        var missing: SystemSound?
        player.onMissingSound = { missing = $0 }
        player.playEnd()
        #expect(missing == .end)
    }
}
