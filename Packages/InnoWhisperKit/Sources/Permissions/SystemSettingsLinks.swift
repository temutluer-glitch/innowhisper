import AppKit
import Diagnostics

/// Opens System Settings exactly at the permission (AC-9, AC-11, AC-16).
@MainActor
public struct SystemSettingsLinks {
    /// Opens a URL; returns `false` if macOS did not accept it.
    let openURL: @MainActor (URL) -> Bool

    public init(openURL: @escaping @MainActor (URL) -> Bool = { NSWorkspace.shared.open($0) }) {
        self.openURL = openURL
    }

    static let fallback = URL(fileURLWithPath: "/System/Applications/System Settings.app")

    static func url(for kind: PermissionKind) -> URL {
        switch kind {
        case .microphone:
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
        case .accessibility:
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        }
    }

    /// Falls back to System Settings without a page if the address is refused.
    public func open(_ kind: PermissionKind) {
        if openURL(Self.url(for: kind)) {
            Log.write("System Settings opened at \(kind)", category: .permissions)
            return
        }
        Log.write("System Settings page refused for \(kind), opening start page", category: .permissions, level: .error)
        _ = openURL(Self.fallback)
    }
}
