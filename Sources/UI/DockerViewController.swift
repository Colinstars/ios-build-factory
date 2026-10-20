import UIKit

/// Docker 容器管理模块
final class DockerViewController: UIViewController {

    private let session: SSHSession
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let refreshControl = UIRefreshControl()
    private let emptyLabel = UILabel()

    private var containers: [DockerContainer] = []
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
        setupEmptyLabel()
        loadData()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DockerContainerCell.self, forCellReuseIdentifier: "DockerCell")
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

    private func setupEmptyLabel() {
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "正在检测 Docker 引擎..."
        emptyLabel.font = .systemFont(ofSize: 15, weight: .regular)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
        ])
    }

    @objc func loadData() {
        guard !isRefreshing else { return }
        isRefreshing = true

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let list = try await self.session.fetchDockerContainers()
                await MainActor.run {
                    self.containers = list
                    self.emptyLabel.isHidden = !list.isEmpty
                    if list.isEmpty {
                        self.emptyLabel.text = "未检测到运行中的 Docker 引擎\n或当前服务器无容器实例"
                    }
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                    self.isRefreshing = false
                }
            } catch {
                await MainActor.run {
                    self.emptyLabel.isHidden = false
                    self.emptyLabel.text = "获取失败: \(error.localizedDescription)"
                    self.refreshControl.endRefreshing()
                    self.isRefreshing = false
                }
            }
        }
    }
}

// MARK: - TableView

extension DockerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return containers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DockerCell", for: indexPath) as! DockerContainerCell
        cell.configure(with: containers[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let c = containers[indexPath.row]

        let sheet = UIAlertController(
            title: c.names,
            message: "镜像: \(c.image)\n状态: \(c.status)",
            preferredStyle: .actionSheet
        )

        if c.isRunning {
            sheet.addAction(UIAlertAction(title: "重启容器 (Restart)", style: .default, handler: { [weak self] _ in
                self?.performAction("restart", id: c.id)
            }))
            sheet.addAction(UIAlertAction(title: "停止容器 (Stop)", style: .destructive, handler: { [weak self] _ in
                self?.performAction("stop", id: c.id)
            }))
        } else {
            sheet.addAction(UIAlertAction(title: "启动容器 (Start)", style: .default, handler: { [weak self] _ in
                self?.performAction("start", id: c.id)
            }))
        }

        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(sheet, animated: true)
    }

    private func performAction(_ action: String, id: String) {
        Task { [weak self] in
            guard let self = self else { return }
            _ = try? await self.session.controlDocker(action: action, containerId: id)
            await MainActor.run {
                self.loadData()
            }
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
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.layer.cornerRadius = 5
        statusDot.clipsToBounds = true

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label

        imageLabel.translatesAutoresizingMaskIntoConstraints = false
        imageLabel.font = .systemFont(ofSize: 13, weight: .regular)
        imageLabel.textColor = .secondaryLabel

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = .tertiaryLabel

        contentView.addSubview(statusDot)
        contentView.addSubview(nameLabel)
        contentView.addSubview(imageLabel)
        contentView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusDot.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusDot.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10),

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
