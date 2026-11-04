import Foundation
import ServiceManagement

/// State of "Start beim Anmelden" as macOS reports it. macOS is the only source of truth.
public enum LoginItemStatus: Sendable, Equatable {
    case enabled
    case notRegistered
    case requiresApproval
    case notFound
}

/// Access to the macOS login items for this app. Replaced by a fake in tests.
@MainActor
public protocol LoginItemService: AnyObject {
    var status: LoginItemStatus { get }
    func register() throws
    func unregister() throws
    func openSystemSettings()
}

/// The real login item of the main app, via `SMAppService.mainApp`.
@MainActor
public final class SystemLoginItemService: LoginItemService {
    public init() {}

    public var status: LoginItemStatus {
        switch SMAppService.mainApp.status {
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notFound: .notFound
        case .notRegistered: .notRegistered
        @unknown default: .notFound
        }
    }

    public func register() throws {
        try SMAppService.mainApp.register()
    }

    public func unregister() throws {
        try SMAppService.mainApp.unregister()
    }

    public func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
