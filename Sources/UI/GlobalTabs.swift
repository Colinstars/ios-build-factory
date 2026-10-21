import UIKit

// MARK: - 1. 底部【文件】全局模块

final class GlobalFilesViewController: UIViewController {

    private let filesVC = FilesViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Files"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = AppTheme.pageBackground

        addChild(filesVC)
        filesVC.view.frame = view.bounds
        filesVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(filesVC.view)
        filesVC.didMove(toParent: self)
    }
}

// MARK: - 2. 底部【容器】全局模块

final class GlobalDockerViewController: UIViewController {

    private let dockerVC = DockerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Containers"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = AppTheme.pageBackground

        addChild(dockerVC)
        dockerVC.view.frame = view.bounds
        dockerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(dockerVC.view)
        dockerVC.didMove(toParent: self)
    }
}
