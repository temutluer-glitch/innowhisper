import AVFAudio
import AVFoundation
import AppKit
import ApplicationServices
import Diagnostics

/// Asks macOS about permissions. The real one talks to the system; tests use
/// a stand-in.
@MainActor
public protocol PermissionChecking: AnyObject {
    func state(of kind: PermissionKind) -> PermissionState
    /// Shows the macOS microphone question (only works while not determined).
    func requestMicrophone() async
    /// Puts InnoWhisper into the Accessibility list of System Settings.
    func registerForAccessibility()
    /// Checks Accessibility again outside the running app, whose own answer
    /// can be stale after the switch in System Settings changed.
    func recheckAccessibility() async
}

extension PermissionChecking {
    public func recheckAccessibility() async {}
}

@MainActor
public final class SystemPermissionChecker: PermissionChecking {
    /// Argument that makes InnoWhisper answer the Accessibility check and quit.
    public nonisolated static let accessibilityCheckArgument = "--check-accessibility"
    /// Answer of the last check outside the app; nil until the list first changes.
    private var checkedOutside: PermissionState?

    public init() {}

    public func state(of kind: PermissionKind) -> PermissionState {
        switch kind {
        case .microphone:
            // AVAudioApplication asks macOS every time. AVCaptureDevice keeps the
            // answer it had at launch, so a switch flipped in System Settings
            // would go unnoticed until a restart (measured, design.md → Bau-Notizen).
            switch AVAudioApplication.shared.recordPermission {
            case .granted: return .granted
            case .undetermined:
                // A grant given through an older AVCaptureDevice question is only
                // known there; never show "not asked" for a microphone that works.
                return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized ? .granted : .notDetermined
            case .denied:
                // Only AVCaptureDevice knows "restricted" (a rule set by the Mac's admin).
                return AVCaptureDevice.authorizationStatus(for: .audio) == .restricted ? .restricted : .denied
            @unknown default: return .denied
            }
        case .accessibility:
            // AXIsProcessTrusted() can keep a stale answer after the switch in
            // System Settings changes, and asking for the focused app succeeds
            // whenever InnoWhisper itself is in front. Asking the Dock followed
            // every switch within half a second (measured 05.11.2026,
            // design.md → Bau-Notizen).
            // After a change of the list, a freshly started process answers
            // correctly every time; the running one sometimes does not (QA BUG-1).
            return checkedOutside ?? Self.currentAccessibilityState()
        }
    }

    nonisolated static func currentAccessibilityState() -> PermissionState {
        accessibilityState(dockAnswer: askDock(), trusted: AXIsProcessTrusted())
    }

    /// Starts InnoWhisper's own program a second time, invisibly, with
    /// `accessibilityCheckArgument`; it answers and quits at once. Without an
    /// answer within 2 seconds the app keeps its own reading.
    public func recheckAccessibility() async {
        guard let program = Bundle.main.executableURL else { return }
        let started = ContinuousClock.now
        let answer = await Task.detached { Self.runCheck(program: program) }.value
        let took = ContinuousClock.now - started
        if let answer {
            checkedOutside = answer
            Log.write("Accessibility checked outside the app: \(answer), took \(took)", category: .permissions)
        } else {
            Log.write("Accessibility check outside the app gave no answer, took \(took)", category: .permissions)
        }
    }

    nonisolated private static func runCheck(program: URL) -> PermissionState? {
        let process = Process()
        process.executableURL = program
        process.arguments = [accessibilityCheckArgument]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return nil }
        let deadline = Date().addingTimeInterval(2)
        while process.isRunning && Date() < deadline { usleep(20_000) }
        if process.isRunning {
            process.terminate()
            return nil
        }
        let text = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        switch text.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "granted": return .granted
        case "denied": return .denied
        default: return nil
        }
    }

    /// Called first thing at launch: when started as the check, answer and quit
    /// before anything else (no window, no menu bar item, no log entry).
    public nonisolated static func answerAccessibilityCheckIfAsked(arguments: [String] = CommandLine.arguments) {
        guard arguments.contains(accessibilityCheckArgument) else { return }
        print(currentAccessibilityState() == .granted ? "granted" : "denied")
        exit(0)
    }

    /// What the Dock's answer says about the permission. macOS refuses the
    /// call with "API disabled" when the switch is off; without a usable
    /// answer (Dock busy or not running) the system's own flag decides.
    nonisolated static func accessibilityState(dockAnswer: AXError?, trusted: Bool) -> PermissionState {
        switch dockAnswer {
        case .apiDisabled?: return .denied
        case .cannotComplete?, nil: return trusted ? .granted : .denied
        default: return .granted
        }
    }

    nonisolated private static func askDock() -> AXError? {
        guard
            let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first
        else { return nil }
        let element = AXUIElementCreateApplication(dock.processIdentifier)
        AXUIElementSetMessagingTimeout(element, 0.5)
        var role: CFTypeRef?
        return AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
    }

    public func requestMicrophone() async {
        // Ask through the same interface that `state(of:)` reads, otherwise the
        // answer stays unseen until a restart (PROJ-3 BUG-7).
        _ = await AVAudioApplication.requestRecordPermission()
    }

    /// Makes InnoWhisper appear in the Accessibility list without the macOS
    /// question window: that window would open next to System Settings, which
    /// open anyway (design.md → Bau-Notizen). An Accessibility call that macOS
    /// refuses is what puts the app on the list.
    public func registerForAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": false] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        _ = Self.askDock()
    }
}
