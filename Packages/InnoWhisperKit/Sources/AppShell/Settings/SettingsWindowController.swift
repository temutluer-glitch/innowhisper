import AppKit
import Observation
import SwiftUI

/// Which section the settings window shows.
@MainActor
@Observable
final class SettingsNavigation {
    var selection: SettingsSection = .general
}

/// Owns the one settings window (AC-5, AC-11, AC-12, EC-6). Usable from
/// anywhere — menu bar, app delegate, problem hints.
@MainActor
public final class SettingsWindowController {
    static let frameAutosaveName = "InnoWhisperSettings"
    static let defaultSize = CGSize(width: 760, height: 520)
    static let minimumSize = CGSize(width: 680, height: 460)
    /// Wider than this, the grouped form stops growing and its content sits
    /// centered (found in the live test). Like System Settings, the window
    /// therefore only grows in height beyond the default width.
    static let maximumWidth: CGFloat = 760

    private let registry: SettingsRegistry
    private let problems: ProblemCenter
    private let navigation = SettingsNavigation()
    private var window: NSWindow?

    public init(registry: SettingsRegistry, problems: ProblemCenter) {
        self.registry = registry
        self.problems = problems
    }

    /// Opens the window, or brings it to the front. With a section, shows that
    /// section (if registered); otherwise the last used one.
    public func open(section: SettingsSection? = nil) {
        if let section, registry.panes[section] != nil {
            navigation.selection = section
        } else if window?.isVisible != true {
            navigation.selection = registry.initialSection
        }
        let window = self.window ?? makeWindow()
        self.window = window
        clampWidth(of: window)
        window.setFrame(reachableFrame(for: window.frame), display: false)
        NSApplication.shared.activate()
        window.makeKeyAndOrderFront(nil)
        AppShellLog.system.notice(
            "Settings window shown, section \(self.navigation.selection.rawValue, privacy: .public), max width \(Int(window.contentMaxSize.width), privacy: .public)"
        )
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: Self.defaultSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "InnoWhisper Einstellungen"
        window.isReleasedWhenClosed = false
        window.contentMinSize = Self.minimumSize
        window.contentMaxSize = CGSize(width: Self.maximumWidth, height: .greatestFiniteMagnitude)
        window.toolbarStyle = .unified
        window.contentViewController = NSHostingController(
            rootView: SettingsWindowView(registry: registry, problems: problems, navigation: navigation)
        )
        window.setContentSize(Self.defaultSize)
        if !window.setFrameUsingName(Self.frameAutosaveName) {
            window.center()
        }
        window.setFrameAutosaveName(Self.frameAutosaveName)
        return window
    }

    /// A frame saved before the width limit existed may be wider; shrink it.
    private func clampWidth(of window: NSWindow) {
        let content = window.contentRect(forFrameRect: window.frame)
        guard content.width > Self.maximumWidth else { return }
        window.setContentSize(CGSize(width: Self.maximumWidth, height: content.height))
    }

    private func reachableFrame(for frame: CGRect) -> CGRect {
        let screens = NSScreen.screens.map(\.visibleFrame)
        let main = NSScreen.main?.visibleFrame ?? screens.first ?? frame
        return WindowFramePolicy.reachableFrame(for: frame, screens: screens, mainScreen: main)
    }
}
