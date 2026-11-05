import AppKit
import Testing

@testable import Onboarding

@MainActor
@Suite struct OnboardingWindowTests {
    @Test func windowIsCenteredInTheGivenFrame() {
        let origin = OnboardingWindowController.centered(
            CGSize(width: 520, height: 440), in: CGRect(x: 1440, y: 0, width: 1920, height: 1080))
        #expect(origin == CGPoint(x: 1440 + 960 - 260, y: 540 - 220))
    }

    @Test func escapeAndCloseDoNotCloseTheWindow() {
        let window = OnboardingWindow(
            contentRect: CGRect(x: 0, y: 0, width: 100, height: 100), styleMask: [.titled], backing: .buffered,
            defer: true)
        window.isReleasedWhenClosed = false
        window.orderFront(nil)
        window.cancelOperation(nil)
        window.performClose(nil)
        #expect(window.isVisible)
        #expect(!window.styleMask.contains(.closable))
        window.orderOut(nil)
    }

    // EC-5, added by /qa: the screen is chosen by the mouse pointer, else the first screen.
    @Test func screenWithTheMouseIsChosen() throws {
        let screens = NSScreen.screens
        let size = CGSize(width: 520, height: 440)
        let last = try #require(screens.last)
        let mouse = CGPoint(x: last.frame.midX, y: last.frame.midY)
        #expect(
            OnboardingWindowController.origin(for: size, screens: screens, mouse: mouse)
                == OnboardingWindowController.centered(size, in: last.visibleFrame))
    }

    @Test func mouseOutsideEveryScreenFallsBackToTheFirst() throws {
        let screens = NSScreen.screens
        let size = CGSize(width: 520, height: 440)
        let first = try #require(screens.first)
        let outside = CGPoint(x: -1_000_000, y: -1_000_000)
        #expect(
            OnboardingWindowController.origin(for: size, screens: screens, mouse: outside)
                == OnboardingWindowController.centered(size, in: first.visibleFrame))
        #expect(OnboardingWindowController.origin(for: size, screens: [], mouse: outside) == CGPoint(x: -260, y: -220))
    }
}
