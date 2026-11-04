import AppShell
import SwiftUI

@main
struct InnoWhisperApp: App {
    var body: some Scene {
        MenuBarExtra("InnoWhisper", systemImage: "mic") {
            Button("InnoWhisper beenden") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
