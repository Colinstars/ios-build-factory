import Foundation

final class ServerStore {
    static let shared = ServerStore()
    private let key = "serverlens.servers.v2"

    private(set) var servers: [Server] = []

    private init() {
        load()
        if servers.isEmpty {
            // 预置已绑定 Ed25519 私钥的真实 DMIT 主机，开箱即用 100% 瞬连！
            servers = [
                Server(
                    name: "DMIT-LAX.PRO",
                    host: "179.253.225.179",
                    port: 22,
                    username: "root",
                    authType: .sshKey(keyId: SSHKeyStore.dmitKeyId),
                    tag: "生产 / 洛杉矶"
                )
            ]
            save()
        }
    }

    func add(_ server: Server) {
        servers.append(server)
        save()
    }

    func delete(at index: Int) {
        guard index < servers.count else { return }
        servers.remove(at: index)
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let list = try? JSONDecoder().decode([Server].self, from: data) {
            self.servers = list
        }
    }
}
