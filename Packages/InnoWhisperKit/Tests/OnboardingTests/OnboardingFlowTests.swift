import Foundation
import SwiftUI
import Testing

@testable import Onboarding

@MainActor
final class Switch {
    var on: Bool
    init(_ on: Bool) { self.on = on }
}

@MainActor
func makeStep(_ id: String, order: Int, satisfied: Switch, automatic: Bool = true) -> OnboardingStep {
    OnboardingStep(
        id: id, logName: "test-step", order: order, title: id, completesAutomatically: automatic,
        isSatisfied: { satisfied.on },
        content: { EmptyView() })
}

@MainActor
func freshStore() -> (OnboardingProgressStore, UserDefaults) {
    let suite = "onboarding-test-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return (OnboardingProgressStore(defaults: defaults), defaults)
}

func ids(_ pages: [OnboardingPage]) -> [String] {
    pages.map { page in
        switch page {
        case .welcome: "welcome"
        case .step(let step): step.id
        case .done: "done"
        }
    }
}

@MainActor
@Suite struct OnboardingFlowTests {
    let mic = Switch(false)
    let access = Switch(false)
    var steps: [OnboardingStep] {
        [makeStep("accessibility", order: 40, satisfied: access), makeStep("microphone", order: 30, satisfied: mic)]
    }

    @Test func firstStartShowsAllStepsInOrder() throws {
        let (store, _) = freshStore()
        let flow = try #require(OnboardingFlow.start(steps: steps, store: store) {})
        #expect(ids(flow.pages) == ["welcome", "microphone", "accessibility", "done"])
        #expect(flow.currentIndex == 0)
        #expect(flow.positionText == "Schritt 1 von 4")
    }

    @Test func weiterIsLockedUntilPermissionIsGranted() throws {
        let (store, _) = freshStore()
        let flow = try #require(OnboardingFlow.start(steps: steps, store: store) {})
        flow.advance()
        #expect(flow.positionText == "Schritt 2 von 4")
        #expect(!flow.canAdvance)
        flow.advance()
        #expect(flow.currentIndex == 1)
        mic.on = true
        #expect(flow.canAdvance)
        flow.advance()
        #expect(flow.currentIndex == 2)
    }

    @Test func backKeepsGrantsAndIsMissingOnFirstPage() throws {
        let (store, _) = freshStore()
        mic.on = true
        let flow = try #require(OnboardingFlow.start(steps: steps, store: store) {})
        #expect(!flow.canGoBack)
        flow.advance()
        flow.advance()
        flow.goBack()
        #expect(flow.currentIndex == 1)
        #expect(flow.canAdvance)
    }

    @Test func quittingMidwayResumesAtFirstOpenStep() throws {
        let (store, defaults) = freshStore()
        mic.on = true
        let flow = try #require(OnboardingFlow.start(steps: steps, store: store) {})
        flow.advance()
        flow.advance()
        let reopened = try #require(
            OnboardingFlow.start(steps: steps, store: OnboardingProgressStore(defaults: defaults)) {})
        #expect(ids(reopened.pages) == ["welcome", "microphone", "accessibility", "done"])
        #expect(reopened.currentIndex == 2)
    }

    @Test func alreadyGrantedStepsAreShownOnFirstStart() throws {
        let (store, _) = freshStore()
        mic.on = true
        access.on = true
        let flow = try #require(OnboardingFlow.start(steps: steps, store: store) {})
        #expect(ids(flow.pages) == ["welcome", "microphone", "accessibility", "done"])
        flow.advance()
        #expect(flow.canAdvance)
    }

    @Test func fertigStoresFinishAndCallsBack() throws {
        let (store, _) = freshStore()
        mic.on = true
        access.on = true
        var finished = false
        let flow = try #require(OnboardingFlow.start(steps: steps, store: store) { finished = true })
        for _ in 0..<4 { flow.advance() }
        #expect(finished)
        #expect(store.finishedOnce)
        #expect(OnboardingFlow.start(steps: steps, store: store) {} == nil)
    }

    @Test func revokedEarlierPermissionJumpsBack() throws {
        let (store, _) = freshStore()
        mic.on = true
        access.on = true
        let flow = try #require(OnboardingFlow.start(steps: steps, store: store) {})
        flow.advance()
        flow.advance()
        mic.on = false
        flow.advance()
        #expect(flow.currentIndex == 1)
        #expect(!store.completedSteps.contains("microphone"))
    }

    @Test func revokedPermissionIsCheckedAgainOnFertig() throws {
        let (store, _) = freshStore()
        mic.on = true
        access.on = true
        var finished = false
        let flow = try #require(OnboardingFlow.start(steps: steps, store: store) { finished = true })
        for _ in 0..<3 { flow.advance() }
        access.on = false
        flow.advance()
        #expect(!finished)
        #expect(flow.currentIndex == 2)
    }

    @Test func afterUpdateOnlyNewOpenStepsAndDoneAreShown() throws {
        let (store, _) = freshStore()
        mic.on = true
        access.on = true
        let flow = try #require(OnboardingFlow.start(steps: steps, store: store) {})
        for _ in 0..<4 { flow.advance() }
        let key = Switch(false)
        let updated = steps + [makeStep("key", order: 10, satisfied: key, automatic: false)]
        let run = try #require(OnboardingFlow.start(steps: updated, store: store) {})
        #expect(ids(run.pages) == ["key", "done"])
        #expect(run.positionText == "Schritt 1 von 2")
    }

    @Test func newSatisfiedStepCompletesAutomatically() throws {
        let (store, _) = freshStore()
        mic.on = true
        access.on = true
        let flow = try #require(OnboardingFlow.start(steps: steps, store: store) {})
        for _ in 0..<4 { flow.advance() }
        let camera = Switch(true)
        let updated = steps + [makeStep("camera", order: 45, satisfied: camera)]
        #expect(OnboardingFlow.start(steps: updated, store: store) {} == nil)
        #expect(store.completedSteps.contains("camera"))
    }

    @Test func revokedPermissionAfterFinishDoesNotReopen() throws {
        let (store, _) = freshStore()
        mic.on = true
        access.on = true
        let flow = try #require(OnboardingFlow.start(steps: steps, store: store) {})
        for _ in 0..<4 { flow.advance() }
        mic.on = false
        #expect(OnboardingFlow.start(steps: steps, store: store) {} == nil)
    }

    @Test func damagedProgressStartsFromTheBeginning() throws {
        let (_, defaults) = freshStore()
        defaults.set(42, forKey: OnboardingProgressStore.completedStepsKey)
        defaults.set(true, forKey: OnboardingProgressStore.finishedOnceKey)
        let store = OnboardingProgressStore(defaults: defaults)
        #expect(!store.finishedOnce)
        let flow = try #require(OnboardingFlow.start(steps: steps, store: store) {})
        #expect(flow.currentIndex == 0)
    }

    @Test func unknownStoredIdsAreIgnored() throws {
        let (_, defaults) = freshStore()
        defaults.set(["welcome", "gone-feature"], forKey: OnboardingProgressStore.completedStepsKey)
        let flow = try #require(
            OnboardingFlow.start(steps: steps, store: OnboardingProgressStore(defaults: defaults)) {})
        #expect(flow.currentIndex == 1)
    }
}
