/// Error log of InnoWhisper (PROJ-2): technical events only, never dictation
/// content. Foundation layer — every module may use it, it depends on nothing.
public enum DiagnosticsInfo {
    /// Log subsystem, shared with Apple's unified log.
    public static let subsystem = "com.innosolv.InnoWhisper"
}
