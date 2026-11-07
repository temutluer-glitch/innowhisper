import AVFoundation
import CoreMedia
import Diagnostics
import Foundation

/// Which microphone a recording uses (design.md → Datenmodell).
public enum MicrophoneKind: Equatable, Sendable, LogValue {
    /// The microphone chosen in the settings.
    case chosen
    /// The microphone macOS uses as its input ("Systemmikrofon").
    case system

    public var logDescription: StaticString {
        switch self {
        case .chosen: "chosen"
        case .system: "system"
        }
    }
}

/// Why opening the microphone or writing the file failed. The controller
/// shows `RecordingTexts.recordingFailed` (design.md).
public enum CaptureError: Error, Equatable, Sendable, LogValue {
    /// The recording file could not be created.
    case cannotCreateFile
    /// The audio could not be converted to 16 kHz mono.
    case cannotConvert
    /// Writing to the recording file failed (e.g. disk full).
    case cannotWrite
    /// The file was already finished or cancelled.
    case writerClosed
    /// There is no audio input device at all.
    case noMicrophone
    /// The device could not be opened.
    case cannotOpenMicrophone
    /// A recording is already running on this capture.
    case alreadyRunning
    /// `stop()` without a running recording.
    case notRunning

    public var logDescription: StaticString {
        switch self {
        case .cannotCreateFile: "cannotCreateFile"
        case .cannotConvert: "cannotConvert"
        case .cannotWrite: "cannotWrite"
        case .writerClosed: "writerClosed"
        case .noMicrophone: "noMicrophone"
        case .cannotOpenMicrophone: "cannotOpenMicrophone"
        case .alreadyRunning: "alreadyRunning"
        case .notRunning: "notRunning"
        }
    }
}

/// What `start` opened (AC-13).
public struct CaptureStart: Equatable, Sendable {
    public let kind: MicrophoneKind
    /// Localized name of the device that records.
    public let usedName: String
    /// The microphone id asked for, nil for the system microphone.
    public let wantedID: String?
    /// Localized name of the wanted device; nil when no device was asked for or
    /// its name is unknown (it was not connected since the app started).
    public let wantedName: String?

    public init(kind: MicrophoneKind, usedName: String, wantedID: String?, wantedName: String?) {
        self.kind = kind
        self.usedName = usedName
        self.wantedID = wantedID
        self.wantedName = wantedName
    }

    /// `true` when a chosen microphone was missing and the system microphone records instead (AC-13).
    public var fellBack: Bool { wantedID != nil && kind == .system }
}

/// Live measurement while recording (level bar, AC-4, AC-11, AC-14).
public struct CaptureLevel: Equatable, Sendable {
    /// Level of the latest audio, 0…1.
    public let level: Double
    /// `true` once any non-zero sample arrived (AC-14).
    public let hasSignal: Bool
    /// Share of voiced audio so far (AC-11).
    public let voicedFraction: Double

    public init(level: Double, hasSignal: Bool, voicedFraction: Double) {
        self.level = level
        self.hasSignal = hasSignal
        self.voicedFraction = voicedFraction
    }
}

/// Why a running recording cannot go on. The controller then calls `stop()`
/// to keep what was recorded (EC-2) or shows `RecordingTexts.recordingFailed`.
public enum CaptureInterruption: Equatable, Sendable, LogValue {
    /// The recording device was unplugged (EC-2).
    case deviceDisconnected
    /// The capture session reported a runtime error.
    case sessionFailed
    /// Writing the file failed; nothing more is written.
    case writeFailed

    public var logDescription: StaticString {
        switch self {
        case .deviceDisconnected: "deviceDisconnected"
        case .sessionFailed: "sessionFailed"
        case .writeFailed: "writeFailed"
        }
    }
}

/// A finished recording file (AC-6, AC-11).
public struct CaptureResult: Equatable, Sendable {
    public let fileURL: URL
    public let duration: Duration
    public let voicedFraction: Double
    public let hasSignal: Bool

    public init(fileURL: URL, duration: Duration, voicedFraction: Double, hasSignal: Bool) {
        self.fileURL = fileURL
        self.duration = duration
        self.voicedFraction = voicedFraction
        self.hasSignal = hasSignal
    }
}

/// Opens a microphone and records into a file. The real one uses
/// AVCaptureSession; controller tests use a stand-in.
@MainActor
public protocol MicrophoneCapturing: AnyObject {
    /// Called on the main actor about 20 times per second, and at once when
    /// sound starts to flow.
    var onLevel: (@MainActor (CaptureLevel) -> Void)? { get set }
    /// Called on the main actor at most once per recording.
    var onInterruption: (@MainActor (CaptureInterruption) -> Void)? { get set }
    /// Opens the chosen microphone if `microphoneID` is connected, otherwise
    /// the system microphone (AC-12, AC-13), and starts writing `fileURL`.
    /// Does not ask for the microphone permission. Throws `CaptureError`.
    func start(microphoneID: String?, fileURL: URL) throws -> CaptureStart
    /// Closes the microphone, writes the rest of the audio and closes the file.
    func stop() async throws -> CaptureResult
    /// Closes the microphone and deletes the file.
    func cancel()
}

