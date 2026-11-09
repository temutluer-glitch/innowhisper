import Foundation
import Recording
import Testing

@testable import Transcription

@MainActor
@Suite final class RecordingListTests {
    let defaults = UserDefaults(suiteName: "RecordingList-\(UUID().uuidString)")!
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(
        "RecordingListTests-\(UUID().uuidString)", isDirectory: true)
    var storage: RecordingStorage { RecordingStorage(baseDirectory: base) }

    deinit {
        try? FileManager.default.removeItem(at: base)
    }

    /// A clock the test moves forward by hand.
    final class Clock {
        var date = Date(timeIntervalSince1970: 1_800_000_000)
        func tick() -> Date {
            date += 1
            return date
        }
    }

    /// Writes a recording file into the folder and describes it.
    func makeRecording(spokenAt: Date = .now, seconds: Int = 3, name: String? = nil) throws -> FinishedRecording {
        let url =
            if let name {
                storage.folder.appendingPathComponent(name)
            } else {
                try storage.newFileURL()
            }
        try storage.prepareFolder()
        try Data([1, 2, 3]).write(to: url)
        return FinishedRecording(
            sequence: 1, fileURL: url, duration: .seconds(seconds), microphone: .system, startedAt: spokenAt)
    }

    func fileExists(_ recording: FinishedRecording) -> Bool {
        FileManager.default.fileExists(atPath: recording.fileURL.path)
    }

    func storeRaw(_ json: String) {
        defaults.set(Data(json.utf8), forKey: TranscriptionInfo.recordingsDefaultsKey)
    }

    // AC-20, EC-6: add, convert and remove are saved at once and survive a restart
    @Test func roundTripSurvivesReload() throws {
        let clock = Clock()
        let list = RecordingList(defaults: defaults, storage: storage, now: clock.tick)
        let first = try makeRecording(spokenAt: Date(timeIntervalSince1970: 100), seconds: 4)
        let second = try makeRecording(spokenAt: Date(timeIntervalSince1970: 200))
        let third = try makeRecording(spokenAt: Date(timeIntervalSince1970: 300))
        #expect(list.add(first))
        #expect(list.add(second))
        #expect(list.add(third))
        #expect(list.markConverted(second.fileURL.lastPathComponent))
        // EC-6: the change is on disk right away, before any other change.
        let afterConvert = RecordingList(defaults: defaults, storage: storage, now: clock.tick)
        #expect(afterConvert.entry(named: second.fileURL.lastPathComponent)?.state == .converted)
        #expect(list.remove(third.fileURL.lastPathComponent, deleteFile: true))
        #expect(!fileExists(third))

        let reloaded = RecordingList(defaults: defaults, storage: storage, now: clock.tick)
        #expect(reloaded.entries.count == 2)
        let open = try #require(reloaded.entry(named: first.fileURL.lastPathComponent))
        #expect(open.state == .open)
        #expect(open.convertedAt == nil)
        #expect(open.spokenAt == Date(timeIntervalSince1970: 100))
        #expect(open.duration == 4)
        let converted = try #require(reloaded.entry(named: second.fileURL.lastPathComponent))
        #expect(converted.state == .converted)
        #expect(converted.convertedAt == Date(timeIntervalSince1970: 1_800_000_001))
        #expect(reloaded.entry(named: third.fileURL.lastPathComponent) == nil)
    }

    // remove without deleteFile keeps the file; unknown names are refused
    @Test func removeCanKeepTheFile() throws {
        let list = RecordingList(defaults: defaults, storage: storage)
        let recording = try makeRecording()
        list.add(recording)
        #expect(list.remove(recording.fileURL.lastPathComponent, deleteFile: false))
        #expect(fileExists(recording))
        #expect(list.entries.isEmpty)
        #expect(!list.remove("missing.caf", deleteFile: true))
        #expect(!list.markConverted("missing.caf"))
    }

