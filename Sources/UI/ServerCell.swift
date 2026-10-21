import UIKit

/// 100% 对标 Termius 官方 Hosts 列表卡片规范的高级精雕主机单元格
final class ServerCell: UITableViewCell {

    private let cardContainer = UIView()
    private let iconBadge = UIView()
    private let osIconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // 卡片容器：统一使用 AppTheme.cardBackground 严苛规范
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.backgroundColor = AppTheme.cardBackground
        cardContainer.layer.cornerRadius = 16
        cardContainer.layer.cornerCurve = .continuous
        cardContainer.layer.borderWidth = 0.5
        cardContainer.layer.borderColor = AppTheme.separator.cgColor
        cardContainer.clipsToBounds = true
        contentView.addSubview(cardContainer)

        // 左侧操作系统图标徽章 (对齐 Termius 的 Debian 红/粉圆角底座)
        iconBadge.translatesAutoresizingMaskIntoConstraints = false
        iconBadge.layer.cornerRadius = 12
        iconBadge.layer.cornerCurve = .continuous
        iconBadge.clipsToBounds = true
        cardContainer.addSubview(iconBadge)

        osIconView.translatesAutoresizingMaskIntoConstraints = false
        osIconView.contentMode = .scaleAspectFit
        iconBadge.addSubview(osIconView)

        // 主标题：加粗白字
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        cardContainer.addSubview(titleLabel)

        // 副标题：使用标准系统字体，彻底解决 Monospaced 字体导致的下沉切边/遮挡 BUG
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = UIColor(white: 0.6, alpha: 1.0)
        subtitleLabel.numberOfLines = 1
        cardContainer.addSubview(subtitleLabel)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.color = UIColor(red: 122/255.0, green: 162/255.0, blue: 247/255.0, alpha: 1.0)
        cardContainer.addSubview(spinner)

        NSLayoutConstraint.activate([
            // 卡片容器在 Cell 内部留出舒适边距
            cardContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            // 图标底座：44x44
            iconBadge.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 14),
            iconBadge.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            iconBadge.widthAnchor.constraint(equalToConstant: 44),
            iconBadge.heightAnchor.constraint(equalToConstant: 44),

            osIconView.centerXAnchor.constraint(equalTo: iconBadge.centerXAnchor),
            osIconView.centerYAnchor.constraint(equalTo: iconBadge.centerYAnchor),
            osIconView.widthAnchor.constraint(equalToConstant: 24),
            osIconView.heightAnchor.constraint(equalToConstant: 24),

            // 文本区域：高度充裕，彻底杜绝字母 g, p, y, q 或下划线被裁切
            titleLabel.leadingAnchor.constraint(equalTo: iconBadge.trailingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: spinner.leadingAnchor, constant: -10),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -14),

            spinner.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -18),
            spinner.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor)
        ])
    }

    func configure(with server: Server, isConnecting: Bool = false) {
        titleLabel.text = server.name

        // 智能根据系统类型自动渲染真实 Linux 发行版官方色彩徽章 (对齐 Termius)
        let os = (server.osType ?? "").lowercased()
        if os.contains("debian") || server.name.lowercased().contains("dmit") || server.name.lowercased().contains("debian") {
            // Debian 官方标志：Debian 螺旋红白徽章
            iconBadge.backgroundColor = UIColor(red: 215/255.0, green: 10/255.0, blue: 83/255.0, alpha: 0.95)
            let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
            osIconView.image = UIImage(systemName: "tornado", withConfiguration: cfg) // 拟物 Debian 螺旋
            osIconView.tintColor = .white
        } else if os.contains("ubuntu") {
            iconBadge.backgroundColor = UIColor(red: 233/255.0, green: 84/255.0, blue: 32/255.0, alpha: 0.95)
            let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
            osIconView.image = UIImage(systemName: "circle.circle.fill", withConfiguration: cfg)
            osIconView.tintColor = .white
        } else if os.contains("centos") || os.contains("redhat") {
            iconBadge.backgroundColor = UIColor(red: 147/255.0, green: 34/255.0, blue: 147/255.0, alpha: 0.95)
            let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
            osIconView.image = UIImage(systemName: "cube.fill", withConfiguration: cfg)
            osIconView.tintColor = .white
        } else if os.contains("alpine") {
            iconBadge.backgroundColor = UIColor(red: 13/255.0, green: 89/255.0, blue: 135/255.0, alpha: 0.95)
            let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
            osIconView.image = UIImage(systemName: "mountain.2.fill", withConfiguration: cfg)
            osIconView.tintColor = .white
        } else {
            iconBadge.backgroundColor = UIColor(red: 45/255.0, green: 50/255.0, blue: 70/255.0, alpha: 0.95)
            let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
            osIconView.image = UIImage(systemName: "terminal.fill", withConfiguration: cfg)
            osIconView.tintColor = UIColor(red: 122/255.0, green: 162/255.0, blue: 247/255.0, alpha: 1.0)
        }

        if isConnecting {
            subtitleLabel.text = "Connecting..."
            subtitleLabel.textColor = UIColor(red: 122/255.0, green: 162/255.0, blue: 247/255.0, alpha: 1.0)
            spinner.startAnimating()
        } else {
            subtitleLabel.text = "\(server.username)@\(server.host):\(server.port)"
            subtitleLabel.textColor = UIColor(white: 0.55, alpha: 1.0)
            spinner.stopAnimating()
        }
    }
}
