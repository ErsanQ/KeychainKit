import Security

// MARK: - KeychainAccessibility

/// Controls when a Keychain item can be accessed.
///
/// Choose the most restrictive accessibility level that meets your needs:
///
/// ```swift
/// // Accessible only when device is unlocked (recommended for most cases)
/// try Keychain.save(token, forKey: "auth", accessibility: .whenUnlocked)
///
/// // Accessible after first unlock (good for background tasks)
/// try Keychain.save(token, forKey: "auth", accessibility: .afterFirstUnlock)
/// ```
public enum KeychainAccessibility: Sendable {

    /// Item is accessible only while the device is unlocked.
    ///
    /// This is the **recommended default** for most use cases.
    /// The item is not backed up to iCloud.
    case whenUnlocked

    /// Item is accessible after the first unlock following a device restart.
    ///
    /// Suitable for items accessed by background tasks.
    case afterFirstUnlock

    /// Item is always accessible, regardless of lock state.
    ///
    /// - Warning: Use only for items that must be accessed in all circumstances.
    case always

    /// Item is accessible only while unlocked and **not** synced to iCloud.
    case whenUnlockedThisDeviceOnly

    /// Item is accessible after first unlock and **not** synced to iCloud.
    case afterFirstUnlockThisDeviceOnly

    // MARK: - Internal

    var cfString: CFString {
        switch self {
        case .whenUnlocked:                return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock:            return kSecAttrAccessibleAfterFirstUnlock
        case .always:                      return kSecAttrAccessibleAlways
        case .whenUnlockedThisDeviceOnly:  return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }
}
