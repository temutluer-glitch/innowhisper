import SwiftUI

/// Area "Aufnahme" (AC-12, AC-16 to AC-18): shortcut, mode and microphone.
/// Same building blocks and sizes as "Zugang & Erlaubnisse".
public struct RecordingSettingsPane: View {
    let shortcuts: ShortcutStore
    let microphone: MicrophoneChoiceStore
    let microphones: MicrophoneList
    let availability: ShortcutAvailability
    let onRecordingShortcut: @MainActor (Bool) -> Void

    public init(
        shortcuts: ShortcutStore,
        microphone: MicrophoneChoiceStore,
        microphones: MicrophoneList,
        availability: ShortcutAvailability = ShortcutAvailability(),
        onRecordingShortcut: @escaping @MainActor (Bool) -> Void
    ) {
        self.shortcuts = shortcuts
        self.microphone = microphone
        self.microphones = microphones
        self.availability = availability
        self.onRecordingShortcut = onRecordingShortcut
    }

    public var body: some View {
        Form {
            Section("Tastenkürzel") {
                LabeledContent {
                    ShortcutField(store: shortcuts, availability: availability, onRecordingChanged: onRecordingShortcut)
                } label: {
                    Text("Kürzel")
                    Text(ShortcutHint.text(for: shortcuts.shortcut, mode: shortcuts.mode))
                }
                Picker("Modus", selection: modeBinding) {
                    ForEach(ShortcutMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section("Mikrofon") {
                MicrophonePicker(store: microphone, list: microphones)
            }
        }
        .formStyle(.grouped)
    }

    private var modeBinding: Binding<ShortcutMode> {
        Binding(get: { shortcuts.mode }, set: { shortcuts.setMode($0) })
    }
}

/// How to use the current shortcut, e.g. "Halte die rechte ⌘-Taste und sprich." (AC-19).
enum ShortcutHint {
    static func text(for shortcut: Shortcut, mode: ShortcutMode) -> String {
        let keys: String
        switch shortcut {
        case .modifierOnly(let key): keys = "die \(key.isRight ? "rechte" : "linke") \(key.family.symbols)-Taste"
        case .combination: keys = shortcut.displayName
        }
        switch mode {
        case .hold: return "Halte \(keys) und sprich."
        case .toggle: return "Drücke \(keys) zum Starten und noch einmal zum Beenden."
        }
    }
}
