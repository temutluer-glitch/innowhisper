import Foundation
import Security
import Testing

@testable import GroqAccess

/// The keychain itself is checked on the running app (tasks.md T8); these
/// tests pin down what is asked of it.
@Suite struct KeyStoreTests {
    @Test func ownEntryUsesInnoWhispersNames() {
        let store = SystemKeyStore()
        #expect(store.baseQuery[kSecAttrService as String] as? String == "com.innosolv.InnoWhisper")
        #expect(store.baseQuery[kSecAttrAccount as String] as? String == "groq-api-key")
        #expect(store.baseQuery[kSecClass as String] as? String == kSecClassGenericPassword as String)
    }

    // BUG-2: the key lives in the login keychain (moves with a Mac migration,
    // never to iCloud); nothing asks for a protection the login keychain ignores.
    @Test func keyGoesToTheLoginKeychainWithoutICloud() {
        let store = SystemKeyStore()
        let attributes = store.attributes(for: "gsk_test")
        #expect(attributes[kSecValueData as String] as? Data == Data("gsk_test".utf8))
        #expect(attributes[kSecAttrSynchronizable as String] == nil)
        #expect(attributes[kSecAttrAccessible as String] == nil)
        #expect(store.baseQuery[kSecUseDataProtectionKeychain as String] == nil)
        #expect(store.baseQuery[kSecAttrSynchronizable as String] == nil)
    }

    @Test func oldEntryIsLookedUpWithoutReadingTheKey() {
        let reader = SystemLegacyKeyReader()
        #expect(reader.baseQuery[kSecAttrService as String] as? String == "com.innosolv.WhisperDictation")
        #expect(reader.baseQuery[kSecAttrAccount as String] as? String == "groq_api_key")
        #expect(reader.existenceQuery[kSecReturnData as String] == nil)
        #expect(reader.existenceQuery[kSecReturnAttributes as String] as? Bool == true)
        #expect(reader.readQuery[kSecReturnData as String] as? Bool == true)
    }
}
