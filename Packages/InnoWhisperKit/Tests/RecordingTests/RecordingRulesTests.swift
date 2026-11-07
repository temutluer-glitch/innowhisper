import Foundation
import Testing

@testable import Recording

@Suite struct RecordingRulesTests {
    /// A chunk of `count` samples of a sine wave with the given amplitude.
    private func sine(amplitude: Float, count: Int = 1_600) -> [Float] {
        (0..<count).map { amplitude * sin(Float($0) * 2 * .pi * 440 / 16_000) }
    }

    /// A chunk whose every sample has the same value, so its power is exactly `decibels`.
    private func constant(decibels: Float, count: Int = 1_600) -> [Float] {
        Array(repeating: pow(10, decibels / 20), count: count)
    }

    // MARK: Keep or discard

    // AC-10: shorter than half a second is dropped without a notice
    @Test func shortRecordingIsDroppedSilently() {
        #expect(
            RecordingRules.verdict(duration: .milliseconds(490), voicedFraction: 1, interrupted: false)
                == .discardSilently)
        #expect(RecordingRules.verdict(duration: .milliseconds(500), voicedFraction: 1, interrupted: false) == .keep)
    }

    // AC-10, EC-2/EC-3/EC-4: an interruption keeps a short recording that holds speech
    @Test func interruptedShortRecordingIsKept() {
        #expect(RecordingRules.verdict(duration: .milliseconds(200), voicedFraction: 0.5, interrupted: true) == .keep)
    }

    // AC-11: below 5 % voiced audio the recording counts as silent
    @Test func silentRecordingIsDroppedWithNotice() {
        #expect(
            RecordingRules.verdict(duration: .seconds(4), voicedFraction: 0.049, interrupted: false)
                == .discardAsSilent)
        #expect(RecordingRules.verdict(duration: .seconds(4), voicedFraction: 0.05, interrupted: false) == .keep)
    }

    // MARK: Audio meter

    // AC-11: a quiet chunk measures its power and does not count as voiced
    @Test func quietChunkIsNotVoiced() {
        var meter = AudioMeter()
        meter.add(constant(decibels: -36))
        #expect(abs(meter.lastDecibels - -36) < 0.01)
        #expect(meter.voicedFraction == 0)
        #expect(meter.hasSignal)
    }

    // AC-11: a loud sine chunk counts as voiced
    @Test func loudSineChunkIsVoiced() {
        var meter = AudioMeter()
        meter.add(sine(amplitude: 0.5))
        // RMS of a sine is amplitude / √2 → about −9 dB.
        #expect(abs(meter.lastDecibels - -9.03) < 0.1)
        #expect(meter.voicedFraction == 1)
        #expect(meter.level > 0.8)
        #expect(meter.hasSignal)
    }

    // AC-11: the threshold sits at −35 dB
    @Test func chunkJustAboveThresholdIsVoiced() {
        var meter = AudioMeter()
        meter.add(constant(decibels: -34))
        #expect(meter.voicedFraction == 1)
    }

    // AC-11: the voiced fraction spans all chunks and feeds the 5 % rule
    @Test func mixedChunksGiveVoicedFraction() {
        var meter = AudioMeter()
        meter.add(sine(amplitude: 0.5))
        for _ in 0..<19 { meter.add(constant(decibels: -50)) }
        #expect(meter.voicedFraction == 0.05)
        #expect(
            RecordingRules.verdict(duration: .seconds(2), voicedFraction: meter.voicedFraction, interrupted: false)
                == .keep)
        meter.add(constant(decibels: -50))
        #expect(meter.voicedFraction < 0.05)
        #expect(
            RecordingRules.verdict(duration: .seconds(2), voicedFraction: meter.voicedFraction, interrupted: false)
                == .discardAsSilent)
    }

    // AC-14: a chunk of only zeros is digital silence, not a signal
    @Test func zeroOnlyChunkIsNoSignal() {
        var meter = AudioMeter()
        meter.add([Float](repeating: 0, count: 1_600))
        #expect(!meter.hasSignal)
        #expect(meter.lastDecibels == AudioMeter.silenceDecibels)
        #expect(meter.level == 0)
        #expect(meter.voicedFraction == 0)
        var single = [Float](repeating: 0, count: 1_600)
        single[800] = 0.0001
        meter.add(single)
        #expect(meter.hasSignal)
        meter.add([Float](repeating: 0, count: 1_600))
        #expect(meter.hasSignal)
    }

    // AC-11, AC-14: an empty chunk changes nothing
    @Test func emptyChunkChangesNothing() {
        var meter = AudioMeter()
        meter.add([])
        #expect(meter == AudioMeter())
    }

    // AC-11: level bar maps −60 dB…0 dB linearly and clamps
    @Test func levelMapsAndClamps() {
        #expect(AudioMeter.level(forDecibels: -60) == 0)
        #expect(AudioMeter.level(forDecibels: -30) == 0.5)
        #expect(AudioMeter.level(forDecibels: 0) == 1)
        #expect(AudioMeter.level(forDecibels: -90) == 0)
        #expect(AudioMeter.level(forDecibels: -160) == 0)
        #expect(AudioMeter.level(forDecibels: 6) == 1)
        var meter = AudioMeter()
        meter.add(constant(decibels: -30))
        #expect(abs(meter.level - 0.5) < 0.001)
    }

    // MARK: No sound

    // AC-14: no signal within one second cancels the start
    @Test func noSoundAfterOneSecond() {
        #expect(!RecordingRules.isSoundMissing(sinceOpened: .milliseconds(990), hasSignal: false))
        #expect(RecordingRules.isSoundMissing(sinceOpened: .seconds(1), hasSignal: false))
        #expect(!RecordingRules.isSoundMissing(sinceOpened: .seconds(5), hasSignal: true))
    }

    // MARK: Esc

    // AC-8: up to 30 s one Esc cancels
    @Test func singleEscapeCancelsUpToThirtySeconds() {
        var rule = EscapeRule()
        #expect(rule.escape(atAge: .seconds(2)) == .cancel)
        rule.reset()
        #expect(rule.escape(atAge: .seconds(30)) == .cancel)
    }

    // AC-9: after 30 s the first Esc asks again
    @Test func escapeAfterThirtySecondsAsksAgain() {
        var rule = EscapeRule()
        #expect(rule.escape(atAge: .milliseconds(30_100)) == .askAgain)
    }

    // AC-9: a second Esc within 3 s cancels
    @Test func secondEscapeWithinThreeSecondsCancels() {
        var rule = EscapeRule()
        #expect(rule.escape(atAge: .seconds(40)) == .askAgain)
        #expect(rule.escape(atAge: .milliseconds(42_900)) == .cancel)
    }

    // AC-9: after the 3 s window a further Esc counts as a first one again
    @Test func escapeAfterWindowAsksAgain() {
        var rule = EscapeRule()
        #expect(rule.escape(atAge: .seconds(40)) == .askAgain)
        #expect(rule.escape(atAge: .milliseconds(43_100)) == .askAgain)
        #expect(rule.escape(atAge: .milliseconds(45_000)) == .cancel)
    }

    // AC-9: a new recording forgets a pending first Esc
    @Test func resetForgetsPendingEscape() {
        var rule = EscapeRule()
        #expect(rule.escape(atAge: .seconds(40)) == .askAgain)
        rule.reset()
        #expect(rule.escape(atAge: .seconds(41)) == .askAgain)
    }

    // MARK: Disk

    // EC-4: at least 200 MB must be free
    @Test func diskSpaceBoundary() {
        let limit: Int64 = 200 * 1024 * 1024
        #expect(RecordingRules.hasEnoughDiskSpace(freeBytes: limit))
        #expect(!RecordingRules.hasEnoughDiskSpace(freeBytes: limit - 1))
        #expect(!RecordingRules.hasEnoughDiskSpace(freeBytes: 0))
    }

    // MARK: Texts

    // AC-8, AC-9, AC-11, AC-13, AC-14, AC-15, AC-18, AC-20, EC-2, EC-4: texts exactly as specified
    @Test func textsAreExact() {
        #expect(RecordingTexts.cancelled == "Aufnahme abgebrochen.")
        #expect(RecordingTexts.pressEscapeAgain == "Nochmal Esc drücken zum Abbrechen.")
        #expect(RecordingTexts.nothingHeard == "Nichts gehört, Aufnahme verworfen.")
        #expect(
            RecordingTexts.microphoneMissing(wanted: "AirPods Pro", using: "MacBook Pro-Mikrofon")
                == "AirPods Pro nicht gefunden, nehme MacBook Pro-Mikrofon.")
        #expect(RecordingTexts.noSound == "Das Mikrofon liefert keinen Ton. Prüfe, ob es angeschlossen ist.")
        #expect(RecordingTexts.microphoneNotAllowed == "Mikrofon nicht erlaubt.")
        #expect(RecordingTexts.allowNow == "Jetzt erlauben")
        #expect(RecordingTexts.microphoneDisconnected == "Mikrofon getrennt, Aufnahme beendet.")
        #expect(RecordingTexts.diskFull == "Kein Speicherplatz mehr, Aufnahme beendet.")
        #expect(RecordingTexts.recordingFailed == "Aufnahme fehlgeschlagen. Bitte versuche es noch einmal.")
        #expect(RecordingTexts.shortcutTaken == "Dieses Kürzel ist schon belegt. Wähle ein anderes.")
        #expect(RecordingTexts.probeWorked == "Klappt. Dein Mikrofon funktioniert.")
    }
}
