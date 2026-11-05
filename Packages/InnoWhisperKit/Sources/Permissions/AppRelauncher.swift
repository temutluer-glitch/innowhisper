import AppKit
import Diagnostics

/// Restarts InnoWhisper (EC-3): macOS is asked to open the app again after
/// one second, then the app quits. The saved onboarding progress makes it
/// continue at the same step.
@MainActor
public struct AppRelauncher {
    let bundlePath: String
    let run: @MainActor (_ executable: String, _ arguments: [String]) throws -> Void
    let quit: @MainActor () -> Void

    public init() {
        self.init(
            bundlePath: Bundle.main.bundlePath,
            run: { executable, arguments in
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                try process.run()
            },
            quit: { NSApplication.shared.terminate(nil) })
    }

    init(
        bundlePath: String,
        run: @escaping @MainActor (String, [String]) throws -> Void,
        quit: @escaping @MainActor () -> Void
    ) {
        self.bundlePath = bundlePath
        self.run = run
        self.quit = quit
    }

    /// The path is passed as an argument, never pasted into the command text.
    static func command(bundlePath: String) -> (String, [String]) {
        ("/bin/sh", ["-c", "sleep 1; /usr/bin/open \"$0\"", bundlePath])
    }

    public func relaunch() {
        let (executable, arguments) = Self.command(bundlePath: bundlePath)
        do {
            try run(executable, arguments)
            Log.write("Relaunch requested", category: .permissions)
            quit()
        } catch {
            Log.write("Relaunch failed: \(error: error)", category: .permissions, level: .error)
        }
    }
}
