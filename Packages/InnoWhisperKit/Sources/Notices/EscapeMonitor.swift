import AppKit

/// Watches Esc only while an error notice is visible (AC-4). Passive: the app
/// the user types in still receives its Esc. Keys from other apps arrive only
/// once InnoWhisper has the Accessibility permission (PROJ-3).
@MainActor
final class EscapeMonitor {
    static let escapeKeyCode: UInt16 = 53

    private let onEscape: @MainActor () -> Void
    private var global: Any?
    private var local: Any?

    init(onEscape: @escaping @MainActor () -> Void) {
        self.onEscape = onEscape
    }

    func start() {
        guard global == nil else { return }
        global = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == Self.escapeKeyCode else { return }
            MainActor.assumeIsolated { self?.onEscape() }
        }
        local = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == Self.escapeKeyCode { self?.onEscape() }
            return event
        }
    }

    func stop() {
        if let global { NSEvent.removeMonitor(global) }
        if let local { NSEvent.removeMonitor(local) }
        global = nil
        local = nil
    }
}
