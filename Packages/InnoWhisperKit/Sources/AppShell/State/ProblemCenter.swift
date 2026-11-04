import Observation

/// A problem a feature reports to the app frame, e.g. a missing permission.
/// Shown as a hint with one solving action, in its settings section and/or
/// in the menu bar panel.
public struct Problem: Identifiable, Sendable {
    /// Stable identifier, e.g. `legacyAppRunning`. Reporting the same id again
    /// replaces the earlier entry.
    public let id: String
    /// Settings section the hint belongs to; `nil` = menu bar panel only.
    public let section: SettingsSection?
    /// One understandable sentence, never a raw error code.
    public let message: String
    /// Title of the solving button, e.g. "Alte Version beenden".
    public let actionTitle: String
    /// What the button does.
    public let action: @MainActor @Sendable () -> Void

    public init(
        id: String,
        section: SettingsSection?,
        message: String,
        actionTitle: String,
        action: @escaping @MainActor @Sendable () -> Void
    ) {
        self.id = id
        self.section = section
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
}

/// Collects the problems currently reported by features. In memory only.
@MainActor
@Observable
public final class ProblemCenter {
    public private(set) var problems: [Problem] = []

    public init() {}

    /// Adds a problem, or replaces the one with the same id (keeps its position).
    public func report(_ problem: Problem) {
        if let index = problems.firstIndex(where: { $0.id == problem.id }) {
            problems[index] = problem
        } else {
            problems.append(problem)
        }
    }

    /// Removes the problem with this id; unknown ids are ignored.
    public func withdraw(id: String) {
        problems.removeAll { $0.id == id }
    }

    public func isReported(id: String) -> Bool {
        problems.contains { $0.id == id }
    }

    /// Problems that belong to the given settings section.
    public func problems(in section: SettingsSection) -> [Problem] {
        problems.filter { $0.section == section }
    }

    public var hasProblems: Bool { !problems.isEmpty }
}
