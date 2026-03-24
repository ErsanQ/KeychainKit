import Foundation

// MARK: - Keychain

/// A clean static API for reading, writing, and deleting Keychain items.
///
/// ## Saving & Reading Strings
/// ```swift
/// // Save
/// try Keychain.save("eyJhbGci...", forKey: "auth_token")
///
/// // Read
/// let token = try Keychain.string(forKey: "auth_token")
///
/// // Delete
/// try Keychain.delete(forKey: "auth_token")
/// ```
///
/// ## Saving Codable Objects
/// ```swift
/// struct User: Codable {
///     let id: String
///     let email: String
/// }
///
/// let user = User(id: "123", email: "user@example.com")
/// try Keychain.save(user, forKey: "current_user")
///
/// let saved = try Keychain.object(User.self, forKey: "current_user")
/// ```
///
/// ## Optional reads (no throw)
/// ```swift
/// let token = Keychain.stringOrNil(forKey: "auth_token")
/// ```
public enum Keychain {

    // MARK: - Default Store

    private static let store = KeychainStore()

    // MARK: - Save: String

    /// Saves a `String` to the Keychain.
    ///
    /// - Parameters:
    ///   - value: The string to store.
    ///   - key: A unique key identifying this item.
    ///   - accessibility: When the item can be accessed. Defaults to `.whenUnlocked`.
    public static func save(
        _ value: String,
        forKey key: String,
        accessibility: KeychainAccessibility = .whenUnlocked
    ) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try store.saveOrUpdate(data, forKey: key, accessibility: accessibility)
    }

    // MARK: - Save: Data

    /// Saves raw `Data` to the Keychain.
    public static func save(
        _ data: Data,
        forKey key: String,
        accessibility: KeychainAccessibility = .whenUnlocked
    ) throws {
        try store.saveOrUpdate(data, forKey: key, accessibility: accessibility)
    }

    // MARK: - Save: Codable

    /// Saves any `Codable` object to the Keychain as JSON.
    ///
    /// ```swift
    /// try Keychain.save(currentUser, forKey: "user")
    /// ```
    public static func save<T: Codable>(
        _ value: T,
        forKey key: String,
        accessibility: KeychainAccessibility = .whenUnlocked
    ) throws {
        let data = try JSONEncoder().encode(value)
        try store.saveOrUpdate(data, forKey: key, accessibility: accessibility)
    }

    // MARK: - Read: String

    /// Reads a `String` from the Keychain.
    ///
    /// - Throws: ``KeychainError/itemNotFound`` if the key doesn't exist.
    public static func string(forKey key: String) throws -> String {
        let data = try store.read(forKey: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }

    /// Reads a `String` from the Keychain, returning `nil` if not found.
    public static func stringOrNil(forKey key: String) -> String? {
        try? string(forKey: key)
    }

    // MARK: - Read: Data

    /// Reads raw `Data` from the Keychain.
    public static func data(forKey key: String) throws -> Data {
        try store.read(forKey: key)
    }

    /// Reads raw `Data` from the Keychain, returning `nil` if not found.
    public static func dataOrNil(forKey key: String) -> Data? {
        try? store.read(forKey: key)
    }

    // MARK: - Read: Codable

    /// Reads and decodes a `Codable` object from the Keychain.
    ///
    /// ```swift
    /// let user = try Keychain.object(User.self, forKey: "user")
    /// ```
    public static func object<T: Codable>(_ type: T.Type, forKey key: String) throws -> T {
        let data = try store.read(forKey: key)
        return try JSONDecoder().decode(type, from: data)
    }

    /// Reads and decodes a `Codable` object, returning `nil` if not found or decoding fails.
    public static func objectOrNil<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        try? object(type, forKey: key)
    }

    // MARK: - Delete

    /// Removes an item from the Keychain.
    ///
    /// Silently succeeds if the key doesn't exist.
    public static func delete(forKey key: String) throws {
        try store.delete(forKey: key)
    }

    // MARK: - Exists

    /// Returns `true` if an item exists for the given key.
    public static func exists(forKey key: String) -> Bool {
        store.exists(forKey: key)
    }

    // MARK: - All Keys

    /// Returns all keys stored by this app in the Keychain.
    public static func allKeys() throws -> [String] {
        try store.allKeys()
    }
}
