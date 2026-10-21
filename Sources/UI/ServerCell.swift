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
        
        let tagInfo = server.tag.map { " [\($0)]" } ?? ""
        let authDesc: String
        switch server.authType {
        case .password:
            authDesc = "密码"
        case .sshKey(let keyId):
            let kName = SSHKeyStore.shared.keys.first(where: { $0.id == keyId })?.name ?? "私钥"
            authDesc = "私钥: \(kName)"
        }
        
        content.secondaryText = "\(server.username)@\(server.host):\(server.port) · \(authDesc)\(tagInfo)"
        content.secondaryTextProperties.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        content.secondaryTextProperties.color = .secondaryLabel
        content.image = UIImage(systemName: "server.rack")
        content.imageProperties.tintColor = .systemBlue
        contentConfiguration = content
    }
}
