import Foundation

/// 全局 SSH 密钥存储仓库
final class SSHKeyStore {
    static let shared = SSHKeyStore()
    private let key = "serverlens.sshkeys.v3"

    private(set) var keys: [SSHKey] = []

    // 预置的 DMIT 专用有效 Ed25519 密钥 UUID
    static let dmitKeyId = UUID(uuidString: "77777777-8888-9999-aaaa-bbbbccccdddd")!

    private init() {
        load()
        if keys.isEmpty {
            // 内置服务器端 authorized_keys 真正信任的有效 Ed25519 密钥 (id_new)
            let dmitKey = SSHKey(
                id: SSHKeyStore.dmitKeyId,
                name: "DMIT LAX (Ed25519)",
                keyType: .ed25519,
                privateKeyPEM: """
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACBnaBJX7OI3sfJfbO/Q55VvUtSiQI5Sxp0vqfeuhUk0SgAAAJiKSzTYiks0
2AAAAAtzc2gtZWQyNTUxOQAAACBnaBJX7OI3sfJfbO/Q55VvUtSiQI5Sxp0vqfeuhUk0Sg
AAAEAQeci1m0AEItEYAc4ts7TzpmgA1/3Vtm3GSGSzRKlGJWdoElfs4jex8l9s79DnlW9S
1KJAjlLGnS+p966FSTRKAAAAEWNlbm9yZWNAZ21haWwuY29tAQIDBA==
-----END OPENSSH PRIVATE KEY-----
""",
                publicKeyOpenSSH: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGdoElfswjex8l9s79DnlW9S1KJAjlLGnS+p966FSTRK cenorec@gmail.com"
            )

            let localGenKey = SSHKey.generateEd25519(name: "备用 Ed25519 密钥")
            keys = [dmitKey, localGenKey]
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
