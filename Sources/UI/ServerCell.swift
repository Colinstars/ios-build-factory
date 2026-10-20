import UIKit

/// 主机单元格 —— 使用 Apple 原生的 UIListContentConfiguration，零自定义绘制。
final class ServerCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with server: Server) {
        var content = UIListContentConfiguration.subtitleCell()
        content.text = server.name
        content.secondaryText = "\(server.username)@\(server.host):\(server.port)"
        content.secondaryTextProperties.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        content.image = UIImage(systemName: "server.rack")
        content.imageProperties.tintColor = .systemBlue
        contentConfiguration = content
    }
}
