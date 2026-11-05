import Foundation
import Testing

@testable import Permissions

@MainActor
@Suite struct PermissionTests {
    @Test func settingsOpenAtTheRightPage() {
        var opened: [URL] = []
        let links = SystemSettingsLinks {
            opened.append($0)
            return true
        }
        links.open(.microphone)
        links.open(.accessibility)
        #expect(
            opened.map(\.absoluteString) == [
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone",
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            ])
    }

    @Test func refusedPageFallsBackToSystemSettings() {
        var opened: [URL] = []
        let links = SystemSettingsLinks { url in
            opened.append(url)
            return url.isFileURL
        }
        links.open(.accessibility)
        #expect(opened.count == 2)
        #expect(opened.last?.path == "/System/Applications/System Settings.app")
    }

    @Test func onlyGrantedCountsAsGranted() {
        #expect(PermissionState.granted.isGranted)
        #expect(!PermissionState.denied.isGranted)
        #expect(!PermissionState.restricted.isGranted)
        #expect(!PermissionState.notDetermined.isGranted)
    }

    @Test func problemTextsAndIDs() {
        #expect(PermissionKind.microphone.missingMessage == "Mikrofon nicht erlaubt.")
        #expect(PermissionKind.accessibility.missingMessage == "Bedienungshilfen nicht erlaubt.")
        #expect(PermissionKind.microphone.problemID == "permission.microphone")
        #expect(PermissionKind.accessibility.problemID == "permission.accessibility")
    }
}
