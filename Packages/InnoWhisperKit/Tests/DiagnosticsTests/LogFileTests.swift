import Foundation
import Testing

@testable import Diagnostics

final class FixedClock: @unchecked Sendable {
    var date: Date
    init(_ date: Date) { self.date = date }
}

struct LogFileTests {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("logfile-\(UUID().uuidString)", isDirectory: true)
    }

    private func read(_ url: URL) -> String {
        (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    // AC-11: one line per entry with time and category
    @Test func writesOneLinePerEntry() {
        let clock = FixedClock(start)
        let log = LogFile(directory: tempDir(), now: { clock.date })
        log.write("Aufnahme gestartet", category: .app)
        log.write("n=\(2)", category: .notices)
        log.flush()
        let lines = read(log.fileURL).split(separator: "\n")
        #expect(lines.count == 2)
        #expect(lines[0].contains("[app] Aufnahme gestartet"))
        #expect(lines[1].contains("[notices] n=2"))
        #expect(LogLineFormat.date(ofLine: lines[0]) == clock.date)
    }

    // AC-13: entries older than 7 days are removed at start
    @Test func dropsEntriesOlderThanSevenDays() {
        let dir = tempDir()
        let clock = FixedClock(start)
        let first = LogFile(directory: dir, now: { clock.date })
        first.write("alt", category: .app)
        first.flush()
        clock.date = start.addingTimeInterval(6 * 24 * 3600)
        first.write("mittel", category: .app)
        first.flush()
        clock.date = start.addingTimeInterval(8 * 24 * 3600)
        let reopened = LogFile(directory: dir, now: { clock.date })
        let content = read(reopened.fileURL)
        #expect(!content.contains("alt"))
        #expect(content.contains("mittel"))
    }

    // AC-13: above the size limit the oldest entries go until below the target
    @Test func trimsBySize() {
        let clock = FixedClock(start)
        let log = LogFile(
            directory: tempDir(), retention: LogRetention(maxBytes: 2_000, trimTargetBytes: 1_000), now: { clock.date })
        for index in 0..<60 { log.write("Eintrag \(index)", category: .app) }
        log.flush()
        let content = read(log.fileURL)
        #expect(content.utf8.count <= 2_000)
        #expect(content.contains("Eintrag 59"))
        #expect(!content.contains("Eintrag 0\n"))
    }

    // EC-4: no file yet → an empty one is created
    @Test func ensureFileCreatesEmptyFile() throws {
        let dir = tempDir()
        let log = LogFile(directory: dir)
        try FileManager.default.removeItem(at: log.fileURL)
        let url = log.ensureFileExists()
        #expect(url == log.fileURL)
        #expect(FileManager.default.fileExists(atPath: log.fileURL.path))
        #expect(read(log.fileURL).isEmpty)
    }

    // EC-3: an unwritable place marks the log unavailable, writing does not crash
    @Test func unwritableDirectoryIsUnavailable() {
        let log = LogFile(directory: URL(fileURLWithPath: "/System/InnoWhisperTest", isDirectory: true))
        log.write("x", category: .app)
        log.flush()
        #expect(!log.isAvailable)
        #expect(log.ensureFileExists() == nil)
    }
}
