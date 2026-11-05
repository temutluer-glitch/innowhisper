import AppKit
import AppShell
import Permissions
import SwiftUI

/// Entry point. Answers the invisible Accessibility check first (PROJ-3,
/// QA BUG-1), then starts the app as usual.
@main
enum InnoWhisperMain {
    static func main() {
        SystemPermissionChecker.answerAccessibilityCheckIfAsked()
        InnoWhisperApp.main()
    }
}

struct InnoWhisperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        let environment = appDelegate.environment
        MenuBarExtra(
            isInserted: Binding(
                get: { environment.showsMenuBarItem },
                set: { environment.showsMenuBarItem = $0 }
            )
        ) {
            MenuBarPanel(
                problems: environment.problems,
                openSettings: { environment.openSettings($0) },
                quit: { NSApplication.shared.terminate(nil) }
            ) {
                EmptyView()
            }
        } label: {
            MenuBarLabel(activity: environment.activity, problems: environment.problems)
        }
        .menuBarExtraStyle(.window)
    }
}
