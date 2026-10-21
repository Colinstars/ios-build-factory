import UIKit

/// 底部五大功能分区的主导航控制器 (Hosts / Agent / Files / Containers / Settings)
final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
    }

    private func setupViewControllers() {
        // 1. Hosts
        let hostsNav = UINavigationController(rootViewController: ServerListViewController())
        hostsNav.tabBarItem = UITabBarItem(title: "Hosts", image: UIImage(systemName: "server.rack"), selectedImage: UIImage(systemName: "server.rack"))

        // 2. Agent
        let agentNav = UINavigationController(rootViewController: AgentViewController())
        agentNav.tabBarItem = UITabBarItem(title: "Agent", image: UIImage(systemName: "sparkles"), selectedImage: UIImage(systemName: "sparkles"))

        // 3. Files
        let filesNav = UINavigationController(rootViewController: GlobalFilesViewController())
        filesNav.tabBarItem = UITabBarItem(title: "Files", image: UIImage(systemName: "folder"), selectedImage: UIImage(systemName: "folder.fill"))

        // 4. Containers
        let dockerNav = UINavigationController(rootViewController: GlobalDockerViewController())
        dockerNav.tabBarItem = UITabBarItem(title: "Containers", image: UIImage(systemName: "shippingbox"), selectedImage: UIImage(systemName: "shippingbox.fill"))

        // 5. Settings
        let opsNav = UINavigationController(rootViewController: ServerOpsViewController())
        opsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), selectedImage: UIImage(systemName: "gearshape.fill"))

        viewControllers = [hostsNav, agentNav, filesNav, dockerNav, opsNav]
    }
}
