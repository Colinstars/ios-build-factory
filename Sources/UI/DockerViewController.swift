import UIKit

/// Docker 容器管理模块 (纯 UI 演示与真实交互形态)
///
/// 遵循你的指示：当前阶段功能先不强求走真实远程下发，只做纯正、精致、规范的 Apple 原生 UI！
final class DockerViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let refreshControl = UIRefreshControl()

    // 默认内置经典 Docker 容器卡片，展示完美的运行与停止状态
    private var containers: [DockerContainer] = [
        DockerContainer(id: "c8f1a20b", image: "nginx:alpine", status: "Up 3 hours (healthy)", isRunning: true, names: "web-gateway"),
        DockerContainer(id: "9e4d5671", image: "redis:7.2-alpine", status: "Up 2 days", isRunning: true, names: "redis-cache"),
        DockerContainer(id: "3a11c890", image: "postgres:16", status: "Up 5 days (Port: 5432)", isRunning: true, names: "db-postgres"),
        DockerContainer(id: "5b78f112", image: "traefik:v2.10", status: "Exited (0) 4 hours ago", isRunning: false, names: "traefik-proxy"),
        DockerContainer(id: "1c990234", image: "node:20-slim", status: "Exited (137) 1 day ago", isRunning: false, names: "build-worker")
    ]

    init(session: SSHSession? = nil) {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "容器"
        navigationController?.navigationBar.prefersLargeTitles = true

        view.backgroundColor = .systemGroupedBackground
        setupTableView()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DockerContainerCell.self, forCellReuseIdentifier: "DockerCell")
        

        view.addSubview(tableView)

        refreshControl.addTarget(self, action: #selector(didPullRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func didPullRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
}

// MARK: - TableView

extension DockerViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let running = containers.filter { $0.isRunning }
        let stopped = containers.filter { !$0.isRunning }
        return section == 0 ? running.count : stopped.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let runningCount = containers.filter { $0.isRunning }.count
        let stoppedCount = containers.filter { !$0.isRunning }.count
        return section == 0 ? "运行中 (\(runningCount))" : "已停止 (\(stoppedCount))"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DockerCell", for: indexPath) as! DockerContainerCell
        let running = containers.filter { $0.isRunning }
        let stopped = containers.filter { !$0.isRunning }
        let c = indexPath.section == 0 ? running[indexPath.row] : stopped[indexPath.row]
        cell.configure(with: c)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let running = containers.filter { $0.isRunning }
        let stopped = containers.filter { !$0.isRunning }
        let c = indexPath.section == 0 ? running[indexPath.row] : stopped[indexPath.row]

        let sheet = UIAlertController(
            title: c.names,
            message: "镜像: \(c.image)\n状态: \(c.status)",
            preferredStyle: .actionSheet
        )

        if c.isRunning {
            sheet.addAction(UIAlertAction(title: "重启容器 (Restart)", style: .default, handler: { [weak self] _ in
                self?.toggleContainer(id: c.id, targetRunning: true)
            }))
            sheet.addAction(UIAlertAction(title: "停止容器 (Stop)", style: .destructive, handler: { [weak self] _ in
                self?.toggleContainer(id: c.id, targetRunning: false)
            }))
        } else {
            sheet.addAction(UIAlertAction(title: "启动容器 (Start)", style: .default, handler: { [weak self] _ in
                self?.toggleContainer(id: c.id, targetRunning: true)
            }))
        }

        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(sheet, animated: true)
    }

    private func toggleContainer(id: String, targetRunning: Bool) {
        if let idx = containers.firstIndex(where: { $0.id == id }) {
            let old = containers[idx]
            containers[idx] = DockerContainer(
                id: old.id,
                image: old.image,
                status: targetRunning ? "Up Just now" : "Exited (0) Just now",
                isRunning: targetRunning,
                names: old.names
            )
            tableView.reloadData()
        }
    }
}

// MARK: - Docker Cell

final class DockerContainerCell: UITableViewCell {

    private let statusDot = UIView()
    private let nameLabel = UILabel()
    private let imageLabel = UILabel()
    private let statusLabel = UILabel()

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

        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.layer.cornerRadius = 4
        statusDot.clipsToBounds = true

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label

        imageLabel.translatesAutoresizingMaskIntoConstraints = false
        imageLabel.font = .systemFont(ofSize: 13, weight: .regular)
        imageLabel.textColor = .secondaryLabel

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        statusLabel.textColor = .tertiaryLabel

        contentView.addSubview(statusDot)
        contentView.addSubview(nameLabel)
        contentView.addSubview(imageLabel)
        contentView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusDot.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusDot.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 8),
            statusDot.heightAnchor.constraint(equalToConstant: 8),

            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            imageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            imageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            imageLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            statusLabel.topAnchor.constraint(equalTo: imageLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    func configure(with c: DockerContainer) {
        nameLabel.text = c.names
        imageLabel.text = c.image
        statusLabel.text = c.status
        statusDot.backgroundColor = c.isRunning ? .systemGreen : .systemGray3
    }
}
