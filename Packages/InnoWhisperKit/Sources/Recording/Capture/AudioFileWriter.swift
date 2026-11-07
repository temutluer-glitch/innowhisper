import AVFAudio
import AudioToolbox
import Diagnostics
import Foundation

/// Writes one recording file: CAF, 16 kHz, mono, 16-bit integer PCM, linear
/// and uncompressed (design.md → Datenmodell). CAF stays readable up to the
/// last written frame when the app stops unexpectedly and has no length
/// limit, so recordings have no maximum duration (AC-6).
///
/// Takes `AVAudioPCMBuffer`s in any PCM input format (e.g. 48 kHz stereo
/// float from a microphone), converts them to 16 kHz mono and appends them.
/// Not thread-safe by itself: use one instance from one serial queue only.
public final class AudioFileWriter {
    /// Audio handed to the file and to the level meter: 16 kHz, mono, 32-bit float.
    public static let processingFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32, sampleRate: RecordingInfo.sampleRate, channels: 1, interleaved: false)!

    /// Settings of the file on disk (design.md → Datenmodell).
    static var fileSettings: [String: Any] {
        [
            AVAudioFileTypeKey: kAudioFileCAFType,
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: RecordingInfo.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ]
    }

    public let fileURL: URL
    /// Frames of 16 kHz audio written to the file so far.
    public private(set) var framesWritten: AVAudioFramePosition = 0
    private var file: AVAudioFile?
    private var converter: AVAudioConverter?

    /// Creates (or replaces) the file at `fileURL`. Throws `CaptureError.cannotCreateFile`.
    public init(fileURL: URL) throws {
        self.fileURL = fileURL
        do {
            file = try AVAudioFile(
                forWriting: fileURL, settings: Self.fileSettings, commonFormat: .pcmFormatFloat32,
                interleaved: false)
        } catch {
            Log.write("Recording file could not be created: \(error: error)", category: .recording, level: .error)
            throw CaptureError.cannotCreateFile
        }
    }

    /// Length of the audio written so far.
    public var duration: Duration {
        Self.duration(ofFrames: framesWritten)
    }

    /// Converts `buffer` to 16 kHz mono, appends it to the file and returns the
    /// converted samples (−1…1) for the level meter. The sample-rate converter
    /// keeps a few frames back between calls; `finish()` writes them, so the
    /// file has no gaps (AC-6). Throws `CaptureError.cannotConvert`,
    /// `.cannotWrite` or `.writerClosed`.
    @discardableResult
    public func append(_ buffer: AVAudioPCMBuffer) throws -> [Float] {
        guard let file else { throw CaptureError.writerClosed }
        guard buffer.frameLength > 0 else { return [] }
        if buffer.format == Self.processingFormat {
            try write(buffer, to: file)
            return Self.samples(of: buffer)
        }
        if let current = converter, current.inputFormat != buffer.format {
            // The device changed its format mid-recording: write what the old
            // converter still holds, then continue with a new one.
            _ = try drain(current, input: nil, to: file)
            converter = nil
        }
        let active = try converter ?? makeConverter(for: buffer.format)
        converter = active
        return try drain(active, input: buffer, to: file)
    }

    /// Writes what the converter still holds, closes the file and returns its
    /// duration. Throws `CaptureError.cannotConvert`, `.cannotWrite` or `.writerClosed`.
    public func finish() throws -> Duration {
        guard let file else { throw CaptureError.writerClosed }
        defer {
            file.close()
            self.file = nil
            converter = nil
        }
        if let converter {
            _ = try drain(converter, input: nil, to: file)
        }
        return duration
    }

    /// Closes the file and deletes it. Safe to call more than once.
    public func cancel() {
        file?.close()
        file = nil
        converter = nil
        try? FileManager.default.removeItem(at: fileURL)
    }

    static func duration(ofFrames frames: AVAudioFramePosition) -> Duration {
        .nanoseconds(Int64(frames) * 1_000_000_000 / Int64(RecordingInfo.sampleRate))
    }

    private func makeConverter(for format: AVAudioFormat) throws -> AVAudioConverter {
        guard let converter = AVAudioConverter(from: format, to: Self.processingFormat) else {
            Log.write("Recording converter could not be created", category: .recording, level: .error)
            throw CaptureError.cannotConvert
        }
        // Mix all input channels into the one output channel instead of keeping only the first.
        converter.downmix = true
        return converter
    }

    /// Feeds `input` (or the end of the stream when nil) through `converter`
    /// and writes every frame that comes out.
    private func drain(_ converter: AVAudioConverter, input: AVAudioPCMBuffer?, to file: AVAudioFile) throws
        -> [Float]
    {
        let ratio = Self.processingFormat.sampleRate / converter.inputFormat.sampleRate
        let inputFrames = Double(input?.frameLength ?? 0)
        let capacity = AVAudioFrameCount((inputFrames * ratio).rounded(.up)) + 1_024
        var samples: [Float] = []
        let feed = ConverterFeed(input)
        while true {
            guard let output = AVAudioPCMBuffer(pcmFormat: Self.processingFormat, frameCapacity: capacity) else {
                throw CaptureError.cannotConvert
            }
            var conversionError: NSError?
            let status = converter.convert(to: output, error: &conversionError) { _, inputStatus in
                feed.next(inputStatus)
            }
            if status == .error {
                if let conversionError {
                    Log.write(
                        "Recording conversion failed: \(error: conversionError)", category: .recording, level: .error)
                }
                throw CaptureError.cannotConvert
            }
            if output.frameLength > 0 {
                try write(output, to: file)
                samples += Self.samples(of: output)
            }
            // `.haveData` means the output buffer filled up and more may follow.
            guard status == .haveData else { break }
        }
        return samples
    }

    private func write(_ buffer: AVAudioPCMBuffer, to file: AVAudioFile) throws {
        do {
            try file.write(from: buffer)
        } catch {
            Log.write("Recording file write failed: \(error: error)", category: .recording, level: .error)
            throw CaptureError.cannotWrite
        }
        framesWritten += AVAudioFramePosition(buffer.frameLength)
    }

    private static func samples(of buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channel = buffer.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
    }
}

/// Hands one buffer to the converter exactly once, then says "no data for now"
/// (more audio will follow) or, without a buffer, "end of stream". The
/// converter calls it synchronously inside `convert(to:error:withInputFrom:)`
/// on the writer's own thread, which is what makes the unchecked `Sendable` safe.
private final class ConverterFeed: @unchecked Sendable {
    private var input: AVAudioPCMBuffer?
    private let endOfStream: Bool

    init(_ input: AVAudioPCMBuffer?) {
        self.input = input
        endOfStream = input == nil
    }

    func next(_ status: UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer? {
        if let buffer = input {
            input = nil
            status.pointee = .haveData
            return buffer
        }
        status.pointee = endOfStream ? .endOfStream : .noDataNow
        return nil
    }
}
