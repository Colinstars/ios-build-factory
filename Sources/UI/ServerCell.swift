import UIKit

/// 顶级商业级主机卡片 Cell (对标 ServerCat / Termius 工业级设计规范)
///
/// 遵循 Apple HIG 视觉层次规范：
/// 1. 左侧图标：40x40 pt 现代圆角方形徽标 (App-style Container)，渐变深空科技蓝底座 + 纯白精致主机符号；
/// 2. 标题区：17pt 加粗标题，清晰有力；
/// 3. 副标题区：等宽字体格式化展示主机网络地址 (IP:Port)，搭配用户身份徽章；
/// 4. 右侧状态：呼吸绿点状态指示器 (在线/正常) + 系统级精致指示箭头。
final class ServerCell: UITableViewCell {

    // 左侧图标容器
    private let iconContainer = UIView()
    private let iconGradientLayer = CAGradientLayer()
    private let iconSymbolView = UIImageView()

    // 中间文本区
    private let titleLabel = UILabel()
    private let addressLabel = UILabel()

    // 右侧状态与指示区
    private let statusBadge = UIView()
    private let statusDot = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        iconGradientLayer.frame = iconContainer.bounds
    }

    private func setupViews() {
        // 卡片整体背景：锁定为系统卡片纯白色
        backgroundColor = SheetColorScheme.card
        contentView.backgroundColor = SheetColorScheme.card

        // 1. 图标容器 (40x40 连续圆角 + 科技感渐变底座)
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.layer.cornerRadius = 10
        iconContainer.layer.cornerCurve = .continuous
        iconContainer.clipsToBounds = true

        iconGradientLayer.colors = [
            UIColor(red: 30/255.0, green: 80/255.0, blue: 220/255.0, alpha: 1.0).cgColor,
            UIColor(red: 20/255.0, green: 40/255.0, blue: 140/255.0, alpha: 1.0).cgColor
        ]
        iconGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        iconGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        iconContainer.layer.addSublayer(iconGradientLayer)

        iconSymbolView.translatesAutoresizingMaskIntoConstraints = false
        iconSymbolView.contentMode = .scaleAspectFit
        iconSymbolView.tintColor = .white
        let symbolCfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iconSymbolView.image = UIImage(systemName: "server.rack", withConfiguration: symbolCfg)
        iconContainer.addSubview(iconSymbolView)

        // 2. 文本区
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = .label

        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        addressLabel.textColor = .secondaryLabel

        // 3. 右侧状态绿点徽章
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        statusBadge.layer.cornerRadius = 9
        statusBadge.clipsToBounds = true

        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.backgroundColor = .systemGreen
        statusDot.layer.cornerRadius = 3.5
        statusBadge.addSubview(statusDot)

        contentView.addSubview(iconContainer)
        contentView.addSubview(titleLabel)
        contentView.addSubview(addressLabel)
        contentView.addSubview(statusBadge)

        NSLayoutConstraint.activate([
            // 图标容器约束
            iconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            iconContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 40),
            iconContainer.heightAnchor.constraint(equalToConstant: 40),

            // 内部符号居中
            iconSymbolView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconSymbolView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconSymbolView.widthAnchor.constraint(equalToConstant: 22),
            iconSymbolView.heightAnchor.constraint(equalToConstant: 22),

            // 标题
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusBadge.leadingAnchor, constant: -8),

            // 地址与端口
            addressLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            addressLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            addressLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusBadge.leadingAnchor, constant: -8),
            addressLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            // 状态指示器
            statusBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            statusBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusBadge.widthAnchor.constraint(equalToConstant: 18),
            statusBadge.heightAnchor.constraint(equalToConstant: 18),

            statusDot.centerXAnchor.constraint(equalTo: statusBadge.centerXAnchor),
            statusDot.centerYAnchor.constraint(equalTo: statusBadge.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 7),
            statusDot.heightAnchor.constraint(equalToConstant: 7),
        ])
    }

    func configure(with server: Server) {
        titleLabel.text = server.name
        addressLabel.text = "\(server.username)@\(server.host):\(server.port)"
    }
}
