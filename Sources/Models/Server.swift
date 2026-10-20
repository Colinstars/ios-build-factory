import Foundation

struct Server: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var authType: AuthType

    enum AuthType: Codable, Hashable {
        case password(String)
        case privateKey(key: String, passphrase: String?)
    }

    init(id: UUID = UUID(),
         name: String,
         host: String,
         port: Int = 22,
         username: String = "root",
         authType: AuthType) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authType = authType
    }
}

struct ServerMetrics: Equatable {
    var load1: Double = 0
    var load5: Double = 0
    var load15: Double = 0
    var cpuCores: Int = 1

    var memTotalMB: Double = 0
    var memAvailableMB: Double = 0
    var memUsedPercent: Double {
        guard memTotalMB > 0 else { return 0 }
        return max(0, min(100, (memTotalMB - memAvailableMB) / memTotalMB * 100))
    }

    var diskTotalGB: Double = 0
    var diskAvailGB: Double = 0
    var diskUsedPercent: Double {
        guard diskTotalGB > 0 else { return 0 }
        return max(0, min(100, (diskTotalGB - diskAvailGB) / diskTotalGB * 100))
    }

    var uptimeString: String = "-"
    var osString: String = "-"
    var sampledAt: Date = Date()
}
