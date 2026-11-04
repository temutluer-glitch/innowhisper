import Diagnostics
import Foundation
import Observation

/// What the user chose in the "alte Version läuft noch" dialog.
public enum LegacyPromptChoice: Sendable, LogValue {
    case terminate
    case later

    public var logDescription: StaticString {
        switch self {
        case .terminate: "terminate"
        case .later: "later"
        }
    }
}

/// Result of trying to quit the old app.
public enum LegacyTerminationOutcome: Sendable, Equatable {
    case terminated
    case stillRunning
}

/// Detects and quits the old app (AC-16 to AC-18, EC-2, EC-3).
@MainActor
@Observable
public final class LegacyAppGuard {
    /// Old app and its beta, both still installed on team Macs as "InnoWhisper".
    public static let legacyBundleIdentifiers: Set<String> = [
        "com.innosolv.WhisperDictation",
        "com.innosolv.WhisperDictation.beta",
    ]
    public static let problemID = "legacyAppRunning"
    static let pollInterval: Duration = .milliseconds(250)
    static let politeTimeout: Duration = .seconds(2)
    static let totalTimeout: Duration = .seconds(5)

    /// Hooks into the UI; set by the app before `start()`.
    public struct Presenter {
        public var askWhatToDo: @MainActor () async -> LegacyPromptChoice
        public var showTerminated: @MainActor () -> Void
        /// Receives the ready-made step-by-step text (EC-3).
        public var showManualInstructions: @MainActor (String) -> Void

        public init(
            askWhatToDo: @escaping @MainActor () async -> LegacyPromptChoice,
            showTerminated: @escaping @MainActor () -> Void,
            showManualInstructions: @escaping @MainActor (String) -> Void
        ) {
            self.askWhatToDo = askWhatToDo
            self.showTerminated = showTerminated
            self.showManualInstructions = showManualInstructions
        }
    }

    public private(set) var isPrompting = false
    @ObservationIgnored private let apps: RunningApplicationsProviding
    @ObservationIgnored private let problems: ProblemCenter
    @ObservationIgnored private let presenter: Presenter
    @ObservationIgnored private let sleep: @MainActor (Duration) async -> Void
    @ObservationIgnored private var knownLegacyPIDs: Set<pid_t> = []

    public init(
        apps: RunningApplicationsProviding,
        problems: ProblemCenter,
        presenter: Presenter,
        sleep: @escaping @MainActor (Duration) async -> Void = { try? await Task.sleep(for: $0) }
    ) {
        self.apps = apps
        self.problems = problems
        self.presenter = presenter
        self.sleep = sleep
    }

    /// Checks at launch and whenever an app launches or quits.
    public func start() {
        apps.observeChanges { [weak self] in
            guard let self else { return }
            Task { await self.check() }
        }
        Task { await check() }
    }

    /// Running instances of the old app.
    public func legacyApps() -> [RunningApp] {
        apps.runningApps().filter { app in
            app.bundleIdentifier.map(Self.legacyBundleIdentifiers.contains) ?? false
        }
    }

    /// Asks the user when a newly seen old app runs (AC-16, EC-2); clears the
    /// problem once none runs any more (AC-18).
    public func check() async {
        let running = legacyApps()
        let pids = Set(running.map(\.pid))
        guard !pids.isEmpty else {
            knownLegacyPIDs = []
            problems.withdraw(id: Self.problemID)
            return
        }
        let newlySeen = !pids.subtracting(knownLegacyPIDs).isEmpty
        Log.write("Legacy app running: \(pids.count) instance(s), new: \(newlySeen)", category: .appShell)
        knownLegacyPIDs = pids
        guard newlySeen, !isPrompting else { return }

        isPrompting = true
        let choice = await presenter.askWhatToDo()
        Log.write("Legacy prompt answered: \(choice)", category: .appShell)
        isPrompting = false
        switch choice {
        case .terminate:
            await terminateLegacyApps()
        case .later:
            reportProblem()
        }
    }

    /// Quits all old app instances: normally, after 2 s immediately, after
    /// 5 s in total the manual instructions (AC-17, EC-3).
    @discardableResult
    public func terminateLegacyApps() async -> LegacyTerminationOutcome {
        let targets = legacyApps()
        guard !targets.isEmpty else {
            problems.withdraw(id: Self.problemID)
            return .terminated
        }
        for target in targets { apps.terminate(pid: target.pid) }

        var waited: Duration = .zero
        var forced = false
        while waited < Self.totalTimeout {
            if legacyApps().isEmpty {
                knownLegacyPIDs = []
                problems.withdraw(id: Self.problemID)
                presenter.showTerminated()
                return .terminated
            }
            if !forced, waited >= Self.politeTimeout {
                Log.write("Legacy app ignored polite quit, forcing", category: .appShell)
                for app in legacyApps() { apps.forceTerminate(pid: app.pid) }
                forced = true
            }
            await sleep(Self.pollInterval)
            waited += Self.pollInterval
        }
        if legacyApps().isEmpty {
            knownLegacyPIDs = []
            problems.withdraw(id: Self.problemID)
            presenter.showTerminated()
            return .terminated
        }
        Log.write("Legacy app still running after 5 s", category: .appShell)
        reportProblem()
        presenter.showManualInstructions(Self.manualInstructions(for: legacyApps()))
        return .stillRunning
    }

    /// Steps to quit the old app by hand (EC-3). Activity Monitor shows the
    /// old app as "InnoWhisper" — the same name as the new one — so the PID
    /// tells them apart. Never names the internal executable.
    public static func manualInstructions(for apps: [RunningApp]) -> String {
        let pids = apps.map { String($0.pid) }.joined(separator: ", ")
        let which =
            apps.count == 1 ? "die Zeile mit der Nummer (PID) \(pids)" : "die Zeilen mit den Nummern (PID) \(pids)"
        return """
            So beendest du sie selbst:
            1. Öffne das Programm Aktivitätsanzeige.
            2. Tippe oben rechts ins Suchfeld: InnoWhisper
            3. Markiere \(which). Die neue InnoWhisper hat eine andere Nummer.
            4. Klicke oben auf das ⓧ-Symbol, dann auf Sofort beenden.
            """
    }

    private func reportProblem() {
        problems.report(
            Problem(
                id: Self.problemID,
                section: nil,
                message: "Die alte Version läuft noch und stört das Diktieren.",
                actionTitle: "Alte Version beenden",
                action: { [weak self] in
                    guard let self else { return }
                    Task { await self.terminateLegacyApps() }
                }
            ))
    }
}
