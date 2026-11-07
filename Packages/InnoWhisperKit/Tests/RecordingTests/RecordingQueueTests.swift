import Foundation
import Testing

@testable import Recording

/// Records what it receives, in order.
@MainActor
private final class CollectingConsumer: RecordingConsumer {
    var received: [FinishedRecording] = []

    func receive(_ recording: FinishedRecording) {
        received.append(recording)
    }
}

@MainActor
@Suite struct RecordingQueueTests {
    /// A fresh temporary base directory per test.
    private let base = FileManager.default.temporaryDirectory
        .appendingPathComponent("RecordingQueueTests-\(UUID().uuidString)", isDirectory: true)

    private var storage: RecordingStorage { RecordingStorage(baseDirectory: base) }

    /// Creates a small recording file in the folder, as the capture would.
    private func makeFile() throws -> URL {
        let url = try storage.newFileURL()
        try Data([0, 1, 2, 3]).write(to: url)
        return url
    }

    private func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }

    private func finish(_ queue: RecordingQueue, _ url: URL) -> FinishedRecording {
        queue.finish(fileURL: url, duration: .seconds(2), microphone: .system, startedAt: Date())
    }

    // MARK: Sequence and order

    // AC-7: numbering starts at 1 per launch and only grows
    @Test func sequenceStartsAtOneAndIncreases() throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let queue = RecordingQueue(storage: storage, consumer: CollectingConsumer())
        #expect(queue.lastSequence == 0)
        let numbers = try (0..<4).map { _ in finish(queue, try makeFile()).sequence }
        #expect(numbers == [1, 2, 3, 4])
        #expect(queue.lastSequence == 4)
    }

    // AC-6, AC-7: the consumer gets every recording, in spoken order, with its data
    @Test func consumerReceivesInSpokenOrder() throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let consumer = CollectingConsumer()
        let queue = RecordingQueue(storage: storage, consumer: consumer)
        let files = try (0..<3).map { _ in try makeFile() }
        let start = Date(timeIntervalSince1970: 1_000)
        queue.finish(fileURL: files[0], duration: .seconds(600), microphone: .chosen, startedAt: start)
        _ = finish(queue, files[1])
        _ = finish(queue, files[2])
        #expect(consumer.received.map(\.fileURL) == files)
        #expect(consumer.received.map(\.sequence) == [1, 2, 3])
        #expect(
            consumer.received.first
                == FinishedRecording(
                    sequence: 1, fileURL: files[0], duration: .seconds(600), microphone: .chosen, startedAt: start))
    }

    // MARK: Discard

    // AC-8, AC-11: a discarded recording is deleted and consumes no number
    @Test func discardDeletesFileWithoutConsumingNumber() throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let consumer = CollectingConsumer()
        let queue = RecordingQueue(storage: storage, consumer: consumer)
        _ = finish(queue, try makeFile())
        let cancelled = try makeFile()
        queue.discard(fileURL: cancelled, reason: .cancelled)
        let silent = try makeFile()
        queue.discard(fileURL: silent, reason: .silent)
        #expect(!exists(cancelled))
        #expect(!exists(silent))
        #expect(finish(queue, try makeFile()).sequence == 2)
        #expect(consumer.received.count == 2)
    }

    // Safety: storage never deletes a file outside its own folder
    @Test func deleteRefusesFilesOutsideTheFolder() throws {
        defer { try? FileManager.default.removeItem(at: base) }
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let outside = base.appendingPathComponent("outside.caf")
        try Data([1]).write(to: outside)
        #expect(!storage.delete(outside))
        #expect(exists(outside))
    }

    // MARK: Placeholder consumer

    // AC-6: until PROJ-6 only the latest recording is kept; the previous file is deleted
    @Test func placeholderKeepsOnlyTheLatestFile() throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let placeholder = PlaceholderConsumer(storage: storage)
        let queue = RecordingQueue(storage: storage, consumer: placeholder)
        let first = try makeFile()
        let second = try makeFile()
        _ = finish(queue, first)
        #expect(exists(first))
        let kept = finish(queue, second)
        #expect(!exists(first))
        #expect(exists(second))
        #expect(placeholder.latest == kept)
    }

    // MARK: Storage

    // Crash leftovers are deleted at start and counted
    @Test func leftoversAreRemovedAndCounted() throws {
        defer { try? FileManager.default.removeItem(at: base) }
        #expect(storage.removeLeftovers() == 0)
        let files = try (0..<3).map { _ in try makeFile() }
        #expect(storage.removeLeftovers() == 3)
        #expect(files.allSatisfy { !exists($0) })
        let remaining = try FileManager.default.contentsOfDirectory(atPath: storage.folder.path(percentEncoded: false))
        #expect(remaining.isEmpty)
    }

    // New file locations are unique, end in .caf and lie inside the folder
    @Test func newFileURLsAreUniqueAndInsideFolder() throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let urls = try (0..<20).map { _ in try storage.newFileURL() }
        #expect(Set(urls).count == urls.count)
        #expect(urls.allSatisfy { $0.pathExtension == "caf" && storage.contains($0) })
        #expect(storage.folder.lastPathComponent == "Recordings")
        var isDirectory: ObjCBool = false
        #expect(
            FileManager.default.fileExists(
                atPath: storage.folder.path(percentEncoded: false), isDirectory: &isDirectory))
        #expect(isDirectory.boolValue)
    }

    // EC-4: free disk space of the folder's volume is known
    @Test func freeSpaceIsPositive() throws {
        defer { try? FileManager.default.removeItem(at: base) }
        let bytes = try #require(storage.availableBytes())
        #expect(bytes > 0)
    }
}
