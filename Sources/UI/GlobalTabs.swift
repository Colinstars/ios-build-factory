import UIKit

// MARK: - 1. 底部【终端】全局页面 (响应全局上下文)

final class GlobalTerminalViewController: UIViewController {

    private var currentServerId: UUID?
    private var terminalVC: TerminalViewController?
    private let tipLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "终端"
        self.navigationItem.title = "终端"
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
        tipLabel.text = "暂无连接目标\n请在【状态】列表点击任意服务器切换上下文"
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
            self.navigationItem.title = "终端"
            return
        }

        if currentServerId == server.id && terminalVC != nil {
            return // 已就绪，保持会话不重连
        }

        tipLabel.isHidden = true
        // 关键修复：绝不能设置 self.title，只能设置 self.navigationItem.title！
        // 否则底部 TabBar 的『终端』字样会被强行改写成『终端 (DMIT 示例)』！
        self.navigationItem.title = "终端 (\(server.name))"
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

// MARK: - 2. 底部【文件】全局页面

final class GlobalFilesViewController: UIViewController {

    private var currentServerId: UUID?
    private var filesVC: FilesViewController?
    private let tipLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "文件"
        view.backgroundColor = .systemBackground
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
        reloadActiveFiles()
    }

    @objc private func didChangeServer() {
        reloadActiveFiles()
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

    private func reloadActiveFiles() {
        ActiveServerContext.shared.refreshIfNeeded()
        guard let server = ActiveServerContext.shared.activeServer else {
            filesVC?.view.removeFromSuperview()
            filesVC?.removeFromParent()
            filesVC = nil
            currentServerId = nil
            tipLabel.isHidden = false
            self.navigationItem.title = "文件"
            return
        }

        if currentServerId == server.id && filesVC != nil {
            return
        }

        tipLabel.isHidden = true
        self.navigationItem.title = "文件 (\(server.name))"
        currentServerId = server.id

        filesVC?.view.removeFromSuperview()
        filesVC?.removeFromParent()

        let session = SSHSession(server: server)
        let f = FilesViewController(session: session, initialPath: "/")
        addChild(f)
        f.view.frame = view.bounds
        f.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(f.view)
        f.didMove(toParent: self)
        self.filesVC = f
    }
}

// MARK: - 3. 底部【容器】全局页面

final class GlobalDockerViewController: UIViewController {

    private var currentServerId: UUID?
    private var dockerVC: DockerViewController?
    private let tipLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "容器"
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
        reloadActiveDocker()
    }

    @objc private func didChangeServer() {
        reloadActiveDocker()
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

    private func reloadActiveDocker() {
        ActiveServerContext.shared.refreshIfNeeded()
        guard let server = ActiveServerContext.shared.activeServer else {
            dockerVC?.view.removeFromSuperview()
            dockerVC?.removeFromParent()
            dockerVC = nil
            currentServerId = nil
            tipLabel.isHidden = false
            self.navigationItem.title = "容器"
            return
        }

        if currentServerId == server.id && dockerVC != nil {
            return
        }

        tipLabel.isHidden = true
        self.navigationItem.title = "容器 (\(server.name))"
        currentServerId = server.id

        dockerVC?.view.removeFromSuperview()
        dockerVC?.removeFromParent()

        let session = SSHSession(server: server)
        let d = DockerViewController(session: session)
        addChild(d)
        d.view.frame = view.bounds
        d.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(d.view)
        d.didMove(toParent: self)
        self.dockerVC = d
    }
}

// MARK: - 4. 底部【更多】全局页面

final class GlobalOpsViewController: UIViewController {

    private var currentServerId: UUID?
    private var opsVC: ServerOpsViewController?
    private let tipLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "运维工具"
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
            self.navigationItem.title = "运维工具"
            return
        }

        if currentServerId == server.id && opsVC != nil {
            return
        }

        tipLabel.isHidden = true
        self.navigationItem.title = "运维 (\(server.name))"
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
