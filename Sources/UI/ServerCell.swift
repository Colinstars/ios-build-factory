import UIKit

/// 100% 对标 Termius 官方 Hosts 列表卡片规范的精细化主机单元格
final class ServerCell: UITableViewCell {

    private let iconContainer = UIView()
    private let osIcon = UIImageView()
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
        // 卡片底座
        contentView.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 28/255.0, green: 30/255.0, blue: 44/255.0, alpha: 1.0)
                : UIColor.secondarySystemGroupedBackground
        }
        contentView.layer.cornerRadius = 14
        contentView.clipsToBounds = true

        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = UIColor(red: 215/255.0, green: 10/255.0, blue: 83/255.0, alpha: 0.15)
        iconContainer.layer.cornerRadius = 10
        iconContainer.clipsToBounds = true
        contentView.addSubview(iconContainer)

        osIcon.translatesAutoresizingMaskIntoConstraints = false
        let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        osIcon.image = UIImage(systemName: "terminal.fill", withConfiguration: cfg)
        osIcon.tintColor = UIColor(red: 235/255.0, green: 60/255.0, blue: 110/255.0, alpha: 1.0)
        osIcon.contentMode = .scaleAspectFit
        iconContainer.addSubview(osIcon)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        contentView.addSubview(titleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        contentView.addSubview(subtitleLabel)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.color = UIColor(red: 122/255.0, green: 162/255.0, blue: 247/255.0, alpha: 1.0)
        contentView.addSubview(spinner)

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            iconContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 42),
            iconContainer.heightAnchor.constraint(equalToConstant: 42),

            osIcon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            osIcon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: spinner.leadingAnchor, constant: -10),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),

            spinner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            spinner.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 留出卡片上下边距
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
    }

    func configure(with server: Server, isConnecting: Bool = false) {
        titleLabel.text = server.name

        if isConnecting {
            subtitleLabel.text = "Connecting..."
            subtitleLabel.textColor = UIColor(red: 122/255.0, green: 162/255.0, blue: 247/255.0, alpha: 1.0)
            spinner.startAnimating()
        } else {
            subtitleLabel.text = "\(server.username)@\(server.host):\(server.port)"
            subtitleLabel.textColor = .secondaryLabel
            spinner.stopAnimating()
        }
    }
}
