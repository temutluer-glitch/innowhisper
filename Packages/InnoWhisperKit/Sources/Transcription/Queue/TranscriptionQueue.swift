import AppShell
import Diagnostics
import Foundation
import Notices
import Recording

/// Everything the queue talks to, so tests can swap each part.
@MainActor
public struct TranscriptionServices {
    public var transcriber: any Transcribing
    public var split: @Sendable (URL) async throws -> AudioPieces
    /// The Groq key from the keychain; `nil` when none is stored (AC-12).
    public var readKey: @MainActor () -> String?
    /// Groq refused the key: the app re-checks it in PROJ-4 (AC-13).
    public var keyRejected: @MainActor () -> Void
    /// Opens the key settings (buttons of AC-12 and AC-13).
    public var showKeySettings: @MainActor @Sendable () -> Void
    public var notify: @MainActor (NoticeKind, String, NoticeAction?) -> Void
    public var problems: ProblemCenter
    public var activity: ActivityCenter
    public var delivery: any TextDelivering
    public var list: RecordingList
    public var settings: TranscriptionSettings
    public var sleep: @Sendable (Duration) async -> Void
    public var now: @MainActor () -> ContinuousClock.Instant

    public init(
        transcriber: any Transcribing = GroqTranscriber(),
        split: @escaping @Sendable (URL) async throws -> AudioPieces = { try await AudioSplitter().split($0) },
        readKey: @escaping @MainActor () -> String?,
        keyRejected: @escaping @MainActor () -> Void,
        showKeySettings: @escaping @MainActor @Sendable () -> Void,
        notify: @escaping @MainActor (NoticeKind, String, NoticeAction?) -> Void,
        problems: ProblemCenter,
        activity: ActivityCenter,
        delivery: any TextDelivering,
        list: RecordingList,
        settings: TranscriptionSettings,
        sleep: @escaping @Sendable (Duration) async -> Void = { try? await Task.sleep(for: $0) },
        now: @escaping @MainActor () -> ContinuousClock.Instant = { ContinuousClock.now }
    ) {
        self.transcriber = transcriber
        self.split = split
        self.readKey = readKey
        self.keyRejected = keyRejected
        self.showKeySettings = showKeySettings
        self.notify = notify
        self.problems = problems
        self.activity = activity
        self.delivery = delivery
        self.list = list
        self.settings = settings
        self.sleep = sleep
        self.now = now
    }
}

/// Takes finished recordings and turns them into text, handing texts on
/// strictly in spoken order (AC-8); a job that failed for good does not hold
/// later ones up (AC-9).
///
/// Guarantee (design.md, EC-2, AC-8, AC-9): every state change happens on the
/// main actor, one after the other. "Erneut versuchen" only acts on `failed`
/// jobs and moves them to `converting` in the same step, so a second click
/// finds nothing to do. Handing on sets `handedOn` and marks the list entry
/// converted before the text leaves; nothing ever leaves `handedOn`.
@MainActor
public final class TranscriptionQueue: RecordingConsumer {
    /// Id of the problem in the menu bar panel while a dictation waits for a retry.
    public static let problemID = "transcriptionFailed"

    private let services: TranscriptionServices
    private var jobs: [TranscriptionJob] = []
    private var nextOrder = 0
    private var activeRequests = 0
    private var slotWaiters: [(key: (Int, Int), continuation: CheckedContinuation<Void, Never>)] = []

    public init(services: TranscriptionServices) {
        self.services = services
    }

    // MARK: - Intake

    /// A new recording from PROJ-5 (AC-1).
    public func receive(_ recording: FinishedRecording) {
        guard services.list.add(recording) else {
            Log.write(
                "Recording #\(recording.sequence) not taken: invalid entry", category: .transcription, level: .error)
            return
        }
        enqueue(
            fileName: recording.fileURL.lastPathComponent, fileURL: recording.fileURL, duration: recording.duration,
            recovered: false)
    }

    /// Open recordings found at start, oldest first (AC-20). Their texts go
    /// to the clipboard, several together as one text.
    public func receiveRecovered(_ entries: [RecordingListEntry]) {
        for entry in entries where entry.state == .open {
            enqueue(
                fileName: entry.fileName, fileURL: services.list.fileURL(for: entry.fileName),
                duration: .milliseconds(Int64((entry.duration * 1000).rounded())), recovered: true)
        }
    }

