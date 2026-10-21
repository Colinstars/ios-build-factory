import Foundation

/// 全局 SSH 密钥存储仓库
final class SSHKeyStore {
    static let shared = SSHKeyStore()
    private let key = "serverlens.sshkeys.v2"

    private(set) var keys: [SSHKey] = []

    // 预置的 DMIT 专用 Ed25519 密钥 UUID (方便 ServerStore 默认绑定)
    static let dmitKeyId = UUID(uuidString: "77777777-8888-9999-aaaa-bbbbccccdddd")!

    private init() {
        load()
        if keys.isEmpty {
            // 内置用户的真实 DMIT Ed25519 密钥（直连免去手动复制粘贴之苦）
            let dmitKey = SSHKey(
                id: SSHKeyStore.dmitKeyId,
                name: "DMIT LAX (Ed25519)",
                keyType: .ed25519,
                privateKeyPEM: """
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACAJtAKsc2czg96/IOxGwtmUDdyDOMIncTfOnWCkkpjCeAAAAJhFW+lKRVvp
SgAAAAtzc2gtZWQyNTUxOQAAACAJtAKsc2czg96/IOxGwtmUDdyDOMIncTfOnWCkkpjCeA
AAAECPslXBf26MaNzOhlzQwAUxWPCSeQYTl/1huZkecKB4lQm0AqxzZzOD3r8g7EbC2ZQN
3IM4widxN86dYKSSmMJ4AAAAEWNlbm9yZWNAZ21haWwuY29tAQIDBA==
-----END OPENSSH PRIVATE KEY-----
""",
                publicKeyOpenSSH: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAm0AqxzZzOD3r8g7EbC2ZQN3IM4widxN86dYKSSmMJ4 cenorec@gmail.com"
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
