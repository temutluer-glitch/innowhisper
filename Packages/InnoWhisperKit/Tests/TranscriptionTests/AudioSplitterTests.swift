import AVFAudio
import AudioToolbox
import Foundation
import Testing

@testable import Transcription

@Suite final class AudioSplitterTests {
    static let rate = 16_000

    let directory: URL
    let base: URL
    /// Short lengths so the test files stay small: piece 2 s, single piece up
    /// to 2.2 s, window ±0.5 s, quiet stretch 0.1 s.
    let splitter: AudioSplitter

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AudioSplitterTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        base = directory.appendingPathComponent("pieces", isDirectory: true)
        splitter = AudioSplitter(
            pieceLength: .seconds(2), singlePieceLimit: .milliseconds(2_200), cutSearchWindow: .milliseconds(500),
            quietStretch: .milliseconds(100), baseFolder: base)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: - Helpers

    static func frames(_ seconds: Double) -> Int { Int(seconds * Double(rate)) }

    /// A loud tone of `seconds` length; `quiet` ranges (in seconds) are
    /// replaced by a tone of the given amplitude (0 = digital silence).
    static func tone(seconds: Double, quiet: [(from: Double, to: Double, amplitude: Double)] = []) -> [Int16] {
        var samples = (0..<frames(seconds)).map { Int16(8_000 * sin(Double($0) * 0.07)) }
        for gap in quiet {
            for index in frames(gap.from)..<min(frames(gap.to), samples.count) {
                samples[index] = Int16(gap.amplitude * sin(Double(index) * 0.07))
            }
        }
        return samples
    }

