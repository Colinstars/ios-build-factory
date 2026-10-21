import UIKit

protocol AddServerViewControllerDelegate: AnyObject {
    func addServerViewController(_ controller: AddServerViewController, didAdd server: Server)
}

/// 添加主机表单控制器
final class AddServerViewController: UIViewController {

    weak var delegate: AddServerViewControllerDelegate?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let nameField = UITextField()
    private let hostField = UITextField()
    private let portField = UITextField()
    private let userField = UITextField()
    private let tagField = UITextField()

    private let authSegment = UISegmentedControl(items: ["密码认证", "SSH 密钥"])
    private let passwordField = UITextField()
    private var selectedKeyIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "添加主机"
        view.backgroundColor = AppTheme.pageBackground

        setupNavigationBar()
        configureControls()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = AppTheme.pageBackground
        tableView.backgroundColor = AppTheme.pageBackground
    }

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "取消",
            style: .plain,
            target: self,
            action: #selector(didTapCancel)
        )

        let saveItem = UIBarButtonItem(
            title: "完成",
            style: .done,
            target: self,
            action: #selector(didTapSave)
        )
        navigationItem.rightBarButtonItem = saveItem
    }

    private func configureControls() {
        nameField.placeholder = "主机别名 (如: Web-Prod-01)"
        nameField.clearButtonMode = .whileEditing
        nameField.autocapitalizationType = .none
        nameField.autocorrectionType = .no
        nameField.textColor = .label

        hostField.placeholder = "IP 或域名 (必填)"
        hostField.clearButtonMode = .whileEditing
        hostField.keyboardType = .URL
        hostField.autocapitalizationType = .none
        hostField.autocorrectionType = .no
        hostField.textColor = .label

        portField.text = "22"
        portField.placeholder = "22"
        portField.keyboardType = .numberPad
        portField.textColor = .label

        userField.text = "root"
        userField.placeholder = "root"
        userField.autocapitalizationType = .none
        userField.autocorrectionType = .no
        userField.textColor = .label

        tagField.placeholder = "环境标签 (可选，如 Production)"
        tagField.clearButtonMode = .whileEditing
        tagField.autocapitalizationType = .none
        tagField.autocorrectionType = .no
        tagField.textColor = .label

        passwordField.placeholder = "输入主机密码"
        passwordField.isSecureTextEntry = true
        passwordField.clearButtonMode = .whileEditing
        passwordField.textColor = .label

        authSegment.selectedSegmentIndex = 0
        authSegment.addTarget(self, action: #selector(didChangeAuthType), for: .valueChanged)
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = AppTheme.pageBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func didChangeAuthType() {
        tableView.reloadSections(IndexSet(integer: 1), with: .fade)
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    @objc private func didTapSave() {
        guard let host = hostField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !host.isEmpty else {
            shake(field: hostField)
            return
        }

        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = (name?.isEmpty ?? true) ? host : name!
        let port = Int(portField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "22") ?? 22
        let user = userField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalUser = (user?.isEmpty ?? true) ? "root" : user!
        let tag = tagField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        let authType: Server.AuthType
        if authSegment.selectedSegmentIndex == 0 {
            let pwd = passwordField.text ?? ""
            authType = .password(pwd)
        } else {
            let allKeys = SSHKeyStore.shared.keys
            if selectedKeyIndex < allKeys.count {
                authType = .sshKey(keyId: allKeys[selectedKeyIndex].id)
            } else {
                authType = .password("")
            }
        }

        let newServer = Server(
            name: finalName,
            host: host,
            port: port,
            username: finalUser,
            authType: authType,
            tag: tag?.isEmpty ?? true ? nil : tag
        )

        delegate?.addServerViewController(self, didAdd: newServer)
        dismiss(animated: true)
    }

    private func shake(field: UITextField) {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.duration = 0.4
        anim.values = [-10.0, 10.0, -8.0, 8.0, -5.0, 5.0, 0.0]
        field.layer.add(anim, forKey: "shake")
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// MARK: - TableView

extension AddServerViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 5 // 别名, IP, 端口, 用户名, 标签
        case 1:
            return authSegment.selectedSegmentIndex == 0 ? 2 : 2
        case 2:
            return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "基础连接配置"
        case 1: return "身份凭据与鉴权"
        case 2: return "快捷操作"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.backgroundColor = AppTheme.cardBackground

        let bg = UIView()
        bg.backgroundColor = AppTheme.cardBackground
        cell.selectedBackgroundView = bg

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            setupFieldCell(cell, label: "主机名称", field: nameField)
        case (0, 1):
            setupFieldCell(cell, label: "主机地址", field: hostField)
        case (0, 2):
            setupFieldCell(cell, label: "SSH 端口", field: portField)
        case (0, 3):
            setupFieldCell(cell, label: "登录用户", field: userField)
        case (0, 4):
            setupFieldCell(cell, label: "环境标签", field: tagField)

        case (1, 0):
            let segCell = UITableViewCell()
            segCell.selectionStyle = .none
            segCell.backgroundColor = AppTheme.cardBackground
            authSegment.translatesAutoresizingMaskIntoConstraints = false
            segCell.contentView.addSubview(authSegment)
            NSLayoutConstraint.activate([
                authSegment.topAnchor.constraint(equalTo: segCell.contentView.topAnchor, constant: 8),
                authSegment.bottomAnchor.constraint(equalTo: segCell.contentView.bottomAnchor, constant: -8),
                authSegment.leadingAnchor.constraint(equalTo: segCell.contentView.leadingAnchor, constant: 16),
                authSegment.trailingAnchor.constraint(equalTo: segCell.contentView.trailingAnchor, constant: -16)
            ])
            return segCell

        case (1, 1):
            if authSegment.selectedSegmentIndex == 0 {
                setupFieldCell(cell, label: "主机密码", field: passwordField)
            } else {
                let keyCell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                keyCell.backgroundColor = AppTheme.cardBackground
                keyCell.textLabel?.text = "选择 SSH 密钥"
                let allKeys = SSHKeyStore.shared.keys
                if selectedKeyIndex < allKeys.count {
                    keyCell.detailTextLabel?.text = allKeys[selectedKeyIndex].name
                } else {
                    keyCell.detailTextLabel?.text = "无可用密钥"
                }
                keyCell.accessoryType = .disclosureIndicator
                keyCell.selectionStyle = .default
                return keyCell
            }

        case (2, 0):
            let actionCell = UITableViewCell()
            actionCell.backgroundColor = AppTheme.cardBackground
            actionCell.textLabel?.text = "立即保存主机"
            actionCell.textLabel?.textColor = AppTheme.accent
            actionCell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            actionCell.textLabel?.textAlignment = .center
            actionCell.selectionStyle = .default
            return actionCell

        default:
            break
        }

        return cell
    }

    private func setupFieldCell(_ cell: UITableViewCell, label: String, field: UITextField) {
        let labelView = UILabel()
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.text = label
        labelView.font = .systemFont(ofSize: 15)
        labelView.textColor = .label
        labelView.setContentHuggingPriority(.required, for: .horizontal)

        field.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(labelView)
        cell.contentView.addSubview(field)

        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            labelView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            labelView.widthAnchor.constraint(equalToConstant: 80),

            field.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            field.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            field.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 1 && indexPath.row == 1 && authSegment.selectedSegmentIndex == 1 {
            let allKeys = SSHKeyStore.shared.keys
            let alert = UIAlertController(title: "选择登录密钥", message: nil, preferredStyle: .actionSheet)
            for (idx, k) in allKeys.enumerated() {
                alert.addAction(UIAlertAction(title: k.name, style: .default, handler: { [weak self] _ in
                    self?.selectedKeyIndex = idx
                    self?.tableView.reloadRows(at: [indexPath], with: .fade)
                }))
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            present(alert, animated: true)
        } else if indexPath.section == 2 && indexPath.row == 0 {
            didTapSave()
        }
    }
}
