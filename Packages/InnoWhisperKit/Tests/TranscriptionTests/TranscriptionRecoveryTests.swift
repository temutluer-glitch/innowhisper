import AppShell
import Foundation
import Recording
import Testing

@testable import Transcription

@MainActor
@Suite struct TranscriptionRecoveryTests {
    let queueTests = TranscriptionQueueTests()

    // AC-20, EC-6: open entries are converted in spoken order and go together to
    // the clipboard; converted ones are not repeated; piece folders are cleared
    @Test func openRecordingsAreRecoveredOnce() async throws {
        defer { try? FileManager.default.removeItem(at: queueTests.base) }
        let transcriber = ScriptedTranscriber([
            "old-0.flac": [said("Schon fertig.")], "a-0.flac": [said("Eins.")], "b-0.flac": [said("Zwei.")],
        ])
        let (_, before, _) = queueTests.makeQueue(transcriber)
        before.add(try queueTests.recording("b", sequence: 3))
        before.add(try queueTests.recording("old", sequence: 1))
        before.markConverted("old.caf")
        before.add(try queueTests.recording("a", sequence: 2))
        let (queue, list, _) = queueTests.makeQueue(transcriber)
        var cleared = 0
        TranscriptionRecovery.resume(list: list, queue: queue, removePieceFolders: { cleared += 1 })
        await settleQueue()
        #expect(cleared == 1)
        // Both run at the same time, so only the set of requests is fixed; the
        // spoken order shows in the text.
        #expect(Set(transcriber.calls.map(\.piece)) == ["a-0.flac", "b-0.flac"])
        #expect(queueTests.delivery.delivered.map(\.text) == ["Eins.\n\nZwei."])
        #expect(queueTests.delivery.delivered.map(\.kind) == [.recovered])
        #expect(list.openEntries.isEmpty)
    }

    // Only converted entries → nothing converted again, nothing delivered (EC-6)
    @Test func nothingOpenDoesNothing() async throws {
        defer { try? FileManager.default.removeItem(at: queueTests.base) }
        let transcriber = ScriptedTranscriber(["done-0.flac": [said("Schon fertig.")]])
        let (_, before, _) = queueTests.makeQueue(transcriber)
        before.add(try queueTests.recording("done"))
        before.markConverted("done.caf")
        let (queue, list, _) = queueTests.makeQueue(transcriber)
        TranscriptionRecovery.resume(list: list, queue: queue, removePieceFolders: {})
        await settleQueue()
        #expect(transcriber.calls.isEmpty)
        #expect(queueTests.delivery.delivered.isEmpty)
    }
}
