import Foundation
import Citadel
import NIOCore
@preconcurrency import NIOSSH

/// 工业级 SSH PTY 全双工终端管道中继器
final class SSHPtyStreamRelay: @unchecked Sendable {

    private var stdinWriter: TTYStdinWriter?
    private let lock = NSLock()

    func setWriter(_ writer: TTYStdinWriter) {
        lock.lock()
        defer { lock.unlock() }
        self.stdinWriter = writer
    }

    /// 传递原始字节，确保控制序列不被二次编码损坏
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
                // 静默处理正常关闭后的写失败
            }
        }
    }

    func writeString(_ text: String) {
        writeBytes(Array(text.utf8))
    }

    /// 动态窗口尺寸广播 (SIGWINCH)
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

    /// 建立远程 Linux 伪终端 (PTY) 会话，开启双向字节直通管道
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
                onTerminate?(nil)
            } catch {
                let desc = error.localizedDescription
                onTerminate?(desc)
            }
        }

        return relay
    }
}
