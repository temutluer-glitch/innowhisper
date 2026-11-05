import Testing

@testable import Permissions

@Test func checkIntervalsMeetTheTimeBounds() {
    #expect(PermissionsInfo.onboardingInterval <= .seconds(1))
    #expect(PermissionsInfo.backgroundInterval <= .seconds(3))
}