    // AC-19: the 51st converted recording removes the oldest converted entry and its file
    @Test func fiftyFirstConvertedPrunesOldest() throws {
        let clock = Clock()
        let list = RecordingList(defaults: defaults, storage: storage, now: clock.tick)
        var recordings: [FinishedRecording] = []
        for index in 0..<51 {
            let recording = try makeRecording(spokenAt: Date(timeIntervalSince1970: Double(index)))
            recordings.append(recording)
            list.add(recording)
        }
        // Convert in an order where the oldest conversion is not the first spoken one.
        let order = [5] + Array(0..<5) + Array(6..<51)
        for index in order.prefix(50) {
            list.markConverted(recordings[index].fileURL.lastPathComponent)
        }
        #expect(list.entries.count == 51)
        #expect(fileExists(recordings[5]))

        list.markConverted(recordings[order[50]].fileURL.lastPathComponent)
        #expect(list.entries.count == 50)
        #expect(list.entry(named: recordings[5].fileURL.lastPathComponent) == nil)
        #expect(!fileExists(recordings[5]))
        #expect(fileExists(recordings[0]))
        #expect(list.entries.allSatisfy { $0.state == .converted })

        let reloaded = RecordingList(defaults: defaults, storage: storage, now: clock.tick)
        #expect(reloaded.entries.count == 50)
    }

    // AC-20: open entries never count and are never pruned, even 60 of them
    @Test func openEntriesAreNeverPruned() throws {
        let clock = Clock()
        let list = RecordingList(defaults: defaults, storage: storage, now: clock.tick)
        var open: [FinishedRecording] = []
        for _ in 0..<60 {
            let recording = try makeRecording()
            open.append(recording)
            list.add(recording)
        }
        for _ in 0..<51 {
            let recording = try makeRecording()
            list.add(recording)
            list.markConverted(recording.fileURL.lastPathComponent)
        }
        #expect(list.openEntries.count == 60)
        #expect(list.entries.count == 110)
        #expect(open.allSatisfy(fileExists))
        let reloaded = RecordingList(defaults: defaults, storage: storage, now: clock.tick)
        #expect(reloaded.openEntries.count == 60)
    }

    // Adding the same file twice keeps one entry, unchanged
    @Test func duplicateAddKeepsOneEntry() throws {
        let list = RecordingList(defaults: defaults, storage: storage)
        let recording = try makeRecording()
        #expect(list.add(recording))
        list.markConverted(recording.fileURL.lastPathComponent)
        #expect(list.add(recording))
        #expect(list.entries.count == 1)
        #expect(list.entries.first?.state == .converted)
    }

    // design.md: entries whose file is gone fall away at load, and the list is saved
    @Test func missingFileIsDroppedAtLoad() throws {
        let list = RecordingList(defaults: defaults, storage: storage)
        let kept = try makeRecording()
        let gone = try makeRecording()
        list.add(kept)
        list.add(gone)
        try FileManager.default.removeItem(at: gone.fileURL)

        let reloaded = RecordingList(defaults: defaults, storage: storage)
        #expect(reloaded.entries.map(\.fileName) == [kept.fileURL.lastPathComponent])
        let stored = try #require(defaults.data(forKey: TranscriptionInfo.recordingsDefaultsKey))
        let decoded = try JSONDecoder().decode([RecordingListEntry].self, from: stored)
        #expect(decoded.map(\.fileName) == [kept.fileURL.lastPathComponent])
    }

    // An unreadable stored list counts as empty
    @Test func corruptedDataGivesEmptyList() throws {
        storeRaw("{not json")
        #expect(RecordingList(defaults: defaults, storage: storage).entries.isEmpty)
        defaults.set("a string", forKey: TranscriptionInfo.recordingsDefaultsKey)
        let list = RecordingList(defaults: defaults, storage: storage)
        #expect(list.entries.isEmpty)
        // The list keeps working afterwards.
        #expect(list.add(try makeRecording()))
        #expect(RecordingList(defaults: defaults, storage: storage).entries.count == 1)
    }

