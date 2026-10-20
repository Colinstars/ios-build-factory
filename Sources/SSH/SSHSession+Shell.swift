import Foundation
import Citadel
import NIOCore
@preconcurrency import NIOSSH

extension SSHSession {

    /// 开启真实的交互式 PTY Shell 终端流。
    func startInteractiveShell(onOutput: @escaping @Sendable (ByteBuffer) -> Void) async throws -> @Sendable (String) async throws -> Void {
        if !isConnected() {
            try await connect()
        }

        guard let client = self.client else {
            throw NSError(domain: "SSHSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法建立连接"])
        }

        let request = SSHChannelRequestEvent.PseudoTerminalRequest(
            wantReply: true,
            term: "xterm-256color",
            terminalCharacterWidth: 80,
            terminalRowHeight: 24,
            terminalPixelWidth: 0,
            terminalPixelHeight: 0,
            terminalModes: .init([:])
        )

        let stdinBox = StdinBox()

        Task.detached {
            do {
                try await client.withPTY(request) { inbound, outbound in
                    await stdinBox.setWriter(outbound)
                    for try await chunk in inbound {
                        switch chunk {
                        case .stdout(let buffer):
                            onOutput(buffer)
                        case .stderr(let buffer):
                            onOutput(buffer)
                        }
                    }
                }
            } catch {
                print("Shell 任务结束或断开: \(error)")
            }
        }

        return { [stdinBox] text in
            await stdinBox.write(text)
        }
    }

    func getClient() -> SSHClient? {
        return self.client
    }
}

private actor StdinBox {
    private var writer: TTYStdinWriter?

    func setWriter(_ w: TTYStdinWriter) {
        self.writer = w
    }

    func write(_ text: String) async {
        guard let writer = writer else { return }
        var buffer = ByteBuffer()
        buffer.writeString(text)
        try? await writer.write(buffer)
    }
}
