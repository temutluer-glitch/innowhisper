import Observation

/// Hands every shortcut or mode change from the settings to the watcher
/// (AC-16, AC-17). The watcher keeps a running recording on the old one.
@MainActor
public final class ShortcutFollower {
    private let store: ShortcutStore
    private let monitor: HotkeyMonitor

    public init(store: ShortcutStore, monitor: HotkeyMonitor) {
        self.store = store
        self.monitor = monitor
    }

    public func start() {
        let (shortcut, mode) = withObservationTracking {
            (store.shortcut, store.mode)
        } onChange: { [weak self] in
            Task { @MainActor in self?.start() }
        }
        // Always hand over the latest choice: comparing with the watcher's active
        // setting misses a change back while an earlier one is still waiting (BUG-13).
        monitor.update(shortcut: shortcut, mode: mode)
    }
}
