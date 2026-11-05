import AVFoundation
import ApplicationServices

/// Asks macOS about permissions. The real one talks to the system; tests use
/// a stand-in.
@MainActor
public protocol PermissionChecking: AnyObject {
    func state(of kind: PermissionKind) -> PermissionState
    /// Shows the macOS microphone question (only works while not determined).
    func requestMicrophone() async
    /// Puts InnoWhisper into the Accessibility list of System Settings.
    func registerForAccessibility()
}

@MainActor
public final class SystemPermissionChecker: PermissionChecking {
    public init() {}

    public func state(of kind: PermissionKind) -> PermissionState {
        switch kind {
        case .microphone:
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized: return .granted
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
            case .denied: return .denied
            @unknown default: return .denied
            }
        case .accessibility:
            return AXIsProcessTrusted() ? .granted : .denied
        }
    }

    public func requestMicrophone() async {
        _ = await AVCaptureDevice.requestAccess(for: .audio)
    }

    /// Makes InnoWhisper appear in the Accessibility list without the macOS
    /// question window: that window would open next to System Settings, which
    /// open anyway (design.md → Bau-Notizen). An Accessibility call that macOS
    /// refuses is what puts the app on the list.
    public func registerForAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": false] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        var value: CFTypeRef?
        _ = AXUIElementCopyAttributeValue(
            AXUIElementCreateSystemWide(), kAXFocusedApplicationAttribute as CFString, &value)
    }
}