    // Odd file names, durations not above 0 and files outside the folder are rejected
    @Test func invalidEntriesAreRejected() throws {
        for name in ["", ".", "..", "../x.caf", "a/b.caf", "a\\b.caf", ".hidden.caf", "x..caf"] {
            #expect(RecordingListEntry(fileName: name, spokenAt: .now, duration: 1) == nil, "\(name)")
        }
        #expect(RecordingListEntry(fileName: "ok.caf", spokenAt: .now, duration: 0) == nil)
        #expect(RecordingListEntry(fileName: "ok.caf", spokenAt: .now, duration: -1) == nil)
        #expect(RecordingListEntry(fileName: "ok.caf", spokenAt: .now, duration: .nan) == nil)
        #expect(RecordingListEntry(fileName: "ok.caf", spokenAt: .now, duration: 1, state: .converted) == nil)
        #expect(RecordingListEntry(fileName: "ok.caf", spokenAt: .now, duration: 1) != nil)

        let list = RecordingList(defaults: defaults, storage: storage)
        #expect(!list.add(try makeRecording(seconds: 0)))
        let outside = FinishedRecording(
            sequence: 1, fileURL: base.appendingPathComponent("outside.caf"), duration: .seconds(2),
            microphone: .system, startedAt: .now)
        #expect(!list.add(outside))
        #expect(list.entries.isEmpty)

        // Stored entries with odd values are dropped one by one at load.
        let good = try makeRecording(name: "good.caf")
        _ = try makeRecording(name: "zero.caf")
        storeRaw(
            """
            [{"fileName":"good.caf","spokenAt":1,"duration":2,"state":"open"},
             {"fileName":"../good.caf","spokenAt":1,"duration":2,"state":"open"},
             {"fileName":"zero.caf","spokenAt":1,"duration":0,"state":"open"},
             {"fileName":"good.caf","spokenAt":5,"duration":2,"state":"open"}]
            """)
        let reloaded = RecordingList(defaults: defaults, storage: storage)
        #expect(reloaded.entries.map(\.fileName) == [good.fileURL.lastPathComponent])
        #expect(reloaded.entries.first?.spokenAt == Date(timeIntervalSinceReferenceDate: 1))
    }

    // keptFileNames names every entry, open and converted
    @Test func keptFileNamesListsAllEntries() throws {
        let list = RecordingList(defaults: defaults, storage: storage)
        let open = try makeRecording()
        let converted = try makeRecording()
        let removed = try makeRecording()
        list.add(open)
        list.add(converted)
        list.add(removed)
        list.markConverted(converted.fileURL.lastPathComponent)
        list.remove(removed.fileURL.lastPathComponent, deleteFile: false)
        #expect(list.keptFileNames == [open.fileURL.lastPathComponent, converted.fileURL.lastPathComponent])
        #expect(storage.removeLeftovers(keeping: list.keptFileNames) == 1)
        #expect(fileExists(open) && fileExists(converted) && !fileExists(removed))
    }

    // AC-20: open entries come in spoken order, converted ones are left out
    @Test func openEntriesInSpokenOrder() throws {
        let list = RecordingList(defaults: defaults, storage: storage)
        let late = try makeRecording(spokenAt: Date(timeIntervalSince1970: 300))
        let early = try makeRecording(spokenAt: Date(timeIntervalSince1970: 100))
        let middle = try makeRecording(spokenAt: Date(timeIntervalSince1970: 200))
        let done = try makeRecording(spokenAt: Date(timeIntervalSince1970: 50))
        for recording in [late, early, middle, done] { list.add(recording) }
        list.markConverted(done.fileURL.lastPathComponent)
        #expect(list.openEntries.map(\.fileName) == [early, middle, late].map(\.fileURL.lastPathComponent))
        let reloaded = RecordingList(defaults: defaults, storage: storage)
        #expect(reloaded.openEntries.map(\.fileName) == [early, middle, late].map(\.fileURL.lastPathComponent))
    }
}
