import UIKit

/// 全局运维配置模型 (对标 Termius / ServerCat 设置项)
struct OpsSettings: Codable {
    var defaultPort: Int = 22
    var defaultUser: String = "root"
    var connectionTimeoutSeconds: Int = 15
    var autoRefreshIntervalSeconds: Int = 3
    var terminalFontSize: Int = 13
    var keepAliveIntervalSeconds: Int = 30
}

final class SettingsStore {
    static let shared = SettingsStore()
    private let key = "serverlens.settings.v1"
    private(set) var settings = OpsSettings()

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let s = try? JSONDecoder().decode(OpsSettings.self, from: data) {
            self.settings = s
        }
    }

    func update(_ newSettings: OpsSettings) {
        self.settings = newSettings
        if let data = try? JSONEncoder().encode(newSettings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

/// 底部第 5 项【更多】重塑为真正的【设置与运维中心】(对标 Termius Settings / ServerCat 设置)
/// 涵盖：SSH 密钥库管理、默认连接偏好、终端显示配置、网络保活心跳、关于与开源说明
final class ServerOpsViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "设置"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground

        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - TableView

extension ServerOpsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // 密钥管理
        case 1: return 2 // 连接偏好
        case 2: return 2 // 终端与会话
        case 3: return 2 // 关于与数据安全
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "安全凭据"
        case 1: return "SSH 默认偏好"
        case 2: return "终端与通信通道"
        case 3: return "关于 ServerLens"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "支持 Ed25519 与 RSA 工业级密钥。所有私钥均严格隔离保存在 iOS 本地沙盒中，绝不上云。"
        }
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = AppTheme.cardBackground

        let s = SettingsStore.shared.settings

        if indexPath.section == 0 {
            cell.textLabel?.text = "SSH 密钥管理库 (Keychain)"
            let count = SSHKeyStore.shared.keys.count
            cell.detailTextLabel?.text = "\(count) 个密钥"
            cell.accessoryType = .disclosureIndicator
            cell.imageView?.image = UIImage(systemName: "key.fill")
            cell.imageView?.tintColor = .systemYellow
        } else if indexPath.section == 1 {
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                cell.textLabel?.text = "默认端口"
                cell.detailTextLabel?.text = "\(s.defaultPort)"
                cell.imageView?.image = UIImage(systemName: "number")
                cell.imageView?.tintColor = .systemBlue
            } else {
                cell.textLabel?.text = "默认用户名"
                cell.detailTextLabel?.text = s.defaultUser
                cell.imageView?.image = UIImage(systemName: "person.crop.circle")
                cell.imageView?.tintColor = .systemGreen
            }
        } else if indexPath.section == 2 {
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                cell.textLabel?.text = "连接超时时间"
                cell.detailTextLabel?.text = "\(s.connectionTimeoutSeconds) 秒"
                cell.imageView?.image = UIImage(systemName: "timer")
                cell.imageView?.tintColor = .systemOrange
            } else {
                cell.textLabel?.text = "Keep-Alive 保活心跳"
                cell.detailTextLabel?.text = "\(s.keepAliveIntervalSeconds) 秒"
                cell.imageView?.image = UIImage(systemName: "waveform.path.ecg")
                cell.imageView?.tintColor = .systemPurple
            }
        } else {
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                cell.textLabel?.text = "版本号"
                cell.detailTextLabel?.text = "0.5.0 (Build 13)"
                cell.imageView?.image = UIImage(systemName: "info.circle")
                cell.imageView?.tintColor = .systemGray
            } else {
                cell.textLabel?.text = "数据隐私协议"
                cell.detailTextLabel?.text = "本地独占存储"
                cell.imageView?.image = UIImage(systemName: "hand.raised.fill")
                cell.imageView?.tintColor = .systemGreen
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 && indexPath.row == 0 {
            // 打开专门的 SSH 密钥管理页面
            let keysVC = SSHKeysViewController()
            navigationController?.pushViewController(keysVC, animated: true)
        }
    }
}
