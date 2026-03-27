# KeychainKit

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?logo=swift" alt="Swift 5.9"/>
  <img src="https://img.shields.io/badge/iOS-16%2B-blue?logo=apple" alt="iOS 16+"/>
  <img src="https://img.shields.io/badge/macOS-13%2B-blue?logo=apple" alt="macOS 13+"/>
  <img src="https://img.shields.io/badge/SPM-compatible-green" alt="SPM compatible"/>
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="MIT License"/>
</p>

<p align="center">
  The Keychain, finally made simple. One property wrapper. Zero boilerplate.
</p>

---

<p align="center">
  The Keychain, finally made simple. One property wrapper. Zero boilerplate.
</p>

---

## The Problem

Every iOS developer has written this before:

```swift
// 😭 Native Keychain API — 15 lines to save a single string
var query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "auth_token",
    kSecValueData as String: data,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
]
SecItemDelete(query as CFDictionary)
let status = SecItemAdd(query as CFDictionary, nil)
guard status == errSecSuccess else { /* handle error */ }
```

## The Solution

```swift
// 😍 KeychainKit — 1 line
@KeychainItem("auth_token") var token: String?
```

---

## Features

- ✅ `@KeychainItem` — stores `String?` with one line
- ✅ `@KeychainObject` — stores any `Codable` type as JSON
- ✅ `@KeychainData` — stores raw `Data` (keys, certificates)
- ✅ Static `Keychain` API for imperative usage
- ✅ 5 accessibility levels
- ✅ Full error handling via `KeychainError`
- ✅ Zero dependencies — wraps native `Security.framework`
- ✅ iOS 16+, macOS 13+, tvOS, watchOS, visionOS

---

## Installation

### Swift Package Manager

In Xcode: `File → Add Package Dependencies` and enter:

```
https://github.com/ErsanQ/KeychainKit
```

Or in `Package.swift`:

```swift
.package(url: "https://github.com/ErsanQ/KeychainKit", from: "1.0.0")
```

---

## Usage

### Property Wrappers (Recommended)

```swift
import KeychainKit

// String
@KeychainItem("auth_token") var token: String?

token = "eyJhbGci..."   // Save
print(token)             // Read
token = nil              // Delete

// Codable
struct Session: Codable {
    let accessToken: String
    let expiresAt: Date
}

@KeychainObject("session") var session: Session?

session = Session(accessToken: "...", expiresAt: .now + 3600)
print(session?.accessToken)
session = nil

// Raw Data
@KeychainData("encryption_key") var encryptionKey: Data?
encryptionKey = key.rawRepresentation
```

### Static API

```swift
// Save
try Keychain.save("eyJhbGci...", forKey: "auth_token")

// Read
let token = try Keychain.string(forKey: "auth_token")

// Optional read (no throw)
let token = Keychain.stringOrNil(forKey: "auth_token")

// Codable
try Keychain.save(user, forKey: "current_user")
let user = try Keychain.object(User.self, forKey: "current_user")

// Delete
try Keychain.delete(forKey: "auth_token")

// Check existence
Keychain.exists(forKey: "auth_token") // Bool

// All keys
let keys = try Keychain.allKeys()
```

### Error Handling

```swift
do {
    let token = try Keychain.string(forKey: "auth_token")
    useToken(token)
} catch KeychainError.itemNotFound {
    redirectToLogin()
} catch {
    print(error.localizedDescription)
}
```

### Custom Accessibility

```swift
// Background-safe (survives device restart without unlock)
@KeychainItem("push_token", accessibility: .afterFirstUnlock)
var pushToken: String?

// Device-only (not synced to iCloud)
@KeychainItem("biometric_key", accessibility: .whenUnlockedThisDeviceOnly)
var biometricKey: String?
```

---

## API Reference

### Property Wrappers

| Wrapper | Type | Description |
|---------|------|-------------|
| `@KeychainItem("key")` | `String?` | Stores a string value |
| `@KeychainObject("key")` | `T: Codable?` | Stores any Codable as JSON |
| `@KeychainData("key")` | `Data?` | Stores raw binary data |

### `Keychain` Static API

| Method | Description |
|--------|-------------|
| `save(_:forKey:)` | Save String, Data, or Codable |
| `string(forKey:)` | Read a String (throws if not found) |
| `stringOrNil(forKey:)` | Read a String (returns nil if not found) |
| `object(_:forKey:)` | Read a Codable object (throws) |
| `objectOrNil(_:forKey:)` | Read a Codable object (returns nil) |
| `data(forKey:)` | Read raw Data (throws) |
| `delete(forKey:)` | Delete an item |
| `exists(forKey:)` | Check if a key exists |
| `allKeys()` | List all stored keys |

### `KeychainAccessibility`

| Case | Description |
|------|-------------|
| `.whenUnlocked` | Default. Accessible while unlocked |
| `.afterFirstUnlock` | Accessible after first unlock (background-safe) |
| `.always` | Always accessible |
| `.whenUnlockedThisDeviceOnly` | Unlocked only, not synced to iCloud |
| `.afterFirstUnlockThisDeviceOnly` | After first unlock, not synced to iCloud |

---

## Requirements

- iOS 16.0+ / macOS 13.0+ / tvOS 16.0+ / watchOS 9.0+ / visionOS 1.0+
- Swift 5.9+
- Xcode 15.0+

---

## License

KeychainKit is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

---

## Author

Built by **Ersan Q Abo Esha** — [@ErsanQ](https://github.com/ErsanQ)

If KeychainKit saved you time, consider giving it a ⭐️ on [GitHub](https://github.com/ErsanQ/KeychainKit).
