import Foundation

/// What the onboarding has already done on this Mac (design.md → Datenmodell).
/// Permission states are never stored here; they are always read live.
@MainActor
public final class OnboardingProgressStore {
    nonisolated static let completedStepsKey = "onboarding.completedSteps"
    nonisolated static let finishedOnceKey = "onboarding.finishedOnce"
    /// Stored id of the welcome page.
    nonisolated static let welcomeID = "welcome"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // A damaged value means "start from the beginning" (design.md, Fehlerfälle).
        if let stored = defaults.object(forKey: Self.completedStepsKey), !(stored is [String]) {
            defaults.removeObject(forKey: Self.completedStepsKey)
            defaults.removeObject(forKey: Self.finishedOnceKey)
        }
    }

    /// Ids of steps the user has left with "Weiter" (or "Los geht's").
    /// Unknown ids are kept but simply never match a registered step.
    public var completedSteps: Set<String> {
        Set(defaults.stringArray(forKey: Self.completedStepsKey) ?? [])
    }

    /// `true` once "Fertig" was clicked for the first time.
    public var finishedOnce: Bool {
        defaults.bool(forKey: Self.finishedOnceKey)
    }

    func markCompleted(_ id: String) {
        var steps = completedSteps
        guard steps.insert(id).inserted else { return }
        defaults.set(steps.sorted(), forKey: Self.completedStepsKey)
    }

    func unmarkCompleted(_ id: String) {
        var steps = completedSteps
        guard steps.remove(id) != nil else { return }
        defaults.set(steps.sorted(), forKey: Self.completedStepsKey)
    }

    func markFinished() {
        defaults.set(true, forKey: Self.finishedOnceKey)
    }
}
