import UIKit

protocol AddServerViewControllerDelegate: AnyObject {
    func addServerViewController(_ controller: AddServerViewController, didAdd server: Server)
}

/// 遵循现代 iOS HIG 规范的添加主机高级表单 (对标 Termius New Host / ServerCat)
///
/// 核心工业级特性：
/// 1. 认证方式支持 SegmentedControl 切换：【密码】与【SSH 密钥】无缝切换；
/// 2. 选密钥时：自动拉取全局 SSHKeyStore 里的密钥列表供点击选择；
/// 3. 分组标签 (Tag)：支持输入生产/测试/香港等机房标签；
/// 4. 彻底锁定 SheetColorScheme 配色，半屏展开前后卡片纯白质感 100% 恒定。
final class AddServerViewController: UIViewController {

    weak var delegate: AddServerViewControllerDelegate?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // 基础信息输入框
    private let nameField = UITextField()
    private let hostField = UITextField()
    private let portField = UITextField()
    private let userField = UITextField()
    private let tagField = UITextField()

    // 认证模式切换器
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
        nameField.placeholder = "我的主机 (如: DMIT 香港)"
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

        tagField.placeholder = "机房/环境标签 (可选，如 香港BGP)"
        tagField.clearButtonMode = .whileEditing
        tagField.autocapitalizationType = .none
        tagField.autocorrectionType = .no
        tagField.textColor = .label

        passwordField.placeholder = "输入主机密码"
        passwordField.isSecureTextEntry = true
        passwordField.clearButtonMode = .whileEditing
        passwordField.textColor = .label

        authSegment.selectedSegmentIndex = 0
        authSegment.addTarget(self, action: #selector(didChangeAuthSegment), for: .valueChanged)
    }

    @objc private func didChangeAuthSegment() {
        tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = SheetColorScheme.background
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

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    @objc private func didTapSave() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let host = hostField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !name.isEmpty, !host.isEmpty else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            shakeTableView()
            return
        }

        let port = Int(portField.text ?? "22") ?? 22
        let user = userField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "root"
        let tag = tagField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        let auth: Server.AuthType
        if authSegment.selectedSegmentIndex == 0 {
            let pwd = passwordField.text ?? ""
            auth = .password(pwd)
        } else {
            let keys = SSHKeyStore.shared.keys
            if keys.indices.contains(selectedKeyIndex) {
                auth = .sshKey(keyId: keys[selectedKeyIndex].id)
            } else {
                auth = .password("")
            }
        }

        let newServer = Server(
            name: name,
            host: host,
            port: port,
            username: user.isEmpty ? "root" : user,
            authType: auth,
            tag: tag?.isEmpty == false ? tag : nil
        )

        delegate?.addServerViewController(self, didAdd: newServer)
        dismiss(animated: true)
    }

    private func shakeTableView() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-12.0, 12.0, -8.0, 8.0, -4.0, 4.0, 0.0]
        tableView.layer.add(animation, forKey: "shake")
    }
}

// MARK: - TableView

extension AddServerViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4 // 名称, 主机, 端口, 标签
        } else if section == 1 {
            return authSegment.selectedSegmentIndex == 0 ? 3 : 2 + SSHKeyStore.shared.keys.count // 用户名, 认证类型, 密码框或密钥列表
        } else {
            return 1 // 保存/快速提示
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return "主机连接配置" }
        if section == 1 { return "身份凭据与鉴权 (Termius 级别)" }
        return nil
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return authSegment.selectedSegmentIndex == 0
                ? "密码仅安全存储在设备 Keychain 中。"
                : "推荐使用 Ed25519 密钥连接。可在【设置 ➔ SSH 密钥】中管理或生成。"
        }
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = AppTheme.cardBackground
        cell.selectionStyle = .none

        var bg = UIBackgroundConfiguration.listGroupedCell()
        bg.backgroundColor = AppTheme.cardBackground
        cell.backgroundConfiguration = bg

        if indexPath.section == 0 {
            if indexPath.row == 0 {
                return makeFieldCell(title: "名称", field: nameField)
            } else if indexPath.row == 1 {
                return makeFieldCell(title: "主机", field: hostField)
            } else if indexPath.row == 2 {
                return makeFieldCell(title: "端口", field: portField)
            } else {
                return makeFieldCell(title: "标签", field: tagField)
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                return makeFieldCell(title: "用户", field: userField)
            } else if indexPath.row == 1 {
                // SegmentedControl 行
                let segCell = UITableViewCell(style: .default, reuseIdentifier: nil)
                segCell.backgroundColor = AppTheme.cardBackground
                segCell.selectionStyle = .none
                segCell.backgroundConfiguration = bg

                authSegment.translatesAutoresizingMaskIntoConstraints = false
                segCell.contentView.addSubview(authSegment)
                NSLayoutConstraint.activate([
                    authSegment.leadingAnchor.constraint(equalTo: segCell.contentView.leadingAnchor, constant: 16),
                    authSegment.trailingAnchor.constraint(equalTo: segCell.contentView.trailingAnchor, constant: -16),
                    authSegment.centerYAnchor.constraint(equalTo: segCell.contentView.centerYAnchor),
                    authSegment.heightAnchor.constraint(equalToConstant: 32)
                ])
                return segCell
            } else {
                if authSegment.selectedSegmentIndex == 0 {
                    return makeFieldCell(title: "密码", field: passwordField)
                } else {
                    // 密钥列表项
                    let keyIdx = indexPath.row - 2
                    let keys = SSHKeyStore.shared.keys
                    let keyCell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                    keyCell.backgroundColor = AppTheme.cardBackground
                    keyCell.backgroundConfiguration = bg
                    keyCell.selectionStyle = .default

                    if keys.indices.contains(keyIdx) {
                        let k = keys[keyIdx]
                        keyCell.textLabel?.text = k.name
                        keyCell.detailTextLabel?.text = "\(k.keyType.rawValue) · \(k.publicKeyOpenSSH.prefix(24))..."
                        keyCell.imageView?.image = UIImage(systemName: "key.fill")
                        keyCell.imageView?.tintColor = .systemYellow
                        keyCell.accessoryType = (selectedKeyIndex == keyIdx) ? .checkmark : .none
                    }
                    return keyCell
                }
            }
        } else {
            cell.textLabel?.text = "保存并测试连接"
            cell.textLabel?.textColor = .systemBlue
            cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .default
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 1 && authSegment.selectedSegmentIndex == 1 && indexPath.row >= 2 {
            selectedKeyIndex = indexPath.row - 2
            tableView.reloadSections(IndexSet(integer: 1), with: .none)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if indexPath.section == 2 {
            didTapSave()
        }
    }

    private func makeFieldCell(title: String, field: UITextField) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.backgroundColor = AppTheme.cardBackground

        var bg = UIBackgroundConfiguration.listGroupedCell()
        bg.backgroundColor = AppTheme.cardBackground
        cell.backgroundConfiguration = bg

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = .label
        cell.contentView.addSubview(titleLabel)

        field.translatesAutoresizingMaskIntoConstraints = false
        field.font = .systemFont(ofSize: 16)
        cell.contentView.addSubview(field)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 64),

            field.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            field.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 11),
            field.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -11),
            field.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
        ])

        return cell
    }
}
