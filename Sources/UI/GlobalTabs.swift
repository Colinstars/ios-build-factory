import UIKit

// MARK: - 1. 底部【终端】全局页面

final class GlobalTerminalViewController: UIViewController {

    private var activeSession: SSHSession?
    private var terminalVC: TerminalViewController?
    private let tipLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "终端"
        view.backgroundColor = UIColor(red: 13/255.0, green: 17/255.0, blue: 23/255.0, alpha: 1.0)
        setupTipLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadActiveTerminal()
    }

    private func setupTipLabel() {
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        tipLabel.text = "请先在【状态】页面添加并选择一台服务器"
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
        guard let firstServer = ServerStore.shared.servers.first else {
            terminalVC?.view.removeFromSuperview()
            terminalVC?.removeFromParent()
            terminalVC = nil
            tipLabel.isHidden = false
            return
        }

        tipLabel.isHidden = true
        title = "终端 - \(firstServer.name)"

        if terminalVC == nil {
            let session = SSHSession(server: firstServer)
            self.activeSession = session
            let term = TerminalViewController(session: session)
            addChild(term)
            term.view.frame = view.bounds
            term.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(term.view)
            term.didMove(toParent: self)
            self.terminalVC = term
        }
    }
}

// MARK: - 2. 底部【文件】全局页面

final class GlobalFilesViewController: UIViewController {

    private var filesVC: FilesViewController?
    private let tipLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "文件"
        view.backgroundColor = .systemBackground
        setupTipLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadActiveFiles()
    }

    private func setupTipLabel() {
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        tipLabel.text = "请先在【状态】页面添加并配置服务器"
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
        guard let firstServer = ServerStore.shared.servers.first else {
            filesVC?.view.removeFromSuperview()
            filesVC?.removeFromParent()
            filesVC = nil
            tipLabel.isHidden = false
            return
        }

        tipLabel.isHidden = true
        title = "文件 - \(firstServer.name)"

        if filesVC == nil {
            let session = SSHSession(server: firstServer)
            let f = FilesViewController(session: session, initialPath: "/")
            addChild(f)
            f.view.frame = view.bounds
            f.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(f.view)
            f.didMove(toParent: self)
            self.filesVC = f
        }
    }
}

// MARK: - 3. 底部【容器】全局页面

final class GlobalDockerViewController: UIViewController {

    private var dockerVC: DockerViewController?
    private let tipLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "容器"
        view.backgroundColor = .systemGroupedBackground
        setupTipLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadActiveDocker()
    }

    private func setupTipLabel() {
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        tipLabel.text = "请先在【状态】页面添加并配置服务器"
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
        guard let firstServer = ServerStore.shared.servers.first else {
            dockerVC?.view.removeFromSuperview()
            dockerVC?.removeFromParent()
            dockerVC = nil
            tipLabel.isHidden = false
            return
        }

        tipLabel.isHidden = true
        title = "容器 - \(firstServer.name)"

        if dockerVC == nil {
            let session = SSHSession(server: firstServer)
            let d = DockerViewController(session: session)
            addChild(d)
            d.view.frame = view.bounds
            d.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(d.view)
            d.didMove(toParent: self)
            self.dockerVC = d
        }
    }
}

// MARK: - 4. 底部【更多】全局页面

final class GlobalOpsViewController: UIViewController {

    private var opsVC: ServerOpsViewController?
    private let tipLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "更多运维"
        view.backgroundColor = .systemGroupedBackground
        setupTipLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadActiveOps()
    }

    private func setupTipLabel() {
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        tipLabel.text = "请先在【状态】页面添加并配置服务器"
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
        guard let firstServer = ServerStore.shared.servers.first else {
            opsVC?.view.removeFromSuperview()
            opsVC?.removeFromParent()
            opsVC = nil
            tipLabel.isHidden = false
            return
        }

        tipLabel.isHidden = true
        title = "运维 - \(firstServer.name)"

        if opsVC == nil {
            let session = SSHSession(server: firstServer)
            let o = ServerOpsViewController(session: session)
            addChild(o)
            o.view.frame = view.bounds
            o.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(o.view)
            o.didMove(toParent: self)
            self.opsVC = o
        }
    }
}
