import UIKit

/// 主机列表项卡片组件 (遵循 Apple HIG 规范，支持多系统自适应徽章展示)
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
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.backgroundColor = AppTheme.cardBackground
        cardContainer.layer.cornerRadius = 14
        cardContainer.layer.cornerCurve = .continuous
        cardContainer.layer.borderWidth = 0.5
        cardContainer.layer.borderColor = AppTheme.separator.cgColor
        cardContainer.clipsToBounds = true
        contentView.addSubview(cardContainer)

        // 精致紧凑图标底座 (36x36 黄金比例)
        iconBadge.translatesAutoresizingMaskIntoConstraints = false
        iconBadge.layer.cornerRadius = 9
        iconBadge.layer.cornerCurve = .continuous
        iconBadge.clipsToBounds = true
        cardContainer.addSubview(iconBadge)

        osIconView.translatesAutoresizingMaskIntoConstraints = false
        osIconView.contentMode = .scaleAspectFit
        iconBadge.addSubview(osIconView)

        // 主标题
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        cardContainer.addSubview(titleLabel)

        // 副标题：12pt 精细体
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = UIColor(red: 142/255.0, green: 146/255.0, blue: 168/255.0, alpha: 1.0)
        subtitleLabel.numberOfLines = 1
        cardContainer.addSubview(subtitleLabel)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.color = AppTheme.accent
        cardContainer.addSubview(spinner)

        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            // 图标底座 36x36
            iconBadge.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 14),
            iconBadge.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            iconBadge.widthAnchor.constraint(equalToConstant: 36),
            iconBadge.heightAnchor.constraint(equalToConstant: 36),

            osIconView.centerXAnchor.constraint(equalTo: iconBadge.centerXAnchor),
            osIconView.centerYAnchor.constraint(equalTo: iconBadge.centerYAnchor),
            osIconView.widthAnchor.constraint(equalToConstant: 20),
            osIconView.heightAnchor.constraint(equalToConstant: 20),

            // 文本区域
            titleLabel.leadingAnchor.constraint(equalTo: iconBadge.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: spinner.leadingAnchor, constant: -10),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -12),

            spinner.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -16),
            spinner.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor)
        ])
    }

    func configure(with server: Server, isConnecting: Bool = false) {
        titleLabel.text = server.name

        // 核心：调用 OSBadgeTheme 注册表动态匹配系统发行版图标与色彩体系，绝无写死
        let theme = OSBadgeTheme.resolve(for: server.osType, serverName: server.name)
        iconBadge.backgroundColor = theme.badgeColor

        if theme.isCustomAsset, let customImg = UIImage(named: theme.iconName) ?? UIImage(contentsOfFile: Bundle.main.bundlePath + "/\(theme.iconName).png") {
            osIconView.image = customImg.withRenderingMode(.alwaysTemplate)
            osIconView.tintColor = .white
        } else {
            let cfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
            osIconView.image = UIImage(systemName: theme.iconName, withConfiguration: cfg)
            osIconView.tintColor = .white
        }

        if isConnecting {
            subtitleLabel.text = "Connecting..."
            subtitleLabel.textColor = AppTheme.accent
            spinner.startAnimating()
        } else {
            // 元数据按规范排版：ssh, 用户名, 系统类型, 地区
            var metas: [String] = ["ssh", server.username]
            if let os = server.osType, !os.isEmpty {
                metas.append(os.lowercased())
            } else {
                metas.append(theme.displayName.lowercased())
            }
            if let reg = server.region, !reg.isEmpty {
                metas.append(reg)
            } else if let tag = server.tag, !tag.isEmpty {
                metas.append(tag)
            }
            subtitleLabel.text = metas.joined(separator: ", ")
            subtitleLabel.textColor = UIColor(red: 142/255.0, green: 146/255.0, blue: 168/255.0, alpha: 1.0)
            spinner.stopAnimating()
        }
    }
}
