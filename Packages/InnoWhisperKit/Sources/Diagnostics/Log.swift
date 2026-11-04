import OSLog
import Synchronization

/// The one way every module writes to the log (AC-11, AC-12): into the log
/// file (once configured) and into Apple's unified log.
public enum Log {
    public enum Level: Sendable {
        case notice
        case error
    }

    private static let file = Mutex<LogFile?>(nil)

    /// Called once at app start with the log file.
    public static func configure(file logFile: LogFile?) {
        file.withLock { $0 = logFile }
    }

    public static func write(_ message: LogMessage, category: LogCategory, level: Level = .notice) {
        let logger = Logger(subsystem: DiagnosticsInfo.subsystem, category: category.name)
        let text = message.text
        switch level {
        case .notice: logger.notice("\(text, privacy: .public)")
        case .error: logger.error("\(text, privacy: .public)")
        }
        let target = file.withLock { $0 }
        target?.write(message, category: category)
    }
}
