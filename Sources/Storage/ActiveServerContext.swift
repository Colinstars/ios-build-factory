import Foundation

/// 全局活动服务器状态中枢：
/// 解决底部 5 大原生 TabBar (状态/终端/文件/容器/更多) 在多台服务器之间无序漂移的问题。
/// 让当前选中的服务器具备唯一的全局上下文，支持热切换与跨 Tab 统一广播。
final class ActiveServerContext {

    static let shared = ActiveServerContext()
    static let didChangeActiveServerNotification = Notification.Name("ActiveServerContext.didChangeActiveServer")

    private(set) var activeServer: Server? {
        didSet {
            NotificationCenter.default.post(name: Self.didChangeActiveServerNotification, object: activeServer)
        }
    }

    private init() {
        self.activeServer = ServerStore.shared.servers.first
    }

    func setActiveServer(_ server: Server) {
        self.activeServer = server
    }

    func refreshIfNeeded() {
        if activeServer == nil || !ServerStore.shared.servers.contains(where: { $0.id == activeServer?.id }) {
            self.activeServer = ServerStore.shared.servers.first
        }
    }
}
