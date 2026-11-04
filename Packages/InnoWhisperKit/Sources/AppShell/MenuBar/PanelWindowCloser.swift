import AppKit
import SwiftUI

/// Knows the window the menu bar panel lives in and closes it on Esc (AC-3).
/// `@Environment(\.dismiss)` and `onExitCommand` do not close a
/// `MenuBarExtra` window (found in the live test of PROJ-1).
@MainActor
final class PanelWindowCloser {
    weak var window: NSWindow?
    private var monitor: Any?

    func startListening() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let window = self.window, event.window === window, event.keyCode == Self.escapeKeyCode
            else { return event }
            self.close()
            return nil
        }
    }

    func stopListening() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    func close() {
        window?.close()
    }

    static let escapeKeyCode: UInt16 = 53
}

/// Reports the hosting window of a SwiftUI view.
struct WindowReader: NSViewRepresentable {
    let onWindow: @MainActor (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in onWindow(view?.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { [weak nsView] in onWindow(nsView?.window) }
    }
}
