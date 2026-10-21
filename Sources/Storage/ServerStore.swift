import Foundation

final class ServerStore {
    static let shared = ServerStore()
    private let key = "serverlens.servers.v6"

    private(set) var servers: [Server] = []

    private init() {
        load()
        if servers.isEmpty {
            // 默认初始主机（不固化 osType 与 region，由应用在连通和网络请求中动态自适应拉取）
            servers = [
                Server(
                    name: "DMIT-LAX.PRO",
                    host: "179.253.225.179",
                    port: 22,
                    username: "root",
                    authType: .sshKey(keyId: SSHKeyStore.dmitKeyId),
                    tag: nil,
                    osType: nil,
                    region: nil
                )
            ]
            save()
        }
    }

    func add(_ server: Server) {
        servers.append(server)
        save()
    }

    func updateMetadata(for id: UUID, os: String? = nil, region: String? = nil) {
        guard let idx = servers.firstIndex(where: { $0.id == id }) else { return }
        var changed = false
        if let os = os, servers[idx].osType != os {
            servers[idx].osType = os
            changed = true
        }
        if let reg = region, servers[idx].region != reg {
            servers[idx].region = reg
            changed = true
        }
        if changed {
            save()
        }
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
