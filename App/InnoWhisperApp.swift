import AppKit
import AppShell
import SwiftUI

@main
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
                openSettings: { environment.settingsWindow.open(section: $0) },
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
