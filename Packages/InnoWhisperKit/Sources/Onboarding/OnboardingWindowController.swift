import AppKit
import Diagnostics
import SwiftUI

/// A window that cannot be closed by Esc or ⌘W (AC-12).
final class OnboardingWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) {}
    override func performClose(_ sender: Any?) {}
    override var canBecomeKey: Bool { true }
}

/// Owns the one onboarding window (AC-1, AC-12, EC-5).
@MainActor
public final class OnboardingWindowController {
    static let size = CGSize(width: 520, height: 440)

    private var window: OnboardingWindow?

    public init() {}

    /// Whether the onboarding window is currently shown.
    public var isOpen: Bool { window?.isVisible == true }

    /// Shows the window for this run, centered on the screen with the mouse
    /// pointer, in front of all other windows.
    public func show(_ flow: OnboardingFlow) {
        let window = OnboardingWindow(
            contentRect: CGRect(origin: .zero, size: Self.size),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.title = OnboardingInfo.windowTitle
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.fullScreenNone]
        window.contentViewController = NSHostingController(rootView: OnboardingView(flow: flow))
        window.setContentSize(Self.size)
        window.setFrameOrigin(
            Self.origin(for: window.frame.size, screens: NSScreen.screens, mouse: NSEvent.mouseLocation))
        self.window = window
        bringToFront()
        Log.write(
            "Onboarding window shown, page \(flow.currentIndex + 1) of \(flow.pages.count), closable \(window.styleMask.contains(.closable))",
            category: .onboarding)
    }

    /// Brings the open window to the front (AC-14).
    public func bringToFront() {
        guard let window else { return }
        NSApplication.shared.activate()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    /// Closes the window after "Fertig".
    public func close() {
        window?.orderOut(nil)
        window = nil
    }

    /// Centered on the screen that contains the mouse pointer, else the first (EC-5).
    static func origin(for size: CGSize, screens: [NSScreen], mouse: CGPoint) -> CGPoint {
        let frames = screens.map(\.visibleFrame)
        let target = screens.first { $0.frame.contains(mouse) }?.visibleFrame ?? frames.first ?? .zero
        return centered(size, in: target)
    }

    static func centered(_ size: CGSize, in frame: CGRect) -> CGPoint {
        CGPoint(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2)
    }
}
