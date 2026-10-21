import UIKit

// MARK: - 1. 底部【文件】全局页面 (纯 UI 稳定呈现，零网络崩溃)

final class GlobalFilesViewController: UIViewController {

    private let filesVC = FilesViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "文件"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground

        addChild(filesVC)
        filesVC.view.frame = view.bounds
        filesVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(filesVC.view)
        filesVC.didMove(toParent: self)
    }
}

// MARK: - 2. 底部【容器】全局页面 (纯 UI 稳定呈现，支持启停交互)

final class GlobalDockerViewController: UIViewController {

    private let dockerVC = DockerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "容器"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground

        addChild(dockerVC)
        dockerVC.view.frame = view.bounds
        dockerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(dockerVC.view)
        dockerVC.didMove(toParent: self)
    }
}

// MARK: - 3. 底部【设置】全局页面 (纯 UI 稳定呈现，导航栏上滑遮罩完美贴合)

final class GlobalOpsViewController: UIViewController {

    private let opsVC = ServerOpsViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "设置"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground

        addChild(opsVC)
        opsVC.view.frame = view.bounds
        opsVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(opsVC.view)
        opsVC.didMove(toParent: self)
    }
}
