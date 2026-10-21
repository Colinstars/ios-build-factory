import UIKit
import NIOCore

/// 100% 对标 Termius 官方交互的全新主机列表控制器
///
/// 核心交互革命：
/// 1. 彻底删除多余繁琐的中间页【ServerDetailViewController】！
/// 2. 点击列表主机卡片，原位触发 Termius 同款【Connecting...】动画与 Spinner；
/// 3. 在后台先行完成 SSH 物理建连与 PTY 握手，一旦握手成功 (Session Established)，瞬间无缝推入全屏沉浸终端！
/// 4. 如果连接失败，原地变红并弹窗提示错误，优雅自然，绝不再出现“先进去一个空终端再看报错”的古老感！
final class ServerListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var servers: [Server] = []

    // 记录当前正在发起握手的主机 ID
    private var connectingServerId: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hosts"
        view.backgroundColor = AppTheme.pageBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAdd)
        )

        setupTableView()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 从终端返回后清空 connecting 状态
        connectingServerId = nil
        reload()
    }

    private func reload() {
        servers = ServerStore.shared.servers
        tableView.reloadData()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ServerCell.self, forCellReuseIdentifier: "ServerCell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func didTapAdd() {
        let addVC = AddServerViewController()
        addVC.delegate = self
        let nav = UINavigationController(rootViewController: addVC)

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(nav, animated: true)
    }

    /// Termius 级现代直连流：点击卡片 ➔ 原地 Connecting ➔ 握手成功直推终端
    private func initiateConnection(to server: Server, at indexPath: IndexPath) {
        guard connectingServerId == nil else { return } // 防止高频连续误触
        connectingServerId = server.id
        tableView.reloadRows(at: [indexPath], with: .none)

        // 触感反馈
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let sess = SSHSession(server: server)

        Task {
            do {
                // 1. 先行进行真实 SSH 握手鉴权
                try await sess.connect()

                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.connectingServerId = nil
                    self.tableView.reloadRows(at: [indexPath], with: .none)

                    // 2. 握手成功，直接推入全屏终端！
                    ActiveServerContext.shared.setActiveServer(server)
                    let termVC = HostTerminalViewController(server: server, preconnectedSession: sess)
                    termVC.onSessionDisconnected = { [weak self] s, err in
                        self?.showDisconnectionDiagnosticSheet(for: s, error: err)
                    }
                    self.navigationItem.backButtonTitle = ""
                    self.navigationController?.pushViewController(termVC, animated: true)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.connectingServerId = nil
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)

                    self.showDisconnectionDiagnosticSheet(for: server, error: error.localizedDescription)
                }
            }
        }
    }

    /// 100% 对齐 Termius 官方真机的断连诊断日志抽屉
    private func showDisconnectionDiagnosticSheet(for server: Server, error: String?) {
        let errList = error != nil ? [error!] : []
        let sheet = ConnectionDiagnosticSheet(server: server, errorLog: errList)
        sheet.modalPresentationStyle = .pageSheet
        if let pc = sheet.sheetPresentationController {
            pc.detents = [.medium(), .large()]
            pc.prefersGrabberVisible = true
        }
        sheet.onReconnect = { [weak self] in
            if let idx = self?.servers.firstIndex(where: { $0.id == server.id }) {
                self?.initiateConnection(to: server, at: IndexPath(row: idx, section: 0))
            }
        }
        present(sheet, animated: true)
    }
}

// MARK: - AddServerViewControllerDelegate

extension ServerListViewController: AddServerViewControllerDelegate {
    func addServerViewController(_ controller: AddServerViewController, didAdd server: Server) {
        ServerStore.shared.add(server)
        reload()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ServerListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        servers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServerCell", for: indexPath) as! ServerCell
        let s = servers[indexPath.row]
        let isConn = (s.id == connectingServerId)
        cell.configure(with: s, isConnecting: isConn)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let s = servers[indexPath.row]
        initiateConnection(to: s, at: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            ServerStore.shared.delete(at: indexPath.row)
            reload()
        }
    }
}
