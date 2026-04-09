import Foundation
import Security

/// Keychain に bool 値を安全に保存するヘルパー
final class KeychainHelper: Sendable {
    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "com.tebasaki.StickerBoard") {
        self.service = service
    }

    // MARK: - Bool

    func save(bool value: Bool, forKey key: String) {
        let data = Data([value ? 1 : 0])
        save(data: data, forKey: key)
    }

    func bool(forKey key: String) -> Bool {
        guard let data = load(forKey: key), data.first == 1 else { return false }
        return true
    }

    // MARK: - 内部操作

    func delete(forKey key: String) {
        let query = baseQuery(forKey: key)
        SecItemDelete(query as CFDictionary)
    }

    private func save(data: Data, forKey key: String) {
        let query = baseQuery(forKey: key).merging([
            kSecValueData as String: data
        ]) { _, new in new }

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func load(forKey key: String) -> Data? {
        let query = baseQuery(forKey: key).merging([
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]) { _, new in new }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func baseQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}
