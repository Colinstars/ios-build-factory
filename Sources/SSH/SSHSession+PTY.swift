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

    func writeString(_ text: String) {
        lock.lock()
        let writer = self.stdinWriter
        lock.unlock()

        guard let writer = writer else { return }
        var buffer = ByteBuffer()
        buffer.writeString(text)
        Task {
            try? await writer.write(buffer)
        }
    }
}

extension SSHSession {

    /// 建立真正的 Linux 伪终端 (PTY) 会话，开启双向字节直通管道 (对标 iTerm / Blink Shell)
    func startInteractivePty(
        cols: Int = 80,
        rows: Int = 24,
        onOutput: @escaping @Sendable (ByteBuffer) -> Void
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
            terminalCharacterWidth: UInt32(cols),
            terminalRowHeight: UInt32(rows),
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
            } catch {
                var errBuf = ByteBuffer()
                errBuf.writeString("\r\n\u{1b}[31m[SSH Session Terminated: \(error.localizedDescription)]\u{1b}[0m\r\n")
                onOutput(errBuf)
            }
        }

        return relay
    }
}
