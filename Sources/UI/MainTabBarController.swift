import UIKit

/// 应用全局主框架：底部 5 大原生 TabBar (状态 / 终端 / 文件 / 容器 / 更多)
final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupAppearance()
    }

    private func setupViewControllers() {
        // 1. 状态 (ServerListViewController 主控状态监控)
        let statusNav = UINavigationController(rootViewController: ServerListViewController())
        statusNav.tabBarItem = UITabBarItem(title: "状态", image: UIImage(systemName: "gauge.with.needle"), selectedImage: UIImage(systemName: "gauge.with.needle.fill"))

        // 2. 终端 (GlobalTerminalViewController)
        let terminalNav = UINavigationController(rootViewController: GlobalTerminalViewController())
        terminalNav.tabBarItem = UITabBarItem(title: "终端", image: UIImage(systemName: "terminal"), selectedImage: UIImage(systemName: "terminal.fill"))

        // 3. 文件 (GlobalFilesViewController)
        let filesNav = UINavigationController(rootViewController: GlobalFilesViewController())
        filesNav.tabBarItem = UITabBarItem(title: "文件", image: UIImage(systemName: "folder"), selectedImage: UIImage(systemName: "folder.fill"))

        // 4. 容器 (GlobalDockerViewController)
        let dockerNav = UINavigationController(rootViewController: GlobalDockerViewController())
        dockerNav.tabBarItem = UITabBarItem(title: "容器", image: UIImage(systemName: "shippingbox"), selectedImage: UIImage(systemName: "shippingbox.fill"))

        // 5. 更多 (GlobalOpsViewController)
        let opsNav = UINavigationController(rootViewController: GlobalOpsViewController())
        opsNav.tabBarItem = UITabBarItem(title: "更多", image: UIImage(systemName: "ellipsis.circle"), selectedImage: UIImage(systemName: "ellipsis.circle.fill"))

        viewControllers = [statusNav, terminalNav, filesNav, dockerNav, opsNav]
    }

    private func setupAppearance() {
        // 遵循 iOS 26+ 规范，构建在 iOS 26 SDK 下时，系统 TabBar 自动启用官方 Liquid Glass 材质
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        tabBar.tintColor = .systemBlue
    }
}
