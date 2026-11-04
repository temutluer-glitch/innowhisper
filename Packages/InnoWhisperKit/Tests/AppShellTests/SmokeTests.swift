import Testing

@testable import AppShell

@Test func bundleIdentifierIsInnoWhisper() {
    #expect(AppShellInfo.bundleIdentifier == "com.innosolv.InnoWhisper")
}
