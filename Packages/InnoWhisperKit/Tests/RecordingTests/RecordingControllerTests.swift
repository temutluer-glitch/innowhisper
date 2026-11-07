import AppShell
import Foundation
import Notices
import Testing

@testable import Recording

@MainActor
final class FakeHotkeys: RecordingHotkeys {
    var onAction: (@MainActor (KeyInterpreter.Action) -> Void)?
    var resets = 0
    func reset() { resets += 1 }
    func press(_ action: KeyInterpreter.Action) { onAction?(action) }
}

@MainActor
final class FakeCapture: MicrophoneCapturing {
    var onLevel: (@MainActor (CaptureLevel) -> Void)?
    var onInterruption: (@MainActor (CaptureInterruption) -> Void)?
    var startResult = CaptureStart(kind: .system, usedName: "MacBook-Mikrofon", wantedID: nil, wantedName: nil)
    var startError: CaptureError?
    var stopDuration: Duration = .seconds(3)
    var stopVoiced = 0.6
    var stopError: CaptureError?
    var starts: [String?] = []
    var cancels = 0
    var stops = 0
    private(set) var fileURL: URL?

    func start(microphoneID: String?, fileURL: URL) throws -> CaptureStart {
        if let startError { throw startError }
        starts.append(microphoneID)
        self.fileURL = fileURL
        FileManager.default.createFile(atPath: fileURL.path, contents: Data([1, 2, 3]))
        return startResult
    }

    func stop() async throws -> CaptureResult {
        stops += 1
        await Task.yield()
        if let stopError { throw stopError }
        return CaptureResult(fileURL: fileURL!, duration: stopDuration, voicedFraction: stopVoiced, hasSignal: true)
    }

    func cancel() {
        cancels += 1
        if let fileURL { try? FileManager.default.removeItem(at: fileURL) }
    }

    func sound(_ level: Double = 0.5) {
        onLevel?(CaptureLevel(level: level, hasSignal: true, voicedFraction: 0.5))
    }
}

@MainActor
final class Consumer: RecordingConsumer {
    var received: [FinishedRecording] = []
    func receive(_ recording: FinishedRecording) { received.append(recording) }
}

/// Sleep stand-in: waits until the test lets the time pass.
@MainActor
final class Timers {
    private var waiting: [(Duration, CheckedContinuation<Void, Never>)] = []

    func sleep(_ duration: Duration) async {
        await withCheckedContinuation { waiting.append((duration, $0)) }
    }

    /// Lets every pending wait of this length finish.
    func elapse(_ duration: Duration) async {
        let due = waiting.filter { $0.0 == duration }
        waiting.removeAll { $0.0 == duration }
        for (_, continuation) in due { continuation.resume() }
        await settle()
    }
}

@MainActor
func settle() async {
    for _ in 0..<30 { await Task.yield() }
}

@MainActor
@Suite struct RecordingControllerTests {
    let hotkeys = FakeHotkeys()
    let capture = FakeCapture()
    let consumer = Consumer()
    let activity = ActivityCenter()
    let timers = Timers()
    let storage = RecordingStorage(
        baseDirectory: FileManager.default.temporaryDirectory.appendingPathComponent("RecTests-\(UUID().uuidString)"))
    let clock = TestClock()

    final class TestClock {
        var now = ContinuousClock.now
    }

    final class Log {
        var notices: [(NoticeKind, String, NoticeAction?)] = []
        var starts = 0
        var ends = 0
        var dictationStarted = 0
        var requested = 0
        var texts: [String] { notices.map(\.1) }
    }

    let log = Log()

    final class Disk {
        var free: Int64? = 10 * 1024 * 1024 * 1024
    }

    let disk = Disk()

    func makeController(
        allowed: Bool = true, chosen: (id: String, name: String?)? = nil
    ) -> RecordingController {
        let queue = RecordingQueue(storage: storage, consumer: consumer)
        let services = RecordingServices(
            capture: capture, storage: storage, queue: queue, activity: activity,
            freeBytes: { [disk] in disk.free },
            chosenMicrophone: { chosen },
            microphoneAllowed: { allowed },
            requestMicrophone: { [log] in log.requested += 1 },
            notify: { [log] kind, text, action in log.notices.append((kind, text, action)) },
            dictationStarted: { [log] in log.dictationStarted += 1 },
            playStart: { [log] in log.starts += 1 },
            playEnd: { [log] in log.ends += 1 },
            now: { [clock] in clock.now },
            sleep: { [timers] duration in await timers.sleep(duration) })
        return RecordingController(hotkeys: hotkeys, services: services)
    }

