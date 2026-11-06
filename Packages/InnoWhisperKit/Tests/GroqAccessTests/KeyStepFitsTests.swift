import AppKit
import AppShell
import Foundation
import SwiftUI
import Testing

@testable import GroqAccess
@testable import Onboarding

/// The key step must fit the fixed onboarding window in its tallest state
/// (takeover offered plus a two-line result), otherwise the window cuts off
/// "Schritt X von Y" and the buttons (found in the live test on 06.11.).
@MainActor
@Suite struct KeyStepFitsTests {
    /// Height the onboarding frame uses around a page: 20 top padding, 15 for
    /// "Schritt X von Y", 2 × 16 minimum spacing, 20 + 24 + 20 for the button
    /// bar (measured with NSHostingView on macOS 26).
    let frameAroundPage: CGFloat = 131

    @Test func tallestKeyStepFitsTheOnboardingWindow() async {
        let defaults = UserDefaults(suiteName: "KeyStepFitsTests-\(UUID().uuidString)")!
        let model = GroqKeyModel(
            store: FakeStore(), legacy: FakeLegacy(key: "gsk_legacy01"), checker: FakeChecker(.rejected),
            defaults: defaults, problems: ProblemCenter(), onboardingFinishedOnce: { false })
        model.lookForLegacyKey()
        await model.takeOver()
        #expect(model.legacyKeyAvailable)
        #expect(model.lastResult == .rejected)

        let window = OnboardingWindowController.size
        let page = NSHostingView(rootView: KeyStepView(model: model).frame(width: window.width)).fittingSize
        #expect(page.height + frameAroundPage <= window.height)
    }
}
