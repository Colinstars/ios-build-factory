import UIKit

protocol AddServerViewControllerDelegate: AnyObject {
    func addServerViewController(_ controller: AddServerViewController, didAdd server: Server)
}

/// 遵循现代 iOS HIG 规范的添加服务器表单页面。
///
/// 彻底根除半屏 (medium) 未展开前发灰、展开后变白的物理原因：
/// 1. 彻底淘汰 cellForRowAt 重复 addSubview 的复用污染，使用固定数组持有 5 个专有 Cell。
/// 2. 绕过系统动态语义色的层级明度衰减，显式注入 UIColor.white (#FFFFFF)，确保浅色模式下从第 0 毫秒起恒为 100% 纯白卡片！
final class AddServerViewController: UIViewController {

    weak var delegate: AddServerViewControllerDelegate?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // 5 大独立输入框控件
    private let nameField = UITextField()
    private let hostField = UITextField()
    private let portField = UITextField()
    private let userField = UITextField()
    private let passwordField = UITextField()

    // 5 个一次性初始化的专用表单 Cell，杜绝复用冲突
    private var basicCells: [UITableViewCell] = []
    private var authCells: [UITableViewCell] = []

    // 纯白高对比度卡片背景色：浅色模式恒为纯白 #FFFFFF，暗色模式为深灰 #2C2C2E
    private let cardBackgroundColor = UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 44/255.0, green: 44/255.0, blue: 46/255.0, alpha: 1.0) : UIColor.white
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "添加服务器"
        view.backgroundColor = .systemGroupedBackground

        setupNavigationBar()
        buildFormCells()
        setupTableView()
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

    private func buildFormCells() {
        // 配置输入框基础属性
        nameField.placeholder = "我的主机 (必填)"
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

        passwordField.placeholder = "连接密码"
        passwordField.isSecureTextEntry = true
        passwordField.clearButtonMode = .whileEditing
        passwordField.textColor = .label

        // 构建 Section 0 (基本信息)
        basicCells = [
            createInputCell(title: "名称", field: nameField),
            createInputCell(title: "主机", field: hostField),
            createInputCell(title: "端口", field: portField)
        ]

        // 构建 Section 1 (凭据认证)
        authCells = [
            createInputCell(title: "用户", field: userField),
            createInputCell(title: "密码", field: passwordField)
        ]
    }

    private func createInputCell(title: String, field: UITextField) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        
        // 关键修复：直接将背景色硬性锁定为卡片纯白色，禁用默认透明层透出灰色底！
        cell.backgroundColor = cardBackgroundColor
        cell.contentView.backgroundColor = cardBackgroundColor

        var bg = UIBackgroundConfiguration.listGroupedCell()
        bg.backgroundColor = cardBackgroundColor
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
            titleLabel.widthAnchor.constraint(equalToConstant: 72),

            field.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            field.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10),
            field.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -10),
            field.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
        ])

        return cell
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
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
        let pwd = passwordField.text ?? ""

        let newServer = Server(
            name: name,
            host: host,
            port: port,
            username: user.isEmpty ? "root" : user,
            authType: .password(pwd)
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

// MARK: - UITableViewDataSource, UITableViewDelegate

extension AddServerViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? basicCells.count : authCells.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "基本信息" : "凭据认证"
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return "密码将安全保存在本地沙盒，支持多路并发 SSH 采集与终端会话。"
        }
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return indexPath.section == 0 ? basicCells[indexPath.row] : authCells[indexPath.row]
    }
}
