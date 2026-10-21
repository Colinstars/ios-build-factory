import Foundation
import Citadel
import NIOCore
@preconcurrency import NIOSSH

/// 工业级 SSH PTY 全双工终端管道中继器 (支持动态 Window Change 尺寸同步与 ANSI / Raw 输入)
final class SSHPtyStreamRelay: @unchecked Sendable {

    private var stdinWriter: TTYStdinWriter?
    private let lock = NSLock()

    func setWriter(_ writer: TTYStdinWriter) {
        lock.lock()
        defer { lock.unlock() }
        self.stdinWriter = writer
    }

    /// 核心优化：直接传递原始字节，杜绝 UTF-8 字符串二次转码导致非标准终端控制序列撕裂
    func writeBytes(_ bytes: [UInt8]) {
        lock.lock()
        let writer = self.stdinWriter
        lock.unlock()

        guard let writer = writer else { return }
        var buffer = ByteBuffer()
        buffer.writeBytes(bytes)
        Task {
            do {
                try await writer.write(buffer)
            } catch {
                // 静默忽略在管道正常关闭后的残余写失败
            }
        }
    }

    func writeString(_ text: String) {
        writeBytes(Array(text.utf8))
    }

    /// 核心修复：当 iOS 屏幕旋转、键盘弹起收起、或 SwiftTerm 字符网格尺寸改变时，向远端 Linux / tmux 发送 SIGWINCH
    func resize(cols: Int, rows: Int, pixelWidth: Int = 0, pixelHeight: Int = 0) {
        lock.lock()
        let writer = self.stdinWriter
        lock.unlock()

        guard let writer = writer else { return }
        Task {
            try? await writer.changeSize(cols: cols, rows: rows, pixelWidth: pixelWidth, pixelHeight: pixelHeight)
        }
    }
}

extension SSHSession {

    /// 建立真正的 Linux 伪终端 (PTY) 会话，开启双向字节直通管道 (对标 iTerm / Blink Shell / Termius)
    func startInteractivePty(
        cols: Int = 80,
        rows: Int = 24,
        onOutput: @escaping @Sendable (ByteBuffer) -> Void,
        onTerminate: (@Sendable (String?) -> Void)? = nil
    ) async throws -> SSHPtyStreamRelay {
        if !isConnected() {
            try await connect()
        }
        guard let client = self.client else {
            throw NSError(domain: "SSHSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "SSH 未建立连接"])
        }

        let ptyRequest = SSHChannelRequestEvent.PseudoTerminalRequest(
            wantReply: true,
            term: "xterm-256color",
            terminalCharacterWidth: cols,
            terminalRowHeight: rows,
            terminalPixelWidth: 0,
            terminalPixelHeight: 0,
            terminalModes: .init([:])
        )

        let relay = SSHPtyStreamRelay()

        Task.detached {
            do {
                try await client.withPTY(ptyRequest) { inbound, outbound in
                    relay.setWriter(outbound)
                    for try await chunk in inbound {
                        switch chunk {
                        case .stdout(let buf):
                            onOutput(buf)
                        case .stderr(let buf):
                            onOutput(buf)
                        }
                    }
                }
                // 正常退出 (例如敲了 exit)
                onTerminate?(nil)
            } catch {
                let desc = error.localizedDescription
                // 异常断连或被远端掐断
                onTerminate?(desc)
            }
        }

        return relay
    }
}
