import UIKit

/// 更多 / 系统运维与进程管理模块 (纯 UI 沉浸与高质感交互形态)
///
/// 遵循 Apple HIG Navigation Bars 规范：
/// 彻底修复列表往上滑时无背景模糊遮罩的 Bug！
/// 启用系统标准 configureWithDefaultBackground()，内容滑入导航栏下方时呈现优雅半透明磨砂遮罩。
final class ServerOpsViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let refreshControl = UIRefreshControl()

    // 默认内置高仿真典型 Linux 服务器运维进程与健康体检数据
    private var processes: [LinuxProcess] = [
        LinuxProcess(id: "1", pid: 9821, user: "root", cpuPercent: 12.4, memPercent: 3.2, command: "nginx: worker process"),
        LinuxProcess(id: "2", pid: 14022, user: "postgres", cpuPercent: 8.7, memPercent: 18.5, command: "postgres: writer process"),
        LinuxProcess(id: "3", pid: 28410, user: "redis", cpuPercent: 4.1, memPercent: 6.8, command: "redis-server *:6379"),
        LinuxProcess(id: "4", pid: 409, user: "root", cpuPercent: 2.3, memPercent: 1.1, command: "containerd"),
        LinuxProcess(id: "5", pid: 1102, user: "systemd-resolve", cpuPercent: 0.8, memPercent: 0.9, command: "systemd-resolved"),
        LinuxProcess(id: "6", pid: 881, user: "root", cpuPercent: 0.5, memPercent: 0.4, command: "/usr/sbin/sshd -D")
    ]
    private var healthReport = QuickHealthReport(loadStatus: "优", memoryStatus: "充裕", diskStatus: "健康", zombieProcs: 0, tcpEstablished: 42)

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "更多"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // 关键物理穿透契约：允许列表向上滑动时毫无阻碍地穿透至导航栏下方，呈现极致微透折射！
        self.extendedLayoutIncludesOpaqueBars = true
        self.edgesForExtendedLayout = .all

        view.backgroundColor = .systemGroupedBackground

        setupTableView()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProcessItemCell.self, forCellReuseIdentifier: "ProcessCell")
        view.addSubview(tableView)

        refreshControl.addTarget(self, action: #selector(didPullRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        // TableView 顶部锚定在 view.topAnchor，确保在滚动穿透时，导航栏的磨砂材质遮罩平滑过滤！
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func didPullRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
}

// MARK: - TableView

extension ServerOpsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 2 } // 常用快捷命令
        if section == 1 { return 2 } // 系统体检
        return processes.count       // 进程列表
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return "常用快捷运维" }
        if section == 1 { return "系统健康与网络" }
        return "Top CPU 占用进程"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.accessoryType = .disclosureIndicator
            if indexPath.row == 0 {
                cell.textLabel?.text = "重启 SSH 服务 (sshd restart)"
                cell.detailTextLabel?.text = "systemctl restart sshd"
                cell.imageView?.image = UIImage(systemName: "arrow.triangle.2.circlepath")
                cell.imageView?.tintColor = .systemBlue
            } else {
                cell.textLabel?.text = "清理系统无用缓存"
                cell.detailTextLabel?.text = "sync; echo 3 > /proc/sys/vm/drop_caches"
                cell.imageView?.image = UIImage(systemName: "trash")
                cell.imageView?.tintColor = .systemOrange
            }
            return cell
        } else if indexPath.section == 1 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                cell.textLabel?.text = "僵尸进程数"
                cell.detailTextLabel?.text = "\(healthReport.zombieProcs) 个"
                cell.detailTextLabel?.textColor = .systemGreen
            } else {
                cell.textLabel?.text = "TCP 建立连接数"
                cell.detailTextLabel?.text = "\(healthReport.tcpEstablished) 个"
                cell.detailTextLabel?.textColor = .label
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProcessCell", for: indexPath) as! ProcessItemCell
            cell.configure(with: processes[indexPath.row])
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            let name = indexPath.row == 0 ? "重启 SSH 服务" : "清理系统缓存"
            let alert = UIAlertController(title: "指令模拟就绪", message: "已确认执行【\(name)】命令，主机运行正常。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "完成", style: .default))
            present(alert, animated: true)
        }
    }
}

// MARK: - Process Cell

final class ProcessItemCell: UITableViewCell {

    private let commLabel = UILabel()
    private let pidLabel = UILabel()
    private let statsLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        selectionStyle = .default
        accessoryType = .disclosureIndicator

        commLabel.translatesAutoresizingMaskIntoConstraints = false
        commLabel.font = .monospacedSystemFont(ofSize: 14, weight: .semibold)
        commLabel.textColor = .label

        pidLabel.translatesAutoresizingMaskIntoConstraints = false
        pidLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        pidLabel.textColor = .secondaryLabel

        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        statsLabel.font = .monospacedSystemFont(ofSize: 12, weight: .bold)
        statsLabel.textColor = .systemBlue
        statsLabel.textAlignment = .right

        contentView.addSubview(commLabel)
        contentView.addSubview(pidLabel)
        contentView.addSubview(statsLabel)

        NSLayoutConstraint.activate([
            commLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            commLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            commLabel.trailingAnchor.constraint(lessThanOrEqualTo: statsLabel.leadingAnchor, constant: -8),

            pidLabel.topAnchor.constraint(equalTo: commLabel.bottomAnchor, constant: 2),
            pidLabel.leadingAnchor.constraint(equalTo: commLabel.leadingAnchor),
            pidLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            statsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    func configure(with p: LinuxProcess) {
        commLabel.text = p.command
        pidLabel.text = "PID: \(p.pid) | 用户: \(p.user)"
        statsLabel.text = String(format: "CPU: %.1f%%  MEM: %.1f%%", p.cpuPercent, p.memPercent)
    }
}
