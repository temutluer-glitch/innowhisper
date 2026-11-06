import Foundation

/// The Groq access key (PROJ-4): entering, checking and storing it in the
/// keychain, taking it over from the old app, and warning when it is missing
/// or no longer valid.
public enum GroqAccessInfo {
    /// Light request that only answers with a valid key (design.md → Prüfung).
    public static let checkURL = URL(string: "https://api.groq.com/openai/v1/models")!
    /// Longest a check may take before it counts as "not reachable" (AC-4, EC-5).
    public static let checkTimeout: Duration = .seconds(15)
    /// Own keychain entry (design.md → Datenmodell).
    public static let keychainService = "com.innosolv.InnoWhisper"
    public static let keychainAccount = "groq-api-key"
    /// Entry of the old app, read only on request and never changed (AC-8).
    public static let legacyKeychainService = "com.innosolv.WhisperDictation"
    public static let legacyKeychainAccount = "groq_api_key"
    /// Settings key for the check state (design.md → Datenmodell).
    public static let statusDefaultsKey = "groqKey.status"
    /// Onboarding step: fixed id and position before the permissions (PROJ-3 design).
    public static let stepID = "groq-key"
    public static let stepOrder = 10
    /// Problem shown when the key is missing or invalid (AC-14, AC-15).
    public static let problemID = "groq.key"
    /// Longest key that is checked at all (design.md → Datenmodell).
    public static let maxKeyLength = 200
}
