import AppShell
import Foundation
import Notices
import Recording
import Synchronization
import Testing

@testable import Transcription

/// Lets the main actor run everything that is ready.
@MainActor
func settleQueue() async {
    for _ in 0..<200 { await Task.yield() }
}

/// Holds requests until the test opens their gate.
actor RequestGate {
    private var open: Set<String> = []
    private var waiting: [String: [CheckedContinuation<Void, Never>]] = [:]

    func wait(_ key: String) async {
        if open.contains(key) { return }
        await withCheckedContinuation { waiting[key, default: []].append($0) }
    }

    func release(_ key: String) {
        open.insert(key)
        for continuation in waiting.removeValue(forKey: key) ?? [] { continuation.resume() }
    }
}

/// Answers per piece name; each piece takes its answers in order, the last repeats.
final class ScriptedTranscriber: Transcribing {
    struct Call: Equatable, Sendable {
        let piece: String
        let model: TranscriptionModel
        let language: TranscriptionLanguage
    }

    private let scripts: Mutex<[String: [TranscriptionPieceResult]]>
    private let recorded = Mutex<[Call]>([])
    private let running = Mutex<(now: Int, most: Int)>((0, 0))
    let gate: RequestGate?

    init(_ scripts: [String: [TranscriptionPieceResult]], gate: RequestGate? = nil) {
        self.scripts = Mutex(scripts)
        self.gate = gate
    }

    var calls: [Call] { recorded.withLock { $0 } }
    var mostAtOnce: Int { running.withLock { $0.most } }

    func transcribe(
        piece: URL, duration: Duration, model: TranscriptionModel, language: TranscriptionLanguage, key: String
    ) async -> TranscriptionPieceResult {
        let name = piece.lastPathComponent
        recorded.withLock { $0.append(Call(piece: name, model: model, language: language)) }
        running.withLock { state in
            state.now += 1
            state.most = max(state.most, state.now)
        }
        if let gate { await gate.wait(name) }
        running.withLock { $0.now -= 1 }
        return scripts.withLock { all in
            guard var list = all[name], let first = list.first else { return .failure(.temporary) }
            if list.count > 1 { list.removeFirst() }
            all[name] = list
            return first
        }
    }
}

@MainActor
final class FakeDelivery: TextDelivering {
    var delivered: [(text: String, kind: DeliveryKind)] = []
    func deliver(_ text: String, kind: DeliveryKind) { delivered.append((text, kind)) }
}

func said(_ text: String) -> TranscriptionPieceResult {
    .success([TranscriptSegment(text: text, noSpeechProbability: 0.01, averageLogProbability: -0.2)])
}

@MainActor
@Suite struct TranscriptionQueueTests {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent("Queue-\(UUID().uuidString)")
    let defaults = UserDefaults(suiteName: "Queue-\(UUID().uuidString)")!
    let problems = ProblemCenter()
    let activity = ActivityCenter()
    let delivery = FakeDelivery()

    @MainActor
    final class Box {
        var notices: [(kind: NoticeKind, text: String, action: NoticeAction?)] = []
        var key: String? = "gsk_test"
        var keyRejectedCalls = 0
        var keySettingsShown = 0
        var slept: [Duration] = []
        /// Pieces per recording file name; default one piece.
        var pieceCount: [String: Int] = [:]
        var unreadable: Set<String> = []
    }

    let box = Box()
    var storage: RecordingStorage { RecordingStorage(baseDirectory: base) }

    func makeQueue(_ transcriber: any Transcribing) -> (TranscriptionQueue, RecordingList, TranscriptionSettings) {
        let list = RecordingList(defaults: defaults, storage: storage)
        let settings = TranscriptionSettings(defaults: defaults)
        let box = box
        let piecesBase = base.appendingPathComponent("Pieces")
        let services = TranscriptionServices(
            transcriber: transcriber,
            split: { [box] url in
                let name = url.deletingPathExtension().lastPathComponent
                let (count, broken) = await MainActor.run { (box.pieceCount[name] ?? 1, box.unreadable.contains(name)) }
                if broken { throw AudioSplitError.unreadable }
                let folder = piecesBase.appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                let pieces = (0..<count).map { index in
                    AudioPiece(
                        index: index, fileURL: folder.appendingPathComponent("\(name)-\(index).flac"),
                        start: .seconds(index * 300), duration: .seconds(300), startFrame: Int64(index) * 4_800_000,
                        frameCount: 4_800_000)
                }
                return AudioPieces(folder: folder, pieces: pieces)
            },
            readKey: { [box] in box.key },
            keyRejected: { [box] in box.keyRejectedCalls += 1 },
            showKeySettings: { [box] in box.keySettingsShown += 1 },
            notify: { [box] kind, text, action in box.notices.append((kind, text, action)) },
            problems: problems, activity: activity, delivery: delivery, list: list, settings: settings,
            sleep: { [box] duration in await MainActor.run { box.slept.append(duration) } })
        return (TranscriptionQueue(services: services), list, settings)
    }

