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
        if Self.appleShortcuts.contains(candidate) { return false }
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
        [
            kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10, kVK_F11, kVK_F12,
            kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18, kVK_F19,
        ].map { UInt16($0) })

    /// Apple's program shortcuts with ⌥⌘, ⌥⇧⌘ and ⌃⌘ (BUG-3, BUG-15). Shortcuts
    /// that macOS manages itself are in `macOSDefaults`, so switching one off
    /// in the system settings frees it (BUG-17).
    static let appleShortcuts: Set<SystemShortcut> = {
        let optionCommand: ModifierSet = [.option, .command]
        let optionShiftCommand: ModifierSet = [.option, .shift, .command]
        let controlCommand: ModifierSet = [.control, .command]
        let entries: [(Int, ModifierSet)] = [
            (kVK_ANSI_H, optionCommand),  // hide others
            (kVK_ANSI_M, optionCommand),  // minimise all
            (kVK_ANSI_W, optionCommand),  // close all
            (kVK_ANSI_N, optionCommand),  // new …
            (kVK_ANSI_I, optionCommand),  // inspector
            (kVK_ANSI_S, optionCommand),  // sidebar
            (kVK_ANSI_T, optionCommand),  // toolbar
            (kVK_ANSI_V, optionCommand),  // move file
            (kVK_ANSI_C, optionCommand),  // copy style
            (kVK_ANSI_F, optionCommand),  // search field
            (kVK_ANSI_L, optionCommand),  // downloads
            (kVK_ANSI_P, optionCommand),  // path bar
            (kVK_ANSI_Y, optionCommand),  // slideshow
            (kVK_LeftArrow, optionCommand),  // previous tab
            (kVK_RightArrow, optionCommand),  // next tab
            (kVK_ANSI_V, optionShiftCommand),  // paste and match style
            (kVK_ANSI_Q, optionShiftCommand),  // log out at once
            (kVK_ANSI_F, controlCommand),  // full screen
            (kVK_Space, controlCommand),  // emoji and symbols
            (kVK_ANSI_Q, controlCommand),  // lock screen
            (kVK_ANSI_D, controlCommand),  // look up
            (kVK_ANSI_A, controlCommand),  // annotate
            (kVK_ANSI_T, controlCommand),  // new tab group
        ]
        return Set(entries.map { SystemShortcut(keyCode: UInt16($0.0), modifiers: $0.1) })
    }()

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
        "29": SystemShortcut(keyCode: UInt16(kVK_ANSI_3), modifiers: [.control, .shift, .command]),  // shot clip
        "31": SystemShortcut(keyCode: UInt16(kVK_ANSI_4), modifiers: [.control, .shift, .command]),  // area clip
        "12": SystemShortcut(keyCode: UInt16(kVK_F1), modifiers: .control),  // keyboard access
        "7": SystemShortcut(keyCode: UInt16(kVK_F2), modifiers: .control),  // focus menu bar
        "8": SystemShortcut(keyCode: UInt16(kVK_F3), modifiers: .control),  // focus Dock
        "9": SystemShortcut(keyCode: UInt16(kVK_F4), modifiers: .control),  // focus window
        "10": SystemShortcut(keyCode: UInt16(kVK_F5), modifiers: .control),  // focus toolbar
        "11": SystemShortcut(keyCode: UInt16(kVK_F6), modifiers: .control),  // focus floating window
        "13": SystemShortcut(keyCode: UInt16(kVK_F7), modifiers: .control),  // Tab moves focus
        "57": SystemShortcut(keyCode: UInt16(kVK_F8), modifiers: .control),  // focus status menus
        "52": SystemShortcut(keyCode: UInt16(kVK_ANSI_D), modifiers: [.option, .command]),  // Dock
        "59": SystemShortcut(keyCode: UInt16(kVK_F5), modifiers: .command),  // VoiceOver
        "162": SystemShortcut(keyCode: UInt16(kVK_F5), modifiers: [.option, .command]),  // accessibility shortcuts
        "15": SystemShortcut(keyCode: UInt16(kVK_ANSI_8), modifiers: [.option, .command]),  // zoom
        "17": SystemShortcut(keyCode: UInt16(kVK_ANSI_Equal), modifiers: [.option, .command]),  // zoom in
        "19": SystemShortcut(keyCode: UInt16(kVK_ANSI_Minus), modifiers: [.option, .command]),  // zoom out
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
