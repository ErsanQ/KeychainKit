import Foundation

// MARK: - @KeychainItem (Property Wrapper)

/// A property wrapper that reads and writes `String?` values directly to the Keychain.
///
/// ## Recommended — type-safe key (no typos)
/// ```swift
/// extension KeychainKey {
///     static let accessToken = KeychainKey("access_token")
/// }
///
/// @KeychainItem(.accessToken) var token: String?
///
/// token = "eyJhbGci..."   // Save
/// print(token)             // Read
/// token = nil              // Delete
/// ```
///
/// ## Thread-safe mutation with `withLock`
/// ```swift
/// $token.withLock { $0 = "new_token" }
/// $token.withLock { $0 = nil }
/// ```
///
/// ## Legacy — raw string (still supported)
/// ```swift
/// @KeychainItem("auth_token") var token: String?
/// ```
@propertyWrapper
public struct KeychainItem: Sendable {

    private let key: KeychainKey
    private let accessibility: KeychainAccessibility
    private let store: KeychainStore
    private let lock = NSLock()

    /// Creates a Keychain-backed property using a type-safe ``KeychainKey``.
    public init(
        _ key: KeychainKey,
        accessibility: KeychainAccessibility = .whenUnlocked,
        service: String = Bundle.main.bundleIdentifier ?? "com.keychainkit.default"
    ) {
        self.key = key
        self.accessibility = accessibility
        self.store = KeychainStore(service: service)
    }

    public var wrappedValue: String? {
        get {
            lock.lock(); defer { lock.unlock() }
            return try? store.read(forKey: key.rawValue)
                .flatMap { String(data: $0, encoding: .utf8) }
        }
        nonmutating set {
            lock.lock(); defer { lock.unlock() }
            _write(newValue)
        }
    }

    /// Enables thread-safe mutation via `$token.withLock { $0 = "value" }`.
    public var projectedValue: KeychainItemProjection {
        KeychainItemProjection(item: self)
    }

    fileprivate func _write(_ newValue: String?) {
        if let value = newValue, let data = value.data(using: .utf8) {
            try? store.saveOrUpdate(data, forKey: key.rawValue, accessibility: accessibility)
        } else {
            try? store.delete(forKey: key.rawValue)
        }
    }

    fileprivate func _read() -> String? {
        try? store.read(forKey: key.rawValue)
            .flatMap { String(data: $0, encoding: .utf8) }
    }

    fileprivate func acquireLock() { lock.lock() }
    fileprivate func releaseLock() { lock.unlock() }
}

// MARK: - KeychainItemProjection

/// Provides thread-safe mutation via `$token.withLock { }`.
public struct KeychainItemProjection: Sendable {

    private let item: KeychainItem

    fileprivate init(item: KeychainItem) { self.item = item }

    /// Performs an atomic read-modify-write on the Keychain value.
    ///
    /// ```swift
    /// $token.withLock { $0 = refreshedToken }   // update
    /// $token.withLock { $0 = nil }              // delete
    /// $token.withLock { if $0 == nil { $0 = "default" } }
    /// ```
    public func withLock(_ body: (inout String?) -> Void) {
        item.acquireLock()
        defer { item.releaseLock() }
        var current = item._read()
        body(&current)
        item._write(current)
    }
}

// MARK: - @KeychainObject (Codable Property Wrapper)

/// A property wrapper that reads and writes any `Codable` type to the Keychain as JSON.
///
/// ```swift
/// extension KeychainKey {
///     static let userSession = KeychainKey("user_session")
/// }
///
/// @KeychainObject(.userSession) var session: AuthSession?
/// ```
@propertyWrapper
public struct KeychainObject<T: Codable & Sendable>: Sendable {

    private let key: KeychainKey
    private let accessibility: KeychainAccessibility
    private let store: KeychainStore
    private let lock = NSLock()

    public init(
        _ key: KeychainKey,
        accessibility: KeychainAccessibility = .whenUnlocked,
        service: String = Bundle.main.bundleIdentifier ?? "com.keychainkit.default"
    ) {
        self.key = key
        self.accessibility = accessibility
        self.store = KeychainStore(service: service)
    }

    public var wrappedValue: T? {
        get {
            lock.lock(); defer { lock.unlock() }
            guard let data = try? store.read(forKey: key.rawValue) else { return nil }
            return try? JSONDecoder().decode(T.self, from: data)
        }
        nonmutating set {
            lock.lock(); defer { lock.unlock() }
            if let value = newValue, let data = try? JSONEncoder().encode(value) {
                try? store.saveOrUpdate(data, forKey: key.rawValue, accessibility: accessibility)
            } else {
                try? store.delete(forKey: key.rawValue)
            }
        }
    }
}

// MARK: - @KeychainData (Raw Data Property Wrapper)

/// A property wrapper that reads and writes raw `Data` to the Keychain.
///
/// ```swift
/// extension KeychainKey {
///     static let encryptionKey = KeychainKey("encryption_key")
/// }
///
/// @KeychainData(.encryptionKey) var encryptionKey: Data?
/// ```
@propertyWrapper
public struct KeychainData: Sendable {

    private let key: KeychainKey
    private let accessibility: KeychainAccessibility
    private let store: KeychainStore
    private let lock = NSLock()

    public init(
        _ key: KeychainKey,
        accessibility: KeychainAccessibility = .whenUnlocked,
        service: String = Bundle.main.bundleIdentifier ?? "com.keychainkit.default"
    ) {
        self.key = key
        self.accessibility = accessibility
        self.store = KeychainStore(service: service)
    }

    public var wrappedValue: Data? {
        get {
            lock.lock(); defer { lock.unlock() }
            return try? store.read(forKey: key.rawValue)
        }
        nonmutating set {
            lock.lock(); defer { lock.unlock() }
            if let data = newValue {
                try? store.saveOrUpdate(data, forKey: key.rawValue, accessibility: accessibility)
            } else {
                try? store.delete(forKey: key.rawValue)
            }
        }
    }
}
