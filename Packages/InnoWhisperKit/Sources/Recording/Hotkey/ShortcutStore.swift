import Diagnostics
import Foundation
import Observation

/// The saved shortcut and mode (AC-1, AC-16, AC-17). An unreadable or
/// forbidden stored value falls back to the factory setting and is logged.
@MainActor
@Observable
public final class ShortcutStore {
    public private(set) var shortcut: Shortcut
    public private(set) var mode: ShortcutMode

    @ObservationIgnored private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        shortcut = Self.loadShortcut(from: defaults)
        mode = defaults.string(forKey: RecordingInfo.modeDefaultsKey).flatMap(ShortcutMode.init) ?? Shortcut.factoryMode
    }

    /// Saves an allowed shortcut; returns the problem otherwise and keeps the old one.
    @discardableResult
    public func setShortcut(_ new: Shortcut) -> Shortcut.Problem? {
        if let problem = new.problem { return problem }
        guard let data = try? JSONEncoder().encode(new) else { return nil }
        defaults.set(data, forKey: RecordingInfo.shortcutDefaultsKey)
        shortcut = new
        Log.write("Shortcut changed", category: .recording)
        return nil
    }

    public func setMode(_ new: ShortcutMode) {
        guard new != mode else { return }
        defaults.set(new.rawValue, forKey: RecordingInfo.modeDefaultsKey)
        mode = new
        Log.write("Shortcut mode changed to \(new)", category: .recording)
    }

    private static func loadShortcut(from defaults: UserDefaults) -> Shortcut {
        guard let data = defaults.data(forKey: RecordingInfo.shortcutDefaultsKey) else { return .factory }
        guard let stored = try? JSONDecoder().decode(Shortcut.self, from: data), stored.isValid else {
            Log.write("Stored shortcut unreadable, using factory setting", category: .recording, level: .error)
            return .factory
        }
        return stored
    }
}

extension ShortcutMode: LogValue {
    public var logDescription: StaticString {
        switch self {
        case .hold: "hold"
        case .toggle: "toggle"
        }
    }
}
