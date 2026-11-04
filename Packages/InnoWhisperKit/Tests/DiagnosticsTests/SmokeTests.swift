import Testing

@testable import Diagnostics

@Test func subsystemIsInnoWhisper() {
    #expect(DiagnosticsInfo.subsystem == "com.innosolv.InnoWhisper")
}
