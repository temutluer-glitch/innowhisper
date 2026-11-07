import AppShell
import CoreGraphics
import Diagnostics
import Foundation
import Notices
import Observation

/// What the shortcut watcher offers the controller; the real one is `HotkeyMonitor`.
@MainActor
public protocol RecordingHotkeys: AnyObject {
    var onAction: (@MainActor (KeyInterpreter.Action) -> Void)? { get set }
    /// The controller finished or cancelled a recording, or refused to start one.
    func reset()
}

extension HotkeyMonitor: RecordingHotkeys {}

/// Who may record right now (EC-6, AC-19, AC-20).
public enum RecordingGate: Equatable, Sendable, LogValue {
    /// Normal dictation.
    case normal
    /// The onboarding step "Tastenkürzel" is open: recordings are probes and never handed on.
    case probe
    /// The onboarding is open on another step: the shortcut records nothing.
    case blocked

    public var logDescription: StaticString {
        switch self {
        case .normal: "normal"
        case .probe: "probe"
        case .blocked: "blocked"
        }
    }
}

/// Why a running recording ended without the shortcut (EC-2 to EC-4).
public enum RecordingInterruption: Equatable, Sendable, LogValue {
    case microphoneDisconnected
    case systemSleepOrLock
    case diskFull

    public var logDescription: StaticString {
        switch self {
        case .microphoneDisconnected: "microphone disconnected"
        case .systemSleepOrLock: "sleep or screen lock"
        case .diskFull: "disk full"
        }
    }
}

/// Time since the last keyboard or mouse input anywhere on this Mac (BUG-16).
@MainActor public func systemInputIdle() -> Duration {
    guard let anyInput = CGEventType(rawValue: ~0) else { return .zero }
    let seconds = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
    return .milliseconds(Int64(max(0, seconds) * 1000))
}

/// Everything the controller talks to, so tests can swap each part.
@MainActor
public struct RecordingServices {
    public var capture: any MicrophoneCapturing
    public var storage: RecordingStorage
    public var queue: RecordingQueue
    public var activity: ActivityCenter
    /// Free disk space in bytes; `nil` when unknown (EC-4).
    public var freeBytes: @MainActor () -> Int64?
    /// Time since the last keyboard or mouse input anywhere on the Mac (BUG-16).
    public var inputIdle: @MainActor () -> Duration
    /// The chosen microphone (`nil` = system microphone) and its remembered name.
    public var chosenMicrophone: @MainActor () -> (id: String, name: String?)?
    public var microphoneAllowed: @MainActor () -> Bool
    public var requestMicrophone: @MainActor @Sendable () -> Void
    public var notify: @MainActor (NoticeKind, String, NoticeAction?) -> Void
    /// A new dictation starts: an error notice goes away (PROJ-2 AC-4).
    public var dictationStarted: @MainActor () -> Void
    public var playStart: @MainActor () -> Void
    public var playEnd: @MainActor () -> Void
    /// Keeps the Mac and its screen awake while a recording runs (BUG-10).
    public var keepAwake: @MainActor (Bool) -> Void
    public var now: @MainActor () -> ContinuousClock.Instant
    public var sleep: @MainActor (Duration) async -> Void

    public init(
        capture: any MicrophoneCapturing,
        storage: RecordingStorage,
        queue: RecordingQueue,
        activity: ActivityCenter,
        freeBytes: (@MainActor () -> Int64?)? = nil,
        inputIdle: @escaping @MainActor () -> Duration = { .zero },
        chosenMicrophone: @escaping @MainActor () -> (id: String, name: String?)?,
        microphoneAllowed: @escaping @MainActor () -> Bool,
        requestMicrophone: @escaping @MainActor @Sendable () -> Void,
        notify: @escaping @MainActor (NoticeKind, String, NoticeAction?) -> Void,
        dictationStarted: @escaping @MainActor () -> Void,
        playStart: @escaping @MainActor () -> Void,
        playEnd: @escaping @MainActor () -> Void,
        keepAwake: @escaping @MainActor (Bool) -> Void = { _ in },
        now: @escaping @MainActor () -> ContinuousClock.Instant = { ContinuousClock.now },
        sleep: @escaping @MainActor (Duration) async -> Void = { try? await Task.sleep(for: $0) }
    ) {
        self.capture = capture
        self.storage = storage
        self.queue = queue
        self.activity = activity
        self.freeBytes = freeBytes ?? { storage.availableBytes() }
        self.inputIdle = inputIdle
        self.chosenMicrophone = chosenMicrophone
        self.microphoneAllowed = microphoneAllowed
        self.requestMicrophone = requestMicrophone
        self.notify = notify
        self.dictationStarted = dictationStarted
        self.playStart = playStart
        self.playEnd = playEnd
        self.keepAwake = keepAwake
        self.now = now
        self.sleep = sleep
    }
}

