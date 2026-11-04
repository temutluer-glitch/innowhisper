import OSLog

/// Unified logging for the app frame. Never logs dictation content.
enum AppShellLog {
    static let system = Logger(subsystem: "com.innosolv.InnoWhisper", category: "appshell")
}
