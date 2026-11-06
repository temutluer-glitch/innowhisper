import AppShell
import Diagnostics
import Foundation
import Network
import Observation

/// State of the stored key (design.md → Datenmodell).
public enum KeyStatus: String, Sendable, Equatable, LogValue {
    case valid
    case unchecked
    case invalid
    /// Nothing in the keychain; never stored as such.
    case missing

    public var logDescription: StaticString {
        switch self {
        case .valid: "valid"
        case .unchecked: "unchecked"
        case .invalid: "invalid"
        case .missing: "missing"
        }
    }

    public var title: String {
        switch self {
        case .valid: "Schlüssel funktioniert"
        case .unchecked: "Noch nicht geprüft"
        case .invalid: "Ungültig"
        case .missing: "Kein Schlüssel"
        }
    }
}

extension KeyCheckResult: LogValue {
    public var logDescription: StaticString {
        switch self {
        case .valid: "valid"
        case .rejected: "rejected"
        case .unreachable: "unreachable"
        }
    }
}

/// What the last action in the key field led to; shown below the field.
public enum KeyEntryResult: Equatable, Sendable {
    case works
    case rejected
    case savedUnchecked
    case saveFailed
    case removeFailed
    case takeoverFailed
    /// "Prüfen" in the settings without an answer; the state stays.
    case notReachable

    public var isSuccess: Bool { self == .works }

    public var message: String {
        switch self {
        case .works: "Schlüssel funktioniert."
        case .rejected: "Groq lehnt diesen Schlüssel ab. Prüfe, ob du ihn vollständig kopiert hast."
        case .savedUnchecked: "Groq ist gerade nicht erreichbar. Der Schlüssel wird gespeichert und später geprüft."
        case .saveFailed: "Der Schlüssel konnte nicht gespeichert werden. Bitte versuche es noch einmal."
        case .removeFailed: "Der Schlüssel konnte nicht entfernt werden. Bitte versuche es noch einmal."
        case .takeoverFailed: "Übernahme hat nicht geklappt. Füge deinen Schlüssel einfach unten ein."
        case .notReachable: "Groq ist gerade nicht erreichbar. Versuche es später noch einmal."
        }
    }
}

/// The Groq access for the whole app (design.md → Abläufe): checks, stores,
/// takes over and removes the key, and reports a missing or invalid key as a
/// problem once the onboarding is done (AC-2 to AC-18).
@MainActor
@Observable
public final class GroqKeyModel {
    public private(set) var status: KeyStatus = .missing
    /// Last 4 characters of the stored key, for display only (AC-11, AC-17).
    public private(set) var lastFour: String?
    public private(set) var isChecking = false
    public private(set) var lastResult: KeyEntryResult?
    /// Whether the old app has a key; set when the onboarding step appears (AC-7, EC-9).
    public private(set) var legacyKeyAvailable = false
    /// Set by the problem button so the settings group opens with the key field (AC-14).
    public var wantsEdit = false

    /// Set by the app while the onboarding window is open.
    public var onboardingIsOpen = false {
        didSet {
            guard onboardingIsOpen != oldValue else { return }
            updateProblems()
        }
    }

    /// Opens the settings at "Zugang & Erlaubnisse"; set by the app.
    @ObservationIgnored public var showSettings: @MainActor () -> Void = {}

    @ObservationIgnored private let store: KeyStoring
    @ObservationIgnored private let legacy: LegacyKeyReading
    @ObservationIgnored private let checker: KeyChecking
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let problems: ProblemCenter
    @ObservationIgnored private let onboardingFinishedOnce: @MainActor () -> Bool
    @ObservationIgnored private var network: NWPathMonitor?
    /// Counts confirmed removals; a check that started before one must not
    /// write its result afterwards (BUG-1).
    @ObservationIgnored private var removals = 0

    public init(
        store: KeyStoring = SystemKeyStore(),
        legacy: LegacyKeyReading = SystemLegacyKeyReader(),
        checker: KeyChecking = KeyValidator(),
        defaults: UserDefaults = .standard,
        problems: ProblemCenter,
        onboardingFinishedOnce: @escaping @MainActor () -> Bool
    ) {
        self.store = store
        self.legacy = legacy
        self.checker = checker
        self.defaults = defaults
        self.problems = problems
        self.onboardingFinishedOnce = onboardingFinishedOnce
        loadStoredKey()
    }

