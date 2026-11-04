import AppKit
import AppShell

/// System dialogs around the old app (AC-16, AC-17, EC-3).
@MainActor
enum LegacyAlerts {
    static let presenter = LegacyAppGuard.Presenter(
        askWhatToDo: { askWhatToDo() },
        showTerminated: { showTerminated() },
        showManualInstructions: { showManualInstructions($0) }
    )

    static func askWhatToDo() -> LegacyPromptChoice {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Die alte Version läuft noch und stört das Diktieren."
        alert.informativeText = "Beende sie, damit Tastenkürzel und Aufnahme zuverlässig funktionieren."
        alert.addButton(withTitle: "Alte Version beenden")
        alert.addButton(withTitle: "Später")
        NSApplication.shared.activate()
        return alert.runModal() == .alertFirstButtonReturn ? .terminate : .later
    }

    static func showTerminated() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Die alte Version wurde beendet."
        alert.addButton(withTitle: "OK")
        NSApplication.shared.activate()
        alert.runModal()
    }

    static func showManualInstructions(_ steps: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Die alte Version lässt sich nicht beenden."
        alert.informativeText = steps
        alert.addButton(withTitle: "OK")
        NSApplication.shared.activate()
        alert.runModal()
    }
}
