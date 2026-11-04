import Foundation

/// Fixed category names of log entries.
public struct LogCategory: Sendable, Equatable {
    public let name: String

    public init(_ name: StaticString) {
        self.name = name.description
    }

    public static let app = LogCategory("app")
    public static let appShell = LogCategory("appshell")
    public static let notices = LogCategory("notices")
}

/// The log file on this Mac (AC-11, AC-13, EC-3, EC-4). All file access runs
/// one after another on a private queue, never on the main thread.
public final class LogFile: @unchecked Sendable {
    public static let defaultDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/InnoWhisper", isDirectory: true)
    public static let defaultFileName = "InnoWhisper.log"

    public let fileURL: URL
    private let directory: URL
    private let retention: LogRetention
    private let now: @Sendable () -> Date
    private let queue = DispatchQueue(label: "com.innosolv.InnoWhisper.logfile")
    private var available = true
    private var sizeBytes: Int = 0

    public init(
        directory: URL = LogFile.defaultDirectory,
        fileName: String = LogFile.defaultFileName,
        retention: LogRetention = LogRetention(),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.directory = directory
        self.fileURL = directory.appendingPathComponent(fileName)
        self.retention = retention
        self.now = now
        queue.sync { prepare() }
    }

    /// False when the file could not be created or written (EC-3).
    public var isAvailable: Bool {
        queue.sync { available }
    }

    /// Appends one entry. Never throws; a failure marks the log unavailable.
    public func write(_ message: LogMessage, category: LogCategory) {
        let date = now()
        queue.async { [self] in
            guard available else { return }
            let line = LogLineFormat.line(date: date, category: category.name, text: message.text)
            append(line)
        }
    }

    /// Creates an empty file if none exists (EC-4). Returns the file, or nil
    /// when the log is not available.
    public func ensureFileExists() -> URL? {
        queue.sync {
            guard available, createFileIfNeeded() else { return nil }
            return fileURL
        }
    }

    /// Waits until all queued writes are done (tests, shutdown).
    public func flush() {
        queue.sync {}
    }

    // MARK: - Queue-confined

    private func prepare() {
        guard createFileIfNeeded() else { return }
        trim()
    }

    private func createFileIfNeeded() -> Bool {
        let manager = FileManager.default
        do {
            try manager.createDirectory(at: directory, withIntermediateDirectories: true)
            if !manager.fileExists(atPath: fileURL.path) {
                guard manager.createFile(atPath: fileURL.path, contents: nil) else {
                    available = false
                    return false
                }
            }
            sizeBytes = (try? manager.attributesOfItem(atPath: fileURL.path)[.size] as? Int) ?? 0
            return true
        } catch {
            available = false
            return false
        }
    }

    private func append(_ line: String) {
        guard let data = (line + "\n").data(using: .utf8) else { return }
        do {
            let handle = try FileHandle(forWritingTo: fileURL)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            sizeBytes += data.count
        } catch {
            available = false
            return
        }
        if sizeBytes > retention.maxBytes { trim() }
    }

    private func trim() {
        guard let data = try? Data(contentsOf: fileURL), let content = String(data: data, encoding: .utf8) else {
            return
        }
        let kept = retention.apply(to: content, now: now())
        guard kept != content else { return }
        do {
            try Data(kept.utf8).write(to: fileURL, options: .atomic)
            sizeBytes = kept.utf8.count
        } catch {
            available = false
        }
    }
}

/// One line per entry: time, category in brackets, message.
enum LogLineFormat {
    static func line(date: Date, category: String, text: String) -> String {
        "\(timestamp(date)) [\(category)] \(text.replacingOccurrences(of: "\n", with: " "))"
    }

    static func timestamp(_ date: Date) -> String {
        date.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: true).timeZone(separator: .colon))
    }

    static func date(ofLine line: Substring) -> Date? {
        guard let space = line.firstIndex(of: " ") else { return nil }
        return try? Date(
            String(line[..<space]),
            strategy: .iso8601.year().month().day().time(includingFractionalSeconds: true).timeZone(separator: .colon))
    }
}
