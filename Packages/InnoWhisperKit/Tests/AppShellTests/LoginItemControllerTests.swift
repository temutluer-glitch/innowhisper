import Foundation
import Testing

@testable import AppShell

@MainActor
final class FakeLoginItemService: LoginItemService {
    var status: LoginItemStatus
    var statusAfterRegister: LoginItemStatus = .enabled
    var registerError: Error?
    var registerCalls = 0
    var unregisterCalls = 0
    var openedSettings = false

    init(status: LoginItemStatus) { self.status = status }

    func register() throws {
        registerCalls += 1
        if let registerError { throw registerError }
        status = statusAfterRegister
    }

    func unregister() throws {
        unregisterCalls += 1
        status = .notRegistered
    }

    func openSystemSettings() { openedSettings = true }
}

struct Refused: Error {}

@MainActor
struct LoginItemControllerTests {
    let inApplications = URL(fileURLWithPath: "/Applications/InnoWhisper.app")
    let inDownloads = URL(fileURLWithPath: "/Users/test/Downloads/InnoWhisper.app")
    let home = URL(fileURLWithPath: "/Users/test")

    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func make(
        _ service: FakeLoginItemService, defaults: UserDefaults? = nil, bundle: URL? = nil
    ) -> (LoginItemController, ProblemCenter) {
        let problems = ProblemCenter()
        let controller = LoginItemController(
            service: service, problems: problems, defaults: defaults ?? freshDefaults(),
            bundleURL: bundle ?? inApplications, homeDirectory: home)
        return (controller, problems)
    }

    // AC-13: first launch switches autostart on
    @Test func firstLaunchEnables() {
        let service = FakeLoginItemService(status: .notRegistered)
        let (controller, problems) = make(service)
        controller.performFirstLaunchSetup()
        #expect(service.registerCalls == 1)
        #expect(controller.isEnabled)
        #expect(!problems.hasProblems)
    }

    // AC-14: a later launch never re-enables a deliberate "off"
    @Test func laterLaunchKeepsOff() {
        let defaults = freshDefaults()
        let service = FakeLoginItemService(status: .notRegistered)
        let (first, _) = make(service, defaults: defaults)
        first.performFirstLaunchSetup()
        first.setEnabled(false)
        #expect(service.unregisterCalls == 1)
        let (second, problems) = make(service, defaults: defaults)
        second.performFirstLaunchSetup()
        #expect(service.registerCalls == 1)
        #expect(!second.isEnabled)
        #expect(!problems.hasProblems)
    }

    // AC-15: switch mirrors macOS after an outside change
    @Test func refreshMirrorsMacOS() {
        let service = FakeLoginItemService(status: .enabled)
        let (controller, _) = make(service)
        controller.refresh()
        #expect(controller.isEnabled)
        service.status = .notRegistered
        controller.refresh()
        #expect(!controller.isEnabled)
    }

    // EC-4: waiting for approval → off + hint with button to System Settings
    @Test func requiresApprovalShowsHint() {
        let service = FakeLoginItemService(status: .notRegistered)
        service.statusAfterRegister = .requiresApproval
        let (controller, problems) = make(service)
        controller.performFirstLaunchSetup()
        #expect(!controller.isEnabled)
        let problem = problems.problems(in: .general).first
        #expect(problem?.id == LoginItemController.problemID)
        #expect(problem?.actionTitle == "Anmeldeobjekte öffnen")
        problem?.action()
        #expect(service.openedSettings)
    }

    // EC-4: refusal outside /Applications → hint to move the app
    @Test func refusalOutsideApplicationsAsksToMove() {
        let service = FakeLoginItemService(status: .notRegistered)
        service.registerError = Refused()
        let (controller, problems) = make(service, bundle: inDownloads)
        controller.performFirstLaunchSetup()
        #expect(!controller.isEnabled)
        #expect(problems.problems(in: .general).first?.message.contains("Programme") == true)
    }

    // EC-4: refusal inside /Applications → generic hint with retry
    @Test func refusalInsideApplicationsOffersRetry() {
        let service = FakeLoginItemService(status: .notFound)
        let (controller, problems) = make(service)
        controller.refresh()
        #expect(problems.problems(in: .general).first?.actionTitle == "Erneut versuchen")
        service.status = .notRegistered
        problems.problems(in: .general).first?.action()
        #expect(controller.isEnabled)
        #expect(!problems.hasProblems)
    }

    // EC-4: hint disappears when the user deliberately switches off
    @Test func switchingOffClearsHint() {
        let service = FakeLoginItemService(status: .notRegistered)
        service.registerError = Refused()
        let (controller, problems) = make(service)
        controller.setEnabled(true)
        #expect(problems.hasProblems)
        controller.setEnabled(false)
        #expect(!problems.hasProblems)
    }

    @Test func detectsUserApplicationsFolder() {
        let service = FakeLoginItemService(status: .enabled)
        let (inUserApps, _) = make(service, bundle: URL(fileURLWithPath: "/Users/test/Applications/InnoWhisper.app"))
        let (inDl, _) = make(service, bundle: inDownloads)
        #expect(inUserApps.isInApplicationsFolder)
        #expect(!inDl.isInApplicationsFolder)
    }
}