/// Which device to open, decided from ids only so it can be tested (AC-12, AC-13).
enum MicrophoneChoice {
    /// The wanted device if it is connected, otherwise the system microphone;
    /// nil when there is none.
    static func resolve(wantedID: String?, connectedIDs: [String], systemID: String?) -> (
        id: String, kind: MicrophoneKind
    )? {
        if let wantedID, connectedIDs.contains(wantedID) {
            return (wantedID, .chosen)
        }
        guard let systemID else { return nil }
        return (systemID, .system)
    }
}

/// Records with AVCaptureSession: the device can be chosen per recording
/// without changing the system microphone, every chunk of audio arrives on
/// its own, and a running video call is not disturbed (EC-7, design.md). No
/// voice processing.
@MainActor
public final class MicrophoneCapture: MicrophoneCapturing {
    public var onLevel: (@MainActor (CaptureLevel) -> Void)?
    public var onInterruption: (@MainActor (CaptureInterruption) -> Void)?

    private let sampleQueue = DispatchQueue(label: "com.innosolv.InnoWhisper.capture.samples")
    private let sessionQueue = DispatchQueue(label: "com.innosolv.InnoWhisper.capture.session")
    private var running: Running?
    /// Counts recordings, so late callbacks of an earlier one are ignored.
    private var generation = 0

    private struct Running {
        let session: AVCaptureSession
        let sink: CaptureSink
        let fileURL: URL
        let observers: [NSObjectProtocol]
    }

    public init() {}

    public func start(microphoneID: String?, fileURL: URL) throws -> CaptureStart {
        guard running == nil else { throw CaptureError.alreadyRunning }
        let connected = MicrophoneDevices.connected()
        let system = MicrophoneDevices.systemDefault()
        guard
            let choice = MicrophoneChoice.resolve(
                wantedID: microphoneID, connectedIDs: connected.map(\.uniqueID), systemID: system?.uniqueID),
            let device = connected.first(where: { $0.uniqueID == choice.id }) ?? system
        else {
            Log.write("Capture start failed: \(CaptureError.noMicrophone)", category: .recording, level: .error)
            throw CaptureError.noMicrophone
        }

        let writer = try AudioFileWriter(fileURL: fileURL)
        let session = AVCaptureSession()
        do {
            try configure(session, device: device)
        } catch {
            writer.cancel()
            Log.write("Capture start failed: \(CaptureError.cannotOpenMicrophone)", category: .recording, level: .error)
            throw CaptureError.cannotOpenMicrophone
        }

        generation += 1
        let current = generation
        let sink = CaptureSink(
            writer: writer,
            publishLevel: { [weak self] level in
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        guard let self, self.generation == current else { return }
                        self.onLevel?(level)
                    }
                }
            },
            reportWriteFailure: { [weak self] in
                DispatchQueue.main.async {
                    MainActor.assumeIsolated { self?.interrupt(.writeFailed, generation: current) }
                }
            })
        guard let output = session.outputs.first as? AVCaptureAudioDataOutput else {
            writer.cancel()
            throw CaptureError.cannotOpenMicrophone
        }
        output.setSampleBufferDelegate(sink, queue: sampleQueue)

        let observers = observe(device: device, session: session, generation: current)
        running = Running(session: session, sink: sink, fileURL: fileURL, observers: observers)
        nonisolated(unsafe) let unsafeSession = session
        sessionQueue.async { unsafeSession.startRunning() }

        let wantedName = microphoneID.flatMap { id in
            connected.first { $0.uniqueID == id }?.localizedName ?? MicrophoneNames.name(for: id)
        }
        let start = CaptureStart(
            kind: choice.kind, usedName: device.localizedName, wantedID: microphoneID, wantedName: wantedName)
        Log.write("Capture started: microphone \(start.kind), fell back \(start.fellBack)", category: .recording)
        return start
    }

    public func stop() async throws -> CaptureResult {
        guard let running = finishRunning() else { throw CaptureError.notRunning }
        nonisolated(unsafe) let session = running.session
        let sink = running.sink
        let fileURL = running.fileURL
        let sampleQueue = sampleQueue
        let result: Result<CaptureResult, CaptureError> = await withCheckedContinuation { continuation in
            sessionQueue.async {
                session.stopRunning()
                // Chunks delivered before the stop are still queued; finish after them.
                sampleQueue.async { continuation.resume(returning: sink.finish(fileURL: fileURL)) }
            }
        }
        if case .success(let capture) = result {
            Log.write("Capture stopped: \(capture.duration), signal \(capture.hasSignal)", category: .recording)
        }
        return try result.get()
    }

    public func cancel() {
        guard let running = finishRunning() else { return }
        nonisolated(unsafe) let session = running.session
        let sink = running.sink
        let sampleQueue = sampleQueue
        sessionQueue.async {
            session.stopRunning()
            sampleQueue.async { sink.cancel() }
        }
        Log.write("Capture cancelled", category: .recording)
    }

    /// Ends the current recording on the main actor: no more callbacks, no observers.
    private func finishRunning() -> Running? {
        guard let running else { return nil }
        self.running = nil
        generation += 1
        running.observers.forEach(NotificationCenter.default.removeObserver)
        return running
    }

    private func interrupt(_ reason: CaptureInterruption, generation expected: Int) {
        guard generation == expected, running != nil else { return }
        Log.write("Capture interrupted: \(reason)", category: .recording, level: .error)
        // Only the first interruption of a recording is reported.
        generation += 1
        onInterruption?(reason)
    }

    private func configure(_ session: AVCaptureSession, device: AVCaptureDevice) throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw CaptureError.cannotOpenMicrophone }
        session.addInput(input)
        let output = AVCaptureAudioDataOutput()
        guard session.canAddOutput(output) else { throw CaptureError.cannotOpenMicrophone }
        session.addOutput(output)
    }

    /// Watches for the used device being unplugged (EC-2) and for session errors.
    private func observe(device: AVCaptureDevice, session: AVCaptureSession, generation current: Int)
        -> [NSObjectProtocol]
    {
        let center = NotificationCenter.default
        let disconnected = center.addObserver(
            forName: AVCaptureDevice.wasDisconnectedNotification, object: device, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.interrupt(.deviceDisconnected, generation: current) }
        }
        let failed = center.addObserver(
            forName: AVCaptureSession.runtimeErrorNotification, object: session, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.interrupt(.sessionFailed, generation: current) }
        }
        return [disconnected, failed]
    }
}

