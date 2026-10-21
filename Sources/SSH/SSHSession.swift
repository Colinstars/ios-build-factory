import Foundation
import Citadel
import NIOCore
import CryptoKit

actor SSHSession {

    let server: Server
    var client: SSHClient?

    init(server: Server) {
        self.server = server
    }

    func isConnected() -> Bool {
        return client != nil
    }

    func connect() async throws {
        if client != nil { return }

        let settings = SSHClientSettings(
            host: server.host,
            port: server.port,
            authenticationMethod: { [auth = self.server.authType, user = self.server.username] in
                switch auth {
                case .password(let pwd):
                    return .passwordBased(username: user, password: pwd)
                case .sshKey(let keyId):
                    if let keyObj = SSHKeyStore.shared.keys.first(where: { $0.id == keyId }),
                       let privKey = keyObj.parseEd25519PrivateKey() {
                        return .ed25519(username: user, privateKey: privKey)
                    }
                    return .passwordBased(username: user, password: "")
                }
            },
            hostKeyValidator: .acceptAnything()
        )

        client = try await SSHClient.connect(to: settings)
    }

    func disconnect() async {
        if let c = client {
            try? await c.close()
            client = nil
        }
    }

    /// 执行合并命令，单次 RTT 取回 loadavg、meminfo、df、uptime、os-release
    func fetchMetrics() async throws -> ServerMetrics {
        if client == nil {
            try await connect()
        }
        guard let client = client else {
            throw NSError(domain: "SSHSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "未连接"])
        }

        let cmd = "cat /proc/loadavg; echo '==='; cat /proc/meminfo; echo '==='; df -k /; echo '==='; uptime -p; echo '==='; uname -srm"
        var buf = try await client.executeCommand(cmd)
        guard let text = buf.readString(length: buf.readableBytes) else {
            throw NSError(domain: "SSHSession", code: -2, userInfo: [NSLocalizedDescriptionKey: "响应为空"])
        }

        return parseMetrics(text)
    }

    private func parseMetrics(_ text: String) -> ServerMetrics {
        var m = ServerMetrics()
        let sections = text.components(separatedBy: "===\n")
        guard sections.count >= 5 else { return m }

        // 1. loadavg
        let loadParts = sections[0].trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
        if loadParts.count >= 3 {
            m.load1 = Double(loadParts[0]) ?? 0
            m.load5 = Double(loadParts[1]) ?? 0
            m.load15 = Double(loadParts[2]) ?? 0
        }

        // 2. meminfo
        for line in sections[1].split(separator: "\n") {
            if line.hasPrefix("MemTotal:") {
                m.memTotalMB = parseKB(line) / 1024.0
            } else if line.hasPrefix("MemAvailable:") {
                m.memAvailableMB = parseKB(line) / 1024.0
            }
        }

        // 3. df -k /
        let dfLines = sections[2].split(separator: "\n")
        if dfLines.count >= 2 {
            let cols = dfLines[1].split(whereSeparator: { $0.isWhitespace })
            if cols.count >= 4 {
                let totalKB = Double(cols[1]) ?? 0
                let availKB = Double(cols[3]) ?? 0
                m.diskTotalGB = totalKB / (1024.0 * 1024.0)
                m.diskAvailGB = availKB / (1024.0 * 1024.0)
            }
        }

        // 4. uptime -p
        m.uptimeString = sections[3].trimmingCharacters(in: .whitespacesAndNewlines)

        // 5. uname
        m.osString = sections[4].trimmingCharacters(in: .whitespacesAndNewlines)

        return m
    }

    private func parseKB<S: StringProtocol>(_ line: S) -> Double {
        let parts = line.split(separator: ":")
        guard parts.count >= 2 else { return 0 }
        let numStr = parts[1].trimmingCharacters(in: .whitespaces).split(separator: " ").first ?? ""
        return Double(numStr) ?? 0
    }
}
