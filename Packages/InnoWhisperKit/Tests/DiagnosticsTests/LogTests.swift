import Foundation
import Testing

@testable import Diagnostics

@Suite(.serialized)
struct LogTests {
    // AC-11: entries written through Log land in the configured file
    @Test func writesIntoConfiguredFile() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("log-\(UUID().uuidString)")
        let file = LogFile(directory: dir)
        Log.configure(file: file)
        defer { Log.configure(file: nil) }
        Log.write("Testeintrag \(42)", category: .app)
        Log.write("Fehler \(error: CocoaError(.fileNoSuchFile))", category: .appShell, level: .error)
        file.flush()
        let content = try String(contentsOf: file.fileURL, encoding: .utf8)
        #expect(content.contains("[app] Testeintrag 42"))
        #expect(content.contains("[appshell] Fehler NSCocoaErrorDomain#4"))
    }

    // Without a file, writing still works (Apple's log only)
    @Test func writingWithoutFileDoesNotCrash() {
        Log.configure(file: nil)
        Log.write("nur Systemprotokoll", category: .app)
    }
}
