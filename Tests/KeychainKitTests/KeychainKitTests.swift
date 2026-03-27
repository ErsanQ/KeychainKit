import XCTest
@testable import KeychainKit

// MARK: - Test Keys
extension KeychainKey {
    static let testKey    = KeychainKey("test_key")
    static let testData   = KeychainKey("test_data")
    static let testObject = KeychainKey("test_object")
}

final class KeychainKitTests: XCTestCase {

    private let testService = "com.keychainkit.tests"
    private var store: KeychainStore!

    override func setUp() {
        super.setUp()
        store = KeychainStore(service: testService)
        try? store.delete(forKey: KeychainKey.testKey.rawValue)
        try? store.delete(forKey: KeychainKey.testData.rawValue)
    }

    override func tearDown() {
        try? store.delete(forKey: KeychainKey.testKey.rawValue)
        try? store.delete(forKey: KeychainKey.testData.rawValue)
        super.tearDown()
    }

    // MARK: - KeychainKey

    func test_keychainKey_rawValue() {
        let key = KeychainKey("auth_token")
        XCTAssertEqual(key.rawValue, "auth_token")
    }

    func test_keychainKey_stringLiteral() {
        let key: KeychainKey = "auth_token"
        XCTAssertEqual(key.rawValue, "auth_token")
    }

    func test_keychainKey_equatable() {
        XCTAssertEqual(KeychainKey("a"), KeychainKey("a"))
        XCTAssertNotEqual(KeychainKey("a"), KeychainKey("b"))
    }

    func test_keychainKey_staticExtension() {
        XCTAssertEqual(KeychainKey.testKey.rawValue, "test_key")
    }

    // MARK: - KeychainStore

    func test_store_saveAndRead() throws {
        let data = "hello".data(using: .utf8)!
        try store.save(data, forKey: KeychainKey.testKey.rawValue, accessibility: .whenUnlocked)
        let result = try store.read(forKey: KeychainKey.testKey.rawValue)
        XCTAssertEqual(String(data: result, encoding: .utf8), "hello")
    }

    func test_store_duplicate_throwsDuplicateItem() throws {
        let data = "value".data(using: .utf8)!
        try store.save(data, forKey: KeychainKey.testKey.rawValue, accessibility: .whenUnlocked)
        XCTAssertThrowsError(
            try store.save(data, forKey: KeychainKey.testKey.rawValue, accessibility: .whenUnlocked)
        ) { error in
            XCTAssertEqual(error as? KeychainError, .duplicateItem)
        }
    }

    func test_store_readMissing_throwsItemNotFound() {
        XCTAssertThrowsError(try store.read(forKey: "ghost")) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_store_saveOrUpdate_upserts() throws {
        let d1 = "first".data(using: .utf8)!
        let d2 = "second".data(using: .utf8)!
        try store.saveOrUpdate(d1, forKey: KeychainKey.testKey.rawValue, accessibility: .whenUnlocked)
        try store.saveOrUpdate(d2, forKey: KeychainKey.testKey.rawValue, accessibility: .whenUnlocked)
        let result = try store.read(forKey: KeychainKey.testKey.rawValue)
        XCTAssertEqual(String(data: result, encoding: .utf8), "second")
    }

    func test_store_delete_removesItem() throws {
        let data = "value".data(using: .utf8)!
        try store.save(data, forKey: KeychainKey.testKey.rawValue, accessibility: .whenUnlocked)
        try store.delete(forKey: KeychainKey.testKey.rawValue)
        XCTAssertThrowsError(try store.read(forKey: KeychainKey.testKey.rawValue))
    }

    func test_store_exists() throws {
        XCTAssertFalse(store.exists(forKey: KeychainKey.testKey.rawValue))
        let data = "v".data(using: .utf8)!
        try store.save(data, forKey: KeychainKey.testKey.rawValue, accessibility: .whenUnlocked)
        XCTAssertTrue(store.exists(forKey: KeychainKey.testKey.rawValue))
    }

    // MARK: - withLock

    func test_withLock_savesValue() {
        @KeychainItem(.testKey) var token: String?
        $token.withLock { $0 = "locked_value" }
        XCTAssertEqual(token, "locked_value")
        $token.withLock { $0 = nil }
    }

    func test_withLock_deletesValue() {
        @KeychainItem(.testKey) var token: String?
        token = "initial"
        $token.withLock { $0 = nil }
        XCTAssertNil(token)
    }

    func test_withLock_conditionalUpdate() {
        @KeychainItem(.testKey) var token: String?
        token = nil
        $token.withLock { if $0 == nil { $0 = "default" } }
        XCTAssertEqual(token, "default")
        $token.withLock { $0 = nil }
    }

    // MARK: - KeychainError

    func test_error_descriptions_notNil() {
        XCTAssertNotNil(KeychainError.duplicateItem.errorDescription)
        XCTAssertNotNil(KeychainError.itemNotFound.errorDescription)
        XCTAssertNotNil(KeychainError.invalidData.errorDescription)
        XCTAssertNotNil(KeychainError.unexpectedStatus(-1).errorDescription)
    }

    func test_error_requiresSettingsRedirect_onlyForPermission() {
        XCTAssertFalse(KeychainError.itemNotFound.requiresSettingsRedirect)
        XCTAssertFalse(KeychainError.duplicateItem.requiresSettingsRedirect)
    }

    // MARK: - Accessibility

    func test_accessibility_allDistinct() {
        let all: [KeychainAccessibility] = [
            .whenUnlocked, .afterFirstUnlock, .always,
            .whenUnlockedThisDeviceOnly, .afterFirstUnlockThisDeviceOnly
        ]
        let strings = all.map { $0.cfString as String }
        XCTAssertEqual(Set(strings).count, all.count)
    }

    // MARK: - Sendable

    func test_sendable_conformances() {
        let _: any Sendable = KeychainKey("x")
        let _: any Sendable = KeychainError.duplicateItem
        let _: any Sendable = KeychainAccessibility.whenUnlocked
    }
}

// MARK: - KeychainError: Equatable
extension KeychainError: Equatable {
    public static func == (lhs: KeychainError, rhs: KeychainError) -> Bool {
        switch (lhs, rhs) {
        case (.duplicateItem, .duplicateItem): return true
        case (.itemNotFound, .itemNotFound):   return true
        case (.invalidData, .invalidData):     return true
        case (.unexpectedStatus(let l), .unexpectedStatus(let r)): return l == r
        default: return false
        }
    }
}
