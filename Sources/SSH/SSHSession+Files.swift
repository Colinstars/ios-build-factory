import Foundation
import NIOCore

struct RemoteFileItem: Identifiable, Hashable {
    let id: String          // path
    let name: String
    let path: String
    let isDirectory: Bool
    let sizeString: String
    let permissions: String
}

extension SSHSession {

    /// 读取远程目录文件列表 (利用标准 ls 命令，不依赖 SFTP 复杂握手，100% 稳定可靠)
    func listRemoteDirectory(at path: String) async throws -> [RemoteFileItem] {
        let safePath = path.replacingOccurrences(of: "'", with: "'\\''")
        // 输出格式: 权限|所有者|大小|修改时间|文件名
        let cmd = "cd '\(safePath)' 2>/dev/null && ls -la --time-style=+%Y-%m-%d 2>/dev/null || ls -la"
        var buf = try await executeRawCommand(cmd)
        guard let text = buf.readString(length: buf.readableBytes) else { return [] }

        var items: [RemoteFileItem] = []
        let lines = text.split(separator: "\n")

        for line in lines {
            let lineStr = String(line).trimmingCharacters(in: .whitespaces)
            if lineStr.hasPrefix("total") || lineStr.isEmpty { continue }

            let cols = lineStr.split(whereSeparator: { $0.isWhitespace })
            guard cols.count >= 6 else { continue }

            let perms = String(cols[0])
            let isDir = perms.hasPrefix("d")
            let sizeBytes = Double(cols[4]) ?? 0.0

            // 文件名可能是最后一列或包含空格的多列
            let nameCols = cols.dropFirst(cols.count >= 8 ? 6 : 5)
            let name = nameCols.joined(separator: " ")

            if name == "." { continue } // 忽略当前目录项

            let fullPath = path == "/" ? "/\(name)" : "\(path)/\(name)"
            let sizeStr = isDir ? "--" : formatFileSize(sizeBytes)

            items.append(RemoteFileItem(
                id: fullPath,
                name: name,
                path: fullPath,
                isDirectory: isDir,
                sizeString: sizeStr,
                permissions: perms
            ))
        }

        // 排序：目录优先，随后按字母序
        return items.sorted { a, b in
            if a.name == ".." { return true }
            if b.name == ".." { return false }
            if a.isDirectory != b.isDirectory {
                return a.isDirectory && !b.isDirectory
            }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
    }

    /// 读取远程文本文件预览 (限制最大 64KB 防 OOM)
    func readRemoteFilePreview(at path: String) async throws -> String {
        let safePath = path.replacingOccurrences(of: "'", with: "'\\''")
        let cmd = "head -c 65536 '\(safePath)'"
        var buf = try await executeRawCommand(cmd)
        return buf.readString(length: buf.readableBytes) ?? "空文件或无法解码为文本"
    }

    /// 执行任意单行运维命令并返回标准输出与错误
    func executeCustomCommand(_ cmd: String) async throws -> String {
        var buf = try await executeRawCommand(cmd)
        return buf.readString(length: buf.readableBytes) ?? "（无输出）"
    }

    private func formatFileSize(_ bytes: Double) -> String {
        if bytes < 1024 { return "\(Int(bytes)) B" }
        let kb = bytes / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024.0
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        let gb = mb / 1024.0
        return String(format: "%.2f GB", gb)
    }
}
