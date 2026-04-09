import Testing
import Foundation
@testable import StickerBoard

struct KeychainHelperTests {

    private let helper = KeychainHelper(service: "com.tebasaki.StickerBoard.test")

    @Test func boolを保存して読み込める() throws {
        let key = "test_bool_key"
        helper.save(bool: true, forKey: key)
        #expect(helper.bool(forKey: key) == true)
        helper.delete(forKey: key)
    }

    @Test func falseを保存して読み込める() {
        let key = "test_bool_false_key"
        helper.save(bool: false, forKey: key)
        #expect(helper.bool(forKey: key) == false)
        helper.delete(forKey: key)
    }

    @Test func 存在しないキーはfalseを返す() {
        let key = "non_existent_key_\(UUID().uuidString)"
        #expect(helper.bool(forKey: key) == false)
    }

    @Test func 上書き保存が正しく動作する() {
        let key = "test_overwrite_key"
        helper.save(bool: true, forKey: key)
        helper.save(bool: false, forKey: key)
        #expect(helper.bool(forKey: key) == false)
        helper.delete(forKey: key)
    }

    @Test func 削除後はfalseを返す() {
        let key = "test_delete_key"
        helper.save(bool: true, forKey: key)
        helper.delete(forKey: key)
        #expect(helper.bool(forKey: key) == false)
    }

    @Test func 異なるキーは独立している() {
        let keyA = "test_key_a"
        let keyB = "test_key_b"
        helper.save(bool: true, forKey: keyA)
        helper.save(bool: false, forKey: keyB)
        #expect(helper.bool(forKey: keyA) == true)
        #expect(helper.bool(forKey: keyB) == false)
        helper.delete(forKey: keyA)
        helper.delete(forKey: keyB)
    }
}
