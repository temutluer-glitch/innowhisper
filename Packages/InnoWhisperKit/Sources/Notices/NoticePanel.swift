import AppKit
import Diagnostics
import Observation
import SwiftUI

/// A borderless panel that never becomes key or main (AC-6).
final class NoticeWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Shows the visible notice of the `NoticeCenter` on screen (AC-1, AC-6, AC-7, EC-2).
@MainActor
public final class NoticePanelController {
    private let center: NoticeCenter
    private let escape: EscapeMonitor
    private var panel: NoticeWindow?

    public init(center: NoticeCenter) {
        self.center = center
        self.escape = EscapeMonitor { [weak center] in center?.dismissCurrent() }
    }

    /// Follows the notice center from now on.
    public func start() {
        observe()
    }

    private func observe() {
        let notice = withObservationTracking {
            center.current
        } onChange: { [weak self] in
            Task { @MainActor in self?.observe() }
        }
        render(notice)
    }

    private func render(_ notice: Notice?) {
        guard let notice else {
            escape.stop()
            hide()
            return
        }
        if notice.kind == .error { escape.start() } else { escape.stop() }
        let panel = self.panel ?? makePanel()
        self.panel = panel
        let host = NSHostingView(
            rootView: NoticeView(
                notice: notice,
                onClick: { [weak center] in
                    if notice.kind == .error { center?.dismissCurrent() }
                },
                onAction: { [weak center] in center?.performAction(id: notice.id) }))
        let size = host.fittingSize
        host.frame = CGRect(origin: .zero, size: size)
        panel.contentView = host
        let frame = NoticePlacement.frame(
            size: size,
            anchor: center.anchor,
            screens: NSScreen.screens.map(\.visibleFrame),
            mouse: NSEvent.mouseLocation,
            mainScreen: NSScreen.main?.visibleFrame ?? .zero
        )
        panel.setFrame(frame, display: true)
        panel.alphaValue = reduceMotion ? 1 : 0
        panel.orderFrontRegardless()
        if !reduceMotion {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                panel.animator().alphaValue = 1
            }
        }
        announce(notice)
        Log.write(
            "Notice shown: \(notice.kind), anchored: \(center.anchor != nil), key: \(panel.isKeyWindow)",
            category: .notices)
    }

    private func hide() {
        guard let panel, panel.isVisible else { return }
        if reduceMotion {
            panel.orderOut(nil)
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                panel.animator().alphaValue = 0
            } completionHandler: {
                MainActor.assumeIsolated {
                    if self.center.current == nil { panel.orderOut(nil) }
                }
            }
        }
    }

    private func makePanel() -> NoticeWindow {
        let panel = NoticeWindow(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isReleasedWhenClosed = false
        return panel
    }

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    private func announce(_ notice: Notice) {
        NSAccessibility.post(
            element: NSApplication.shared,
            notification: .announcementRequested,
            userInfo: [
                .announcement: notice.text,
                .priority: NSAccessibilityPriorityLevel.high.rawValue,
            ]
        )
    }
}
