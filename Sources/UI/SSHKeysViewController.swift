import UIKit

/// SSH 密钥库管理控制器 (对标 Termius Keychain / ServerCat 密钥管理)
/// 遵循 Apple HIG 规范：标准 insetGrouped 列表，支持左滑删除、一键生成 Ed25519、导入 PEM、复制公钥
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
            self?.promptGenerateKey()
        }))
        sheet.addAction(UIAlertAction(title: "导入已有私钥 (PEM / OpenSSH)", style: .default, handler: { [weak self] _ in
            self?.promptImportKey()
        }))
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(sheet, animated: true)
    }

    private func promptGenerateKey() {
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

    private func promptImportKey() {
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

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "点击任意密钥可复制对应 OpenSSH 公钥至剪贴板，方便粘贴到服务器 ~/.ssh/authorized_keys 中。"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "KeyCell")
        cell.backgroundColor = AppTheme.cardBackground
        cell.selectionStyle = .default

        let k = keys[indexPath.row]
        cell.textLabel?.text = k.name
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        cell.detailTextLabel?.text = "\(k.keyType.rawValue) · \(k.publicKeyOpenSSH.prefix(32))..."
        cell.detailTextLabel?.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.imageView?.image = UIImage(systemName: "key.fill")
        cell.imageView?.tintColor = .systemYellow
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let k = keys[indexPath.row]
        UIPasteboard.general.string = k.publicKeyOpenSSH
        
        let alert = UIAlertController(
            title: "公钥已复制",
            message: "已将「\(k.name)」的公钥内容复制至剪贴板！\n\n\(k.publicKeyOpenSSH)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            SSHKeyStore.shared.delete(at: indexPath.row)
            keys = SSHKeyStore.shared.keys
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
