import UIKit

/// 应用全局主框架：底部 5 大原生 TabBar (状态 / 终端 / 文件 / 容器 / 更多)
final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupAppearance()
    }

    private func setupViewControllers() {
        // 1. 主机 (ServerListViewController，原状态已重塑为【主机】)
        let hostsNav = UINavigationController(rootViewController: ServerListViewController())
        hostsNav.tabBarItem = UITabBarItem(title: "主机", image: UIImage(systemName: "server.rack"), selectedImage: UIImage(systemName: "server.rack"))

        // 2. 智能体 (AgentViewController，全面淘汰终端，换用全新 AI 运维智能体)
        let agentNav = UINavigationController(rootViewController: AgentViewController())
        agentNav.tabBarItem = UITabBarItem(title: "智能体", image: UIImage(systemName: "sparkles"), selectedImage: UIImage(systemName: "sparkles"))

        // 3. 文件 (GlobalFilesViewController)
        let filesNav = UINavigationController(rootViewController: GlobalFilesViewController())
        filesNav.tabBarItem = UITabBarItem(title: "文件", image: UIImage(systemName: "folder"), selectedImage: UIImage(systemName: "folder.fill"))

        // 4. 容器 (GlobalDockerViewController)
        let dockerNav = UINavigationController(rootViewController: GlobalDockerViewController())
        dockerNav.tabBarItem = UITabBarItem(title: "容器", image: UIImage(systemName: "shippingbox"), selectedImage: UIImage(systemName: "shippingbox.fill"))

        // 5. 更多 (GlobalOpsViewController)
        let opsNav = UINavigationController(rootViewController: GlobalOpsViewController())
        opsNav.tabBarItem = UITabBarItem(title: "更多", image: UIImage(systemName: "ellipsis.circle"), selectedImage: UIImage(systemName: "ellipsis.circle.fill"))

        viewControllers = [hostsNav, agentNav, filesNav, dockerNav, opsNav]
    }

    private func setupAppearance() {
        tabBar.tintColor = .systemBlue
    }
}
