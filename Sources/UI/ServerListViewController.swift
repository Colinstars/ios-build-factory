import UIKit
import NIOCore

/// 主机列表视图控制器 (支持原生高质感弹性交互与无缝全屏平滑推入)
final class ServerListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var servers: [Server] = []

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
        fetchGeoIPForAllServers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        connectingServerId = nil
        reload()
    }

    private func reload() {
        servers = ServerStore.shared.servers
        tableView.reloadData()
    }

    /// 后台静默根据 IP 动态拉取地理位置并刷新
    private func fetchGeoIPForAllServers() {
        for s in servers {
            if s.region == nil {
                Task {
                    if let region = await GeoIPService.shared.fetchRegion(for: s.host) {
                        await MainActor.run {
                            ServerStore.shared.updateMetadata(for: s.id, region: region)
                            self.reload()
                        }
                    }
                }
            }
        }
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

    /// 发起连接并在握手时动态探测操作系统发行版，成功后无缝灵动推入终端
    private func initiateConnection(to server: Server, at indexPath: IndexPath) {
        guard connectingServerId == nil else { return }
        connectingServerId = server.id
        tableView.reloadRows(at: [indexPath], with: .none)

        // 细腻物理触感反馈
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()

        let sess = SSHSession(server: server)

        Task {
            do {
                try await sess.connect()

                // 异步后台探测远程真实发行版并持久化
                Task {
                    let os = await sess.detectOS()
                    await MainActor.run {
                        ServerStore.shared.updateMetadata(for: server.id, os: os)
                    }
                }

                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.connectingServerId = nil
                    self.tableView.reloadRows(at: [indexPath], with: .none)

                    // 成功触感提示
                    UINotificationFeedbackGenerator().notificationOccurred(.success)

                    ActiveServerContext.shared.setActiveServer(server)
                    let termVC = HostTerminalViewController(server: server, preconnectedSession: sess)
                    termVC.onSessionDisconnected = { [weak self] s, err in
                        self?.showDisconnectionDiagnosticSheet(for: s, error: err)
                    }
                    self.navigationItem.backButtonTitle = ""

                    // 灵动平滑转场推入
                    let transition = CATransition()
                    transition.duration = 0.32
                    transition.type = .push
                    transition.subtype = .fromRight
                    transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    self.navigationController?.view.layer.add(transition, forKey: kCATransition)
                    self.navigationController?.pushViewController(termVC, animated: false)
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
        fetchGeoIPForAllServers()
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
