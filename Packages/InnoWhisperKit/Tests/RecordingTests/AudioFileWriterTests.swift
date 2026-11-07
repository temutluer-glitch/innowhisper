import AVFAudio
import Foundation
import Testing

@testable import Recording

/// The file side of the microphone capture, testable without a microphone.
@Suite struct AudioFileWriterTests {
    /// A new file location in the temporary folder.
    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("AudioFileWriterTests-\(UUID().uuidString).caf")
    }

    /// A buffer as a microphone would deliver it: float, `channels` channels,
    /// `frames` frames of a 440 Hz sine with `amplitude` (0 gives digital silence).
    private func microphoneBuffer(
        frames: AVAudioFrameCount, sampleRate: Double = 48_000, channels: AVAudioChannelCount = 2,
        amplitude: Float = 0.5
    ) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: channels, interleaved: false)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        for channel in 0..<Int(channels) {
            let data = buffer.floatChannelData![channel]
            for frame in 0..<Int(frames) {
                data[frame] = amplitude * sin(Float(frame) * 2 * .pi * 440 / Float(sampleRate))
            }
        }
        return buffer
    }

    private func frameCount(of url: URL) throws -> AVAudioFramePosition {
        try AVAudioFile(forReading: url).length
    }

    private func isClose(_ value: Duration, _ expected: Duration, within tolerance: Duration) -> Bool {
        value >= expected - tolerance && value <= expected + tolerance
    }

    // MARK: Format

    // AC-6, design.md → Datenmodell: 1 s of 48 kHz stereo float becomes a CAF file with 16 kHz, mono, 16-bit integer
    @Test func oneSecondOfStereoBecomesSixteenKilohertzMonoInteger() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = try AudioFileWriter(fileURL: url)
        try writer.append(microphoneBuffer(frames: 48_000))
        let duration = try writer.finish()

        let file = try AVAudioFile(forReading: url)
        let description = file.fileFormat.streamDescription.pointee
        #expect(file.fileFormat.sampleRate == 16_000)
        #expect(file.fileFormat.channelCount == 1)
        #expect(description.mFormatID == kAudioFormatLinearPCM)
        #expect(description.mBitsPerChannel == 16)
        #expect(description.mFormatFlags & kAudioFormatFlagIsFloat == 0)
        #expect(description.mFormatFlags & kAudioFormatFlagIsSignedInteger != 0)
        #expect(abs(file.length - 16_000) <= 160)
        #expect(isClose(duration, .seconds(1), within: .milliseconds(10)))
        let header = try FileHandle(forReadingFrom: url).read(upToCount: 4)
        #expect(header == Data("caff".utf8))
    }

    // MARK: Without gaps

    // AC-6: ten buffers of 0.1 s append to one second, nothing is overwritten
    @Test func severalBuffersAppendWithoutGaps() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = try AudioFileWriter(fileURL: url)
        for _ in 0..<10 {
            try writer.append(microphoneBuffer(frames: 4_800))
        }
        let duration = try writer.finish()

        #expect(isClose(duration, .seconds(1), within: .milliseconds(10)))
        #expect(abs(try frameCount(of: url) - 16_000) <= 160)
        #expect(try frameCount(of: url) == writer.framesWritten)
    }

    // AC-6: 10 minutes of alternating silence and tone in 0.1 s chunks stay gap-free, duration within 0.1 s
    @Test func tenMinutesInChunksStayComplete() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = try AudioFileWriter(fileURL: url)
        let silence = microphoneBuffer(frames: 4_800, amplitude: 0)
        let tone = microphoneBuffer(frames: 4_800)
        for chunk in 0..<6_000 {
            try writer.append(chunk.isMultiple(of: 2) ? silence : tone)
        }
        let duration = try writer.finish()

        #expect(isClose(duration, .seconds(600), within: .milliseconds(100)))
        #expect(abs(try frameCount(of: url) - 9_600_000) <= 1_600)
    }

    // AC-6: audio already in the file format is written unchanged
    @Test func sixteenKilohertzMonoIsWrittenAsIs() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = try AudioFileWriter(fileURL: url)
        let samples = try writer.append(microphoneBuffer(frames: 1_600, sampleRate: 16_000, channels: 1))
        #expect(samples.count == 1_600)
        #expect(try writer.finish() == .milliseconds(100))
        #expect(try frameCount(of: url) == 1_600)
    }

    // MARK: Cancel and crash

    // AC-8 (via the controller): cancel closes and deletes the file
    @Test func cancelDeletesTheFile() throws {
        let url = temporaryURL()
        let writer = try AudioFileWriter(fileURL: url)
        try writer.append(microphoneBuffer(frames: 4_800))
        #expect(FileManager.default.fileExists(atPath: url.path))
        writer.cancel()
        #expect(!FileManager.default.fileExists(atPath: url.path))
        #expect(throws: CaptureError.writerClosed) { try writer.append(microphoneBuffer(frames: 4_800)) }
    }

    // AC-6, design.md: AVAudioFile writes every converted chunk straight
    // through and CAF needs no closing header, so a file that was never
    // finished (app stopped unexpectedly) can be read up to the last written
    // frame. Missing are only the frames the sample-rate converter still holds
    // back (measured about 70 ms at 48 kHz); `finish()` writes those.
    @Test func unfinishedFileIsReadableUpToTheWrittenFrames() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = try AudioFileWriter(fileURL: url)
        for _ in 0..<10 {
            try writer.append(microphoneBuffer(frames: 4_800))
        }

        let unfinished = try AVAudioFile(forReading: url)
        #expect(unfinished.length == writer.framesWritten)
        #expect(unfinished.length > 16_000 - 1_600)
        let buffer = AVAudioPCMBuffer(pcmFormat: unfinished.processingFormat, frameCapacity: 16_000)!
        try unfinished.read(into: buffer)
        #expect(AVAudioFramePosition(buffer.frameLength) == unfinished.length)
        try #require(buffer.frameLength > 0)
        #expect(buffer.floatChannelData![0][Int(buffer.frameLength) - 1] != 0)

        _ = try writer.finish()
        #expect(abs(try frameCount(of: url) - 16_000) <= 160)
    }

    // design.md: a file that cannot be created is a `CaptureError`, the controller shows "Aufnahme fehlgeschlagen …"
    @Test func uncreatableFileThrows() {
        let url = URL(fileURLWithPath: "/nonexistent-folder-\(UUID().uuidString)/recording.caf")
        #expect(throws: CaptureError.cannotCreateFile) { try AudioFileWriter(fileURL: url) }
    }

    // MARK: Level

    // AC-11, AC-14: converted digital silence is no signal, a converted tone is a voiced signal
    @Test func convertedSamplesFeedTheMeter() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = try AudioFileWriter(fileURL: url)

        var silent = AudioMeter()
        let zeros = try writer.append(microphoneBuffer(frames: 4_800, amplitude: 0))
        #expect(!zeros.isEmpty)
        silent.add(zeros)
        #expect(!silent.hasSignal)
        #expect(silent.level == 0)
        #expect(silent.voicedFraction == 0)

        // The converter hands out audio in its own blocks, so a chunk's count
        // varies around 1 600; over a recording it adds up (tests above).
        var voiced = AudioMeter()
        let samples = try writer.append(microphoneBuffer(frames: 4_800))
        #expect(samples.count > 800)
        voiced.add(samples)
        #expect(voiced.hasSignal)
        #expect(voiced.level > 0.8)
        #expect(voiced.voicedFraction == 1)
        writer.cancel()
    }
}

