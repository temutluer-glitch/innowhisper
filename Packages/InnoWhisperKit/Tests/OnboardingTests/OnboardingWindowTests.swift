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
}
