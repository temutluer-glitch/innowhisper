import Diagnostics
import Observation

/// One page of an onboarding run.
public enum OnboardingPage {
    case welcome
    case step(OnboardingStep)
    case done

    var storedID: String? {
        switch self {
        case .welcome: OnboardingProgressStore.welcomeID
        case .step(let step): step.id
        case .done: nil
        }
    }
}

/// Which pages a run shows and where it starts (design.md → „Welche Schritte
/// ein Durchlauf zeigt“). Pure, so it can be tested without a window.
struct OnboardingPlan {
    let pages: [OnboardingPage]
    let startIndex: Int
    /// Steps that count as done without being shown (AC-19).
    let autoCompleted: [OnboardingStep]

    /// `nil` means: no onboarding needed.
    @MainActor
    static func make(steps: [OnboardingStep], completed: Set<String>, finishedOnce: Bool) -> OnboardingPlan? {
        let sorted = steps.sorted { ($0.order, $0.id) < ($1.order, $1.id) }
        if !finishedOnce {
            // First start, or a run that was quit midway (AC-1, AC-13, EC-1).
            let pages: [OnboardingPage] = [.welcome] + sorted.map { .step($0) } + [.done]
            let start =
                pages.firstIndex { page in
                    guard let id = page.storedID else { return true }
                    return !completed.contains(id)
                } ?? pages.count - 1
            return OnboardingPlan(pages: pages, startIndex: start, autoCompleted: [])
        }
        // After an update: only new steps (AC-18, AC-19).
        let open = sorted.filter { !completed.contains($0.id) }
        let automatic = open.filter { $0.completesAutomatically && $0.isSatisfied() }
        let remaining = open.filter { step in !automatic.contains { $0.id == step.id } }
        guard !remaining.isEmpty else {
            return automatic.isEmpty ? nil : OnboardingPlan(pages: [], startIndex: 0, autoCompleted: automatic)
        }
        return OnboardingPlan(pages: remaining.map { .step($0) } + [.done], startIndex: 0, autoCompleted: automatic)
    }
}

/// The state of one onboarding run: current page, "Weiter"/"Zurück", saving
/// progress and the re-check of earlier steps (AC-2, AC-5, AC-7, AC-13, EC-2).
@MainActor
@Observable
public final class OnboardingFlow {
    public let pages: [OnboardingPage]
    public private(set) var currentIndex: Int
    @ObservationIgnored private let store: OnboardingProgressStore
    @ObservationIgnored private let onFinished: @MainActor () -> Void

    init(plan: OnboardingPlan, store: OnboardingProgressStore, onFinished: @escaping @MainActor () -> Void) {
        pages = plan.pages
        currentIndex = plan.startIndex
        self.store = store
        self.onFinished = onFinished
    }

    /// Starts a run for the registered steps, or returns `nil` when nothing
    /// needs to be shown. Steps that complete automatically are stored as
    /// done right here (AC-19).
    public static func start(
        steps: [OnboardingStep],
        store: OnboardingProgressStore,
        onFinished: @escaping @MainActor () -> Void
    ) -> OnboardingFlow? {
        guard
            let plan = OnboardingPlan.make(
                steps: steps, completed: store.completedSteps, finishedOnce: store.finishedOnce)
        else { return nil }
        for step in plan.autoCompleted {
            store.markCompleted(step.id)
            Log.write(
                "Onboarding step completed automatically: \(StepLogName(logDescription: step.logName))",
                category: .onboarding)
        }
        guard !plan.pages.isEmpty else { return nil }
        return OnboardingFlow(plan: plan, store: store, onFinished: onFinished)
    }

    public var currentPage: OnboardingPage { pages[currentIndex] }

    /// "Schritt X von Y" (AC-2).
    public var positionText: String { "Schritt \(currentIndex + 1) von \(pages.count)" }

    /// "Zurück" exists from the second page on (AC-5).
    public var canGoBack: Bool { currentIndex > 0 }

    /// "Weiter" is locked while the current step is not satisfied (AC-7).
    public var canAdvance: Bool {
        if case .step(let step) = currentPage { return step.isSatisfied() }
        return true
    }

    public func goBack() {
        guard canGoBack else { return }
        currentIndex -= 1
    }

    /// "Weiter", "Los geht's" or "Fertig".
    public func advance() {
        guard canAdvance else { return }
        if let id = currentPage.storedID {
            store.markCompleted(id)
            if case .step(let step) = currentPage {
                Log.write(
                    "Onboarding step completed: \(StepLogName(logDescription: step.logName))", category: .onboarding)
            } else {
                Log.write("Onboarding welcome completed", category: .onboarding)
            }
        }
        if let revoked = firstUnsatisfiedStep(upTo: currentIndex) {
            // EC-2: something granted earlier is gone again.
            if case .step(let step) = pages[revoked] {
                store.unmarkCompleted(step.id)
                Log.write(
                    "Onboarding step no longer satisfied, back to: \(StepLogName(logDescription: step.logName))",
                    category: .onboarding)
            }
            currentIndex = revoked
            return
        }
        if case .done = currentPage {
            store.markFinished()
            Log.write("Onboarding finished", category: .onboarding)
            onFinished()
            return
        }
        currentIndex += 1
    }

    private func firstUnsatisfiedStep(upTo index: Int) -> Int? {
        pages.indices.first { candidate in
            guard candidate <= index, case .step(let step) = pages[candidate] else { return false }
            return !step.isSatisfied()
        }
    }
}
