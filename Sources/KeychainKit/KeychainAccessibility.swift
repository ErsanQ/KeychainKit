import Foundation

/// Defines when a Keychain item is accessible to the application.
///
/// These cases correspond to the `kSecAttrAccessible` values in the Security framework.
public enum KeychainAccessibility: Sendable {
    /// Accessible only when the device is unlocked.
    case whenUnlocked
    /// Accessible after the device has been unlocked once after a reboot.
    case afterFirstUnlock
    /// Accessible only when the device is unlocked, and data is not migrated to new devices.
    case whenUnlockedThisDeviceOnly
    /// Accessible after the device has been unlocked once, and data is not migrated.
    case afterFirstUnlockThisDeviceOnly
    
    #if canImport(Security)
    var securityValue: CFString {
        switch self {
        case .whenUnlocked: return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock: return kSecAttrAccessibleAfterFirstUnlock
        case .whenUnlockedThisDeviceOnly: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }
    #endif
}
