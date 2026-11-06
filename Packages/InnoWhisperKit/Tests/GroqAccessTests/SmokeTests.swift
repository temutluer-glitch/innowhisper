import Testing

@testable import GroqAccess

@Test func fixedValuesMatchTheDesign() {
    #expect(GroqAccessInfo.checkTimeout == .seconds(15))
    #expect(GroqAccessInfo.checkURL.absoluteString == "https://api.groq.com/openai/v1/models")
    #expect(GroqAccessInfo.stepOrder == 10)
    #expect(GroqAccessInfo.keychainService != GroqAccessInfo.legacyKeychainService)
}
