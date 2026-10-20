import Foundation

final class ServerStore {
    static let shared = ServerStore()
    private let key = "serverlens.servers.v1"

    private(set) var servers: [Server] = []

    private init() {
        load()
        if servers.isEmpty {
            // 预置一条本地/示例，方便首次启动看效果
            servers = [
                Server(
                    name: "DMIT 示例",
                    host: "179.253.225.179",
                    port: 22,
                    username: "root",
                    authType: .password("")
                )
            ]
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