    /// Writes `samples` as a recording file like PROJ-5 does: CAF, 16 kHz, mono, 16-bit.
    func writeRecording(_ samples: [Int16], name: String = "recording.caf") throws -> URL {
        let url = directory.appendingPathComponent(name)
        let settings: [String: Any] = [
            AVAudioFileTypeKey: kAudioFileCAFType,
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: Double(Self.rate),
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ]
        let file = try AVAudioFile(
            forWriting: url, settings: settings, commonFormat: .pcmFormatInt16, interleaved: false)
        defer { file.close() }
        guard !samples.isEmpty else { return url }
        let buffer = try #require(
            AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(samples.count)))
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source in
            buffer.int16ChannelData![0].update(from: source.baseAddress!, count: samples.count)
        }
        try file.write(from: buffer)
        return url
    }

    /// Reads a piece file back as 16-bit samples.
    func readPiece(_ url: URL) throws -> (file: AVAudioFile, samples: [Int16]) {
        let file = try AVAudioFile(forReading: url, commonFormat: .pcmFormatInt16, interleaved: false)
        let buffer = try #require(
            AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)))
        try file.read(into: buffer)
        let samples = Array(UnsafeBufferPointer(start: buffer.int16ChannelData![0], count: Int(buffer.frameLength)))
        return (file, samples)
    }

    func pieceFolders() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: base, includingPropertiesForKeys: nil)) ?? []
    }

    /// 6 s: a quiet dip (amplitude 200) and a quieter gap (amplitude 20) inside
    /// the window around the first mark (2 s, window 1.5…2.5 s), a silent decoy
    /// outside it (1.0…1.3 s), and a quiet gap inside the second window.
    static let gappedTone = tone(
        seconds: 6,
        quiet: [
            (from: 1.0, to: 1.3, amplitude: 0),
            (from: 1.6, to: 1.75, amplitude: 200),
            (from: 2.3, to: 2.45, amplitude: 20),
            (from: 4.1, to: 4.25, amplitude: 20),
        ])

    // MARK: - Tests

    // AC-6 / design.md: production lengths come from TranscriptionInfo
    @Test func defaultsComeFromTranscriptionInfo() {
        let production = AudioSplitter()
        #expect(production.pieceLength == TranscriptionInfo.pieceLength)
        #expect(production.singlePieceLimit == TranscriptionInfo.singlePieceLimit)
        #expect(production.cutSearchWindow == TranscriptionInfo.cutSearchWindow)
        #expect(production.quietStretch == TranscriptionInfo.quietStretch)
        #expect(production.baseFolder.lastPathComponent == AudioSplitter.piecesFolderName)
    }

    // AC-6: a recording up to the single-piece limit stays one piece
    @Test func shortRecordingIsOnePiece() async throws {
        let samples = Self.tone(seconds: 2.2)
        let result = try await splitter.split(try writeRecording(samples))
        #expect(result.pieces.count == 1)
        let piece = try #require(result.pieces.first)
        #expect(piece.index == 0)
        #expect(piece.startFrame == 0)
        #expect(piece.frameCount == Int64(samples.count))
        #expect(piece.start == .zero)
        #expect(piece.duration == .milliseconds(2_200))
    }

    // AC-7: each cut lies in the quietest stretch within the window, not in a
    // louder dip and not in a silent stretch outside the window
    @Test func cutsLandInsideTheQuietestStretch() async throws {
        let result = try await splitter.split(try writeRecording(Self.gappedTone))
        #expect(result.pieces.count == 3)
        let cuts = result.pieces.dropFirst().map(\.startFrame)
        // The 0.1 s stretch lies wholly in the 0.15 s gap: its middle is ≥ 0.05 s from both gap edges.
        #expect(cuts.count == 2)
        if cuts.count == 2 {
            #expect((Int64(Self.frames(2.35))...Int64(Self.frames(2.40))).contains(cuts[0]))
            #expect((Int64(Self.frames(4.15))...Int64(Self.frames(4.20))).contains(cuts[1]))
        }
    }

    // AC-7: pieces cover the whole recording, in order, without gap or overlap
    @Test func piecesCoverTheRecordingWithoutGapOrOverlap() async throws {
        let samples = Self.gappedTone
        let result = try await splitter.split(try writeRecording(samples))
        #expect(result.pieces.map(\.index) == Array(0..<result.pieces.count))
        var expectedStart: Int64 = 0
        for piece in result.pieces {
            #expect(piece.startFrame == expectedStart)
            #expect(piece.frameCount > 0)
            expectedStart += piece.frameCount
        }
        #expect(expectedStart == Int64(samples.count))
        let total = result.pieces.reduce(Duration.zero) { $0 + $1.duration }
        #expect(total == .seconds(6))
        #expect(result.pieces.last.map { $0.start + $0.duration } == .seconds(6))
    }

    // AC-6 / design.md → Teil-Dateien: pieces are FLAC, 16 kHz, mono, lossless
    @Test func piecesAreReadableLosslessFlac() async throws {
        let samples = Self.gappedTone
        let result = try await splitter.split(try writeRecording(samples))
        var joined: [Int16] = []
        for piece in result.pieces {
            #expect(piece.fileURL.deletingLastPathComponent() == result.folder)
            let (file, pieceSamples) = try readPiece(piece.fileURL)
            #expect(file.fileFormat.streamDescription.pointee.mFormatID == kAudioFormatFLAC)
            #expect(file.fileFormat.sampleRate == 16_000)
            #expect(file.fileFormat.channelCount == 1)
            #expect(file.length == piece.frameCount)
            joined += pieceSamples
        }
        #expect(joined == samples)
    }

    // EC-1: a completely silent middle part still becomes its own piece, cut at the marks
    @Test func silentMiddlePieceIsKept() async throws {
        let samples = Self.tone(seconds: 6, quiet: [(from: 1.4, to: 4.6, amplitude: 0)])
        let result = try await splitter.split(try writeRecording(samples))
        #expect(result.pieces.count == 3)
        // Equal silence everywhere in the windows: the cut falls on the mark itself.
        #expect(result.pieces.dropFirst().first?.startFrame == Int64(Self.frames(2)))
        let middle = try readPiece(try #require(result.pieces.dropFirst().first).fileURL).samples
        #expect(!middle.isEmpty)
        #expect(middle.allSatisfy { $0 == 0 })
    }

    // EC-4: random bytes, an empty file and a missing file are "unreadable", without leftovers
    @Test func damagedFileIsUnreadable() async throws {
        let random = directory.appendingPathComponent("random.caf")
        try Data((0..<4_096).map { _ in UInt8.random(in: .min ... .max) }).write(to: random)
        let empty = directory.appendingPathComponent("empty.caf")
        try Data().write(to: empty)
        let missing = directory.appendingPathComponent("missing.caf")
        for url in [random, empty, missing] {
            await #expect(throws: AudioSplitError.unreadable) {
                _ = try await splitter.split(url)
            }
        }
        #expect(pieceFolders().isEmpty)
    }

    // EC-4: a valid file with no audio is unreadable too
    @Test func recordingWithoutAudioIsUnreadable() async throws {
        let url = try writeRecording([])
        await #expect(throws: AudioSplitError.unreadable) {
            _ = try await splitter.split(url)
        }
    }

    // design.md → Teil-Dateien: each call gets its own folder, and remove() deletes it
    @Test func removeDeletesThePieceFolder() async throws {
        let url = try writeRecording(Self.gappedTone)
        let first = try await splitter.split(url)
        let second = try await splitter.split(url)
        #expect(first.folder != second.folder)
        #expect(first.folder.deletingLastPathComponent().standardizedFileURL == base.standardizedFileURL)
        #expect(FileManager.default.fileExists(atPath: first.folder.path))
        first.remove()
        #expect(!FileManager.default.fileExists(atPath: first.folder.path))
        #expect(FileManager.default.fileExists(atPath: second.folder.path))
        first.remove()  // a second call is harmless
    }

    // design.md → Teil-Dateien: at app start all leftover piece folders are deleted
    @Test func removeAllPieceFoldersClearsLeftovers() async throws {
        let url = try writeRecording(Self.gappedTone)
        _ = try await splitter.split(url)
        _ = try await splitter.split(url)
        #expect(pieceFolders().count == 2)
        AudioSplitter.removeAllPieceFolders(in: base)
        #expect(pieceFolders().isEmpty)
        AudioSplitter.removeAllPieceFolders(in: base)  // nothing left: harmless
    }

    // AC-6: with the production lengths, 10 minutes become two pieces of about 5 minutes
    @Test func tenMinutesBecomeTwoPieces() async throws {
        let samples = [Int16](repeating: 1_000, count: 10 * 60 * Self.rate)
        let result = try await AudioSplitter(baseFolder: base).split(try writeRecording(samples))
        #expect(result.pieces.count == 2)
        #expect(result.pieces.map(\.duration) == [.seconds(300), .seconds(300)])
    }

    // AC-7: among equally quiet stretches the one nearest the mark wins
    @Test func quietestCutPrefersTheMarkOnTies() {
        let silence = [Int16](repeating: 0, count: 1_000)
        #expect(AudioSplitter.quietestCut(in: silence, stretch: 100, preferring: 600) == 600)
        var dip = [Int16](repeating: 1_000, count: 1_000)
        for index in 200..<300 { dip[index] = 0 }
        #expect(AudioSplitter.quietestCut(in: dip, stretch: 100, preferring: 900) == 250)
    }
}
