import UIKit

/// SSH 密钥库管理控制器
final class SSHKeysViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var keys: [SSHKey] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "SSH Keys"
        view.backgroundColor = AppTheme.pageBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAdd)
        )

        setupTableView()
        reload()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = AppTheme.pageBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "KeyCell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func reload() {
        keys = SSHKeyStore.shared.keys
        tableView.reloadData()
    }

    @objc private func didTapAdd() {
        let sheet = UIAlertController(title: "添加 SSH 密钥", message: "选择密钥添加方式：", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "生成全新 Ed25519 密钥对", style: .default, handler: { [weak self] _ in
            self?.handleGenerateKey()
        }))
        sheet.addAction(UIAlertAction(title: "导入已有私钥 (PEM / OpenSSH)", style: .default, handler: { [weak self] _ in
            self?.handleImportKey()
        }))
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(sheet, animated: true)
    }

    private func handleGenerateKey() {
        let alert = UIAlertController(title: "生成 Ed25519 密钥", message: "为新密钥命名：", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "如: 我的 MacBook 或 生产密钥" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "生成", style: .default, handler: { [weak self] _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return }
            let newKey = SSHKey.generateEd25519(name: name)
            SSHKeyStore.shared.add(newKey)
            self?.reload()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }))
        present(alert, animated: true)
    }

    private func handleImportKey() {
        let alert = UIAlertController(title: "导入私钥", message: "输入密钥名称与 Base64 / PEM 私钥内容：", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "密钥名称" }
        alert.addTextField { $0.placeholder = "私钥内容 (Base64 或 PEM)" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default, handler: { [weak self] _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty,
                  let rawKey = alert.textFields?[1].text, !rawKey.isEmpty else { return }
            let imported = SSHKey(
                name: name,
                keyType: .ed25519,
                privateKeyPEM: rawKey,
                publicKeyOpenSSH: "ssh-ed25519 (导入私钥) \(name)@serverlens"
            )
            SSHKeyStore.shared.add(imported)
            self?.reload()
        }))
        present(alert, animated: true)
    }
}

// MARK: - TableView

extension SSHKeysViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keys.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "KeyCell")
        let key = keys[indexPath.row]

        cell.backgroundColor = AppTheme.cardBackground
        cell.textLabel?.text = key.name
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        cell.textLabel?.textColor = .label

        let df = DateFormatter()
        df.dateStyle = .medium
        let dateStr = df.string(from: key.createdAt)

        cell.detailTextLabel?.text = "\(key.keyType.rawValue) · 创建于 \(dateStr)"
        cell.detailTextLabel?.font = .systemFont(ofSize: 12)
        cell.detailTextLabel?.textColor = .secondaryLabel

        cell.imageView?.image = UIImage(systemName: "key.fill")
        cell.imageView?.tintColor = .systemYellow
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let key = keys[indexPath.row]

        let sheet = UIAlertController(title: key.name, message: key.publicKeyOpenSSH, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "复制 OpenSSH 公钥", style: .default, handler: { _ in
            UIPasteboard.general.string = key.publicKeyOpenSSH
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }))
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(sheet, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            SSHKeyStore.shared.delete(at: indexPath.row)
            reload()
        }
    }
}
