import AppShell
import Foundation
import Synchronization
import Testing

@testable import GroqAccess

final class FakeStore: KeyStoring, @unchecked Sendable {
    var key: String?
    var failSave = false
    var failDelete = false

    init(key: String? = nil) { self.key = key }

    func read() throws(KeychainError) -> String? { key }
    func save(_ key: String) throws(KeychainError) {
        if failSave { throw KeychainError(status: -25308) }
        self.key = key
    }
    func delete() throws(KeychainError) {
        if failDelete { throw KeychainError(status: -25308) }
        key = nil
    }
}

final class FakeLegacy: LegacyKeyReading, @unchecked Sendable {
    var key: String?
    var reads = 0

    init(key: String? = nil) { self.key = key }

    func hasKey() -> Bool { key != nil }
    func read() throws(KeychainError) -> String {
        reads += 1
        guard let key else { throw KeychainError(status: -128) }
        return key
    }
}

final class FakeChecker: KeyChecking {
    private let state: Mutex<(answer: KeyCheckResult, keys: [String])>
    let delay: Duration

    init(_ answer: KeyCheckResult = .valid, delay: Duration = .zero) {
        state = Mutex((answer, []))
        self.delay = delay
    }

    var keys: [String] { state.withLock { $0.keys } }
    func answer(_ result: KeyCheckResult) { state.withLock { $0.answer = result } }

    func check(_ key: String) async -> KeyCheckOutcome {
        let result = state.withLock { s in
            s.keys.append(key)
            return s.answer
        }
        if delay > .zero { try? await Task.sleep(for: delay) }
        let code: Int? =
            switch result {
            case .valid: 200
            case .rejected: 401
            case .unreachable: nil
            }
        return KeyCheckOutcome(result: result, statusCode: code, duration: .milliseconds(5))
    }
}

@MainActor
@Suite struct GroqKeyModelTests {
    let problems = ProblemCenter()
    let defaults = UserDefaults(suiteName: "GroqKeyModelTests-\(UUID().uuidString)")!

    func makeModel(
        store: FakeStore = FakeStore(),
        legacy: FakeLegacy = FakeLegacy(),
        checker: FakeChecker = FakeChecker(),
        finished: Bool = true
    ) -> GroqKeyModel {
        GroqKeyModel(
            store: store, legacy: legacy, checker: checker, defaults: defaults,
            problems: problems, onboardingFinishedOnce: { finished })
    }

    // AC-5, EC-1
    @Test func trimmedKeyIsCheckedAndStoredWhenGroqAccepts() async {
        let store = FakeStore()
        let checker = FakeChecker(.valid)
        let model = makeModel(store: store, checker: checker)
        await model.submit("  gsk_abcd1234\n")
        #expect(checker.keys == ["gsk_abcd1234"])
        #expect(store.key == "gsk_abcd1234")
        #expect(model.status == .valid)
        #expect(model.lastFour == "1234")
        #expect(model.lastResult == .works)
        #expect(defaults.string(forKey: GroqAccessInfo.statusDefaultsKey) == "valid")
        #expect(model.isUsable)
    }

    // AC-6, AC-12
    @Test func rejectedKeyIsNotStoredAndTheOldOneStays() async {
        defaults.set("valid", forKey: GroqAccessInfo.statusDefaultsKey)
        let store = FakeStore(key: "gsk_old_0001")
        let model = makeModel(store: store, checker: FakeChecker(.rejected))
        await model.submit("gsk_new_0002")
        #expect(store.key == "gsk_old_0001")
        #expect(model.status == .valid)
        #expect(model.lastFour == "0001")
        #expect(model.lastResult == .rejected)
    }

    // AC-10, EC-5
    @Test func noAnswerStoresTheKeyAsNotYetChecked() async {
        let store = FakeStore()
        let model = makeModel(store: store, checker: FakeChecker(.unreachable))
        await model.submit("gsk_offline1")
        #expect(store.key == "gsk_offline1")
        #expect(model.status == .unchecked)
        #expect(model.lastResult == .savedUnchecked)
        #expect(model.isUsable)
    }

    // AC-2, EC-2
    @Test func emptyOrMalformedInputIsNeverSentToGroq() async {
        let checker = FakeChecker()
        let model = makeModel(checker: checker)
        #expect(!model.canCheck("   \n"))
        #expect(model.canCheck(" gsk_x "))
        await model.submit("gsk with space")
        await model.submit(String(repeating: "a", count: 201))
        #expect(checker.keys.isEmpty)
        #expect(model.lastResult == .rejected)
        #expect(!model.isUsable)
    }

    // EC-3
    @Test func onlyOneCheckRunsAtATime() async {
        let checker = FakeChecker(.valid, delay: .milliseconds(100))
        let model = makeModel(checker: checker)
        async let first: Void = model.submit("gsk_first01")
        async let second: Void = model.submit("gsk_second2")
        _ = await (first, second)
        #expect(checker.keys.count == 1)
    }

    // AC-14, EC-6
    @Test func storedKeyRefusedAtStartBecomesInvalidAndIsReported() async {
        defaults.set("unchecked", forKey: GroqAccessInfo.statusDefaultsKey)
        let store = FakeStore(key: "gsk_gone0007")
        let model = makeModel(store: store, checker: FakeChecker(.rejected))
        await model.checkStored()
        #expect(model.status == .invalid)
        #expect(store.key == "gsk_gone0007")
        let problem = problems.problems.first { $0.id == GroqAccessInfo.problemID }
        #expect(problem?.message == "Groq-Schlüssel ungültig.")
        #expect(problem?.actionTitle == "Schlüssel ändern")
        #expect(problem?.section == .access)
        #expect(problem?.keepsOwnActionInPanel == true)
    }