    /// "Erneut versuchen": converts every failed job again, only the missing pieces (EC-2, EC-3).
    public func retryFailed() {
        let failed = jobs.filter(\.isFailed)
        guard !failed.isEmpty else { return }
        Log.write("Retry requested for \(failed.count) dictations", category: .transcription)
        for job in failed { start(job) }
    }

    /// Number of jobs not yet handed on, for tests and the log.
    var pendingCount: Int { jobs.count }

    private func enqueue(fileName: String, fileURL: URL, duration: Duration, recovered: Bool) {
        nextOrder += 1
        let job = TranscriptionJob(
            order: nextOrder, fileName: fileName, fileURL: fileURL, duration: duration,
            model: services.settings.model, language: services.settings.language, recovered: recovered)
        jobs.append(job)
        start(job)
    }

    // MARK: - Converting

    private func start(_ job: TranscriptionJob) {
        job.state = .converting
        job.startedAt = services.now()
        refreshStatus()
        Task { await self.convert(job) }
    }

    private func convert(_ job: TranscriptionJob) async {
        if job.pieces == nil {
            do {
                job.pieces = try await services.split(job.fileURL)
            } catch AudioSplitError.unreadable {
                Log.write("Dictation #\(job.order): recording unreadable", category: .transcription, level: .error)
                services.notify(.error, TranscriptionTexts.damaged, nil)
                services.list.remove(job.fileName, deleteFile: true)
                finishWithoutText(job)
                return
            } catch {
                Log.write(
                    "Dictation #\(job.order): splitting failed: \(error: error)", category: .transcription,
                    level: .error)
                fail(job, .failed)
                return
            }
        }
        guard let pieces = job.pieces else { return }
        let missing = pieces.pieces.filter { job.finished[$0.index] == nil }
        let runs = missing.map { piece in
            Task { @MainActor in (piece.index, await self.convert(piece, of: job)) }
        }
        var failure: JobFailure?
        for run in runs {
            let (index, outcome) = await run.value
            switch outcome {
            case .success(let segments): job.finished[index] = segments
            case .failure(let pieceFailure):
                if failure == nil || pieceFailure.priority < failure!.priority { failure = pieceFailure }
            }
        }
        if let failure {
            fail(job, failure)
            return
        }
        let ordered = pieces.pieces.map { job.finished[$0.index] ?? [] }
        let filtered = TranscriptFilter.filter(pieces: ordered)
        let segments = ordered.flatMap { $0 }
        let withValues = segments.filter { $0.noSpeechProbability != nil && $0.averageLogProbability != nil }.count
        pieces.remove()
        job.pieces = nil
        job.finished = [:]
        let elapsed = job.startedAt.map { services.now() - $0 } ?? .zero
        Log.write(
            "Dictation #\(job.order) converted: model \(job.model), language \(job.language), \(job.duration), \(pieces.pieces.count) pieces, \(elapsed), segments with values \(withValues) of \(segments.count), dropped segments \(filtered.droppedSegments), subtitle sentences \(filtered.removedSubtitleSentences)",
            category: .transcription)
        if filtered.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            services.notify(.info, TranscriptionTexts.nothingRecognized, nil)
            services.list.remove(job.fileName, deleteFile: true)
            finishWithoutText(job)
            return
        }
        job.state = .ready(filtered.text)
        handOn()
    }

    private enum PieceOutcome {
        case success([TranscriptSegment])
        case failure(JobFailure)
    }

    /// One piece with its silent retries and limit waits (AC-10, AC-14).
    private func convert(_ piece: AudioPiece, of job: TranscriptionJob) async -> PieceOutcome {
        var silentDelays = TranscriptionInfo.silentRetryDelays
        var waitedForLimit: Duration = .zero
        while true {
            await acquireSlot(order: job.order, piece: piece.index)
            // Read right before sending: a key removed while waiting is never used (EC-5, BUG-2).
            guard let key = services.readKey(), !key.isEmpty else {
                releaseSlot()
                return .failure(.keyMissing)
            }
            let result = await services.transcriber.transcribe(
                piece: piece.fileURL, duration: piece.duration, model: job.model, language: job.language, key: key)
            releaseSlot()
            switch result {
            case .success(let segments):
                return .success(segments)
            case .failure(.keyRejected):
                return .failure(.keyRejected)
            case .failure(.ownError):
                return .failure(.failed)
            case .failure(.rateLimited(let wait?)):
                if waitedForLimit + wait <= TranscriptionInfo.longestSelfWait {
                    waitedForLimit += wait
                    Log.write("Dictation #\(job.order): waiting \(wait) for Groq's limit", category: .transcription)
                    await services.sleep(wait)
                    continue
                }
                return .failure(.rateLimited(wait: wait))
            case .failure(let other):
                guard !silentDelays.isEmpty else {
                    return .failure(other == .noInternet ? .noInternet : .failed)
                }
                let delay = silentDelays.removeFirst()
                Log.write("Dictation #\(job.order): silent retry after \(other)", category: .transcription)
                await services.sleep(delay)
            }
        }
    }

    private func fail(_ job: TranscriptionJob, _ failure: JobFailure) {
        job.state = .failed(failure)
        Log.write("Dictation #\(job.order) not converted: \(failure)", category: .transcription, level: .error)
        let retry = NoticeAction(title: TranscriptionTexts.retry) { [weak self] in self?.retryFailed() }
        let keySettings = services.showKeySettings
        switch failure {
        case .keyMissing:
            services.notify(
                .error, TranscriptionTexts.keyMissing,
                NoticeAction(title: TranscriptionTexts.enterKey, perform: keySettings))
        case .keyRejected:
            services.keyRejected()
            services.notify(
                .error, TranscriptionTexts.keyRejected,
                NoticeAction(title: TranscriptionTexts.checkKey, perform: keySettings))
        case .rateLimited(let wait):
            services.notify(.error, TranscriptionTexts.limitReached(wait: wait), retry)
        case .noInternet:
            services.notify(.error, TranscriptionTexts.noInternet, retry)
        case .failed:
            services.notify(.error, TranscriptionTexts.failed, retry)
        }
        handOn()
    }

    private func finishWithoutText(_ job: TranscriptionJob) {
        job.pieces?.remove()
        job.pieces = nil
        job.state = .handedOn
        handOn()
    }

    // MARK: - Handing on

    /// Hands ready texts on from the front (AC-8); failed jobs are skipped (AC-9).
    /// Recovered texts wait until no recovered job is still converting (AC-20).
    /// Everything that becomes ready in one step leaves together, in spoken
    /// order, in one delivery (BUG-1, BUG-4): a later text never overtakes an
    /// earlier one, and a one-text target keeps all of them.
    private func handOn() {
        var ready: [DeliveredText] = []
        for job in jobs {
            switch job.state {
            case .handedOn, .failed:
                continue
            case .waiting, .converting:
                break
            case .ready(let text):
                if job.recovered, jobs.contains(where: { $0.recovered && $0.isBusy }) { break }
                markHandedOn(job)
                ready.append(DeliveredText(text, kind: job.recovered ? .recovered : .live))
                continue
            }
            break
        }
        if !ready.isEmpty { services.delivery.deliver(ready) }
        jobs.removeAll { $0.state == .handedOn }
        refreshStatus()
    }

    /// EC-6: the entry is marked converted in the same step the text leaves.
    private func markHandedOn(_ job: TranscriptionJob) {
        job.state = .handedOn
        services.list.markConverted(job.fileName)
        Log.write("Dictation #\(job.order) handed on", category: .transcription)
    }

    // MARK: - Status

    private func refreshStatus() {
        services.activity.isTranscribing = jobs.contains(where: \.isBusy)
        let failed = jobs.filter(\.isFailed).count
        if failed == 0 {
            services.problems.withdraw(id: Self.problemID)
        } else {
            services.problems.report(
                Problem(
                    id: Self.problemID, section: nil, message: TranscriptionTexts.notConverted(count: failed),
                    actionTitle: TranscriptionTexts.retry, keepsOwnActionInPanel: true,
                    action: { [weak self] in self?.retryFailed() }))
        }
    }

    // MARK: - Request slots (at most three at once, older jobs first)

    private func acquireSlot(order: Int, piece: Int) async {
        if activeRequests < TranscriptionInfo.maximumParallelRequests {
            activeRequests += 1
            return
        }
        await withCheckedContinuation { continuation in
            slotWaiters.append((key: (order, piece), continuation: continuation))
        }
    }

    private func releaseSlot() {
        guard let next = slotWaiters.indices.min(by: { slotWaiters[$0].key < slotWaiters[$1].key }) else {
            activeRequests -= 1
            return
        }
        slotWaiters.remove(at: next).continuation.resume()
    }
}