/// Which microphone opens, from ids only (AC-12, AC-13).
@Suite struct MicrophoneChoiceTests {
    // AC-12: a connected chosen microphone is used
    @Test func connectedChosenMicrophoneIsUsed() throws {
        let choice = try #require(
            MicrophoneChoice.resolve(wantedID: "usb", connectedIDs: ["built-in", "usb"], systemID: "built-in"))
        #expect(choice.id == "usb")
        #expect(choice.kind == .chosen)
    }

    // AC-13: a missing chosen microphone falls back to the system microphone
    @Test func missingChosenMicrophoneFallsBackToSystem() throws {
        let choice = try #require(
            MicrophoneChoice.resolve(wantedID: "usb", connectedIDs: ["built-in"], systemID: "built-in"))
        #expect(choice.id == "built-in")
        #expect(choice.kind == .system)
        let start = CaptureStart(kind: choice.kind, usedName: "MacBook", wantedID: "usb", wantedName: "Shure")
        #expect(start.fellBack)
    }

    // AC-12: no choice means the system microphone, which is no fallback
    @Test func noChoiceUsesSystemMicrophone() throws {
        let choice = try #require(
            MicrophoneChoice.resolve(wantedID: nil, connectedIDs: ["built-in"], systemID: "built-in"))
        #expect(choice.kind == .system)
        #expect(!CaptureStart(kind: .system, usedName: "MacBook", wantedID: nil, wantedName: nil).fellBack)
    }

    // design.md: without any input device there is nothing to open
    @Test func noDeviceAtAll() {
        #expect(MicrophoneChoice.resolve(wantedID: "usb", connectedIDs: [], systemID: nil) == nil)
    }
}