    // AC-10
    @Test func noAnswerAtStartKeepsTheStateWithoutProblem() async {
        defaults.set("valid", forKey: GroqAccessInfo.statusDefaultsKey)
        let model = makeModel(store: FakeStore(key: "gsk_ok000003"), checker: FakeChecker(.unreachable))
        await model.checkStored()
        #expect(model.status == .valid)
        #expect(!problems.isReported(id: GroqAccessInfo.problemID))
    }

    // AC-15, PROJ-3 pattern: no problem while the onboarding is open or not yet done
    @Test func missingKeyIsReportedOnlyAfterTheOnboarding() {
        let early = makeModel(finished: false)
        early.onboardingIsOpen = true
        early.onboardingIsOpen = false
        #expect(!problems.isReported(id: GroqAccessInfo.problemID))
        let model = makeModel(finished: true)
        model.onboardingIsOpen = true
        model.onboardingIsOpen = false
        let problem = problems.problems.first { $0.id == GroqAccessInfo.problemID }
        #expect(problem?.message == "Kein Groq-Schlüssel.")
        #expect(problem?.actionTitle == "Schlüssel eintragen")
        model.onboardingIsOpen = true
        #expect(!problems.isReported(id: GroqAccessInfo.problemID))
    }

    // AC-16
    @Test func validKeyWithdrawsTheProblemAtOnce() async {
        let model = makeModel(checker: FakeChecker(.valid))
        model.onboardingIsOpen = true
        model.onboardingIsOpen = false
        #expect(problems.isReported(id: GroqAccessInfo.problemID))
        await model.submit("gsk_fresh123")
        #expect(!problems.isReported(id: GroqAccessInfo.problemID))
    }

    // AC-13, AC-15
    @Test func removeDeletesTheKeyAndReportsItMissing() {
        defaults.set("valid", forKey: GroqAccessInfo.statusDefaultsKey)
        let store = FakeStore(key: "gsk_bye00009")
        let model = makeModel(store: store)
        model.remove()
        #expect(store.key == nil)
        #expect(model.status == .missing)
        #expect(model.lastFour == nil)
        #expect(defaults.string(forKey: GroqAccessInfo.statusDefaultsKey) == nil)
        #expect(problems.problems.first?.message == "Kein Groq-Schlüssel.")
    }

    // AC-7, AC-8, EC-9
    @Test func oldAppsKeyIsFoundWithoutReadingAndTakenOverOnRequest() async {
        let store = FakeStore()
        let legacy = FakeLegacy(key: "gsk_legacy42")
        let checker = FakeChecker(.valid)
        let model = makeModel(store: store, legacy: legacy, checker: checker)
        model.lookForLegacyKey()
        #expect(model.legacyKeyAvailable)
        #expect(legacy.reads == 0)
        await model.takeOver()
        #expect(legacy.reads == 1)
        #expect(checker.keys == ["gsk_legacy42"])
        #expect(store.key == "gsk_legacy42")
        #expect(legacy.key == "gsk_legacy42")
        #expect(model.status == .valid)
    }

    // AC-9, EC-9
    @Test func failedTakeoverLeavesTheFieldAsTheWay() async {
        let store = FakeStore()
        let legacy = FakeLegacy()
        let model = makeModel(store: store, legacy: legacy)
        model.lookForLegacyKey()
        #expect(!model.legacyKeyAvailable)
        await model.takeOver()
        #expect(model.lastResult == .takeoverFailed)
        #expect(store.key == nil)
        #expect(model.status == .missing)
    }

    // EC-8
    @Test func refusedSaveShowsAMessageAndKeepsTheState() async {
        let store = FakeStore()
        store.failSave = true
        let model = makeModel(store: store, checker: FakeChecker(.valid))
        await model.submit("gsk_nosave01")
        #expect(model.lastResult == .saveFailed)
        #expect(model.status == .missing)
        #expect(model.lastFour == nil)
    }

    // AC-10
    @Test func networkReturnChecksOnlyAKeyThatWasNotChecked() async {
        defaults.set("unchecked", forKey: GroqAccessInfo.statusDefaultsKey)
        let checker = FakeChecker(.valid)
        let model = makeModel(store: FakeStore(key: "gsk_later001"), checker: checker)
        await model.networkBecameAvailable()
        #expect(model.status == .valid)
        await model.networkBecameAvailable()
        #expect(checker.keys.count == 1)
    }

    // AC-14 button
    @Test func problemButtonOpensTheKeySettingsWithTheFieldOpen() {
        let model = makeModel()
        var opened = 0
        model.showSettings = { opened += 1 }
        model.onboardingIsOpen = true
        model.onboardingIsOpen = false
        problems.problems.first { $0.id == GroqAccessInfo.problemID }?.action()
        #expect(opened == 1)
        #expect(model.wantsEdit)
    }

    // AC-11: "Prüfen" in the settings shows what Groq said
    @Test func checkFromTheSettingsShowsTheResult() async {
        defaults.set("valid", forKey: GroqAccessInfo.statusDefaultsKey)
        let checker = FakeChecker(.unreachable)
        let model = makeModel(store: FakeStore(key: "gsk_shown001"), checker: checker)
        await model.checkStored(showResult: true)
        #expect(model.lastResult == .notReachable)
        #expect(model.status == .valid)
        checker.answer(.rejected)
        await model.checkStored(showResult: true)
        #expect(model.lastResult == .rejected)
        #expect(model.status == .invalid)
        await model.checkStored()
        #expect(model.lastResult == .rejected)
    }
}
