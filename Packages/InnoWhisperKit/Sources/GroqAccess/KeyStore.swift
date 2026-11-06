import Foundation
import Security

/// A keychain call macOS refused; carries the status code for the log (EC-8).
public struct KeychainError: Error, Equatable, Sendable {
    public let status: OSStatus

    public init(status: OSStatus) {
        self.status = status
    }
}

/// Reads, saves and deletes InnoWhisper's own key. Tests use a stand-in.
public protocol KeyStoring: Sendable {
    func read() throws(KeychainError) -> String?
    func save(_ key: String) throws(KeychainError)
    func delete() throws(KeychainError)
}

/// InnoWhisper's own entry in the login keychain, protected by the Mac
/// password, never synced to iCloud; it moves along with a Mac migration
/// (AC-5, AC-13, AC-17, design.md → Datenmodell, decision of 06.11.).
public struct SystemKeyStore: KeyStoring {
    let service: String
    let account: String

    public init(
        service: String = GroqAccessInfo.keychainService,
        account: String = GroqAccessInfo.keychainAccount
    ) {
        self.service = service
        self.account = account
    }

    /// Identifies the entry; every call starts from this.
    var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    /// What is written: only the key. The login keychain ignores protection
    /// classes, so none is asked for (BUG-2).
    func attributes(for key: String) -> [String: Any] {
        [kSecValueData as String: Data(key.utf8)]
    }

    public func read() throws(KeychainError) -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw KeychainError(status: status) }
        return String(decoding: data, as: UTF8.self)
    }

    /// Replaces an existing entry in place, otherwise adds one.
    public func save(_ key: String) throws(KeychainError) {
        let update = SecItemUpdate(baseQuery as CFDictionary, attributes(for: key) as CFDictionary)
        if update == errSecSuccess { return }
        guard update == errSecItemNotFound else { throw KeychainError(status: update) }
        let add = SecItemAdd(baseQuery.merging(attributes(for: key)) { $1 } as CFDictionary, nil)
        guard add == errSecSuccess else { throw KeychainError(status: add) }
    }

    /// Deleting a missing entry is fine.
    public func delete() throws(KeychainError) {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status: status) }
    }
}
