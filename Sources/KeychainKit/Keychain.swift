import Foundation

#if canImport(Security)
import Security
#endif

/// A simplified, secure wrapper for iOS/macOS Keychain.
@MainActor
public final class KeychainKit {
    
    public static let shared = KeychainKit()
    private init() {}
    
    /// Saves a string to the keychain.
    public func save(_ value: String, for key: String) throws {
        #if canImport(Security)
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
        #endif
    }
    
    /// Retrieves a string from the keychain.
    public func get(key: String) -> String? {
        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        #endif
        return nil
    }
    
    /// Deletes a key from the keychain.
    public func delete(key: String) {
        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        #endif
    }
}

public enum KeychainError: Error, Sendable {
    case saveFailed(OSStatus)
}
