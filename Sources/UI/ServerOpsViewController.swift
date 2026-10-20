import UIKit

/// 更多 / 系统运维与进程管理模块
final class ServerOpsViewController: UIViewController {

    private let session: SSHSession
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let refreshControl = UIRefreshControl()

    private var processes: [LinuxProcess] = []
    private var healthReport = QuickHealthReport()
    private var isRefreshing = false

    init(session: SSHSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        setupTableView()
        loadData()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProcessItemCell.self, forCellReuseIdentifier: "ProcessCell")
        view.addSubview(tableView)

        refreshControl.addTarget(self, action: #selector(loadData), for: .valueChanged)
        tableView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc func loadData() {
        guard !isRefreshing else { return }
        isRefreshing = true

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let procs = try await self.session.fetchTopProcesses()
                let report = try await self.session.fetchQuickHealth()
                await MainActor.run {
                    self.processes = procs
                    self.healthReport = report
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                    self.isRefreshing = false
                }
            } catch {
                await MainActor.run {
                    self.refreshControl.endRefreshing()
                    self.isRefreshing = false
                }
            }
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
        if section == 0 { return "快捷运维指令" }
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
                cell.detailTextLabel?.textColor = healthReport.zombieProcs > 0 ? .systemRed : .systemGreen
            } else {
                cell.textLabel?.text = "自定义终端执行"
                cell.detailTextLabel?.text = "点击下发"
                cell.accessoryType = .disclosureIndicator
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
            let cmd = indexPath.row == 0 ? "systemctl restart sshd" : "sync && echo 3 > /proc/sys/vm/drop_caches && echo '缓存已清理'"
            executeCommandPrompt(cmd)
        } else if indexPath.section == 1 && indexPath.row == 1 {
            promptCustomCommand()
        }
    }

    private func executeCommandPrompt(_ cmd: String) {
        let alert = UIAlertController(title: "执行确认", message: "是否立即在服务器执行以下指令？\n\n\(cmd)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "执行", style: .destructive, handler: { [weak self] _ in
            self?.runCommand(cmd)
        }))
        present(alert, animated: true)
    }

    private func promptCustomCommand() {
        let alert = UIAlertController(title: "执行 Shell 指令", message: "输入单行指令快速在远端执行并回显：", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "如: whoami 或 iptables -L" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "运行", style: .default, handler: { [weak self] _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            self?.runCommand(text)
        }))
        present(alert, animated: true)
    }

    private func runCommand(_ cmd: String) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let out = try await self.session.executeCustomCommand(cmd)
                await MainActor.run {
                    let resultAlert = UIAlertController(title: "命令执行结果", message: out, preferredStyle: .alert)
                    resultAlert.addAction(UIAlertAction(title: "完成", style: .default))
                    self.present(resultAlert, animated: true)
                    self.loadData()
                }
            } catch {
                await MainActor.run {
                    let errAlert = UIAlertController(title: "执行错误", message: error.localizedDescription, preferredStyle: .alert)
                    errAlert.addAction(UIAlertAction(title: "好的", style: .default))
                    self.present(errAlert, animated: true)
                }
            }
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