/// One recording from the shortcut to the hand-off (design.md → Abläufe).
/// A single state machine on the main actor: a recording can only start
/// from `idle` (EC-8), and a generation number lets late answers of an
/// earlier recording fall away instead of overwriting a newer one.
@MainActor
@Observable
public final class RecordingController {
    public enum State: Equatable, Sendable {
        case idle
        /// Microphone opened, no real sound yet (AC-4, AC-14).
        case starting
        /// Sound flows; start tone played.
        case recording
        /// Closing the file.
        case finishing
    }

    public private(set) var state: State = .idle
    /// Live level 0…1 for the level display (AC-19) and later PROJ-8.
    public private(set) var level: Double = 0
    /// Set by the app from the onboarding state.
    public var gate: RecordingGate = .normal {
        didSet {
            guard gate != oldValue else { return }
            Log.write("Recording gate: \(gate)", category: .recording)
        }
    }
    /// Outcome of a probe in the onboarding step: true = worked (AC-20).
    @ObservationIgnored public var onProbeResult: (@MainActor (Bool) -> Void)?

    @ObservationIgnored private let hotkeys: any RecordingHotkeys
    @ObservationIgnored private var services: RecordingServices
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var openedAt: ContinuousClock.Instant?
    @ObservationIgnored private var startedAt = Date()
    @ObservationIgnored private var fileURL: URL?
    @ObservationIgnored private var microphoneKind: MicrophoneKind = .system
    @ObservationIgnored private var escapeRule = EscapeRule()
    /// Whether the Mac is kept awake right now, and when speech was last heard (BUG-12).
    @ObservationIgnored private var isKeptAwake = false
    @ObservationIgnored private var lastSpeechAt: ContinuousClock.Instant?
    /// Running background noise in dB and when it was last updated (BUG-16).
    @ObservationIgnored private var background: (decibels: Double, at: ContinuousClock.Instant)?
    @ObservationIgnored private var watchers: [Task<Void, Never>] = []

    public init(hotkeys: any RecordingHotkeys, services: RecordingServices) {
        self.hotkeys = hotkeys
        self.services = services
        hotkeys.onAction = { [weak self] action in self?.handle(action) }
        services.capture.onLevel = { [weak self] level in self?.received(level) }
        services.capture.onInterruption = { [weak self] interruption in self?.captureInterrupted(interruption) }
    }

    // MARK: - Shortcut

    func handle(_ action: KeyInterpreter.Action) {
        switch action {
        case .none: break
        case .open: open()
        case .finish: finish(interruption: nil)
        case .discard: discardSilently()
        case .escape: escape()
        }
    }

    private func open() {
        guard state == .idle else {
            Log.write("Shortcut ignored: a recording is already running", category: .recording)
            // The watcher must not believe a recording runs that never started (BUG-1).
            hotkeys.reset()
            return
        }
        guard gate != .blocked else {
            Log.write("Shortcut ignored: onboarding open", category: .recording)
            hotkeys.reset()
            return
        }
        guard services.microphoneAllowed() else {
            Log.write("Recording refused: microphone not allowed", category: .recording, level: .error)
            services.notify(
                .error, RecordingTexts.microphoneNotAllowed,
                NoticeAction(title: RecordingTexts.allowNow, perform: services.requestMicrophone))
            hotkeys.reset()
            return
        }
        if let free = services.freeBytes(), !RecordingRules.hasEnoughDiskSpace(freeBytes: free) {
            Log.write("Recording refused: disk full", category: .recording, level: .error)
            services.notify(.error, RecordingTexts.diskFull, nil)
            hotkeys.reset()
            return
        }
        let url: URL
        let start: CaptureStart
        let chosen = services.chosenMicrophone()
        do {
            url = try services.storage.newFileURL()
            start = try services.capture.start(microphoneID: chosen?.id, fileURL: url)
        } catch {
            Log.write("Recording could not start: \(error: error)", category: .recording, level: .error)
            services.notify(.error, RecordingTexts.recordingFailed, nil)
            hotkeys.reset()
            return
        }
        generation += 1
        state = .starting
        openedAt = services.now()
        startedAt = Date()
        fileURL = url
        microphoneKind = start.kind
        escapeRule.reset()
        level = 0
        background = nil
        Log.write(
            "Recording opening, microphone \(start.kind), gate \(gate)", category: .recording)
        if start.fellBack {
            let wanted = start.wantedName ?? chosen?.name ?? "Dein Mikrofon"
            services.notify(.info, RecordingTexts.microphoneMissing(wanted: wanted, using: start.usedName), nil)
        }
        watchForNoSound(generation)
    }

