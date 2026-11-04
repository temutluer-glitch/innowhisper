import Foundation
import Testing

@testable import Diagnostics

enum SampleState: LogValue {
    case ready
    var logDescription: StaticString { "ready" }
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
        #expect(message.text == "app=<unknown-app>" || message.text == "app=<none>")
    }

    // AC-12: only domain and code of an error, never its message
    @Test func errorMessageTextIsDropped() {
        let error = NSError(domain: "Test", code: 7, userInfo: [NSLocalizedDescriptionKey: "Diktat: Hallo Welt"])
        let message: LogMessage = "e=\(error: error)"
        #expect(message.text == "e=<domain>#7")
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

    // BUG-1 (a): an identifier-shaped word that is no installed app is never logged
    @Test(arguments: ["max.mustermann", "z.B.", "Termin-am-3.12", "meier.mueller-gmbh.de", "Danke."])
    func identifierShapedFreeTextIsRejected(value: String) {
        let message: LogMessage = "app=\(bundleID: value)"
        #expect(message.text == "app=<unknown-app>")
    }

    // BUG-1 (a): a real installed app still shows
    @Test func installedAppIsLogged() {
        let message: LogMessage = "app=\(bundleID: "com.apple.TextEdit")"
        #expect(message.text == "app=com.apple.TextEdit")
    }

    // BUG-1 (b): an error domain made of free text is never logged
    @Test func freeTextErrorDomainIsRejected() {
        let error = NSError(domain: "Hallo Herr Meier, mein Passwort ist geheim", code: 7)
        let message: LogMessage = "e=\(error: error)"
        #expect(message.text == "e=<domain>#7")
        let oneWord = NSError(domain: "geheim", code: 2)
        let second: LogMessage = "e=\(error: oneWord)"
        #expect(second.text == "e=<domain>#2")
    }

    // BUG-1 (c): a LogValue can only describe itself with fixed text from the
    // source code; stored text (struct field, enum payload, String itself) is
    // rejected by the compiler, also with a hand-written allCases.
    @Test func logValueOnlyFixedText() throws {
        #expect(
            try typecheckSnippet(
                #"enum S: LogValue { case a; var logDescription: StaticString { "a" } }; func f() { let m: LogMessage = "\(S.a)"; _ = m }"#
            ).status == 0)
        let attempts = [
            #"struct A: LogValue { let s: String; static var allCases: [A] { [] } }"#,
            #"struct B: LogValue { let s: String; static var allCases: [B] { [] }; var logDescription: String { s } }"#,
            #"struct C: LogValue { let s: String; static var allCases: [C] { [] }; var logDescription: StaticString { s } }"#,
            #"enum P: LogValue { case text(String); static var allCases: [P] { [] }; var logDescription: StaticString { switch self { case .text(let t): t } } }"#,
            #"extension String: @retroactive CaseIterable { public static var allCases: [String] { [] } }; extension String: LogValue { public var logDescription: String { self } }"#,
        ]
        for code in attempts {
            let result = try typecheckSnippet(code)
            #expect(result.status != 0, "\(code)")
            #expect(result.errors.contains("StaticString") || result.errors.contains("LogValue"), "\(result.errors)")
        }
    }

    private func typecheckSnippet(_ code: String) throws -> (status: Int32, errors: String) {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("logval-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let source = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/Diagnostics/LogMessage.swift")
        let snippet = dir.appendingPathComponent("snippet.swift")
        try code.write(to: snippet, atomically: true, encoding: .utf8)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["swiftc", "-typecheck", "-parse-as-library", source.path, snippet.path]
        let pipe = Pipe()
        process.standardError = pipe
        process.standardOutput = FileHandle.nullDevice
        try process.run()
        let errors = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        process.waitUntilExit()
        return (process.terminationStatus, errors)
    }
}
