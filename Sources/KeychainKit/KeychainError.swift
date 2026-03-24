import Foundation

// MARK: - KeychainError

/// Describes errors that can occur during Keychain operations.
///
/// ```swift
/// do {
///     try Keychain.save("my_token", forKey: "auth")
/// } catch KeychainError.duplicateItem {
///     try Keychain.update("my_token", forKey: "auth")
/// } catch {
///     print(error.localizedDescription)
/// }
/// ```
public enum KeychainError: LocalizedError, Sendable {

    /// An item with this key already exists in the Keychain.
    case duplicateItem

    /// No item was found for the given key.
    case itemNotFound

    /// The data could not be encoded or decoded.
    case invalidData

    /// The Keychain returned an unexpected status code.
    case unexpectedStatus(OSStatus)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .duplicateItem:
            return "A Keychain item with this key already exists."
        case .itemNotFound:
            return "No Keychain item was found for this key."
        case .invalidData:
            return "The data could not be encoded or decoded."
        case .unexpectedStatus(let status):
            return "Keychain operation failed with status: \(status)."
        }
    }
}
