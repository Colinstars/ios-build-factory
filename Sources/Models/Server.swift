import Foundation

struct Server: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var authType: AuthType
    var tag: String?            // 分组标签 (如: 生产, 测试, 香港)
    var osType: String?         // 操作系统识别 (如: debian, ubuntu, centos, alpine, arch, linux)
    var region: String?         // 地区/数据中心 (如: 洛杉矶, 香港, 日本, 美西)

    enum AuthType: Codable, Hashable {
        case password(String)
        case sshKey(keyId: UUID)
    }

    init(id: UUID = UUID(),
         name: String,
         host: String,
         port: Int = 22,
         username: String = "root",
         authType: AuthType,
         tag: String? = nil,
         osType: String? = nil,
         region: String? = nil) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authType = authType
        self.tag = tag
        self.osType = osType
        self.region = region
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
