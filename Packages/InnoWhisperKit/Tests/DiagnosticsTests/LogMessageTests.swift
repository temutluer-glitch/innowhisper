import Foundation
import Testing

@testable import Diagnostics

enum SampleState: LogValue {
    case ready
    var logDescription: String { "ready" }
}

struct LogMessageTests {
    // AC-12: safe values render
    @Test func safeValuesRender() {
        let count = 3
        let message: LogMessage =
            "n=\(count) ok=\(true) d=\(Duration.milliseconds(1500)) s=\(SampleState.ready) app=\(bundleID: "com.apple.TextEdit") e=\(error: CocoaError(.fileNoSuchFile))"
        #expect(
            message.text
                == "n=3 ok=true d=1500ms s=ready app=com.apple.TextEdit e=NSCocoaErrorDomain#4")
    }

    // AC-12: anything that is not an app identifier is replaced
    @Test(arguments: ["Hallo Welt, das ist mein Diktat", "geheim", "", nil] as [String?])
    func freeTextIsNeverLoggedAsBundleID(value: String?) {
        let message: LogMessage = "app=\(bundleID: value)"
        #expect(message.text == "app=<invalid>" || message.text == "app=<none>")
    }

    // AC-12: only domain and code of an error, never its message
    @Test func errorMessageTextIsDropped() {
        let error = NSError(domain: "Test", code: 7, userInfo: [NSLocalizedDescriptionKey: "Diktat: Hallo Welt"])
        let message: LogMessage = "e=\(error: error)"
        #expect(message.text == "e=Test#7")
        #expect(!message.text.contains("Hallo"))
    }

    // AC-12: the compiler refuses a free String in a log message
    @Test func compilerRejectsFreeText() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("logmsg-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let source = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/Diagnostics/LogMessage.swift")
        let ok = dir.appendingPathComponent("ok.swift")
        let bad = dir.appendingPathComponent("bad.swift")
        let viaInit = dir.appendingPathComponent("init.swift")
        try #"func f() { let n = 1; let m: LogMessage = "n=\(n)"; _ = m }"#.write(
            to: ok, atomically: true, encoding: .utf8)
        try #"func f() { let dictated = "Hallo"; let m: LogMessage = "t=\(dictated)"; _ = m }"#
            .write(to: bad, atomically: true, encoding: .utf8)
        try #"func f() { let dictated = "Hallo"; let m = LogMessage(stringLiteral: dictated); _ = m }"#
            .write(to: viaInit, atomically: true, encoding: .utf8)
        #expect(try typecheck([source, ok]) == 0)
        #expect(try typecheck([source, bad]) != 0)
        #expect(try typecheck([source, viaInit]) != 0)
    }

    private func typecheck(_ files: [URL]) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["swiftc", "-typecheck", "-parse-as-library"] + files.map(\.path)
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }
}
