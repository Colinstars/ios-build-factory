import UIKit

/// 服务器列表主页。
///
/// 遵循 HIG 规范：
/// - 内容层（UITableView）使用标准材质（systemGroupedBackground），**绝不使用玻璃**。
/// - 功能层（右下角浮动添加按钮）使用 **GlassSurface (regular + interactive)** 挂载，
///   在 iOS 26+ 呈现官方 UIGlassEffect，在 iOS 18~25 降级为超薄材质 + 仿高光描边。
final class ServerListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let floatingAddButton = GlassSurface(variant: .regular, cornerRadius: 28)
    private let addIcon = UIImageView()

    private var servers: [Server] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ServerLens"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground

        setupTableView()
        setupFloatingAddButton()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    private func reload() {
        servers = ServerStore.shared.servers
        tableView.reloadData()
    }

    // MARK: - Setup UI

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
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

    /// 功能层：浮动添加按钮。符合 HIG『仅关键功能元素使用玻璃』与『玻璃可做主要行动点着色』。
    private func setupFloatingAddButton() {
        floatingAddButton.translatesAutoresizingMaskIntoConstraints = false
        floatingAddButton.setInteractive(true)

        addIcon.translatesAutoresizingMaskIntoConstraints = false
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        addIcon.image = UIImage(systemName: "plus", withConfiguration: cfg)
        addIcon.tintColor = .systemBlue
        addIcon.contentMode = .center

        floatingAddButton.addSubview(addIcon)
        view.addSubview(floatingAddButton)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapAdd))
        floatingAddButton.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            floatingAddButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            floatingAddButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            floatingAddButton.widthAnchor.constraint(equalToConstant: 56),
            floatingAddButton.heightAnchor.constraint(equalToConstant: 56),

            addIcon.centerXAnchor.constraint(equalTo: floatingAddButton.centerXAnchor),
            addIcon.centerYAnchor.constraint(equalTo: floatingAddButton.centerYAnchor),
        ])
    }

    // MARK: - Actions

    @objc private func didTapAdd() {
        let alert = UIAlertController(title: "添加服务器", message: "输入连接信息（支持密码认证）", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "显示名称 (如 DMIT)" }
        alert.addTextField { $0.placeholder = "主机 IP / 域名" }
        alert.addTextField { $0.placeholder = "端口 (默认 22)" ; $0.text = "22" ; $0.keyboardType = .numberPad }
        alert.addTextField { $0.placeholder = "用户名 (默认 root)" ; $0.text = "root" }
        alert.addTextField { $0.placeholder = "密码" ; $0.isSecureTextEntry = true }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default, handler: { [weak self] _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty,
                  let host = alert.textFields?[1].text, !host.isEmpty else { return }
            let portStr = alert.textFields?[2].text ?? "22"
            let port = Int(portStr) ?? 22
            let user = alert.textFields?[3].text ?? "root"
            let pwd = alert.textFields?[4].text ?? ""

            let s = Server(
                name: name,
                host: host,
                port: port,
                username: user.isEmpty ? "root" : user,
                authType: .password(pwd)
            )
            ServerStore.shared.add(s)
            self?.reload()
        }))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ServerListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servers.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServerCell", for: indexPath) as! ServerCell
        cell.configure(with: servers[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let s = servers[indexPath.row]
        let detail = ServerDetailViewController(server: s)
        navigationController?.pushViewController(detail, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            ServerStore.shared.delete(at: indexPath.row)
            servers = ServerStore.shared.servers
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
