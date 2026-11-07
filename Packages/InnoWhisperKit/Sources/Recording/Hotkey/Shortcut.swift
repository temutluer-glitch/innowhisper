import Carbon.HIToolbox
import Foundation

/// A single modifier key on one side of the keyboard (design.md → Datenmodell).
public enum ModifierKey: String, CaseIterable, Codable, Sendable {
    case rightCommand
    case leftCommand
    case rightOption
    case leftOption
    case rightControl
    case leftControl
    case rightShift
    case leftShift

    /// Hardware key code macOS reports for this key.
    public var keyCode: UInt16 {
        switch self {
        case .rightCommand: UInt16(kVK_RightCommand)
        case .leftCommand: UInt16(kVK_Command)
        case .rightOption: UInt16(kVK_RightOption)
        case .leftOption: UInt16(kVK_Option)
        case .rightControl: UInt16(kVK_RightControl)
        case .leftControl: UInt16(kVK_Control)
        case .rightShift: UInt16(kVK_RightShift)
        case .leftShift: UInt16(kVK_Shift)
        }
    }

    /// The family the key belongs to (⌘, ⌥, ⌃ or ⇧).
    public var family: ModifierSet {
        switch self {
        case .rightCommand, .leftCommand: .command
        case .rightOption, .leftOption: .option
        case .rightControl, .leftControl: .control
        case .rightShift, .leftShift: .shift
        }
    }

    public var isRight: Bool {
        switch self {
        case .rightCommand, .rightOption, .rightControl, .rightShift: true
        default: false
        }
    }

    /// "rechte ⌘", "linke ⌥" …
    public var displayName: String {
        "\(isRight ? "rechte" : "linke") \(family.symbols)"
    }

    public init?(keyCode: UInt16) {
        guard let key = Self.allCases.first(where: { $0.keyCode == keyCode }) else { return nil }
        self = key
    }
}

/// The modifier families pressed together with a main key.
public struct ModifierSet: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let control = ModifierSet(rawValue: 1 << 0)
    public static let option = ModifierSet(rawValue: 1 << 1)
    public static let shift = ModifierSet(rawValue: 1 << 2)
    public static let command = ModifierSet(rawValue: 1 << 3)

    /// In the macOS order: ⌃ ⌥ ⇧ ⌘.
    public var symbols: String {
        var text = ""
        if contains(.control) { text += "⌃" }
        if contains(.option) { text += "⌥" }
        if contains(.shift) { text += "⇧" }
        if contains(.command) { text += "⌘" }
        return text
    }
}

/// How the shortcut starts and ends a recording (AC-2, AC-3).
public enum ShortcutMode: String, CaseIterable, Codable, Sendable {
    case hold
    case toggle

    public var title: String {
        switch self {
        case .hold: "Halten"
        case .toggle: "Ein/aus"
        }
    }
}

/// The one shortcut of PROJ-5: a lone modifier or a combination (design.md → Datenmodell).
public enum Shortcut: Equatable, Codable, Sendable {
    case modifierOnly(ModifierKey)
    case combination(keyCode: UInt16, modifiers: ModifierSet)

    /// Right ⌘ alone (AC-1).
    public static let factory = Shortcut.modifierOnly(.rightCommand)
    public static let factoryMode = ShortcutMode.hold

    /// Why an entered shortcut is not allowed (AC-16).
    public enum Problem: Equatable, Sendable {
        case needsModifier
        case escapeNotAllowed
        case modifierAsMainKey
    }

    /// `nil` when the shortcut may be used (AC-16).
    public var problem: Problem? {
        switch self {
        case .modifierOnly:
            return nil
        case .combination(let keyCode, let modifiers):
            if keyCode == UInt16(kVK_Escape) { return .escapeNotAllowed }
            if ModifierKey(keyCode: keyCode) != nil || Self.otherModifierKeyCodes.contains(keyCode) {
                return .modifierAsMainKey
            }
            if modifiers.isEmpty { return .needsModifier }
            return nil
        }
    }

    public var isValid: Bool { problem == nil }

    /// "rechte ⌘", "⌥ Leertaste" …
    public var displayName: String {
        switch self {
        case .modifierOnly(let key):
            key.displayName
        case .combination(let keyCode, let modifiers):
            "\(modifiers.symbols) \(Self.keyName(for: keyCode))"
        }
    }

    /// Caps Lock and Fn are modifiers too, but never a main key.
    static let otherModifierKeyCodes: Set<UInt16> = [UInt16(kVK_CapsLock), UInt16(kVK_Function)]

    /// Readable name of a main key, independent of the keyboard layout for
    /// special keys and from the current layout for character keys.
    public static func keyName(for keyCode: UInt16) -> String {
        if let special = specialKeyNames[keyCode] { return special }
        if let character = layoutCharacter(for: keyCode) { return character.uppercased() }
        return "Taste \(keyCode)"
    }

    static let specialKeyNames: [UInt16: String] = [
        UInt16(kVK_Space): "Leertaste", UInt16(kVK_Return): "↩", UInt16(kVK_Tab): "⇥",
        UInt16(kVK_Delete): "⌫", UInt16(kVK_ForwardDelete): "⌦", UInt16(kVK_LeftArrow): "←",
        UInt16(kVK_RightArrow): "→", UInt16(kVK_UpArrow): "↑", UInt16(kVK_DownArrow): "↓",
        UInt16(kVK_Home): "↖", UInt16(kVK_End): "↘", UInt16(kVK_PageUp): "⇞", UInt16(kVK_PageDown): "⇟",
        UInt16(kVK_F1): "F1", UInt16(kVK_F2): "F2", UInt16(kVK_F3): "F3", UInt16(kVK_F4): "F4",
        UInt16(kVK_F5): "F5", UInt16(kVK_F6): "F6", UInt16(kVK_F7): "F7", UInt16(kVK_F8): "F8",
        UInt16(kVK_F9): "F9", UInt16(kVK_F10): "F10", UInt16(kVK_F11): "F11", UInt16(kVK_F12): "F12",
    ]

    private static func layoutCharacter(for keyCode: UInt16) -> String? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
            let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }
        let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue() as Data
        return data.withUnsafeBytes { buffer -> String? in
            guard let layout = buffer.bindMemory(to: UCKeyboardLayout.self).baseAddress else { return nil }
            var deadKeyState: UInt32 = 0
            var characters = [UniChar](repeating: 0, count: 4)
            var length = 0
            let status = UCKeyTranslate(
                layout, keyCode, UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit), &deadKeyState, characters.count, &length, &characters)
            guard status == noErr, length > 0 else { return nil }
            let text = String(utf16CodeUnits: characters, count: length)
            return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text
        }
    }
}
