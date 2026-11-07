import AppShell
import Carbon.HIToolbox
import CoreGraphics
import Foundation
import Notices
import Testing

@testable import Recording

/// Capture whose `stop()` waits until the test lets it finish (file still closing).
@MainActor
final class GatedCapture: MicrophoneCapturing {
    var onLevel: (@MainActor (CaptureLevel) -> Void)?
    var onInterruption: (@MainActor (CaptureInterruption) -> Void)?
    var starts = 0
    private var fileURL: URL?
    private var pendingStop: CheckedContinuation<Void, Never>?

    func start(microphoneID: String?, fileURL: URL) throws -> CaptureStart {
        starts += 1
        self.fileURL = fileURL
        FileManager.default.createFile(atPath: fileURL.path, contents: Data([1]))
        return CaptureStart(kind: .system, usedName: "Mikrofon", wantedID: nil, wantedName: nil)
    }

    func stop() async throws -> CaptureResult {
        await withCheckedContinuation { pendingStop = $0 }
        return CaptureResult(fileURL: fileURL!, duration: .seconds(3), voicedFraction: 0.6, hasSignal: true)
    }

    func cancel() {}

    func sound() { onLevel?(CaptureLevel(level: 0.5, hasSignal: true, voicedFraction: 0.5)) }

    func finishStop() async {
        await settle()
        pendingStop?.resume()
        pendingStop = nil
        await settle()
    }
}

/// BUG-1 (QA 07.11.): shortcut watcher and recording controller must never
/// disagree about whether a recording runs.
@MainActor
@Suite struct HotkeyControllerSyncTests {
    let tap = FakeKeyEventTap()
    let ticker = FakeTicker()
    let clock = FakeClock()
    let capture = GatedCapture()
    let storage = RecordingStorage(
        baseDirectory: FileManager.default.temporaryDirectory.appendingPathComponent("Sync-\(UUID().uuidString)"))

    var commandDown: CGEventFlags {
        CGEventFlags(rawValue: CGEventFlags.maskCommand.rawValue | HotkeyMonitor.deviceFlag(of: .rightCommand))
    }

    func make(mode: ShortcutMode) -> (HotkeyMonitor, RecordingController) {
        let monitor = HotkeyMonitor(
            shortcut: .factory, mode: mode, tap: tap, ticker: ticker, now: { [clock] in clock.time },
            deliver: { $0() }, log: { _, _ in })
        _ = monitor.start()
        let services = RecordingServices(
            capture: capture, storage: storage, queue: RecordingQueue(storage: storage, consumer: Consumer()),
            activity: ActivityCenter(), freeBytes: { 10_000_000_000 }, chosenMicrophone: { nil },
            microphoneAllowed: { true }, requestMicrophone: {}, notify: { _, _, _ in }, dictationStarted: {},
            playStart: {}, playEnd: {})
        return (monitor, RecordingController(hotkeys: monitor, services: services))
    }

    /// Right ⌘ tapped (down and up within 0.1 s).
    func tapRightCommand() {
        _ = tap.send(.flagsChanged(keyCode: UInt16(kVK_RightCommand), flags: commandDown))
        clock.time += .milliseconds(100)
        _ = tap.send(.flagsChanged(keyCode: UInt16(kVK_RightCommand), flags: []))
        clock.time += .seconds(1)
    }

    func escapeIsSwallowed() -> Bool {
        let swallowed = tap.send(.keyDown(keyCode: UInt16(kVK_Escape), flags: [], isRepeat: false))
        _ = tap.send(.keyUp(keyCode: UInt16(kVK_Escape)))
        return swallowed
    }

    // Case A: a tap while the previous file is still closing
    @Test func tapWhileFinishingNeitherEatsTheNextTapNorEscape() async {
        let (monitor, controller) = make(mode: .toggle)
        tapRightCommand()
        capture.sound()
        #expect(controller.state == .recording)
        tapRightCommand()
        #expect(controller.state == .finishing)
        tapRightCommand()
        #expect(monitor.phase == .idle)
        await capture.finishStop()
        #expect(controller.state == .idle)
        #expect(!escapeIsSwallowed())
        tapRightCommand()
        #expect(capture.starts == 2)
        #expect(controller.state == .starting)
    }

    // Case B: the mode changes while a recording runs (AC-17)
    @Test func modeChangeWaitsForTheNextRecording() async {
        let (monitor, controller) = make(mode: .toggle)
        tapRightCommand()
        capture.sound()
        monitor.update(shortcut: .factory, mode: .hold)
        #expect(monitor.mode == .toggle)
        #expect(monitor.phase == .active)
        tapRightCommand()
        #expect(controller.state == .finishing)
        await capture.finishStop()
        #expect(monitor.mode == .hold)
    }

    // Case B: clicking the shortcut field while recording ends the recording first
    @Test func pausingDuringARecordingEndsIt() {
        let (monitor, controller) = make(mode: .toggle)
        tapRightCommand()
        capture.sound()
        monitor.setPaused(true)
        #expect(controller.state == .finishing)
        #expect(monitor.phase == .idle)
    }
}
