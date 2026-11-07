import AppKit
import AppShell
import Foundation
import SwiftUI
import Testing

@testable import Onboarding
@testable import Recording

@MainActor
@Suite struct ShortcutStepTests {
    let defaults: UserDefaults
    let probe: ShortcutProbe

    init() {
        defaults = UserDefaults(suiteName: "ShortcutStepTests-\(UUID().uuidString)")!
        probe = ShortcutProbe(defaults: defaults)
    }

    func makeController() -> RecordingController {
        let storage = RecordingStorage(
            baseDirectory: FileManager.default.temporaryDirectory.appendingPathComponent("Step-\(UUID().uuidString)"))
        let services = RecordingServices(
            capture: FakeCapture(), storage: storage,
            queue: RecordingQueue(storage: storage, consumer: Consumer()), activity: ActivityCenter(),
            chosenMicrophone: { nil }, microphoneAllowed: { true }, requestMicrophone: {},
            notify: { _, _, _ in }, dictationStarted: {}, playStart: {}, playEnd: {})
        return RecordingController(hotkeys: FakeHotkeys(), services: services)
    }

    func makeStep(_ controller: RecordingController) -> OnboardingStep {
        ShortcutStep.make(
            controller: controller, probe: probe, shortcuts: ShortcutStore(defaults: defaults),
            microphone: MicrophoneChoiceStore(defaults: defaults), microphones: MicrophoneList(listensForChanges: false)
        )
    }

    // AC-19: step after the permissions, never done by itself
    @Test func stepComesAfterThePermissionsAndNeedsAProbe() {
        let step = makeStep(makeController())
        #expect(step.id == "shortcut")
        #expect(step.order == 60)
        #expect(!step.completesAutomatically)
        #expect(!step.isSatisfied())
    }

    // AC-19, AC-20: "Weiter" only after a probe that worked
    @Test func probeResultFromTheControllerUnlocksTheStep() {
        let controller = makeController()
        let step = makeStep(controller)
        controller.onProbeResult?(false)
        #expect(!step.isSatisfied())
        #expect(probe.result == .nothingHeard)
        controller.onProbeResult?(true)
        #expect(step.isSatisfied())
    }

    // BUG-2 (QA 07.11.): quitting on "Fertig" and starting again must not ask for the probe again
    @Test func probeSurvivesARestartOnTheLastPage() {
        let store = OnboardingProgressStore(defaults: defaults)
        var finished = false
        let firstProbe = ShortcutProbe(defaults: defaults)
        let first = ShortcutStep.make(
            controller: makeController(), probe: firstProbe, shortcuts: ShortcutStore(defaults: defaults),
            microphone: MicrophoneChoiceStore(defaults: defaults), microphones: MicrophoneList(listensForChanges: false)
        )
        let flow = OnboardingFlow.start(steps: [first], store: store) {}
        firstProbe.record(worked: true)
        flow?.advance()
        flow?.advance()
        // App quit on "Fertig"; next start with fresh objects
        let secondProbe = ShortcutProbe(defaults: defaults)
        let second = ShortcutStep.make(
            controller: makeController(), probe: secondProbe, shortcuts: ShortcutStore(defaults: defaults),
            microphone: MicrophoneChoiceStore(defaults: defaults), microphones: MicrophoneList(listensForChanges: false)
        )
        let resumed = OnboardingFlow.start(steps: [second], store: store) { finished = true }
        #expect(secondProbe.succeeded)
        resumed?.advance()
        #expect(finished)
    }

    // Fits the onboarding window in its tallest state (lesson from PROJ-4)
    @Test func tallestStateFitsTheOnboardingWindow() {
        let controller = makeController()
        probe.record(worked: false)
        let view = ShortcutStepView(
            controller: controller, probe: probe, shortcuts: ShortcutStore(defaults: defaults),
            microphone: MicrophoneChoiceStore(defaults: defaults), microphones: MicrophoneList(listensForChanges: false)
        )
        let window = OnboardingWindowController.size
        let page = NSHostingView(rootView: view.frame(width: window.width)).fittingSize
        // 131 = frame around a page (see KeyStepFitsTests).
        #expect(page.height + 131 <= window.height)
    }
}
