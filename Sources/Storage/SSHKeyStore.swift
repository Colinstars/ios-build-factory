import Foundation

/// 全局 SSH 密钥存储仓库
final class SSHKeyStore {
    static let shared = SSHKeyStore()
    private let key = "serverlens.sshkeys.v1"

    private(set) var keys: [SSHKey] = []

    private init() {
        load()
        if keys.isEmpty {
            // 默认内置生成一个默认的 ed25519 密钥
            let defaultKey = SSHKey.generateEd25519(name: "默认 Ed25519 密钥")
            keys = [defaultKey]
            save()
        }
    }

    func add(_ sshKey: SSHKey) {
        keys.append(sshKey)
        save()
    }

    func delete(at index: Int) {
        guard index < keys.count else { return }
        keys.remove(at: index)
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(keys) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let list = try? JSONDecoder().decode([SSHKey].self, from: data) {
            self.keys = list
        }
    }
}
