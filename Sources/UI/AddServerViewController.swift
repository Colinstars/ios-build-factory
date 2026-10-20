import UIKit

/// 彻底锁定抽屉界面的色彩常量：
/// 浅色模式下：底色恒为经典苹果分组浅灰 (#F2F2F7)，输入框卡片恒为纯白 (#FFFFFF)；
/// 深色模式下：底色恒为纯黑 (#000000)，输入框卡片恒为深灰卡片 (#1C1C1E)。
/// 杜绝系统动态语义色在不同 detent 提权时的明度坍缩，实现缩小 (medium) 和放大 (large) 配色 100% 绝对一致！
enum SheetColorScheme {
    static let background = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1.0)
            : UIColor(red: 242/255.0, green: 242/255.0, blue: 247/255.0, alpha: 1.0)
    }

    static let card = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 28/255.0, green: 28/255.0, blue: 30/255.0, alpha: 1.0)
            : UIColor.white
    }
}

protocol AddServerViewControllerDelegate: AnyObject {
    func addServerViewController(_ controller: AddServerViewController, didAdd server: Server)
}

/// 遵循现代 iOS HIG 规范的添加服务器表单页面。
///
/// 彻底解决抽屉在 medium（先提一半）和 large（全展开）底色不一致的根本原因：
/// 1. 不再使用不可控的动态语义色，全面绑定 SheetColorScheme；
/// 2. 无论用户点开半屏，还是放大到全屏，底色与输入框卡片色物理级 100% 恒定；
/// 3. 拥有完整的半屏抽屉手感（先提一半，支持手势上滑放大与下拉关闭）。
final class AddServerViewController: UIViewController {

    weak var delegate: AddServerViewControllerDelegate?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let nameField = UITextField()
    private let hostField = UITextField()
    private let portField = UITextField()
    private let userField = UITextField()
    private let passwordField = UITextField()

    private var basicCells: [UITableViewCell] = []
    private var authCells: [UITableViewCell] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "添加服务器"
        view.backgroundColor = SheetColorScheme.background

        setupNavigationBar()
        buildFormCells()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 确保视图展示时底色彻底锁定
        view.backgroundColor = SheetColorScheme.background
        tableView.backgroundColor = SheetColorScheme.background
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
        nameField.placeholder = "我的主机 (如 DMIT 香港)"
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

        basicCells = [
            createInputCell(title: "名称", field: nameField),
            createInputCell(title: "主机", field: hostField),
            createInputCell(title: "端口", field: portField)
        ]

        authCells = [
            createInputCell(title: "用户", field: userField),
            createInputCell(title: "密码", field: passwordField)
        ]
    }

    private func createInputCell(title: String, field: UITextField) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none

        // 彻底锁定输入框卡片颜色：恒为白色（亮色模式纯白卡片，暗色模式深灰卡片），杜绝与浅灰底色融合！
        cell.backgroundColor = SheetColorScheme.card
        cell.contentView.backgroundColor = SheetColorScheme.card

        var bg = UIBackgroundConfiguration.listGroupedCell()
        bg.backgroundColor = SheetColorScheme.card
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