    /// A real (empty) recording file in the folder, as PROJ-5 hands it on.
    func recording(_ name: String, sequence: Int = 1, seconds: Int = 5) throws -> FinishedRecording {
        try storage.prepareFolder()
        let url = storage.folder.appendingPathComponent("\(name).caf")
        FileManager.default.createFile(atPath: url.path(percentEncoded: false), contents: Data([1]))
        return FinishedRecording(
            sequence: sequence, fileURL: url, duration: .seconds(seconds), microphone: .system,
            startedAt: Date(timeIntervalSince1970: TimeInterval(1_000 + sequence)))
    }

    func exists(_ name: String) -> Bool {
        FileManager.default.fileExists(
            atPath: storage.folder.appendingPathComponent("\(name).caf").path(percentEncoded: false))
    }

    // AC-1, AC-3: converted, handed on live, entry marked converted, "wandelt um" while busy
    @Test func recordingIsConvertedAndHandedOn() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let gate = RequestGate()
        let transcriber = ScriptedTranscriber(["a-0.flac": [said("Hallo Welt.")]], gate: gate)
        let (queue, list, _) = makeQueue(transcriber)
        queue.receive(try recording("a"))
        await settleQueue()
        #expect(activity.activity == .transcribing)
        #expect(delivery.delivered.isEmpty)
        await gate.release("a-0.flac")
        await settleQueue()
        #expect(delivery.delivered.map(\.text) == ["Hallo Welt."])
        #expect(delivery.delivered.map(\.kind) == [.live])
        #expect(list.entry(named: "a.caf")?.state == .converted)
        #expect(activity.activity == .idle)
        #expect(box.notices.isEmpty)
        #expect(exists("a"))
    }

    // AC-8: a later dictation that is ready first waits for the earlier one
    @Test func textsLeaveInSpokenOrder() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let gate = RequestGate()
        let transcriber = ScriptedTranscriber(["a-0.flac": [said("Eins.")], "b-0.flac": [said("Zwei.")]], gate: gate)
        let (queue, _, _) = makeQueue(transcriber)
        queue.receive(try recording("a", sequence: 1))
        queue.receive(try recording("b", sequence: 2))
        await settleQueue()
        await gate.release("b-0.flac")
        await settleQueue()
        #expect(delivery.delivered.isEmpty)
        await gate.release("a-0.flac")
        await settleQueue()
        #expect(delivery.delivered.map(\.text) == ["Eins.", "Zwei."])
    }

    // AC-9, AC-11: a failed dictation does not hold later ones; retry hands it on later
    @Test func failedDictationDoesNotBlockAndComesLater() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let transcriber = ScriptedTranscriber([
            "a-0.flac": [.failure(.temporary), .failure(.temporary), .failure(.temporary), said("Eins.")],
            "b-0.flac": [said("Zwei.")],
        ])
        let (queue, list, _) = makeQueue(transcriber)
        queue.receive(try recording("a", sequence: 1))
        queue.receive(try recording("b", sequence: 2))
        await settleQueue()
        #expect(delivery.delivered.map(\.text) == ["Zwei."])
        #expect(box.notices.map(\.text) == [TranscriptionTexts.failed])
        #expect(box.notices.first?.action?.title == "Erneut versuchen")
        #expect(problems.isReported(id: TranscriptionQueue.problemID))
        #expect(problems.problems.first?.message == "1 Diktat nicht umgewandelt.")
        #expect(list.entry(named: "a.caf")?.state == .open)
        #expect(exists("a"))
        #expect(activity.activity == .idle)
        box.notices.first?.action?.perform()
        await settleQueue()
        #expect(delivery.delivered.map(\.text) == ["Zwei.", "Eins."])
        #expect(!problems.isReported(id: TranscriptionQueue.problemID))
        #expect(list.entry(named: "a.caf")?.state == .converted)
    }

    // AC-10: two silent retries after 1 s and 3 s, no notice when the third try works
    @Test func twoSilentRetries() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let transcriber = ScriptedTranscriber([
            "a-0.flac": [.failure(.temporary), .failure(.noInternet), said("Klappt.")]
        ])
        let (queue, _, _) = makeQueue(transcriber)
        queue.receive(try recording("a"))
        await settleQueue()
        #expect(transcriber.calls.count == 3)
        #expect(box.slept == [.seconds(1), .seconds(3)])
        #expect(box.notices.isEmpty)
        #expect(delivery.delivered.map(\.text) == ["Klappt."])
    }

    // AC-11: without internet the notice says so
    @Test func noInternetNotice() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let transcriber = ScriptedTranscriber(["a-0.flac": [.failure(.noInternet)]])
        let (queue, _, _) = makeQueue(transcriber)
        queue.receive(try recording("a"))
        await settleQueue()
        #expect(transcriber.calls.count == 3)
        #expect(box.notices.map(\.text) == ["Keine Internetverbindung. Die Aufnahme ist gespeichert."])
        #expect(box.notices.map(\.kind) == [.error])
    }

    // AC-12, EC-5: no key → nothing uploaded, button opens key settings; retry after entering works
    @Test func missingKey() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let transcriber = ScriptedTranscriber(["a-0.flac": [said("Später.")]])
        let (queue, _, _) = makeQueue(transcriber)
        box.key = nil
        queue.receive(try recording("a"))
        await settleQueue()
        #expect(transcriber.calls.isEmpty)
        #expect(box.notices.map(\.text) == ["Kein Groq-Zugangsschlüssel eingetragen."])
        #expect(box.notices.first?.action?.title == "Schlüssel eintragen")
        box.notices.first?.action?.perform()
        #expect(box.keySettingsShown == 1)
        #expect(exists("a"))
        box.key = "gsk_new"
        queue.retryFailed()
        await settleQueue()
        #expect(delivery.delivered.map(\.text) == ["Später."])
    }

    // AC-13: refused key → PROJ-4 re-checks it, notice with "Schlüssel prüfen", recording kept, no silent retry
    @Test func rejectedKey() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let transcriber = ScriptedTranscriber(["a-0.flac": [.failure(.keyRejected)]])
        let (queue, list, _) = makeQueue(transcriber)
        queue.receive(try recording("a"))
        await settleQueue()
        #expect(transcriber.calls.count == 1)
        #expect(box.keyRejectedCalls == 1)
        #expect(box.notices.map(\.text) == ["Groq lehnt den Zugangsschlüssel ab."])
        #expect(box.notices.first?.action?.title == "Schlüssel prüfen")
        #expect(list.entry(named: "a.caf")?.state == .open)
        #expect(exists("a"))
    }

    // AC-14: short limit waits are sat out; a long one is told in minutes
    @Test func groqLimit() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let transcriber = ScriptedTranscriber([
            "a-0.flac": [.failure(.rateLimited(wait: .seconds(30))), said("Nach der Pause.")],
            "b-0.flac": [.failure(.rateLimited(wait: .seconds(300)))],
        ])
        let (queue, _, _) = makeQueue(transcriber)
        queue.receive(try recording("a", sequence: 1))
        await settleQueue()
        #expect(box.slept == [.seconds(30)])
        #expect(box.notices.isEmpty)
        #expect(delivery.delivered.map(\.text) == ["Nach der Pause."])
        queue.receive(try recording("b", sequence: 2))
        await settleQueue()
        #expect(box.notices.map(\.text) == ["Groq-Grenze erreicht. Versuche es in 5 Minuten erneut."])
        #expect(box.notices.first?.action?.title == "Erneut versuchen")
    }

    // AC-15: only an invented phrase → nothing handed on, notice, recording deleted; the next one is fine
    @Test func nothingRecognized() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let transcriber = ScriptedTranscriber(["a-0.flac": [said("Vielen Dank.")], "b-0.flac": [said("Echt.")]])
        let (queue, list, _) = makeQueue(transcriber)
        queue.receive(try recording("a", sequence: 1))
        queue.receive(try recording("b", sequence: 2))
        await settleQueue()
        #expect(box.notices.map(\.text) == ["Nichts erkannt, kein Text eingefügt."])
        #expect(delivery.delivered.map(\.text) == ["Echt."])
        #expect(!exists("a"))
        #expect(list.entry(named: "a.caf") == nil)
    }

    // EC-4: a damaged recording → notice, file deleted, later dictations go on
    @Test func damagedRecording() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let transcriber = ScriptedTranscriber(["b-0.flac": [said("Weiter.")]])
        let (queue, list, _) = makeQueue(transcriber)
        box.unreadable = ["a"]
        queue.receive(try recording("a", sequence: 1))
        queue.receive(try recording("b", sequence: 2))
        await settleQueue()
        #expect(box.notices.map(\.text) == ["Aufnahme beschädigt, kann nicht umgewandelt werden."])
        #expect(!exists("a"))
        #expect(list.entry(named: "a.caf") == nil)
        #expect(delivery.delivered.map(\.text) == ["Weiter."])
    }

    // AC-7, EC-3: pieces joined in order; a retry only sends the missing piece
    @Test func retrySendsOnlyMissingPieces() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let transcriber = ScriptedTranscriber([
            "a-0.flac": [said("Erster Teil.")],
            "a-1.flac": [.failure(.temporary), .failure(.temporary), .failure(.temporary), said("Zweiter Teil.")],
        ])
        let (queue, _, _) = makeQueue(transcriber)
        box.pieceCount["a"] = 2
        queue.receive(try recording("a", seconds: 600))
        await settleQueue()
        #expect(delivery.delivered.isEmpty)
        queue.retryFailed()
        await settleQueue()
        #expect(transcriber.calls.filter { $0.piece == "a-0.flac" }.count == 1)
        #expect(transcriber.calls.filter { $0.piece == "a-1.flac" }.count == 4)
        #expect(delivery.delivered.map(\.text) == ["Erster Teil. Zweiter Teil."])
    }

    // EC-2: "Erneut versuchen" twice converts once and hands on once
    @Test func doubleRetryActsOnce() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let gate = RequestGate()
        let transcriber = ScriptedTranscriber(
            ["a-0.flac": [.failure(.keyRejected), said("Einmal.")]], gate: gate)
        let (queue, _, _) = makeQueue(transcriber)
        await gate.release("a-0.flac")
        queue.receive(try recording("a"))
        await settleQueue()
        queue.retryFailed()
        queue.retryFailed()
        await settleQueue()
        #expect(transcriber.calls.count == 2)
        #expect(delivery.delivered.map(\.text) == ["Einmal."])
    }

    // AC-4: model and language are fixed when the recording arrives
    @Test func settingsFixedAtArrival() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let gate = RequestGate()
        let transcriber = ScriptedTranscriber(["a-0.flac": [said("A.")], "b-0.flac": [said("B.")]], gate: gate)
        let (queue, _, settings) = makeQueue(transcriber)
        queue.receive(try recording("a", sequence: 1))
        settings.setModel(.accurate)
        settings.setLanguage(.automatic)
        queue.receive(try recording("b", sequence: 2))
        await settleQueue()
        let calls = transcriber.calls
        #expect(calls.first { $0.piece == "a-0.flac" }?.model == .fast)
        #expect(calls.first { $0.piece == "a-0.flac" }?.language == .german)
        #expect(calls.first { $0.piece == "b-0.flac" }?.model == .accurate)
        #expect(calls.first { $0.piece == "b-0.flac" }?.language == .automatic)
        await gate.release("a-0.flac")
        await gate.release("b-0.flac")
        await settleQueue()
    }

    // AC-6: at most three requests at once
    @Test func atMostThreeRequestsAtOnce() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let gate = RequestGate()
        let scripts = Dictionary(uniqueKeysWithValues: (0..<5).map { ("a-\($0).flac", [said("T\($0).")]) })
        let transcriber = ScriptedTranscriber(scripts, gate: gate)
        let (queue, _, _) = makeQueue(transcriber)
        box.pieceCount["a"] = 5
        queue.receive(try recording("a", seconds: 1500))
        await settleQueue()
        #expect(transcriber.calls.count == 3)
        for index in 0..<5 { await gate.release("a-\(index).flac") }
        await settleQueue()
        #expect(transcriber.mostAtOnce == 3)
        #expect(delivery.delivered.map(\.text) == ["T0. T1. T2. T3. T4."])
    }

    // AC-20: recovered dictations go together to the clipboard, separated by a blank line
    @Test func recoveredAreCombined() async throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let gate = RequestGate()
        let transcriber = ScriptedTranscriber(
            ["a-0.flac": [said("Alt eins.")], "b-0.flac": [said("Alt zwei.")]], gate: gate)
        let (first, list, _) = makeQueue(transcriber)
        _ = first
        list.add(try recording("a", sequence: 1))
        list.add(try recording("b", sequence: 2))
        let (queue, reloaded, _) = makeQueue(transcriber)
        queue.receiveRecovered(reloaded.openEntries)
        await settleQueue()
        await gate.release("a-0.flac")
        await settleQueue()
        #expect(delivery.delivered.isEmpty)
        await gate.release("b-0.flac")
        await settleQueue()
        #expect(delivery.delivered.map(\.text) == ["Alt eins.\n\nAlt zwei."])
        #expect(delivery.delivered.map(\.kind) == [.recovered])
        #expect(reloaded.openEntries.isEmpty)
    }
}
