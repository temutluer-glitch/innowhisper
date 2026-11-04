/// App frame of InnoWhisper (PROJ-1): menu bar, settings window, app state.
///
/// Feature modules depend on `AppShell` to report dictation activity and
/// problems, and to register settings sections. `AppShell` never imports a
/// feature module; only the app target knows all of them.
public enum AppShellInfo {
    /// Bundle identifier of InnoWhisper.
    public static let bundleIdentifier = "com.innosolv.InnoWhisper"
}
