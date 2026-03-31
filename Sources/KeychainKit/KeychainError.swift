import Foundation

/// Errors that can occur during Keychain operations.
public enum KeychainError: Error, Sendable {
    /// The item was not found in the Keychain.
    case itemNotFound
    /// The data was found but could not be decoded.
    case decodingError(Error)
    /// The data could not be encoded for storage.
    case encodingError(Error)
    /// A low-level Security framework error occurred.
    /// - Parameter status: The `OSStatus` returned by the framework.
    case securityError(Int32)
    /// An unknown error occurred.
    case unknown
}

extension KeychainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .itemNotFound: return "Item not found in Keychain."
        case .decodingError(let error): return "Failed to decode Keychain data: \(error.localizedDescription)"
        case .encodingError(let error): return "Failed to encode data for Keychain: \(error.localizedDescription)"
        case .securityError(let status): return "Security framework error (Status: \(status))."
        case .unknown: return "An unknown Keychain error occurred."
        }
    }
}
