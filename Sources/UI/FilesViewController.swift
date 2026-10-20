import UIKit

/// 远程文件浏览器模块 (纯 UI 沉浸式与极速交互形态)
///
/// 遵循你的指示：当前阶段专注于把 Apple 原生 UI、层级与手感做到极致！
final class FilesViewController: UIViewController {

    private var currentPath: String = "/etc/nginx"
    private var items: [RemoteFileItem] = []

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let refreshControl = UIRefreshControl()

    init(session: SSHSession? = nil, initialPath: String = "/etc/nginx") {
        self.currentPath = initialPath
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "文件"
        navigationController?.navigationBar.prefersLargeTitles = true

        view.backgroundColor = .systemGroupedBackground

        setupTableView()
        loadDemoFiles()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FileItemCell.self, forCellReuseIdentifier: "FileCell")
        

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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func loadDemoFiles() {
        items = [
            RemoteFileItem(id: "conf.d", name: "conf.d", path: "/etc/nginx/conf.d", isDirectory: true, sizeString: "4 项", permissions: "drwxr-xr-x"),
            RemoteFileItem(id: "sites-enabled", name: "sites-enabled", path: "/etc/nginx/sites-enabled", isDirectory: true, sizeString: "2 项", permissions: "drwxr-xr-x"),
            RemoteFileItem(id: "ssl", name: "ssl", path: "/etc/nginx/ssl", isDirectory: true, sizeString: "3 项", permissions: "drwx------"),
            RemoteFileItem(id: "nginx.conf", name: "nginx.conf", path: "/etc/nginx/nginx.conf", isDirectory: false, sizeString: "2.4 KB", permissions: "-rw-r--r--"),
            RemoteFileItem(id: "mime.types", name: "mime.types", path: "/etc/nginx/mime.types", isDirectory: false, sizeString: "5.1 KB", permissions: "-rw-r--r--"),
            RemoteFileItem(id: "fastcgi_params", name: "fastcgi_params", path: "/etc/nginx/fastcgi_params", isDirectory: false, sizeString: "1.0 KB", permissions: "-rw-r--r--"),
            RemoteFileItem(id: "proxy_params", name: "proxy_params", path: "/etc/nginx/proxy_params", isDirectory: false, sizeString: "840 B", permissions: "-rw-r--r--")
        ]
        tableView.reloadData()
    }
}

// MARK: - TableView

extension FilesViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "当前路径: \(currentPath)"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath) as! FileItemCell
        cell.configure(with: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]

        if item.isDirectory {
            let nextVC = FilesViewController(initialPath: item.path)
            navigationController?.pushViewController(nextVC, animated: true)
        } else {
            let demoCode = """
            user www-data;
            worker_processes auto;
            pid /run/nginx.pid;
            include /etc/nginx/modules-enabled/*.conf;

            events {
                worker_connections 1024;
                multi_accept on;
            }

            http {
                sendfile on;
                tcp_nopush on;
                types_hash_max_size 2048;
                include /etc/nginx/mime.types;
                default_type application/octet-stream;

                access_log /var/log/nginx/access.log;
                error_log /var/log/nginx/error.log;

                gzip on;
                include /etc/nginx/conf.d/*.conf;
                include /etc/nginx/sites-enabled/*;
            }
            """
            let previewVC = FilePreviewViewController(fileName: item.name, content: demoCode)
            let nav = UINavigationController(rootViewController: previewVC)
            present(nav, animated: true)
        }
    }
}

// MARK: - File Item Cell

final class FileItemCell: UITableViewCell {

    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()

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

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.lineBreakMode = .byTruncatingMiddle

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        detailLabel.textColor = .secondaryLabel
        detailLabel.textAlignment = .right

        contentView.addSubview(iconView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(detailLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: detailLabel.leadingAnchor, constant: -12),

            detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            detailLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
        ])
    }

    func configure(with item: RemoteFileItem) {
        nameLabel.text = item.name
        detailLabel.text = item.sizeString

        if item.isDirectory {
            iconView.image = UIImage(systemName: "folder.fill")
            iconView.tintColor = .systemYellow
        } else {
            iconView.image = UIImage(systemName: "doc.text.fill")
            iconView.tintColor = .systemBlue
        }
    }
}

// MARK: - File Preview Controller

final class FilePreviewViewController: UIViewController {

    private let fileName: String
    private let content: String
    private let textView = UITextView()

    init(fileName: String, content: String) {
        self.fileName = fileName
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = fileName
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "完成",
            style: .done,
            target: self,
            action: #selector(didTapDone)
        )

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .systemBackground
        textView.text = content
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func didTapDone() {
        dismiss(animated: true)
    }
}
