import Foundation

#if canImport(Security)
import Security
#endif

/// A premium, type-safe property wrapper for storing data securely in the system Keychain.
///
/// `Keychain` simplifies the complex Security framework into a declarative interface,
/// allowing developers to persist sensitive information like tokens or passwords
/// with minimal code.
///
/// ## Usage
/// ```swift
/// @Keychain("user_token") var token: String?
/// ```
@propertyWrapper
@MainActor
public struct Keychain<T: Codable> {
    private let key: String
    private let accessibility: KeychainAccessibility
    private let service: String?
    
    /// Creates a new Keychain property wrapper.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the data in the Keychain.
    ///   - accessibility: The security level for when the data can be accessed. Defaults to `.afterFirstUnlock`.
    ///   - service: An optional service name to group related data.
    public init(_ key: String, accessibility: KeychainAccessibility = .afterFirstUnlock, service: String? = nil) {
        self.key = key
        self.accessibility = accessibility
        self.service = service
    }
    
    public var wrappedValue: T? {
        get {
            #if canImport(Security)
            let store = KeychainStore(service: service ?? (Bundle.main.bundleIdentifier ?? "com.keychainkit.default"))
            guard let data = try? store.read(forKey: key) else { return nil }
            return try? JSONDecoder().decode(T.self, from: data)
            #else
            return nil
            #endif
        }
        set {
            #if canImport(Security)
            let store = KeychainStore(service: service ?? (Bundle.main.bundleIdentifier ?? "com.keychainkit.default"))
            if let value = newValue {
                if let data = try? JSONEncoder().encode(value) {
                    try? store.saveOrUpdate(data, forKey: key, accessibility: accessibility)
                }
            } else {
                try? store.delete(forKey: key)
            }
            #endif
        }
    }
}
