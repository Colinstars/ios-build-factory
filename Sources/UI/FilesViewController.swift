import UIKit

/// 远程文件浏览器模块
final class FilesViewController: UIViewController {

    private let session: SSHSession
    private var currentPath: String = "/"
    private var items: [RemoteFileItem] = []

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let pathBar = UILabel()
    private let refreshControl = UIRefreshControl()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    init(session: SSHSession, initialPath: String = "/") {
        self.session = session
        self.currentPath = initialPath
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupPathBar()
        setupTableView()
        loadDirectory(path: currentPath)
    }

    private func setupPathBar() {
        pathBar.translatesAutoresizingMaskIntoConstraints = false
        pathBar.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        pathBar.textColor = .secondaryLabel
        pathBar.backgroundColor = .secondarySystemBackground
        pathBar.text = " 当前路径: \(currentPath)"
        view.addSubview(pathBar)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            pathBar.topAnchor.constraint(equalTo: view.topAnchor),
            pathBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pathBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pathBar.heightAnchor.constraint(equalToConstant: 32),

            activityIndicator.centerYAnchor.constraint(equalTo: pathBar.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: pathBar.trailingAnchor, constant: -12),
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FileItemCell.self, forCellReuseIdentifier: "FileCell")
        view.addSubview(tableView)

        refreshControl.addTarget(self, action: #selector(didPullRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: pathBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func didPullRefresh() {
        loadDirectory(path: currentPath)
    }

    func loadDirectory(path: String) {
        currentPath = path
        pathBar.text = " 路径: \(currentPath)"
        activityIndicator.startAnimating()

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let list = try await self.session.listRemoteDirectory(at: path)
                await MainActor.run {
                    self.items = list
                    self.tableView.reloadData()
                    self.activityIndicator.stopAnimating()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.refreshControl.endRefreshing()
                    let alert = UIAlertController(title: "读取目录失败", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "好的", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - TableView

extension FilesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath) as! FileItemCell
        cell.configure(with: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]

        if item.name == ".." {
            // 返回上一级
            let parent = (currentPath as NSString).deletingLastPathComponent
            loadDirectory(path: parent.isEmpty ? "/" : parent)
            return
        }

        if item.isDirectory {
            loadDirectory(path: item.path)
        } else {
            // 文本文件预览
            previewFile(item)
        }
    }

    private func previewFile(_ item: RemoteFileItem) {
        activityIndicator.startAnimating()
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let content = try await self.session.readRemoteFilePreview(at: item.path)
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    let previewVC = FilePreviewViewController(fileName: item.name, content: content)
                    let nav = UINavigationController(rootViewController: previewVC)
                    self.present(nav, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    let alert = UIAlertController(title: "无法读取文件", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .default))
                    self.present(alert, animated: true)
                }
            }
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
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 15, weight: .regular)
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
            detailLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
        ])
    }

    func configure(with item: RemoteFileItem) {
        nameLabel.text = item.name
        detailLabel.text = item.sizeString

        if item.name == ".." {
            iconView.image = UIImage(systemName: "arrow.uturn.backward")
            iconView.tintColor = .systemGray
        } else if item.isDirectory {
            iconView.image = UIImage(systemName: "folder.fill")
            iconView.tintColor = .systemYellow
        } else {
            iconView.image = UIImage(systemName: "doc.text")
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
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .systemBackground
        textView.text = content
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func didTapDone() {
        dismiss(animated: true)
    }
}
