import Foundation
import Testing

@testable import AppShell

struct SingleInstanceAndQuitTests {
    let id = "com.innosolv.InnoWhisper"

    // EC-1: another instance with the same id is found; own pid and other apps are not
    @Test func findsOtherInstance() {
        let running = [
            RunningApp(pid: 1, bundleIdentifier: id),
            RunningApp(pid: 2, bundleIdentifier: id),
            RunningApp(pid: 3, bundleIdentifier: "com.innosolv.WhisperDictation"),
        ]
        #expect(SingleInstanceGuard.otherInstance(ownPID: 2, bundleIdentifier: id, running: running)?.pid == 1)
        #expect(
            SingleInstanceGuard.otherInstance(ownPID: 1, bundleIdentifier: id, running: Array(running.prefix(1)))
                == nil)
    }

    // AC-19, AC-20, EC-5
    @Test(arguments: [
        (DictationActivity.idle, false, QuitPolicy.Decision.quitNow),
        (.recording, false, .askFirst),
        (.transcribing, false, .askFirst),
        (.recording, true, .quitNow),
        (.idle, true, .quitNow),
    ])
    func quitDecision(activity: DictationActivity, shuttingDown: Bool, expected: QuitPolicy.Decision) {
        #expect(QuitPolicy.decide(activity: activity, systemIsShuttingDown: shuttingDown) == expected)
    }

    // AC-20: wording from the spec
    @Test func confirmationWording() {
        #expect(QuitPolicy.confirmationTitle == "Ein Diktat läuft noch.")
        #expect(QuitPolicy.confirmationMessage == "Wenn du jetzt beendest, geht es verloren. Trotzdem beenden?")
    }
}
