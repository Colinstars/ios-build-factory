import UIKit

/// 全局运维配置模型
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

/// 系统全局设置视图控制器
final class ServerOpsViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = AppTheme.pageBackground

        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = AppTheme.pageBackground
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
        case 0: return 1 // 密钥库
        case 1: return 2 // 默认端口与用户名
        case 2: return 2 // 超时与心跳
        case 3: return 2 // 关于与版本
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "安全凭据"
        case 1: return "SSH 偏好"
        case 2: return "终端与通信"
        case 3: return "关于"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "SettingCell")
        cell.backgroundColor = AppTheme.cardBackground
        cell.textLabel?.textColor = .label
        cell.detailTextLabel?.textColor = .secondaryLabel

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "SSH 密钥管理库 (Keychain)"
            let count = SSHKeyStore.shared.keys.count
            cell.detailTextLabel?.text = "\(count) 个密钥"
            cell.accessoryType = .disclosureIndicator
        case (1, 0):
            cell.textLabel?.text = "默认端口"
            cell.detailTextLabel?.text = "\(SettingsStore.shared.settings.defaultPort)"
            cell.accessoryType = .none
        case (1, 1):
            cell.textLabel?.text = "默认用户名"
            cell.detailTextLabel?.text = SettingsStore.shared.settings.defaultUser
            cell.accessoryType = .none
        case (2, 0):
            cell.textLabel?.text = "连接超时时间"
            cell.detailTextLabel?.text = "\(SettingsStore.shared.settings.connectionTimeoutSeconds) 秒"
            cell.accessoryType = .none
        case (2, 1):
            cell.textLabel?.text = "Keep-Alive 心跳保活"
            cell.detailTextLabel?.text = "\(SettingsStore.shared.settings.keepAliveIntervalSeconds) 秒"
            cell.accessoryType = .none
        case (3, 0):
            cell.textLabel?.text = "应用版本"
            cell.detailTextLabel?.text = "1.0.0 (Build 38)"
            cell.accessoryType = .none
        case (3, 1):
            cell.textLabel?.text = "本地数据存储"
            cell.detailTextLabel?.text = "100% 设备本地独占"
            cell.accessoryType = .none
        default:
            break
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 0 {
            let keysVC = SSHKeysViewController()
            navigationController?.pushViewController(keysVC, animated: true)
        }
    }
}
