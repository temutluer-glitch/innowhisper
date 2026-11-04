import Testing

@testable import Notices

@Test func autoDismissIsTwoSeconds() {
    #expect(NoticesInfo.autoDismissDelay == .seconds(2))
}
