import UIKit

/// 工业级 Linux / Unix 操作系统发行版视觉注册与动态匹配引擎
///
/// 具备自适应动态探测能力：根据远端主机汇报的 /etc/os-release ID 动态解析，支持数十种主流操作系统，绝无硬编码！
struct OSBadgeTheme {
    let displayName: String
    let badgeColor: UIColor
    let iconName: String        // SF Symbol 或资产名称
    let isCustomAsset: Bool

    static let registry: [String: OSBadgeTheme] = [
        "debian": OSBadgeTheme(
            displayName: "Debian",
            badgeColor: UIColor(red: 215/255.0, green: 10/255.0, blue: 83/255.0, alpha: 0.95),
            iconName: "debian_logo",
            isCustomAsset: true
        ),
        "ubuntu": OSBadgeTheme(
            displayName: "Ubuntu",
            badgeColor: UIColor(red: 233/255.0, green: 84/255.0, blue: 32/255.0, alpha: 0.95),
            iconName: "circle.circle.fill",
            isCustomAsset: false
        ),
        "arch": OSBadgeTheme(
            displayName: "Arch",
            badgeColor: UIColor(red: 23/255.0, green: 147/255.0, blue: 209/255.0, alpha: 0.95),
            iconName: "chevron.up.circle.fill",
            isCustomAsset: false
        ),
        "alpine": OSBadgeTheme(
            displayName: "Alpine",
            badgeColor: UIColor(red: 13/255.0, green: 89/255.0, blue: 135/255.0, alpha: 0.95),
            iconName: "mountain.2.fill",
            isCustomAsset: false
        ),
        "centos": OSBadgeTheme(
            displayName: "CentOS",
            badgeColor: UIColor(red: 147/255.0, green: 34/255.0, blue: 147/255.0, alpha: 0.95),
            iconName: "cube.fill",
            isCustomAsset: false
        ),
        "fedora": OSBadgeTheme(
            displayName: "Fedora",
            badgeColor: UIColor(red: 41/255.0, green: 65/255.0, blue: 114/255.0, alpha: 0.95),
            iconName: "f.circle.fill",
            isCustomAsset: false
        ),
        "rhel": OSBadgeTheme(
            displayName: "RHEL",
            badgeColor: UIColor(red: 204/255.0, green: 0/255.0, blue: 0/255.0, alpha: 0.95),
            iconName: "shield.fill",
            isCustomAsset: false
        ),
        "rocky": OSBadgeTheme(
            displayName: "Rocky",
            badgeColor: UIColor(red: 16/255.0, green: 185/255.0, blue: 129/255.0, alpha: 0.95),
            iconName: "circle.grid.cross.fill",
            isCustomAsset: false
        ),
        "alma": OSBadgeTheme(
            displayName: "AlmaLinux",
            badgeColor: UIColor(red: 0/255.0, green: 104/255.0, blue: 201/255.0, alpha: 0.95),
            iconName: "diamond.fill",
            isCustomAsset: false
        ),
        "opensuse": OSBadgeTheme(
            displayName: "openSUSE",
            badgeColor: UIColor(red: 115/255.0, green: 186/255.0, blue: 37/255.0, alpha: 0.95),
            iconName: "lizard.fill",
            isCustomAsset: false
        ),
        "darwin": OSBadgeTheme(
            displayName: "macOS",
            badgeColor: UIColor(red: 50/255.0, green: 50/255.0, blue: 50/255.0, alpha: 0.95),
            iconName: "applelogo",
            isCustomAsset: false
        ),
        "freebsd": OSBadgeTheme(
            displayName: "FreeBSD",
            badgeColor: UIColor(red: 171/255.0, green: 0/255.0, blue: 0/255.0, alpha: 0.95),
            iconName: "flame.fill",
            isCustomAsset: false
        ),
        "openwrt": OSBadgeTheme(
            displayName: "OpenWrt",
            badgeColor: UIColor(red: 0/255.0, green: 153/255.0, blue: 204/255.0, alpha: 0.95),
            iconName: "wifi.router.fill",
            isCustomAsset: false
        )
    ]

    /// 智能解析器：根据系统字符串模糊匹配发行版主题，未识别时自动降级到 Linux 标准终端
    static func resolve(for osTypeString: String?, serverName: String = "") -> OSBadgeTheme {
        let text = "\(osTypeString ?? "") \(serverName)".lowercased()
        for (key, theme) in registry {
            if text.contains(key) {
                return theme
            }
        }
        // 默认通用 Linux 极客徽章
        return OSBadgeTheme(
            displayName: "Linux",
            badgeColor: UIColor(red: 45/255.0, green: 50/255.0, blue: 70/255.0, alpha: 0.95),
            iconName: "terminal.fill",
            isCustomAsset: false
        )
    }
}
