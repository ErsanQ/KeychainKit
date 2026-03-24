import XCTest
@testable import KeychainKit

final class KeychainKitTests: XCTestCase {

    private let testService = "com.keychainkit.tests"
    private var store: KeychainStore!

    override func setUp() {
        super.setUp()
        store = KeychainStore(service: testService)
        // Clean slate before each test
        try? store.delete(forKey: "test_key")
        try? store.delete(forKey: "test_data")
        try? store.delete(forKey: "test_object")
    }

    override func tearDown() {
        try? store.delete(forKey: "test_key")
        try? store.delete(forKey: "test_data")
        try? store.delete(forKey: "test_object")
        super.tearDown()
    }

    // MARK: - KeychainStore: Save & Read

    func test_store_saveAndRead_string() throws {
        let data = "hello".data(using: .utf8)!
        try store.save(data, forKey: "test_key", accessibility: .whenUnlocked)
        let result = try store.read(forKey: "test_key")
        XCTAssertEqual(String(data: result, encoding: .utf8), "hello")
    }

    func test_store_duplicate_throwsDuplicateItem() throws {
        let data = "value".data(using: .utf8)!
        try store.save(data, forKey: "test_key", accessibility: .whenUnlocked)
        XCTAssertThrowsError(
            try store.save(data, forKey: "test_key", accessibility: .whenUnlocked)
        ) { error in
            XCTAssertEqual(error as? KeychainError, KeychainError.duplicateItem)
        }
    }

    func test_store_readMissingKey_throwsItemNotFound() {
        XCTAssertThrowsError(
            try store.read(forKey: "nonexistent_key")
        ) { error in
            XCTAssertEqual(error as? KeychainError, KeychainError.itemNotFound)
        }
    }

    func test_store_update_succeeds() throws {
        let data1 = "old".data(using: .utf8)!
        let data2 = "new".data(using: .utf8)!
        try store.save(data1, forKey: "test_key", accessibility: .whenUnlocked)
        try store.update(data2, forKey: "test_key", accessibility: .whenUnlocked)
        let result = try store.read(forKey: "test_key")
        XCTAssertEqual(String(data: result, encoding: .utf8), "new")
    }

    func test_store_saveOrUpdate_upserts() throws {
        let data1 = "first".data(using: .utf8)!
        let data2 = "second".data(using: .utf8)!
        try store.saveOrUpdate(data1, forKey: "test_key", accessibility: .whenUnlocked)
        try store.saveOrUpdate(data2, forKey: "test_key", accessibility: .whenUnlocked)
        let result = try store.read(forKey: "test_key")
        XCTAssertEqual(String(data: result, encoding: .utf8), "second")
    }

    func test_store_delete_removesItem() throws {
        let data = "value".data(using: .utf8)!
        try store.save(data, forKey: "test_key", accessibility: .whenUnlocked)
        try store.delete(forKey: "test_key")
        XCTAssertThrowsError(try store.read(forKey: "test_key"))
    }

    func test_store_deleteNonexistent_succeeds() {
        XCTAssertNoThrow(try store.delete(forKey: "ghost_key"))
    }

    func test_store_exists_trueWhenPresent() throws {
        let data = "value".data(using: .utf8)!
        try store.save(data, forKey: "test_key", accessibility: .whenUnlocked)
        XCTAssertTrue(store.exists(forKey: "test_key"))
    }

    func test_store_exists_falseWhenAbsent() {
        XCTAssertFalse(store.exists(forKey: "nonexistent"))
    }

    // MARK: - KeychainError

    func test_error_duplicateItem_description() {
        XCTAssertNotNil(KeychainError.duplicateItem.errorDescription)
    }

    func test_error_itemNotFound_description() {
        XCTAssertNotNil(KeychainError.itemNotFound.errorDescription)
    }

    func test_error_unexpectedStatus_includesCode() {
        let error = KeychainError.unexpectedStatus(-25300)
        XCTAssertTrue(error.errorDescription?.contains("-25300") ?? false)
    }

    func test_error_equatable_sameCase() {
        XCTAssertEqual(KeychainError.duplicateItem, KeychainError.duplicateItem)
        XCTAssertEqual(KeychainError.itemNotFound, KeychainError.itemNotFound)
    }

    // MARK: - KeychainAccessibility

    func test_accessibility_cfStrings_areDistinct() {
        let all: [KeychainAccessibility] = [
            .whenUnlocked, .afterFirstUnlock, .always,
            .whenUnlockedThisDeviceOnly, .afterFirstUnlockThisDeviceOnly
        ]
        let strings = all.map { $0.cfString as String }
        XCTAssertEqual(Set(strings).count, all.count)
    }

    // MARK: - Sendable Conformance

    func test_keychainError_isSendable() {
        let _: any Sendable = KeychainError.duplicateItem
    }

    func test_accessibility_isSendable() {
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
