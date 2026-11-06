import Foundation
import Security

/// The key the old app stored. Tests use a stand-in.
public protocol LegacyKeyReading: Sendable {
    /// Whether the old app has a key, without reading it, so macOS asks
    /// nothing yet (AC-7, EC-9, design.md → Technische Entscheidungen).
    func hasKey() -> Bool
    /// Reads the key; macOS may ask the user first (AC-8, AC-9).
    func read() throws(KeychainError) -> String
}

/// Reads the old app's keychain entry. It never changes it (AC-8).
public struct SystemLegacyKeyReader: LegacyKeyReading {
    let service: String
    let account: String

    public init(
        service: String = GroqAccessInfo.legacyKeychainService,
        account: String = GroqAccessInfo.legacyKeychainAccount
    ) {
        self.service = service
        self.account = account
    }

    var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
    }

    /// Asks for the entry's attributes only, never its value.
    var existenceQuery: [String: Any] {
        baseQuery.merging([kSecReturnAttributes as String: true]) { $1 }
    }

    var readQuery: [String: Any] {
        baseQuery.merging([kSecReturnData as String: true]) { $1 }
    }

    public func hasKey() -> Bool {
        var result: CFTypeRef?
        return SecItemCopyMatching(existenceQuery as CFDictionary, &result) == errSecSuccess
    }

    public func read() throws(KeychainError) -> String {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(readQuery as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { throw KeychainError(status: status) }
        return String(decoding: data, as: UTF8.self)
    }
}
