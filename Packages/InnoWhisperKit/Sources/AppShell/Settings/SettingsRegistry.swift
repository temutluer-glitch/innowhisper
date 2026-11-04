import Foundation
import Observation
import SwiftUI

/// Content of one settings section, registered by the feature that owns it.
public struct SettingsPane: Identifiable {
    public let section: SettingsSection
    public let content: @MainActor () -> AnyView

    public var id: SettingsSection { section }

    public init<Content: View>(section: SettingsSection, @ViewBuilder content: @escaping @MainActor () -> Content) {
        self.section = section
        self.content = { AnyView(content()) }
    }
}

/// A group inside the "Allgemein" section, contributed by a feature
/// (e.g. sounds from PROJ-2, output mode from PROJ-7).
public struct GeneralSettingsGroup: Identifiable {
    public let id: String
    public let title: String
    /// Smaller numbers come first.
    public let order: Int
    public let content: @MainActor () -> AnyView

    public init<Content: View>(
        id: String,
        title: String,
        order: Int,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) {
        self.id = id
        self.title = title
        self.order = order
        self.content = { AnyView(content()) }
    }
}

/// Which sections and "Allgemein" groups exist, and which section was used last.
@MainActor
@Observable
public final class SettingsRegistry {
    static let lastSectionKey = "settings.lastSection"

    public private(set) var panes: [SettingsSection: SettingsPane] = [:]
    public private(set) var generalGroups: [GeneralSettingsGroup] = []
    @ObservationIgnored private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Registers (or replaces) the content of a section.
    public func register(_ pane: SettingsPane) {
        panes[pane.section] = pane
    }

    /// Registers (or replaces, by id) a group in "Allgemein".
    public func register(_ group: GeneralSettingsGroup) {
        generalGroups.removeAll { $0.id == group.id }
        generalGroups.append(group)
        generalGroups.sort { ($0.order, $0.id) < ($1.order, $1.id) }
    }

    /// Registered sections in sidebar order (AC-7, AC-8).
    public var availableSections: [SettingsSection] {
        SettingsSection.allCases.filter { panes[$0] != nil }
    }

    /// Section to show when the window opens without a target (AC-9):
    /// the last used one if still registered, otherwise "Allgemein".
    public var initialSection: SettingsSection {
        if let raw = defaults.string(forKey: Self.lastSectionKey),
            let section = SettingsSection(rawValue: raw),
            panes[section] != nil
        {
            return section
        }
        return .general
    }

    /// Remembers the section the user is looking at.
    public func rememberSelection(_ section: SettingsSection) {
        defaults.set(section.rawValue, forKey: Self.lastSectionKey)
    }
}
