import Foundation

/// Keeps the log small (AC-13): entries older than 7 days go; above 10 MB the
/// oldest go until it is below 8 MB, so the file is not rewritten on every entry.
public struct LogRetention: Sendable {
    public var maxAge: TimeInterval
    public var maxBytes: Int
    public var trimTargetBytes: Int

    public init(maxAge: TimeInterval = 7 * 24 * 60 * 60, maxBytes: Int = 10_000_000, trimTargetBytes: Int = 8_000_000) {
        self.maxAge = maxAge
        self.maxBytes = maxBytes
        self.trimTargetBytes = trimTargetBytes
    }

    /// Returns the content that remains. Lines without a readable time stay
    /// with the entry before them (continuation) and are aged with it.
    public func apply(to content: String, now: Date) -> String {
        let cutoff = now.addingTimeInterval(-maxAge)
        var lines = content.split(separator: "\n", omittingEmptySubsequences: true)
        var keep = true
        lines = lines.filter { line in
            if let date = LogLineFormat.date(ofLine: line) { keep = date >= cutoff }
            return keep
        }
        var total = lines.reduce(0) { $0 + $1.utf8.count + 1 }
        if total > maxBytes {
            var dropCount = 0
            while total > trimTargetBytes, dropCount < lines.count {
                total -= lines[dropCount].utf8.count + 1
                dropCount += 1
            }
            lines.removeFirst(dropCount)
        }
        return lines.isEmpty ? "" : lines.joined(separator: "\n") + "\n"
    }
}
