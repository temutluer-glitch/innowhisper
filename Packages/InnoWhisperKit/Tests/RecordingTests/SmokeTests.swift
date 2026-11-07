import Diagnostics
import Testing

@testable import Recording

@Test func fixedValuesMatchTheDesign() {
    #expect(RecordingInfo.holdDelay == .milliseconds(250))
    #expect(RecordingInfo.minimumDuration == .milliseconds(500))
    #expect(RecordingInfo.noSoundTimeout == .seconds(1))
    #expect(RecordingInfo.singleEscapeLimit == .seconds(30))
    #expect(RecordingInfo.secondEscapeWindow == .seconds(3))
    #expect(RecordingInfo.minimumFreeBytes == 200 * 1024 * 1024)
    #expect(RecordingInfo.sampleRate == 16_000)
    #expect(RecordingInfo.stepID == "shortcut")
    #expect(RecordingInfo.stepOrder == 60)
    #expect(LogCategory.recording.name == "recording")
}
