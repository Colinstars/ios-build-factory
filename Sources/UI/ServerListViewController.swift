import UIKit

/// 主机列表 —— 完全使用 Apple 出厂原生组件，零自定义外观代码。
final class ServerListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var servers: [Server] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "主机"
        view.backgroundColor = .systemGroupedBackground

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
        reload()
    }

    private func reload() {
        servers = ServerStore.shared.servers
        tableView.reloadData()
    }

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
        cell.configure(with: servers[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let s = servers[indexPath.row]
        ActiveServerContext.shared.setActiveServer(s)

        navigationItem.backButtonTitle = ""
        navigationController?.pushViewController(ServerDetailViewController(server: s), animated: true)
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