    /// AC-14: without real sound after 1 s the start is cancelled with a notice.
    private func watchForNoSound(_ current: Int) {
        let task = Task { [weak self] in
            guard let self else { return }
            await services.sleep(RecordingInfo.noSoundTimeout)
            guard generation == current, state == .starting else { return }
            Log.write("Recording cancelled: microphone delivers no sound", category: .recording, level: .error)
            cancelRecording(reason: .failedStart)
            services.notify(.error, RecordingTexts.noSound, nil)
        }
        watchers.append(task)
    }

    private func received(_ captureLevel: CaptureLevel) {
        guard state == .starting || state == .recording else { return }
        level = captureLevel.level
        let speech = isSpeech(captureLevel.level)
        if state == .recording, speech {
            lastSpeechAt = services.now()
            if services.inputIdle() < RecordingInfo.awakeWithoutInput {
                setKeptAwake(true)
            }
        }
        guard state == .starting, captureLevel.hasSignal else { return }
        state = .recording
        if let openedAt {
            Log.write("Recording started, sound after \(services.now() - openedAt)", category: .recording)
        }
        services.playStart()
        lastSpeechAt = services.now()
        setKeptAwake(true)
        services.dictationStarted()
        services.activity.activity = .recording
        watchDiskSpace(generation)
        watchForSilence(generation)
    }

    /// Speech is a level clearly above the room's running background noise:
    /// the background follows quieter levels at once and rises only slowly, so
    /// steady noise never counts and quiet speech in a quiet room does (BUG-16).
    private func isSpeech(_ level: Double) -> Bool {
        let decibels = level * 60 - 60
        let now = services.now()
        guard let background else {
            self.background = (decibels, now)
            return false
        }
        let elapsed = now - background.at
        let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
        let risen = background.decibels + RecordingInfo.awakeBackgroundRisePerSecond * seconds
        self.background = (min(decibels, risen), now)
        return decibels >= background.decibels + RecordingInfo.awakeSpeechMarginDecibels
    }

    /// A forgotten recording (nothing said for 2 minutes, or no keyboard or
    /// mouse input for 20 minutes) lets the Mac sleep and lock again; the lock
    /// then ends the recording (BUG-12, BUG-16, EC-3).
    private func watchForSilence(_ current: Int) {
        let task = Task { [weak self] in
            while true {
                guard let self else { return }
                await services.sleep(RecordingInfo.speechCheckInterval)
                guard generation == current, state == .recording else { return }
                guard isKeptAwake else { continue }
                if let lastSpeechAt, services.now() - lastSpeechAt >= RecordingInfo.awakeWithoutSpeech {
                    Log.write("Keep-awake released: no speech for 2 minutes", category: .recording)
                    setKeptAwake(false)
                } else if services.inputIdle() >= RecordingInfo.awakeWithoutInput {
                    Log.write("Keep-awake released: no keyboard or mouse input for 20 minutes", category: .recording)
                    setKeptAwake(false)
                }
            }
        }
        watchers.append(task)
    }

    private func setKeptAwake(_ awake: Bool) {
        guard awake != isKeptAwake else { return }
        isKeptAwake = awake
        services.keepAwake(awake)
    }

    /// EC-4: free space is checked every 10 s while recording.
    private func watchDiskSpace(_ current: Int) {
        let task = Task { [weak self] in
            while true {
                guard let self else { return }
                await services.sleep(RecordingInfo.diskCheckInterval)
                guard generation == current, state == .recording else { return }
                if let free = services.freeBytes(), !RecordingRules.hasEnoughDiskSpace(freeBytes: free) {
                    interrupt(.diskFull)
                    return
                }
            }
        }
        watchers.append(task)
    }

    // MARK: - Ending

