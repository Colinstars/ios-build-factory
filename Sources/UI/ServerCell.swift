import UIKit

/// 100% 对标 Termius 官方 Hosts 列表卡片规范的高级精雕主机单元格
///
/// 视觉与排版核心重塑：
/// 1. 【严禁暴露裸 IP】：对标 Termius 原版，第二行只展示 `ssh, root, debian, 洛杉矶`，优雅整洁！
/// 2. 【缩小第二行字号与图标尺寸】：图标精致收窄至 36x36（不再过大傻憨），第二行字号收拢至 12pt；
/// 3. 【真实官方 Debian 旋涡矢量图标】：加载官方 Debian Swirl 标志，告别手搓粗糙占位符！
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

        // 精致紧凑图标底座 (36x36，黄金比例，不再过大臃肿)
        iconBadge.translatesAutoresizingMaskIntoConstraints = false
        iconBadge.layer.cornerRadius = 9
        iconBadge.layer.cornerCurve = .continuous
        iconBadge.clipsToBounds = true
        cardContainer.addSubview(iconBadge)

        osIconView.translatesAutoresizingMaskIntoConstraints = false
        osIconView.contentMode = .scaleAspectFit
        iconBadge.addSubview(osIconView)

        // 主标题：加粗 16pt，字重优雅
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        cardContainer.addSubview(titleLabel)

        // 副标题：12pt 浅灰精细体，行高充裕，彻底杜绝切边与遮挡
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

        // 智能根据系统类型自动渲染真实 Linux 发行版官方色彩徽章 (对标 Termius)
        let os = (server.osType ?? "").lowercased()
        if os.contains("debian") || server.name.lowercased().contains("dmit") || server.name.lowercased().contains("debian") {
            // Debian 官方标志：Debian 螺旋玫红底座 + 官方白色螺旋 Logo
            iconBadge.backgroundColor = UIColor(red: 215/255.0, green: 10/255.0, blue: 83/255.0, alpha: 0.95)
            if let debianImg = UIImage(named: "debian_logo") ?? UIImage(contentsOfFile: Bundle.main.bundlePath + "/debian_logo.png") {
                osIconView.image = debianImg.withRenderingMode(.alwaysTemplate)
                osIconView.tintColor = .white
            } else {
                let cfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
                osIconView.image = UIImage(systemName: "circle.hexagongrid.circle.fill", withConfiguration: cfg)
                osIconView.tintColor = .white
            }
        } else if os.contains("ubuntu") {
            iconBadge.backgroundColor = UIColor(red: 233/255.0, green: 84/255.0, blue: 32/255.0, alpha: 0.95)
            let cfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
            osIconView.image = UIImage(systemName: "circle.circle.fill", withConfiguration: cfg)
            osIconView.tintColor = .white
        } else if os.contains("centos") || os.contains("redhat") {
            iconBadge.backgroundColor = UIColor(red: 147/255.0, green: 34/255.0, blue: 147/255.0, alpha: 0.95)
            let cfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
            osIconView.image = UIImage(systemName: "cube.fill", withConfiguration: cfg)
            osIconView.tintColor = .white
        } else {
            iconBadge.backgroundColor = UIColor(red: 45/255.0, green: 50/255.0, blue: 70/255.0, alpha: 0.95)
            let cfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
            osIconView.image = UIImage(systemName: "terminal.fill", withConfiguration: cfg)
            osIconView.tintColor = AppTheme.accent
        }

        if isConnecting {
            subtitleLabel.text = "Connecting..."
            subtitleLabel.textColor = AppTheme.accent
            spinner.startAnimating()
        } else {
            // 严禁显示生硬 IP！100% 对标 Termius 官方精美信息排版：ssh, root, debian, 地区
            var metas: [String] = ["ssh", server.username]
            if let os = server.osType, !os.isEmpty {
                metas.append(os.lowercased())
            } else {
                metas.append("debian")
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
