import Onboarding

/// The two permission steps of the onboarding (design.md → Schritt-Vertrag).
public enum PermissionSteps {
    @MainActor
    public static func make(monitor: PermissionMonitor, relauncher: AppRelauncher = AppRelauncher()) -> [OnboardingStep]
    {
        [
            OnboardingStep(
                id: "microphone", logName: "microphone", order: 30, title: PermissionKind.microphone.title,
                completesAutomatically: true,
                isSatisfied: { monitor.isGranted(.microphone) },
                content: { PermissionStepView(kind: .microphone, monitor: monitor, relauncher: relauncher) }),
            OnboardingStep(
                id: "accessibility", logName: "accessibility", order: 40, title: PermissionKind.accessibility.title,
                completesAutomatically: true,
                isSatisfied: { monitor.isGranted(.accessibility) },
                content: { PermissionStepView(kind: .accessibility, monitor: monitor, relauncher: relauncher) }),
        ]
    }
}

extension PermissionKind {
    /// Why InnoWhisper needs it (AC-6).
    var explanation: String {
        switch self {
        case .microphone: "InnoWhisper braucht das Mikrofon, um deine Stimme aufzunehmen."
        case .accessibility:
            "InnoWhisper braucht die Bedienungshilfen, um das Eingabefeld zu finden und den Text dort einzufügen."
        }
    }

    var symbol: String {
        switch self {
        case .microphone: "mic.fill"
        case .accessibility: "accessibility"
        }
    }

    /// Title of the button that starts granting, for the current state (AC-8, AC-9, AC-11).
    func requestTitle(for state: PermissionState) -> String {
        if self == .microphone && state == .notDetermined { return "Mikrofon erlauben" }
        return "In den Systemeinstellungen erlauben"
    }

    /// Extra sentence under the button, if any (AC-9, AC-11).
    func hint(for state: PermissionState) -> String? {
        switch (self, state) {
        case (_, .granted), (.microphone, .notDetermined): nil
        case (.microphone, .restricted):
            "Das Mikrofon ist auf diesem Mac gesperrt, zum Beispiel durch eine Vorgabe der IT. Wende dich an die Person, die deinen Mac verwaltet."
        case (.microphone, _):
            "Du hast die Abfrage abgelehnt. Die Erlaubnis lässt sich jetzt nur noch in den Systemeinstellungen erteilen."
        case (.accessibility, _): "Schalte dort InnoWhisper ein."
        }
    }
}
