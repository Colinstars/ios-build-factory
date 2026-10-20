import Foundation

/// Docker 容器数据模型
struct DockerContainer: Identifiable, Hashable {
    let id: String          // 容器短 ID (如 7f8a9b0c)
    let image: String       // 镜像名 (如 nginx:alpine)
    let status: String      // 状态文本 (如 Up 2 hours / Exited (0) 5 mins ago)
    let isRunning: Bool
    let names: String       // 容器名称 (如 web-gateway)
}

/// Linux 进程信息模型
struct LinuxProcess: Identifiable, Hashable {
    let id: String          // PID
    let pid: Int
    let user: String
    let cpuPercent: Double
    let memPercent: Double
    let command: String
}

/// 快速诊断体检报告模型
struct QuickHealthReport {
    var loadStatus: String = "正常"
    var memoryStatus: String = "充足"
    var diskStatus: String = "健康"
    var zombieProcs: Int = 0
    var tcpEstablished: Int = 0
}
