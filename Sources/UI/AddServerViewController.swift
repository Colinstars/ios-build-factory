import UIKit

protocol AddServerViewControllerDelegate: AnyObject {
    func addServerViewController(_ controller: AddServerViewController, didAdd server: Server)
}

/// 遵循现代 iOS HIG 规范的添加服务器表单页面。
///
/// 彻底废弃简陋的 UIAlertController。
/// 采用标准苹果原生分组表格（insetGrouped），利用 UISheetPresentationController 以大半屏 Sheet 优雅拉起。
/// 内容层纯净质感，符合标准交互预期。
final class AddServerViewController: UIViewController {

    weak var delegate: AddServerViewControllerDelegate?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let nameField = UITextField()
    private let hostField = UITextField()
    private let portField = UITextField()
    private let userField = UITextField()
    private let passwordField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "添加服务器"
        view.backgroundColor = .systemGroupedBackground

        setupNavigationBar()
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

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
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

        configureTextFields()
    }

    private func configureTextFields() {
        nameField.placeholder = "我的主机 (必填)"
        nameField.clearButtonMode = .whileEditing
        nameField.autocapitalizationType = .none
        nameField.autocorrectionType = .no

        hostField.placeholder = "IP 或域名 (必填)"
        hostField.clearButtonMode = .whileEditing
        hostField.keyboardType = .URL
        hostField.autocapitalizationType = .none
        hostField.autocorrectionType = .no

        portField.text = "22"
        portField.placeholder = "22"
        portField.keyboardType = .numberPad

        userField.text = "root"
        userField.placeholder = "root"
        userField.autocapitalizationType = .none
        userField.autocorrectionType = .no

        passwordField.placeholder = "连接密码"
        passwordField.isSecureTextEntry = true
        passwordField.clearButtonMode = .whileEditing
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
        return section == 0 ? 3 : 2
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
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.selectionStyle = .none

        let labelWidth: CGFloat = 80
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = .label
        cell.contentView.addSubview(titleLabel)

        let textField: UITextField
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                titleLabel.text = "名称"
                textField = nameField
            } else if indexPath.row == 1 {
                titleLabel.text = "主机"
                textField = hostField
            } else {
                titleLabel.text = "端口"
                textField = portField
            }
        } else {
            if indexPath.row == 0 {
                titleLabel.text = "用户"
                textField = userField
            } else {
                titleLabel.text = "密码"
                textField = passwordField
            }
        }

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = .systemFont(ofSize: 16)
        cell.contentView.addSubview(textField)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: labelWidth),

            textField.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            textField.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10),
            textField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -10),
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
        ])

        return cell
    }
}