    // AC-4, AC-5, AC-7: start tone only once sound flows; end tone; handed on in order
    @Test func recordingStartsWithSoundAndIsHandedOnInOrder() async {
        let controller = makeController()
        hotkeys.press(.open)
        #expect(controller.state == .starting)
        #expect(log.starts == 0)
        #expect(activity.activity == .idle)
        capture.sound()
        #expect(controller.state == .recording)
        #expect(log.starts == 1)
        #expect(log.dictationStarted == 1)
        #expect(activity.activity == .recording)
        hotkeys.press(.finish)
        await settle()
        #expect(log.ends == 1)
        #expect(consumer.received.map(\.sequence) == [1])
        #expect(controller.state == .idle)
        #expect(activity.activity == .idle)
        hotkeys.press(.open)
        capture.sound()
        hotkeys.press(.finish)
        await settle()
        #expect(consumer.received.map(\.sequence) == [1, 2])
    }

    // AC-14: no sound for 1 s → cancelled, no start tone, notice
    @Test func noSoundCancelsAfterOneSecond() async {
        let controller = makeController()
        hotkeys.press(.open)
        await settle()
        await timers.elapse(RecordingInfo.noSoundTimeout)
        #expect(controller.state == .idle)
        #expect(log.starts == 0)
        #expect(capture.cancels == 1)
        #expect(log.texts == [RecordingTexts.noSound])
        #expect(consumer.received.isEmpty)
    }

    // AC-15: missing permission → no recording, notice with "Jetzt erlauben"
    @Test func missingPermissionShowsNoticeWithButton() {
        let controller = makeController(allowed: false)
        hotkeys.press(.open)
        #expect(controller.state == .idle)
        #expect(capture.starts.isEmpty)
        #expect(hotkeys.resets == 1)
        #expect(log.notices.first?.1 == RecordingTexts.microphoneNotAllowed)
        #expect(log.notices.first?.2?.title == "Jetzt erlauben")
        log.notices.first?.2?.perform()
        #expect(log.requested == 1)
    }

    // AC-13: chosen microphone missing → system microphone and notice with both names
    @Test func missingChosenMicrophoneFallsBackWithNotice() {
        capture.startResult = CaptureStart(
            kind: .system, usedName: "MacBook-Mikrofon", wantedID: "usb-1", wantedName: nil)
        let controller = makeController(chosen: (id: "usb-1", name: "Shure MV6"))
        hotkeys.press(.open)
        #expect(controller.state == .starting)
        #expect(capture.starts == ["usb-1"])
        #expect(log.texts == ["Shure MV6 nicht gefunden, nehme MacBook-Mikrofon."])
    }

    // AC-8, AC-9: Esc at once up to 30 s, later only on the second press
    @Test func escapeCancelsAtOnceOrAfterSecondPress() async {
        let controller = makeController()
        hotkeys.press(.open)
        capture.sound()
        clock.now += .seconds(10)
        hotkeys.press(.escape)
        #expect(controller.state == .idle)
        #expect(log.texts.last == RecordingTexts.cancelled)
        #expect(consumer.received.isEmpty)

        hotkeys.press(.open)
        capture.sound()
        clock.now += .seconds(40)
        hotkeys.press(.escape)
        #expect(controller.state == .recording)
        #expect(log.texts.last == RecordingTexts.pressEscapeAgain)
        clock.now += .seconds(1)
        hotkeys.press(.escape)
        #expect(controller.state == .idle)
        #expect(log.texts.last == RecordingTexts.cancelled)
    }

    // AC-10, AC-11: short taps vanish silently, silent recordings with a notice
    @Test func shortAndSilentRecordingsAreDiscarded() async {
        let controller = makeController()
        capture.stopDuration = .milliseconds(400)
        hotkeys.press(.open)
        capture.sound()
        hotkeys.press(.finish)
        await settle()
        #expect(consumer.received.isEmpty)
        #expect(log.texts.isEmpty)
        capture.stopDuration = .seconds(4)
        capture.stopVoiced = 0.01
        hotkeys.press(.open)
        capture.sound()
        hotkeys.press(.finish)
        await settle()
        #expect(consumer.received.isEmpty)
        #expect(log.texts == [RecordingTexts.nothingHeard])
        #expect(controller.state == .idle)
    }

