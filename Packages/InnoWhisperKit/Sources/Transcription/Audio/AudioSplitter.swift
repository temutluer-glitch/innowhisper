import AVFAudio
import AudioToolbox
import Diagnostics
import Foundation
import Recording

/// Why a recording could not be split (EC-4).
public enum AudioSplitError: Error, Equatable, Sendable {
    /// The recording is missing, empty, damaged or not 16 kHz mono (EC-4).
    case unreadable
    /// The pieces could not be written, e.g. the disk is full.
    case cannotWrite
}

/// One piece of a recording, ready to be uploaded (design.md → Teil-Dateien).
public struct AudioPiece: Equatable, Sendable {
    /// Position in spoken order, starting at 0.
    public let index: Int
    /// FLAC file, 16 kHz, mono.
    public let fileURL: URL
    /// Where the piece starts in the recording.
    public let start: Duration
    /// Length of the piece.
    public let duration: Duration
    /// First frame of the piece in the recording (16 kHz).
    public let startFrame: Int64
    /// Number of frames in the piece (16 kHz).
    public let frameCount: Int64
}

/// The pieces of one recording and the temporary folder they live in.
public struct AudioPieces: Equatable, Sendable {
    /// The per-call folder holding all piece files.
    public let folder: URL
    /// The pieces in spoken order; together they cover the whole recording
    /// without gap or overlap.
    public let pieces: [AudioPiece]

    /// Deletes the folder with all piece files. Safe to call more than once.
    public func remove() {
        do {
            try FileManager.default.removeItem(at: folder)
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            return
        } catch {
            Log.write("Piece folder could not be removed: \(error: error)", category: .transcription, level: .error)
        }
    }
}

/// Splits a recording (CAF, 16 kHz, mono, 16-bit) into pieces of about five
/// minutes, cut in the quietest half second near each mark, and writes them
/// as FLAC into a temporary folder of their own (AC-6, AC-7, EC-1, EC-4).
///
/// Holds only values, so it can be handed to any task. `split(_:)` does the
/// heavy reading and encoding off the main actor.
public struct AudioSplitter: Sendable {
    /// Name of the folder inside the system's temporary folder that holds all piece folders.
    public static let piecesFolderName = "InnoWhisper-Pieces"

