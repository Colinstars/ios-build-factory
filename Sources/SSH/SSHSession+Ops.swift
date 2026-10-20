import Foundation
import NIOCore

extension SSHSession {

    /// 探测并抓取服务器运行中的 Docker 容器
    func fetchDockerContainers() async throws -> [DockerContainer] {
        // 利用 format 直接格式化输出，单条命令极速解析
        let cmd = "docker ps -a --format '{{.ID}}|||{{.Image}}|||{{.Status}}|||{{.Names}}' 2>/dev/null || echo 'NO_DOCKER'"
        var buf = try await executeRawCommand(cmd)
        guard let text = buf.readString(length: buf.readableBytes) else { return [] }
        if text.contains("NO_DOCKER") { return [] }

        var list: [DockerContainer] = []
        for line in text.split(separator: "\n") {
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 4 else { continue }
            let id = parts[0].trimmingCharacters(in: .whitespaces)
            let img = parts[1].trimmingCharacters(in: .whitespaces)
            let status = parts[2].trimmingCharacters(in: .whitespaces)
            let name = parts[3].trimmingCharacters(in: .whitespaces)
            let running = status.lowercased().hasPrefix("up")

            list.append(DockerContainer(
                id: id,
                image: img,
                status: status,
                isRunning: running,
                names: name
            ))
        }
        return list
    }

    /// 控制容器生命周期 (start / stop / restart)
    func controlDocker(action: String, containerId: String) async throws -> String {
        let cmd = "docker \(action) \(containerId)"
        var buf = try await executeRawCommand(cmd)
        return buf.readString(length: buf.readableBytes) ?? ""
    }

    /// 抓取 CPU 占用最高的前 10 个系统进程
    func fetchTopProcesses() async throws -> [LinuxProcess] {
        let cmd = "ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 11"
        var buf = try await executeRawCommand(cmd)
        guard let text = buf.readString(length: buf.readableBytes) else { return [] }

        var procs: [LinuxProcess] = []
        let lines = text.split(separator: "\n")
        guard lines.count > 1 else { return [] }

        for line in lines.dropFirst() {
            let cols = line.split(whereSeparator: { $0.isWhitespace })
            guard cols.count >= 5 else { continue }
            let pid = Int(cols[0]) ?? 0
            let user = String(cols[1])
            let cpu = Double(cols[2]) ?? 0.0
            let mem = Double(cols[3]) ?? 0.0
            let comm = String(cols[4])

            procs.append(LinuxProcess(
                id: "\(pid)",
                pid: pid,
                user: user,
                cpuPercent: cpu,
                memPercent: mem,
                command: comm
            ))
        }
        return procs
    }

    /// 一键智能系统健康巡检
    func fetchQuickHealth() async throws -> QuickHealthReport {
        let cmd = "ss -s 2>/dev/null | grep -i 'estab' || netstat -an | grep ESTABLISHED | wc -l; ps -eo stat | grep -c Z"
        var buf = try await executeRawCommand(cmd)
        let text = buf.readString(length: buf.readableBytes) ?? ""
        var report = QuickHealthReport()

        let lines = text.split(separator: "\n")
        if lines.count >= 2 {
            report.zombieProcs = Int(lines[1].trimmingCharacters(in: .whitespaces)) ?? 0
        }
        return report
    }

    func executeRawCommand(_ cmd: String) async throws -> ByteBuffer {
        if !isConnected() {
            try await connect()
        }
        guard let client = self.client else {
            throw NSError(domain: "SSHSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未连接"])
        }
        return try await client.executeCommand(cmd)
    }
}