    // EC-1: another key during the shortcut drops the recording without a word
    @Test func otherKeyDropsSilently() {
        let controller = makeController()
        hotkeys.press(.open)
        capture.sound()
        hotkeys.press(.discard)
        #expect(controller.state == .idle)
        #expect(capture.cancels == 1)
        #expect(log.texts.isEmpty)
        #expect(log.ends == 0)
        #expect(activity.activity == .idle)
    }

    // EC-2, EC-3, EC-4: interruptions hand on what was said
    @Test func interruptionsHandOnWhatWasSaid() async {
        let controller = makeController()
        capture.stopDuration = .milliseconds(300)
        hotkeys.press(.open)
        capture.sound()
        capture.onInterruption?(.deviceDisconnected)
        await settle()
        #expect(consumer.received.count == 1)
        #expect(log.texts == [RecordingTexts.microphoneDisconnected])
        hotkeys.press(.open)
        capture.sound()
        controller.interrupt(.systemSleepOrLock)
        await settle()
        #expect(consumer.received.count == 2)
        #expect(log.texts.count == 1)
    }

    // EC-4: free space checked while recording and before the start
    @Test func lowDiskSpaceEndsTheRecording() async {
        let controller = makeController()
        hotkeys.press(.open)
        capture.sound()
        await settle()
        await timers.elapse(RecordingInfo.diskCheckInterval)
        #expect(controller.state == .recording)
        disk.free = 100 * 1024 * 1024
        await timers.elapse(RecordingInfo.diskCheckInterval)
        #expect(consumer.received.count == 1)
        #expect(log.texts == [RecordingTexts.diskFull])
        #expect(controller.state == .idle)
        hotkeys.press(.open)
        #expect(capture.starts.count == 1)
        #expect(log.texts == [RecordingTexts.diskFull, RecordingTexts.diskFull])
    }

    // EC-6: onboarding open on another step → nothing records
    @Test func blockedGateRecordsNothing() {
        let controller = makeController()
        controller.gate = .blocked
        hotkeys.press(.open)
        #expect(controller.state == .idle)
        #expect(capture.starts.isEmpty)
        #expect(hotkeys.resets == 1)
    }

    // AC-20: a probe is never handed on and reports its result
    @Test func probeIsNeverHandedOn() async {
        let controller = makeController()
        controller.gate = .probe
        var results: [Bool] = []
        controller.onProbeResult = { results.append($0) }
        hotkeys.press(.open)
        capture.sound()
        hotkeys.press(.finish)
        await settle()
        #expect(consumer.received.isEmpty)
        #expect(results == [true])
        #expect(log.texts == [RecordingTexts.probeWorked])
        #expect(!FileManager.default.fileExists(atPath: capture.fileURL!.path))
    }

    // EC-8: only one recording; a late answer of an old one changes nothing
    @Test func onlyOneRecordingAtATime() async {
        let controller = makeController()
        hotkeys.press(.open)
        hotkeys.press(.open)
        #expect(capture.starts.count == 1)
        capture.sound()
        hotkeys.press(.finish)
        hotkeys.press(.open)
        #expect(capture.starts.count == 1)
        await settle()
        #expect(controller.state == .idle)
        await timers.elapse(RecordingInfo.noSoundTimeout)
        #expect(controller.state == .idle)
        #expect(log.texts.isEmpty)
    }

    // design.md → Fehlerverhalten: file cannot be written
    @Test func failedFileShowsANotice() async {
        let controller = makeController()
        capture.startError = .cannotCreateFile
        hotkeys.press(.open)
        #expect(controller.state == .idle)
        #expect(log.texts == [RecordingTexts.recordingFailed])
        capture.startError = nil
        capture.stopError = .cannotWrite
        hotkeys.press(.open)
        capture.sound()
        hotkeys.press(.finish)
        await settle()
        #expect(consumer.received.isEmpty)
        #expect(log.texts.last == RecordingTexts.recordingFailed)
        #expect(controller.state == .idle)
    }
}
