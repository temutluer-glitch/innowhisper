import Carbon.HIToolbox
import Foundation

/// Tells whether macOS or another app already uses a shortcut (AC-18).
/// Two sources: the system shortcuts of macOS (Spotlight, screenshots …) and
/// a probe registration through Carbon, which fails for combinations another
/// app holds exclusively. A lone modifier (right ⌘ …) is never checked.
public struct ShortcutAvailability {
    /// One system shortcut as macOS stores it.
    struct SystemShortcut: Hashable {
        let keyCode: UInt16
        let modifiers: ModifierSet
    }

    private let systemShortcuts: () -> [String: Any]?
    private let probe: (UInt16, ModifierSet) -> Bool

    /// - Parameters:
    ///   - systemShortcuts: the `AppleSymbolicHotKeys` dictionary of macOS.
    ///   - probe: returns true when the combination can be registered.
    init(
        systemShortcuts: @escaping () -> [String: Any]? = Self.readSystemShortcuts,
        probe: @escaping (UInt16, ModifierSet) -> Bool = Self.carbonProbe
    ) {
        self.systemShortcuts = systemShortcuts
        self.probe = probe
    }

    public init() {
        self.init(systemShortcuts: Self.readSystemShortcuts, probe: Self.carbonProbe)
    }

    /// True when the shortcut is free to use.
    public func isFree(_ shortcut: Shortcut) -> Bool {
        guard case .combination(let keyCode, let modifiers) = shortcut else { return true }
        let candidate = SystemShortcut(keyCode: keyCode, modifiers: modifiers)
        if Self.isStandardProgramShortcut(keyCode: keyCode, modifiers: modifiers) { return false }
        if takenBySystem().contains(candidate) { return false }
        return probe(keyCode, modifiers)
    }

    /// Enabled system shortcuts: the stored ones plus the macOS defaults
    /// that are missing from the store (macOS only stores changed entries).
    func takenBySystem() -> Set<SystemShortcut> {
        let stored = systemShortcuts() ?? [:]
        var taken = Set<SystemShortcut>()
        var storedIDs = Set<String>()
        for (id, value) in stored {
            storedIDs.insert(id)
            guard let entry = value as? [String: Any], Self.isEnabled(entry["enabled"]),
                let shortcut = Self.parse(entry["value"])
            else { continue }
            taken.insert(shortcut)
        }
        for (id, shortcut) in Self.macOSDefaults where !storedIDs.contains(id) {
            taken.insert(shortcut)
        }
        return taken
    }

    /// ⌘ or ⇧⌘ with any key except F1 to F12 and the space bar: what programs
    /// use for their own commands (⌘C, ⌘Q, ⇧⌘Z, ⌘Tab, ⌘← …). Taking one of them
    /// would break it in every program (BUG-3). ⌘ Leertaste belongs to macOS
    /// (Spotlight) and is judged by the system shortcuts above.
    static func isStandardProgramShortcut(keyCode: UInt16, modifiers: ModifierSet) -> Bool {
        guard modifiers.contains(.command), modifiers.isSubset(of: [.command, .shift]) else { return false }
        return !functionKeys.contains(keyCode) && keyCode != UInt16(kVK_Space)
    }

    static let functionKeys: Set<UInt16> = Set(
        [kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10, kVK_F11, kVK_F12].map {
            UInt16($0)
        })

    /// Default system shortcuts of macOS by their id in `AppleSymbolicHotKeys`.
    static let macOSDefaults: [String: SystemShortcut] = [
        "64": SystemShortcut(keyCode: UInt16(kVK_Space), modifiers: .command),  // Spotlight
        "65": SystemShortcut(keyCode: UInt16(kVK_Space), modifiers: [.command, .option]),  // Finder search
        "60": SystemShortcut(keyCode: UInt16(kVK_Space), modifiers: .control),  // previous input source
        "61": SystemShortcut(keyCode: UInt16(kVK_Space), modifiers: [.control, .option]),  // next input source
        "28": SystemShortcut(keyCode: UInt16(kVK_ANSI_3), modifiers: [.command, .shift]),  // screenshot
        "30": SystemShortcut(keyCode: UInt16(kVK_ANSI_4), modifiers: [.command, .shift]),  // screenshot area
        "184": SystemShortcut(keyCode: UInt16(kVK_ANSI_5), modifiers: [.command, .shift]),  // screenshot tools
        "32": SystemShortcut(keyCode: UInt16(kVK_UpArrow), modifiers: .control),  // Mission Control
        "33": SystemShortcut(keyCode: UInt16(kVK_DownArrow), modifiers: .control),  // app windows
        "79": SystemShortcut(keyCode: UInt16(kVK_LeftArrow), modifiers: .control),  // space left
        "81": SystemShortcut(keyCode: UInt16(kVK_RightArrow), modifiers: .control),  // space right
    ]

    private static func isEnabled(_ value: Any?) -> Bool {
        (value as? Bool) ?? ((value as? Int).map { $0 != 0 } ?? false)
    }

    /// `value.parameters` = [character, key code, modifier flags as NSEvent stores them].
    private static func parse(_ value: Any?) -> SystemShortcut? {
        guard let value = value as? [String: Any], let parameters = value["parameters"] as? [Int],
            parameters.count == 3, (0...0xFFFF).contains(parameters[1])
        else { return nil }
        return SystemShortcut(keyCode: UInt16(parameters[1]), modifiers: modifierSet(fromEventFlags: parameters[2]))
    }

    /// NSEvent modifier flag bits: ⇧ 1<<17, ⌃ 1<<18, ⌥ 1<<19, ⌘ 1<<20.
    static func modifierSet(fromEventFlags flags: Int) -> ModifierSet {
        var set = ModifierSet()
        if flags & (1 << 17) != 0 { set.insert(.shift) }
        if flags & (1 << 18) != 0 { set.insert(.control) }
        if flags & (1 << 19) != 0 { set.insert(.option) }
        if flags & (1 << 20) != 0 { set.insert(.command) }
        return set
    }

    static func readSystemShortcuts() -> [String: Any]? {
        UserDefaults(suiteName: "com.apple.symbolichotkeys")?.dictionary(forKey: "AppleSymbolicHotKeys")
    }

    /// Registers and immediately releases the combination; fails while another app holds it.
    static func carbonProbe(keyCode: UInt16, modifiers: ModifierSet) -> Bool {
        var carbonModifiers: UInt32 = 0
        if modifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if modifiers.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if modifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        if modifiers.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        var reference: EventHotKeyRef?
        let id = EventHotKeyID(signature: OSType(0x494E_5748), id: 1)  // "INWH"
        let status = RegisterEventHotKey(
            UInt32(keyCode), carbonModifiers, id, GetApplicationEventTarget(), OptionBits(0), &reference)
        if let reference { UnregisterEventHotKey(reference) }
        return status == noErr
    }
}
