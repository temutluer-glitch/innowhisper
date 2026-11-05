import Diagnostics

/// The two permissions InnoWhisper needs, and no others.
public enum PermissionKind: String, CaseIterable, Sendable, LogValue {
    case microphone
    case accessibility

    public var logDescription: StaticString {
        switch self {
        case .microphone: "microphone"
        case .accessibility: "accessibility"
        }
    }

    /// Name shown to the user.
    public var title: String {
        switch self {
        case .microphone: "Mikrofon"
        case .accessibility: "Bedienungshilfen"
        }
    }

    /// Sentence of the problem hint when the permission is missing (AC-16).
    public var missingMessage: String {
        switch self {
        case .microphone: "Mikrofon nicht erlaubt."
        case .accessibility: "Bedienungshilfen nicht erlaubt."
        }
    }

    /// Identifier of the problem reported when it is missing (AC-15).
    public var problemID: String {
        switch self {
        case .microphone: "permission.microphone"
        case .accessibility: "permission.accessibility"
        }
    }
}

/// What macOS says about a permission. Never stored, always read live.
public enum PermissionState: Sendable, Equatable, LogValue {
    case granted
    /// macOS has never asked (microphone only).
    case notDetermined
    case denied
    /// Blocked by a device profile (IT). Shown like `denied`, logged apart.
    case restricted

    public var isGranted: Bool { self == .granted }

    public var logDescription: StaticString {
        switch self {
        case .granted: "granted"
        case .notDetermined: "notDetermined"
        case .denied: "denied"
        case .restricted: "restricted"
        }
    }
}
