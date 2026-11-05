/// Microphone and Accessibility permissions (PROJ-3): reading their state,
/// asking for them, watching for changes and reporting missing ones.
public enum PermissionsInfo {
    /// How often the state is checked while the onboarding is open (AC-8, AC-10).
    public static let onboardingInterval: Duration = .seconds(1)
    /// How often the state is checked otherwise (AC-15, AC-16).
    public static let backgroundInterval: Duration = .seconds(3)
}
