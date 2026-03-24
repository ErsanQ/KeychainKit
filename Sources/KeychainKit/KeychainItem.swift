import Foundation

// MARK: - @KeychainItem (Property Wrapper)

/// A property wrapper that reads and writes `String?` values directly to the Keychain.
///
/// This is the simplest way to persist sensitive data — declare the property
/// and use it like any other optional string.
///
/// ```swift
/// @KeychainItem("auth_token") var token: String?
///
/// // Save
/// token = "eyJhbGci..."
///
/// // Read
/// if let t = token { useToken(t) }
///
/// // Delete
/// token = nil
/// ```
///
/// - Note: For `Codable` types, use ``KeychainObject`` instead.
@propertyWrapper
public struct KeychainItem: Sendable {

    // MARK: - Properties

    private let key: String
    private let accessibility: KeychainAccessibility
    private let store: KeychainStore

    // MARK: - Init

    /// Creates a Keychain-backed property.
    ///
    /// - Parameters:
    ///   - key: The unique Keychain key for this value.
    ///   - accessibility: Access level. Defaults to `.whenUnlocked`.
    ///   - service: The Keychain service identifier. Defaults to the app's bundle ID.
    public init(
        _ key: String,
        accessibility: KeychainAccessibility = .whenUnlocked,
        service: String = Bundle.main.bundleIdentifier ?? "com.keychainkit.default"
    ) {
        self.key = key
        self.accessibility = accessibility
        self.store = KeychainStore(service: service)
    }

    // MARK: - wrappedValue

    public var wrappedValue: String? {
        get {
            try? store.read(forKey: key).flatMap { String(data: $0, encoding: .utf8) }
        }
        nonmutating set {
            if let value = newValue, let data = value.data(using: .utf8) {
                try? store.saveOrUpdate(data, forKey: key, accessibility: accessibility)
            } else {
                try? store.delete(forKey: key)
            }
        }
    }
}

// MARK: - @KeychainObject (Codable Property Wrapper)

/// A property wrapper that reads and writes any `Codable` type to the Keychain as JSON.
///
/// ```swift
/// struct AuthSession: Codable {
///     let accessToken: String
///     let refreshToken: String
///     let expiresAt: Date
/// }
///
/// @KeychainObject("session") var session: AuthSession?
///
/// // Save
/// session = AuthSession(accessToken: "...", refreshToken: "...", expiresAt: .now + 3600)
///
/// // Read
/// if let s = session, s.expiresAt > .now {
///     useToken(s.accessToken)
/// }
///
/// // Delete
/// session = nil
/// ```
@propertyWrapper
public struct KeychainObject<T: Codable & Sendable>: Sendable {

    // MARK: - Properties

    private let key: String
    private let accessibility: KeychainAccessibility
    private let store: KeychainStore

    // MARK: - Init

    public init(
        _ key: String,
        accessibility: KeychainAccessibility = .whenUnlocked,
        service: String = Bundle.main.bundleIdentifier ?? "com.keychainkit.default"
    ) {
        self.key = key
        self.accessibility = accessibility
        self.store = KeychainStore(service: service)
    }

    // MARK: - wrappedValue

    public var wrappedValue: T? {
        get {
            guard let data = try? store.read(forKey: key) else { return nil }
            return try? JSONDecoder().decode(T.self, from: data)
        }
        nonmutating set {
            if let value = newValue, let data = try? JSONEncoder().encode(value) {
                try? store.saveOrUpdate(data, forKey: key, accessibility: accessibility)
            } else {
                try? store.delete(forKey: key)
            }
        }
    }
}

// MARK: - @KeychainData (Raw Data Property Wrapper)

/// A property wrapper that reads and writes raw `Data` to the Keychain.
///
/// Useful for cryptographic keys, certificates, or any binary data.
///
/// ```swift
/// @KeychainData("encryption_key") var encryptionKey: Data?
/// encryptionKey = symmetricKey.rawRepresentation
/// ```
@propertyWrapper
public struct KeychainData: Sendable {

    private let key: String
    private let accessibility: KeychainAccessibility
    private let store: KeychainStore

    public init(
        _ key: String,
        accessibility: KeychainAccessibility = .whenUnlocked,
        service: String = Bundle.main.bundleIdentifier ?? "com.keychainkit.default"
    ) {
        self.key = key
        self.accessibility = accessibility
        self.store = KeychainStore(service: service)
    }

    public var wrappedValue: Data? {
        get { try? store.read(forKey: key) }
        nonmutating set {
            if let data = newValue {
                try? store.saveOrUpdate(data, forKey: key, accessibility: accessibility)
            } else {
                try? store.delete(forKey: key)
            }
        }
    }
}
