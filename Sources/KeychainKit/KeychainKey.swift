import Foundation

// MARK: - KeychainKey

/// A type-safe identifier for a Keychain item.
///
/// Instead of raw strings (which are typo-prone), define your keys once
/// and reference them everywhere with compile-time safety:
///
/// ```swift
/// extension KeychainKey {
///     static let accessToken  = KeychainKey("access_token")
///     static let refreshToken = KeychainKey("refresh_token")
///     static let userSession  = KeychainKey("user_session")
///     static let deviceId     = KeychainKey("device_id")
/// }
///
/// // Usage — no raw strings, no typos
/// @KeychainItem(.accessToken)  var token: String?
/// @KeychainItem(.refreshToken) var refresh: String?
/// @KeychainObject(.userSession) var session: AuthSession?
/// ```
public struct KeychainKey: Sendable, Hashable, ExpressibleByStringLiteral {

    /// The underlying raw string stored in the Keychain.
    public let rawValue: String

    // MARK: - Init

    /// Creates a key with a raw string identifier.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Allows string literals to be used directly as ``KeychainKey``.
    ///
    /// This enables backward-compatible usage:
    /// ```swift
    /// @KeychainItem("auth_token") var token: String?  // still works
    /// @KeychainItem(.accessToken) var token: String?  // preferred
    /// ```
    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }
}
