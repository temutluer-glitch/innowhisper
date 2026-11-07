import AppKit
import CoreGraphics
import SwiftUI

/// Turns the keys pressed while the field records into a shortcut (AC-16).
/// Pure, so the rules are testable without a window.
struct ShortcutRecording: Equatable {
    enum Outcome: Equatable {
        /// Still waiting for keys.
        case waiting
        /// Esc without other keys: recording ends, old shortcut stays.
        case cancelled
        /// A key without ⌘, ⌥, ⌃ or ⇧: show a hint, keep recording.
        case needsModifier
        case recorded(Shortcut)
    }

    private var held: Set<ModifierKey> = []
    /// The one modifier pressed alone so far; cleared by any other key.
    private var loneCandidate: ModifierKey?

    /// A modifier went down or up; `held` is the full set held afterwards.
    mutating func modifiersChanged(to newHeld: Set<ModifierKey>) -> Outcome {
        defer { held = newHeld }
        if newHeld.count > held.count {
            // Pressed: a candidate only while it is the only modifier.
            loneCandidate = newHeld.count == 1 ? newHeld.first : nil
            return .waiting
        }
        // Released: a lone modifier pressed and released without other keys.
        if newHeld.isEmpty, let key = loneCandidate {
            loneCandidate = nil
            return .recorded(.modifierOnly(key))
        }
        return .waiting
    }

    mutating func keyDown(keyCode: UInt16, families: ModifierSet) -> Outcome {
        loneCandidate = nil
        if keyCode == KeyInterpreter.escapeKeyCode && families.isEmpty { return .cancelled }
        let shortcut = Shortcut.combination(keyCode: keyCode, modifiers: families)
        switch shortcut.problem {
        case .none: return .recorded(shortcut)
        case .needsModifier, .escapeNotAllowed: return .needsModifier
        case .modifierAsMainKey: return .waiting
        }
    }
}

/// The "Tastenkürzel" field: shows the shortcut; a click records a new one
/// (AC-16, AC-18). The shortcut watcher is paused while recording.
struct ShortcutField: View {
    let store: ShortcutStore
    let availability: ShortcutAvailability
    let onRecordingChanged: @MainActor (Bool) -> Void

    @State private var isRecording = false
    @State private var message: String?
    @State private var monitor: Any?
    @State private var focusObserver: NSObjectProtocol?
    @State private var recording = ShortcutRecording()

    static let needsModifierText = "Drücke dazu mindestens ⌘, ⌥, ⌃ oder ⇧."

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Button(isRecording ? "Taste drücken …" : store.shortcut.displayName) {
                isRecording ? stop() : start()
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .accessibilityLabel("Tastenkürzel: \(store.shortcut.displayName)")
            .accessibilityHint(isRecording ? "Drücke jetzt die neue Taste, Esc bricht ab." : "Klicken, um zu ändern.")
            if let message {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onDisappear { stop() }
    }

    private func start() {
        message = nil
        recording = ShortcutRecording()
        isRecording = true
        onRecordingChanged(true)
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            MainActor.assumeIsolated { handle(event) }
            return nil
        }
        // macOS handles its own shortcuts (⌘ Leertaste opens Spotlight) before
        // InnoWhisper sees the key; the settings window then loses the keyboard.
        // That means: taken. Never record the lone modifier left behind.
        focusObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { takenBySystem() }
        }
    }

    private func takenBySystem() {
        guard isRecording else { return }
        stop()
        message = RecordingTexts.shortcutTaken
    }

    private func stop() {
        guard isRecording else { return }
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        if let focusObserver { NotificationCenter.default.removeObserver(focusObserver) }
        focusObserver = nil
        isRecording = false
        onRecordingChanged(false)
    }

    private func handle(_ event: NSEvent) {
        let flags = CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
        let outcome: ShortcutRecording.Outcome
        if event.type == .flagsChanged {
            outcome = recording.modifiersChanged(to: HotkeyMonitor.heldModifiers(in: flags))
        } else {
            outcome = recording.keyDown(keyCode: event.keyCode, families: HotkeyMonitor.families(in: flags))
        }
        switch outcome {
        case .waiting:
            break
        case .cancelled:
            stop()
        case .needsModifier:
            message = Self.needsModifierText
        case .recorded(let shortcut):
            stop()
            guard availability.isFree(shortcut) else {
                message = RecordingTexts.shortcutTaken
                return
            }
            if store.setShortcut(shortcut) != nil {
                message = Self.needsModifierText
            } else {
                message = nil
            }
        }
    }
}
