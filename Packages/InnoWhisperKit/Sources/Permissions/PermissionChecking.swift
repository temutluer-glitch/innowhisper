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
    /// Answer of the last check outside the app; nil while there is none, then
    /// the app's own reading counts (QA BUG-11).
    private var checkedOutside: PermissionState?
    private let readAccessibility: @MainActor () -> PermissionState
    private let askOutside: @Sendable () async -> PermissionState?

    public convenience init() {
        self.init(
            readAccessibility: { Self.currentAccessibilityState() },
            askOutside: { await Self.askOutsideTheApp() })
    }

    init(
        readAccessibility: @escaping @MainActor () -> PermissionState,
        askOutside: @escaping @Sendable () async -> PermissionState?
    ) {
        self.readAccessibility = readAccessibility
        self.askOutside = askOutside
    }

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
            return checkedOutside ?? readAccessibility()
        }
    }

    nonisolated static func currentAccessibilityState() -> PermissionState {
        accessibilityState(dockAnswer: askDock(), trusted: AXIsProcessTrusted())
    }

    /// Checks Accessibility in a freshly started copy of InnoWhisper. Without
    /// an answer the app's own reading counts again. Logs only what changes,
    /// so a flood of checks cannot fill the log (QA BUG-8, BUG-11).
    public func recheckAccessibility() async {
        let answer = await askOutside()
        guard answer != checkedOutside else { return }
        if let answer {
            Log.write("Accessibility checked outside the app: \(answer)", category: .permissions)
        } else {
            Log.write("Accessibility check outside the app gave no answer, own reading counts", category: .permissions)
        }
        checkedOutside = answer
    }

    /// Starts InnoWhisper's own program a second time, invisibly, with
    /// `accessibilityCheckArgument`; it answers and quits at once. No answer
    /// within 2 seconds, or anything unexpected, means nil. Waits without
    /// blocking a thread.
    nonisolated static func askOutsideTheApp() async -> PermissionState? {
        guard let program = Bundle.main.executableURL else { return nil }
        return await withCheckedContinuation { continuation in
            let check = OutsideCheck(continuation)
            let process = Process()
            process.executableURL = program
            process.arguments = [accessibilityCheckArgument]
            let output = Pipe()
            process.standardOutput = output
            process.standardError = FileHandle.nullDevice
            process.terminationHandler = { finished in
                let text = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                check.finish(finished.terminationStatus == 0 ? parseAnswer(text) : nil)
            }
            do {
                try process.run()
            } catch {
                check.finish(nil)
                return
            }
            check.stopAfterTimeout(process)
        }
    }

    nonisolated static func parseAnswer(_ text: String) -> PermissionState? {
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

/// Hands the answer of one check outside the app back exactly once: from the
/// finished process or, after 2 seconds, from the time limit.
private final class OutsideCheck: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<PermissionState?, Never>?

    init(_ continuation: CheckedContinuation<PermissionState?, Never>) {
        self.continuation = continuation
    }

    func finish(_ answer: PermissionState?) {
        lock.lock()
        let waiting = continuation
        continuation = nil
        lock.unlock()
        waiting?.resume(returning: answer)
    }

    func stopAfterTimeout(_ process: Process) {
        nonisolated(unsafe) let process = process
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [self] in
            if process.isRunning { process.terminate() }
            finish(nil)
        }
    }
}