    /// The onboarding step counts as done with a working or not yet checked key (AC-2, AC-10).
    public var isUsable: Bool { status == .valid || status == .unchecked }

    /// Checks the stored key once and watches for the network coming back (AC-10, AC-14).
    public func start() {
        updateProblems()
        Task { await checkStored() }
        guard network == nil else { return }
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }
            Task { @MainActor in await self?.networkBecameAvailable() }
        }
        monitor.start(queue: DispatchQueue(label: "com.innosolv.InnoWhisper.groq.network"))
        network = monitor
    }

    /// Whether "Prüfen" can be pressed for this input (EC-2, EC-3).
    public func canCheck(_ input: String) -> Bool {
        !isChecking && Self.trimmed(input) != nil
    }

    /// Clears the result line when the user types again.
    public func clearResult() {
        lastResult = nil
    }

    /// "Prüfen" in the onboarding step or after "Ändern" (AC-4 to AC-6, AC-10, AC-12).
    public func submit(_ input: String) async {
        guard !isChecking, let key = Self.trimmed(input) else { return }
        guard Self.isWellFormed(key) else {
            Log.write("Key not checked: malformed input", category: .groq)
            lastResult = .rejected
            return
        }
        await checkAndSave(key)
    }

    /// Looks whether the old app has a key, without reading it (AC-7, EC-9).
    public func lookForLegacyKey() {
        legacyKeyAvailable = status == .missing && legacy.hasKey()
    }

    /// "Schlüssel übernehmen": reads the old app's key (macOS may ask), then checks it (AC-8, AC-9).
    public func takeOver() async {
        guard !isChecking else { return }
        let key: String
        do {
            key = try legacy.read()
        } catch {
            Log.write("Takeover from old app failed: status \(Int(error.status))", category: .groq, level: .error)
            lastResult = .takeoverFailed
            return
        }
        guard let trimmed = Self.trimmed(key), Self.isWellFormed(trimmed) else {
            Log.write("Takeover from old app failed: malformed key", category: .groq, level: .error)
            lastResult = .takeoverFailed
            return
        }
        Log.write("Key taken over from old app", category: .groq)
        await checkAndSave(trimmed)
    }

    /// "Entfernen" after the confirmation (AC-13, AC-15).
    public func remove() {
        do {
            try store.delete()
        } catch {
            Log.write("Key could not be removed: status \(Int(error.status))", category: .groq, level: .error)
            lastResult = .removeFailed
            return
        }
        Log.write("Key removed", category: .groq)
        removals += 1
        status = .missing
        lastFour = nil
        lastResult = nil
        defaults.removeObject(forKey: GroqAccessInfo.statusDefaultsKey)
        updateProblems()
    }

    /// Checks the stored key; a refusal marks it invalid, no answer keeps the state (AC-10, AC-14, EC-6).
    /// `showResult` fills the result line, for "Prüfen" in the settings (AC-11).
    public func checkStored(showResult: Bool = false) async {
        guard status != .missing, !isChecking else { return }
        let key: String?
        do {
            key = try store.read()
        } catch {
            Log.write("Stored key could not be read: status \(Int(error.status))", category: .groq, level: .error)
            return
        }
        guard let key else {
            setStatus(.missing, lastFour: nil)
            return
        }
        isChecking = true
        let removalsBefore = removals
        let outcome = await checker.check(key)
        isChecking = false
        log(outcome, context: "Stored key check")
        guard removals == removalsBefore else { return discardResult() }
        switch outcome.result {
        case .valid: setStatus(.valid, lastFour: lastFour)
        case .rejected: setStatus(.invalid, lastFour: lastFour)
        case .unreachable: break
        }
        if showResult {
            lastResult =
                switch outcome.result {
                case .valid: .works
                case .rejected: .rejected
                case .unreachable: .notReachable
                }
        }
    }

    /// The network is back: a key saved without check is checked now (AC-10).
    public func networkBecameAvailable() async {
        guard status == .unchecked else { return }
        await checkStored()
    }

    /// The problem button: settings at "Zugang & Erlaubnisse" with the key field open (AC-14, AC-15).
    public func showKeySettings() {
        wantsEdit = true
        showSettings()
    }

    // MARK: - Steps

    private func checkAndSave(_ key: String) async {
        isChecking = true
        let removalsBefore = removals
        let outcome = await checker.check(key)
        isChecking = false
        log(outcome, context: "Key check")
        guard removals == removalsBefore else { return discardResult() }
        switch outcome.result {
        case .valid: save(key, as: .valid)
        case .unreachable: save(key, as: .unchecked)
        case .rejected: lastResult = .rejected
        }
    }

    /// The key was removed while Groq was asked; the removal stands (BUG-1).
    private func discardResult() {
        Log.write("Check result discarded: key was removed meanwhile", category: .groq)
    }

    /// Stores the key and its state; the old key stays if the keychain refuses (EC-8).
    private func save(_ key: String, as newStatus: KeyStatus) {
        do {
            try store.save(key)
        } catch {
            Log.write("Key could not be saved: status \(Int(error.status))", category: .groq, level: .error)
            lastResult = .saveFailed
            return
        }
        Log.write("Key saved as \(newStatus)", category: .groq)
        setStatus(newStatus, lastFour: String(key.suffix(4)))
        lastResult = newStatus == .valid ? .works : .savedUnchecked
        wantsEdit = false
    }

    private func setStatus(_ newStatus: KeyStatus, lastFour newLastFour: String?) {
        if status != newStatus {
            Log.write("Key status: \(status) -> \(newStatus)", category: .groq)
        }
        status = newStatus
        lastFour = newLastFour
        if newStatus == .missing {
            defaults.removeObject(forKey: GroqAccessInfo.statusDefaultsKey)
        } else {
            defaults.set(newStatus.rawValue, forKey: GroqAccessInfo.statusDefaultsKey)
        }
        updateProblems()
    }

    private func loadStoredKey() {
        do {
            guard let key = try store.read() else {
                status = .missing
                Log.write("Key at start: \(status)", category: .groq)
                return
            }
            lastFour = String(key.suffix(4))
            let stored = defaults.string(forKey: GroqAccessInfo.statusDefaultsKey).flatMap(KeyStatus.init)
            status = (stored == .valid || stored == .invalid) ? stored! : .unchecked
        } catch {
            Log.write("Key at start could not be read: status \(Int(error.status))", category: .groq, level: .error)
            status = .missing
        }
        Log.write("Key at start: \(status)", category: .groq)
    }

    private func log(_ outcome: KeyCheckOutcome, context: StaticString) {
        let label = LogLabel(logDescription: context)
        if let code = outcome.statusCode {
            Log.write("\(label): \(outcome.result), status \(code), took \(outcome.duration)", category: .groq)
        } else {
            Log.write("\(label): \(outcome.result), no answer, took \(outcome.duration)", category: .groq)
        }
    }

    /// Missing or invalid key → problem, but only after the onboarding (AC-14, AC-15, AC-16).
    private func updateProblems() {
        let reports = onboardingFinishedOnce() && !onboardingIsOpen
        guard reports, status == .missing || status == .invalid else {
            if problems.isReported(id: GroqAccessInfo.problemID) {
                problems.withdraw(id: GroqAccessInfo.problemID)
            }
            return
        }
        let missing = status == .missing
        problems.report(
            Problem(
                id: GroqAccessInfo.problemID,
                section: .access,
                message: missing ? "Kein Groq-Schlüssel." : "Groq-Schlüssel ungültig.",
                actionTitle: missing ? "Schlüssel eintragen" : "Schlüssel ändern",
                keepsOwnActionInPanel: true
            ) { [weak self] in self?.showKeySettings() })
    }

    // MARK: - Input

    /// Removes spaces and line breaks around the input; `nil` when nothing is left (EC-1, EC-2).
    static func trimmed(_ input: String) -> String? {
        let key = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return key.isEmpty ? nil : key
    }

    /// 1 to 200 visible characters without spaces (design.md → Datenmodell).
    static func isWellFormed(_ key: String) -> Bool {
        guard (1...GroqAccessInfo.maxKeyLength).contains(key.count) else { return false }
        return key.unicodeScalars.allSatisfy { $0.value > 0x20 && $0.value < 0x7F }
    }
}

/// A fixed label for a log line.
private struct LogLabel: LogValue {
    let logDescription: StaticString
}
