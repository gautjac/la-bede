import Foundation
import Security

/// Tiny Keychain wrapper for the one secret La Bédé needs: the user's Fal.ai API
/// key, used to draw the comic panels with a real diffusion model. Stored in the
/// Keychain (not UserDefaults) so the key never lands in a plist or a backup in
/// the clear.
enum Secrets {
    private static let service = "com.jac.LaBede"
    private static let account = "fal_api_key"

    /// The stored Fal.ai key, or nil if the user hasn't added one yet.
    static var falKey: String? {
        get { read(account) }
        set {
            if let newValue, !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                write(newValue.trimmingCharacters(in: .whitespacesAndNewlines), account: account)
            } else {
                delete(account)
            }
        }
    }

    /// True when a non-empty key is stored.
    static var hasFalKey: Bool {
        guard let k = falKey else { return false }
        return !k.isEmpty
    }

    // MARK: Keychain primitives

    private static func write(_ value: String, account: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(insert as CFDictionary, nil)
        }
    }

    private static func read(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }

    private static func delete(_ account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