    /// The default parent of all piece folders.
    public static var defaultBaseFolder: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(piecesFolderName, isDirectory: true)
    }

    /// Frames read and written per step while copying a piece.
    static let chunkFrames: AVAudioFrameCount = 65_536
    /// Settings of a piece file on disk (design.md → Teil-Dateien).
    static var pieceSettings: [String: Any] {
        [
            AVAudioFileTypeKey: kAudioFileFLACType,
            AVFormatIDKey: kAudioFormatFLAC,
            AVSampleRateKey: RecordingInfo.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitDepthHintKey: 16,
        ]
    }

    let pieceLength: Duration
    let singlePieceLimit: Duration
    let cutSearchWindow: Duration
    let quietStretch: Duration
    let baseFolder: URL

    /// The defaults come from `TranscriptionInfo`; tests pass shorter lengths.
    public init(
        pieceLength: Duration = TranscriptionInfo.pieceLength,
        singlePieceLimit: Duration = TranscriptionInfo.singlePieceLimit,
        cutSearchWindow: Duration = TranscriptionInfo.cutSearchWindow,
        quietStretch: Duration = TranscriptionInfo.quietStretch,
        baseFolder: URL = AudioSplitter.defaultBaseFolder
    ) {
        self.pieceLength = pieceLength
        self.singlePieceLimit = singlePieceLimit
        self.cutSearchWindow = cutSearchWindow
        self.quietStretch = quietStretch
        self.baseFolder = baseFolder
    }

    /// Reads the recording at `recordingURL`, splits it and writes the pieces.
    /// Runs off the main actor. Throws `AudioSplitError.unreadable` for a
    /// missing, empty or damaged recording (EC-4) and `.cannotWrite` when the
    /// pieces cannot be written; on any error no piece files are left behind.
    @concurrent
    public func split(_ recordingURL: URL) async throws -> AudioPieces {
        try splitNow(recordingURL)
    }

    /// Deletes every piece folder under `baseFolder`, e.g. left over from a
    /// run that ended unexpectedly (design.md → Teil-Dateien: deleted at app start).
    public static func removeAllPieceFolders(in baseFolder: URL = AudioSplitter.defaultBaseFolder) {
        do {
            try FileManager.default.removeItem(at: baseFolder)
            Log.write("Leftover piece folders removed", category: .transcription)
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            return
        } catch {
            Log.write(
                "Leftover piece folders could not be removed: \(error: error)", category: .transcription,
                level: .error)
        }
    }

    // MARK: - Splitting

    func splitNow(_ recordingURL: URL) throws -> AudioPieces {
        let source = try openRecording(recordingURL)
        let totalFrames = source.length
        let cuts = try cutFrames(in: source, totalFrames: totalFrames)

        let folder = baseFolder.appendingPathComponent(UUID().uuidString, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            Log.write("Piece folder could not be created: \(error: error)", category: .transcription, level: .error)
            throw AudioSplitError.cannotWrite
        }

        let bounds = [0] + cuts + [totalFrames]
        var pieces: [AudioPiece] = []
        do {
            for index in 0..<(bounds.count - 1) {
                let startFrame = bounds[index]
                let endFrame = bounds[index + 1]
                let url = folder.appendingPathComponent("piece-\(index).flac")
                try copyFrames(from: source, range: startFrame..<endFrame, to: url)
                let start = Self.duration(ofFrames: startFrame)
                pieces.append(
                    AudioPiece(
                        index: index, fileURL: url, start: start,
                        duration: Self.duration(ofFrames: endFrame) - start,
                        startFrame: startFrame, frameCount: endFrame - startFrame))
            }
        } catch {
            try? FileManager.default.removeItem(at: folder)
            throw error
        }
        Log.write(
            "Recording split into \(pieces.count) pieces, length \(Self.duration(ofFrames: totalFrames))",
            category: .transcription)
        return AudioPieces(folder: folder, pieces: pieces)
    }

    /// Opens the recording for lossless 16-bit reading and checks its format.
    private func openRecording(_ url: URL) throws -> AVAudioFile {
        let file: AVAudioFile
        do {
            file = try AVAudioFile(forReading: url, commonFormat: .pcmFormatInt16, interleaved: false)
        } catch {
            Log.write("Recording could not be opened: \(error: error)", category: .transcription, level: .error)
            throw AudioSplitError.unreadable
        }
        let format = file.fileFormat
        guard format.sampleRate == RecordingInfo.sampleRate, format.channelCount == 1 else {
            Log.write(
                "Recording has an unexpected format: \(format.sampleRate) Hz, \(format.channelCount) channels",
                category: .transcription, level: .error)
            throw AudioSplitError.unreadable
        }
        guard file.length > 0 else {
            Log.write("Recording holds no audio", category: .transcription, level: .error)
            throw AudioSplitError.unreadable
        }
        return file
    }

    /// Frames at which the recording is cut, ascending. Empty for a recording
    /// up to `singlePieceLimit`. Each mark lies `pieceLength` after the
    /// previous cut; the cut sits in the middle of the quietest
    /// `quietStretch` within `cutSearchWindow` around the mark. The last
    /// piece takes the rest and is at most `singlePieceLimit` long.
    func cutFrames(in source: AVAudioFile, totalFrames: Int64) throws -> [Int64] {
        let limit = Self.frames(of: singlePieceLimit)
        let length = Self.frames(of: pieceLength)
        let window = Self.frames(of: cutSearchWindow)
        let stretch = max(1, Self.frames(of: quietStretch))
        var cuts: [Int64] = []
        var previous: Int64 = 0
        while totalFrames - previous > limit {
            let mark = previous + length
            // Keep a whole stretch between the window and both neighbouring cuts.
            let lower = max(previous + stretch, mark - window)
            let upper = min(totalFrames - stretch, mark + window)
            let cut: Int64
            if upper - lower >= stretch {
                let samples = try readSamples(from: source, range: lower..<upper)
                cut = lower + Int64(Self.quietestCut(in: samples, stretch: Int(stretch), preferring: Int(mark - lower)))
            } else {
                cut = min(max(mark, previous + 1), totalFrames - 1)
            }
            cuts.append(cut)
            previous = cut
        }
        return cuts
    }

    /// Offset (from the start of `samples`) of the middle of the quietest
    /// stretch of `stretch` samples. The search moves in steps of 1/50 of a
    /// stretch; among equally quiet stretches the one closest to `preferred`
    /// wins, so pure silence is cut at the mark itself.
    static func quietestCut(in samples: [Int16], stretch: Int, preferring preferred: Int) -> Int {
        let step = max(1, stretch / 50)
        let blocksPerStretch = max(1, stretch / step)
        let blockCount = samples.count / step
        guard blockCount >= blocksPerStretch else { return min(max(0, preferred), samples.count) }
        // Energy of each block, then a running sum over one stretch of blocks.
        var blockEnergy = [Double](repeating: 0, count: blockCount)
        for block in 0..<blockCount {
            var sum = 0.0
            for sample in samples[(block * step)..<((block + 1) * step)] {
                let value = Double(sample)
                sum += value * value
            }
            blockEnergy[block] = sum
        }
        var energy = blockEnergy[0..<blocksPerStretch].reduce(0, +)
        let halfStretch = blocksPerStretch * step / 2
        var bestCut = halfStretch
        var bestEnergy = energy
        for first in stride(from: 1, through: blockCount - blocksPerStretch, by: 1) {
            energy += blockEnergy[first + blocksPerStretch - 1] - blockEnergy[first - 1]
            let cut = first * step + halfStretch
            // Relative tolerance absorbs rounding drift of the running sum.
            let tolerance = 1e-9 * max(1, bestEnergy)
            if energy < bestEnergy - tolerance
                || (abs(energy - bestEnergy) <= tolerance && abs(cut - preferred) < abs(bestCut - preferred))
            {
                bestEnergy = energy
                bestCut = cut
            }
        }
        return bestCut
    }

    // MARK: - Reading and writing

    /// Reads `range` of the recording as 16-bit samples. Throws `.unreadable`.
    private func readSamples(from source: AVAudioFile, range: Range<Int64>) throws -> [Int16] {
        var samples: [Int16] = []
        samples.reserveCapacity(Int(range.count))
        try forEachChunk(of: source, range: range) { buffer in
            guard let channel = buffer.int16ChannelData?[0] else { throw AudioSplitError.unreadable }
            samples += UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength))
        }
        return samples
    }

    /// Copies `range` of the recording into a new FLAC file at `url`.
    private func copyFrames(from source: AVAudioFile, range: Range<Int64>, to url: URL) throws {
        let piece: AVAudioFile
        do {
            piece = try AVAudioFile(
                forWriting: url, settings: Self.pieceSettings, commonFormat: .pcmFormatInt16, interleaved: false)
        } catch {
            Log.write("Piece file could not be created: \(error: error)", category: .transcription, level: .error)
            throw AudioSplitError.cannotWrite
        }
        defer { piece.close() }
        try forEachChunk(of: source, range: range) { buffer in
            do {
                try piece.write(from: buffer)
            } catch {
                Log.write("Piece file write failed: \(error: error)", category: .transcription, level: .error)
                throw AudioSplitError.cannotWrite
            }
        }
    }

    /// Reads `range` in chunks and hands each chunk to `body`. A read error or
    /// a recording shorter than its header says throws `.unreadable`.
    private func forEachChunk(
        of source: AVAudioFile, range: Range<Int64>, _ body: (AVAudioPCMBuffer) throws -> Void
    ) throws {
        guard
            let buffer = AVAudioPCMBuffer(pcmFormat: source.processingFormat, frameCapacity: Self.chunkFrames)
        else { throw AudioSplitError.unreadable }
        source.framePosition = range.lowerBound
        var remaining = range.count
        while remaining > 0 {
            let wanted = AVAudioFrameCount(min(Int64(Self.chunkFrames), Int64(remaining)))
            do {
                try source.read(into: buffer, frameCount: wanted)
            } catch {
                Log.write("Recording read failed: \(error: error)", category: .transcription, level: .error)
                throw AudioSplitError.unreadable
            }
            guard buffer.frameLength > 0 else {
                Log.write("Recording ended before its stated length", category: .transcription, level: .error)
                throw AudioSplitError.unreadable
            }
            try body(buffer)
            remaining -= Int(buffer.frameLength)
        }
    }

    // MARK: - Frames and durations

    static func frames(of duration: Duration) -> Int64 {
        let (seconds, attoseconds) = duration.components
        let rate = Int64(RecordingInfo.sampleRate)
        return seconds * rate + Int64((Double(attoseconds) * Double(rate) / 1e18).rounded())
    }

    static func duration(ofFrames frames: Int64) -> Duration {
        .nanoseconds(frames * 1_000_000_000 / Int64(RecordingInfo.sampleRate))
    }
}
