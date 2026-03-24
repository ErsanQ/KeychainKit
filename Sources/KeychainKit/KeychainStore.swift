import Foundation
import Security

// MARK: - KeychainStore

/// The low-level engine that wraps `Security.framework` Keychain APIs.
///
/// This is an internal type. Use ``Keychain`` (static API) or
/// ``KeychainItem`` (Property Wrapper) for all public-facing operations.
struct KeychainStore: Sendable {

    // MARK: - Properties

    let service: String
    let accessGroup: String?

    // MARK: - Init

    init(service: String = Bundle.main.bundleIdentifier ?? "com.keychainkit.default",
         accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    // MARK: - Save

    func save(_ data: Data, forKey key: String, accessibility: KeychainAccessibility) throws {
        var query = baseQuery(forKey: key)
        query[kSecValueData as String]        = data
        query[kSecAttrAccessible as String]   = accessibility.cfString

        let status = SecItemAdd(query as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            throw KeychainError.duplicateItem
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Update

    func update(_ data: Data, forKey key: String, accessibility: KeychainAccessibility) throws {
        let query = baseQuery(forKey: key)
        let attributes: [String: Any] = [
            kSecValueData as String:      data,
            kSecAttrAccessible as String: accessibility.cfString
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Save or Update (Upsert)

    func saveOrUpdate(_ data: Data, forKey key: String, accessibility: KeychainAccessibility) throws {
        do {
            try save(data, forKey: key, accessibility: accessibility)
        } catch KeychainError.duplicateItem {
            try update(data, forKey: key, accessibility: accessibility)
        }
    }

    // MARK: - Read

    func read(forKey key: String) throws -> Data {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String]  = true
        query[kSecMatchLimit as String]  = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.invalidData
            }
            return data
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Delete

    func delete(forKey key: String) throws {
        let query = baseQuery(forKey: key)
        let status = SecItemDelete(query as CFDictionary)

        switch status {
        case errSecSuccess, errSecItemNotFound:
            return // Both are acceptable — item is gone either way
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Exists

    func exists(forKey key: String) -> Bool {
        var query = baseQuery(forKey: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - All Keys

    func allKeys() throws -> [String] {
        var query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String:       kSecMatchLimitAll
        ]
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }

        return items.compactMap { $0[kSecAttrAccount as String] as? String }
    }

    // MARK: - Private

    private func baseQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }
}