/// Receives the audio chunks on the capture's serial queue: converts and
/// writes them, measures them and publishes the level. Every method runs on
/// that one queue, which is what makes the unchecked `Sendable` safe.
private final class CaptureSink: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate, @unchecked Sendable {
    /// At most this often a level is published, except when sound starts to flow.
    static let publishInterval: Duration = .milliseconds(50)

    private let writer: AudioFileWriter
    private let publishLevel: @Sendable (CaptureLevel) -> Void
    private let reportWriteFailure: @Sendable () -> Void
    private var meter = AudioMeter()
    private var lastPublish: ContinuousClock.Instant?
    private var failed = false
    private var closed = false

    init(
        writer: AudioFileWriter, publishLevel: @escaping @Sendable (CaptureLevel) -> Void,
        reportWriteFailure: @escaping @Sendable () -> Void
    ) {
        self.writer = writer
        self.publishLevel = publishLevel
        self.reportWriteFailure = reportWriteFailure
    }

    func captureOutput(
        _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection
    ) {
        guard !closed, !failed, let buffer = Self.pcmBuffer(from: sampleBuffer) else { return }
        let samples: [Float]
        do {
            samples = try writer.append(buffer)
        } catch {
            failed = true
            reportWriteFailure()
            return
        }
        let hadSignal = meter.hasSignal
        meter.add(samples)
        let now = ContinuousClock.now
        let due = lastPublish.map { now - $0 >= Self.publishInterval } ?? true
        guard due || meter.hasSignal != hadSignal else { return }
        lastPublish = now
        publishLevel(CaptureLevel(level: meter.level, hasSignal: meter.hasSignal, voicedFraction: meter.voicedFraction))
    }

    func finish(fileURL: URL) -> Result<CaptureResult, CaptureError> {
        closed = true
        if failed {
            writer.cancel()
            return .failure(.cannotWrite)
        }
        do {
            let duration = try writer.finish()
            return .success(
                CaptureResult(
                    fileURL: fileURL, duration: duration, voicedFraction: meter.voicedFraction,
                    hasSignal: meter.hasSignal))
        } catch let error as CaptureError {
            return .failure(error)
        } catch {
            return .failure(.cannotWrite)
        }
    }

    func cancel() {
        closed = true
        writer.cancel()
    }

    /// Copies the audio of a sample buffer into a PCM buffer of the same format.
    static func pcmBuffer(from sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
        guard let description = CMSampleBufferGetFormatDescription(sampleBuffer) else { return nil }
        let frames = CMSampleBufferGetNumSamples(sampleBuffer)
        let format = AVAudioFormat(cmAudioFormatDescription: description)
        guard frames > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))
        else { return nil }
        buffer.frameLength = AVAudioFrameCount(frames)
        let status = CMSampleBufferCopyPCMDataIntoAudioBufferList(
            sampleBuffer, at: 0, frameCount: Int32(frames), into: buffer.mutableAudioBufferList)
        return status == noErr ? buffer : nil
    }
}