    /// Ends normally (shortcut released) or because of an interruption (EC-2 to EC-4).
    private func finish(interruption: RecordingInterruption?) {
        switch state {
        case .idle, .finishing:
            return
        case .starting:
            // Released or interrupted before any sound arrived: nothing to keep.
            Log.write("Recording ended before sound arrived", category: .recording)
            cancelRecording(reason: .tooShort)
            return
        case .recording:
            break
        }
        let current = generation
        let interrupted = interruption != nil
        state = .finishing
        stopWatchers()
        hotkeys.reset()
        services.playEnd()
        if let interruption {
            Log.write("Recording interrupted: \(interruption)", category: .recording)
        }
        Task { [weak self] in
            guard let self else { return }
            let result: CaptureResult
            do {
                result = try await services.capture.stop()
            } catch {
                guard generation == current else { return }
                Log.write("Recording could not be finished: \(error: error)", category: .recording, level: .error)
                if let fileURL { services.queue.discard(fileURL: fileURL, reason: .failedStart) }
                services.notify(.error, RecordingTexts.recordingFailed, nil)
                endRecording()
                return
            }
            guard generation == current else { return }
            deliver(result, interrupted: interrupted)
            switch interruption {
            case .microphoneDisconnected: services.notify(.info, RecordingTexts.microphoneDisconnected, nil)
            case .diskFull: services.notify(.error, RecordingTexts.diskFull, nil)
            case .systemSleepOrLock, nil: break
            }
            endRecording()
        }
    }

    private func deliver(_ result: CaptureResult, interrupted: Bool) {
        let verdict = RecordingRules.verdict(
            duration: result.duration, voicedFraction: result.voicedFraction, interrupted: interrupted)
        switch (verdict, gate) {
        case (.keep, .probe):
            services.queue.discard(fileURL: result.fileURL, reason: .probe)
            services.notify(.success, RecordingTexts.probeWorked, nil)
            onProbeResult?(true)
        case (.keep, _):
            services.queue.finish(
                fileURL: result.fileURL, duration: result.duration,
                microphone: microphoneKind == .chosen ? .chosen : .system, startedAt: startedAt)
        case (.discardSilently, _):
            services.queue.discard(fileURL: result.fileURL, reason: .tooShort)
        case (.discardAsSilent, _):
            services.queue.discard(fileURL: result.fileURL, reason: .silent)
            services.notify(.info, RecordingTexts.nothingHeard, nil)
            if gate == .probe { onProbeResult?(false) }
        }
    }

    /// EC-1: another key during the shortcut — drop without a word.
    private func discardSilently() {
        guard state == .starting || state == .recording else { return }
        Log.write("Recording discarded: another key was pressed", category: .recording)
        cancelRecording(reason: .cancelled)
    }

    /// AC-8, AC-9: Esc cancels at once up to 30 s, later only on a second Esc.
    private func escape() {
        guard state == .starting || state == .recording, let openedAt else {
            // No recording here: the watcher must stop swallowing Esc (BUG-1).
            hotkeys.reset()
            return
        }
        switch escapeRule.escape(atAge: services.now() - openedAt) {
        case .askAgain:
            Log.write("Escape pressed, waiting for a second one", category: .recording)
            services.notify(.info, RecordingTexts.pressEscapeAgain, nil)
        case .cancel:
            Log.write("Recording cancelled with Escape", category: .recording)
            cancelRecording(reason: .cancelled)
            services.notify(.info, RecordingTexts.cancelled, nil)
        }
    }

    // MARK: - Interruptions

    /// Sleep, screen lock (EC-3) or disk full (EC-4); called by the app's watchers.
    public func interrupt(_ interruption: RecordingInterruption) {
        guard state == .starting || state == .recording else { return }
        finish(interruption: interruption)
    }

    private func captureInterrupted(_ interruption: CaptureInterruption) {
        switch interruption {
        case .deviceDisconnected, .sessionFailed:
            interrupt(.microphoneDisconnected)
        case .writeFailed:
            guard state == .starting || state == .recording else { return }
            // Ends normally; stop() reports the write error and the notice follows.
            finish(interruption: nil)
        }
    }

    // MARK: - Helpers

    private func cancelRecording(reason: RecordingDiscardReason) {
        services.capture.cancel()
        if let fileURL { services.queue.discard(fileURL: fileURL, reason: reason) }
        hotkeys.reset()
        endRecording()
    }

    private func endRecording() {
        setKeptAwake(false)
        lastSpeechAt = nil
        background = nil
        stopWatchers()
        generation += 1
        state = .idle
        level = 0
        fileURL = nil
        openedAt = nil
        if services.activity.activity == .recording {
            services.activity.activity = .idle
        }
    }

    private func stopWatchers() {
        for watcher in watchers { watcher.cancel() }
        watchers.removeAll()
    }
}
