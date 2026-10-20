import UIKit

/// 服务器列表主页。
///
/// 遵循 HIG 规范：
/// - 内容层（UITableView）使用标准材质（systemGroupedBackground），绝不使用玻璃。
/// - 功能层（右下角浮动添加按钮）使用 GlassSurface (regular + interactive) 挂载。
/// - 模态交互遵循 HIG Modality 标准：添加操作弹出标准半屏 Sheet 表单 (AddServerViewController)，
///   彻底淘汰简陋的 UIAlertController。
final class ServerListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let floatingAddButton = GlassSurface(variant: .regular, cornerRadius: 28)
    private let addIcon = UIImageView()

    private var servers: [Server] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "主机"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // 关键物理穿透契约：允许内容向导航栏与底部安全区全面延展，唤醒极致液态通透折射
        self.extendedLayoutIncludesOpaqueBars = true
        self.edgesForExtendedLayout = .all

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

    /// 功能层：浮动添加按钮。
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

    // MARK: - Actions (遵循 HIG Sheets 规范)

    @objc private func didTapAdd() {
        let addVC = AddServerViewController()
        addVC.delegate = self
        let nav = UINavigationController(rootViewController: addVC)
        // 关键修复：外层导航控制器必须硬性绑定为标准抽屉浅灰底色！
        // 杜绝外壳透明透出底层白色导致 medium 半展开时输入框与底色融为一体！
        nav.view.backgroundColor = SheetColorScheme.background
        
        // 完美实现先提一半的抽屉特性：支持 [.medium(), .large()]
        // 配合 SheetColorScheme，放大和缩小仅仅是高度的区别，配色与分层 100% 绝对一致！
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        
        present(nav, animated: true)
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
        // 关键更新：将当前点击的节点同步设为全局活跃主机
        ActiveServerContext.shared.setActiveServer(s)
        
        // 优化返回按键文字，避免挤占导航栏导致转场计算延时
        navigationItem.backButtonTitle = ""
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
