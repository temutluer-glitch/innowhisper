import Diagnostics
import SwiftUI

/// One step a feature adds to the onboarding (design.md → Schritt-Vertrag).
/// "Willkommen" and "Fertig" belong to the frame and are never registered.
public struct OnboardingStep: Identifiable {
    /// Fixed, unique and never changed: it is stored as "done".
    public let id: String
    /// Fixed text for the log (PROJ-2 AC-12).
    public let logName: StaticString
    /// Smaller numbers come first. Taken: microphone 30, accessibility 40.
    /// Reserved: access key 10, microphone choice 50, hotkey 60, test dictation 70.
    public let order: Int
    public let title: String
    public let content: @MainActor () -> AnyView
    /// While `false`, "Weiter" stays locked (AC-7). Reads observable state,
    /// so views update when it changes.
    public let isSatisfied: @MainActor () -> Bool
    /// A step that is already satisfied counts as done without being shown
    /// after an update (AC-19).
    public let completesAutomatically: Bool

    public init<Content: View>(
        id: String,
        logName: StaticString,
        order: Int,
        title: String,
        completesAutomatically: Bool,
        isSatisfied: @escaping @MainActor () -> Bool,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) {
        self.id = id
        self.logName = logName
        self.order = order
        self.title = title
        self.completesAutomatically = completesAutomatically
        self.isSatisfied = isSatisfied
        self.content = { AnyView(content()) }
    }
}

/// A step name that may appear in the log.
struct StepLogName: LogValue {
    let logDescription: StaticString
}
