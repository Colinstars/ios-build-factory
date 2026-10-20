import UIKit

// MARK: - 1. 底部【终端】全局页面

final class GlobalTerminalViewController: UIViewController {

    private var currentServerId: UUID?
    private var terminalVC: TerminalViewController?
    private let tipLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "终端"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = UIColor(red: 13/255.0, green: 17/255.0, blue: 23/255.0, alpha: 1.0)
        setupTipLabel()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didChangeServer),
            name: ActiveServerContext.didChangeActiveServerNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadActiveTerminal()
    }

    @objc private func didChangeServer() {
        reloadActiveTerminal()
    }

    private func setupTipLabel() {
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        tipLabel.text = "暂无连接目标\n请在【状态】列表添加或选择一台服务器"
        tipLabel.font = .systemFont(ofSize: 15, weight: .regular)
        tipLabel.textColor = .secondaryLabel
        tipLabel.textAlignment = .center
        tipLabel.numberOfLines = 0
        view.addSubview(tipLabel)

        NSLayoutConstraint.activate([
            tipLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tipLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            tipLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            tipLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func reloadActiveTerminal() {
        ActiveServerContext.shared.refreshIfNeeded()
        guard let server = ActiveServerContext.shared.activeServer else {
            terminalVC?.view.removeFromSuperview()
            terminalVC?.removeFromParent()
            terminalVC = nil
            currentServerId = nil
            tipLabel.isHidden = false
            return
        }

        if currentServerId == server.id && terminalVC != nil {
            return
        }

        tipLabel.isHidden = true
        currentServerId = server.id

        terminalVC?.view.removeFromSuperview()
        terminalVC?.removeFromParent()

        let session = SSHSession(server: server)
        let term = TerminalViewController(session: session)
        addChild(term)
        term.view.frame = view.bounds
        term.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(term.view)
        term.didMove(toParent: self)
        self.terminalVC = term
    }
}

// MARK: - 2. 底部【文件】全局页面 (纯 UI 稳定呈现，零网络崩溃)

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

// MARK: - 3. 底部【容器】全局页面 (纯 UI 稳定呈现，支持启停交互)

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

// MARK: - 4. 底部【更多】全局页面

final class GlobalOpsViewController: UIViewController {

    private var currentServerId: UUID?
    private var opsVC: ServerOpsViewController?
    private let tipLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "更多"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground
        setupTipLabel()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didChangeServer),
            name: ActiveServerContext.didChangeActiveServerNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadActiveOps()
    }

    @objc private func didChangeServer() {
        reloadActiveOps()
    }

    private func setupTipLabel() {
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        tipLabel.text = "暂无活跃服务器\n请在【状态】列表选择目标机器"
        tipLabel.font = .systemFont(ofSize: 15, weight: .regular)
        tipLabel.textColor = .secondaryLabel
        tipLabel.textAlignment = .center
        view.addSubview(tipLabel)

        NSLayoutConstraint.activate([
            tipLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tipLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func reloadActiveOps() {
        ActiveServerContext.shared.refreshIfNeeded()
        guard let server = ActiveServerContext.shared.activeServer else {
            opsVC?.view.removeFromSuperview()
            opsVC?.removeFromParent()
            opsVC = nil
            currentServerId = nil
            tipLabel.isHidden = false
            return
        }

        if currentServerId == server.id && opsVC != nil {
            return
        }

        tipLabel.isHidden = true
        currentServerId = server.id

        opsVC?.view.removeFromSuperview()
        opsVC?.removeFromParent()

        let session = SSHSession(server: server)
        let o = ServerOpsViewController(session: session)
        addChild(o)
        o.view.frame = view.bounds
        o.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(o.view)
        o.didMove(toParent: self)
        self.opsVC = o
    }
}
