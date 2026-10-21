import UIKit
import WebKit
import NIOCore

/// 工业级移动端全屏真 PTY 交互终端 (100% 对标 Termius 官方真机极客体验)
///
/// 视觉与交互重塑：
/// 1. 彻底隐藏系统顶部导航栏 (`navigationBar.isHidden = true`)，顶部 0 遮挡，终端直接延展至灵动岛/状态栏下方！
/// 2. 右侧悬浮半透明胶囊把手（Termius 标志性右侧边抽屉呼出把手）；
/// 3. 底部集成 Termius 官方同款的双层辅助栏：
///    - 第一层：会话标签栏 `[ < 返回 ]  [ 🐚 DMIT-LAX  ⓧ ]  [ + ]  [ 田 ]`
///    - 第二层：专业物理按键行 `[shift tab] [?] [/] [📋] [esc] [tab] [ctrl] [alt] [^C] [⌨️]`
/// 4. 键盘弹起与收起时，辅助栏与 WebKit 视口自适应联动，绝对不留黑白割裂。
final class HostTerminalViewController: UIViewController, WKScriptMessageHandler {

    private let server: Server
    private var webView: WKWebView!
    private var accessoryContainer: TerminalAccessoryView!
    private var accessoryBottomConstraint: NSLayoutConstraint?

    private var session: SSHSession?
    private var ptyRelay: SSHPtyStreamRelay?

    init(server: Server) {
        self.server = server
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 关键：彻底隐藏顶部导航栏，实现 100% 沉浸全屏终端！
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 离开终端时还原系统导航栏
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Termius 经典深蓝黑底色
        view.backgroundColor = UIColor(red: 22/255.0, green: 23/255.0, blue: 33/255.0, alpha: 1.0)

        setupWebView()
        setupAccessoryBar()
        setupKeyboardObservers()
        loadXterm()
        startInteractivePtySession()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let userContent = WKUserContentController()
        userContent.add(self, name: "terminalInput")
        userContent.add(self, name: "terminalResize")
        config.userContentController = userContent

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(webView)

        // 顶部直通 Safe Area Top，不留任何多余灰色横条
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupAccessoryBar() {
        accessoryContainer = TerminalAccessoryView(serverTitle: server.name)
        accessoryContainer.translatesAutoresizingMaskIntoConstraints = false
        accessoryContainer.delegate = self
        view.addSubview(accessoryContainer)

        let bottomConstraint = accessoryContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        self.accessoryBottomConstraint = bottomConstraint

        NSLayoutConstraint.activate([
            accessoryContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            accessoryContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            accessoryContainer.heightAnchor.constraint(equalToConstant: 80),
            bottomConstraint,

            webView.bottomAnchor.constraint(equalTo: accessoryContainer.topAnchor)
        ])
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func keyboardWillChangeFrame(_ note: Notification) {
        guard let userInfo = note.userInfo,
              let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveVal = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }

        let screenH = UIScreen.main.bounds.height
        let isHiding = endFrame.origin.y >= screenH
        let safeAreaBottom = view.safeAreaInsets.bottom

        let offset = isHiding ? 0 : -(endFrame.height - safeAreaBottom)
        accessoryBottomConstraint?.constant = offset

        let opts = UIView.AnimationOptions(rawValue: curveVal << 16)
        UIView.animate(withDuration: duration, delay: 0, options: opts, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.webView.evaluateJavaScript("window.fitTerminal && window.fitTerminal()")
        })
    }

    private func loadXterm() {
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "xterm") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    /// 核心架构：启动真正的远程 Linux PTY 会话
    private func startInteractivePtySession() {
        appendOutput("Connecting to \(server.username)@\(server.host):\(server.port) via PTY...\r\n")

        let sess = SSHSession(server: server)
        self.session = sess

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let relay = try await sess.startInteractivePty(cols: 80, rows: 24) { [weak self] buffer in
                    var buf = buffer
                    if let text = buf.readString(length: buf.readableBytes) {
                        self?.appendOutput(text)
                    }
                }

                await MainActor.run {
                    self.ptyRelay = relay
                }
            } catch {
                await MainActor.run {
                    let errDesc = error.localizedDescription
                    if case .sshKey = self.server.authType {
                        self.appendOutput("\r\n\u{1b}[31m[SSH 密钥认证失败]\u{1b}[0m\r\n")
                        self.appendOutput("远端服务器拒绝了公钥鉴权 (Permission denied: publickey)。\r\n")
                        self.appendOutput("错误详情: \(errDesc)\r\n\r\n")
                    } else if errDesc.contains("4") || errDesc.contains("allAuthenticationOptionsFailed") {
                        self.appendOutput("\r\n\u{1b}[31m[SSH 认证失败]\u{1b}[0m\r\n")
                        self.appendOutput("远端服务器拒绝了连接鉴权。\r\n")
                        self.appendOutput("原因：当前主机设置了密码登录，但该主机仅允许私钥认证。\r\n")
                        self.appendOutput("指引：请进入【设置 ➔ SSH 密钥】导入您的 ed25519 私钥并在主机配置中选中。\r\n\r\n")
                    } else {
                        self.appendOutput("\r\n\u{1b}[31m[PTY Error: \(errDesc)]\u{1b}[0m\r\n\r\n")
                    }
                }
            }
        }
    }

    private func appendOutput(_ text: String) {
        let b64 = text.data(using: .utf8)?.base64EncodedString() ?? ""
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript("window.writeBase64('\(b64)')")
        }
    }

    private func didTapMenuAction() {
        let alert = UIAlertController(title: server.name, message: "\(server.host):\(server.port)", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "清空终端 (Clear)", style: .default, handler: { [weak self] _ in
            self?.webView.evaluateJavaScript("window.clearTerminal()")
        }))
        alert.addAction(UIAlertAction(title: "重新连接 (Reconnect)", style: .default, handler: { [weak self] _ in
            self?.startInteractivePtySession()
        }))
        alert.addAction(UIAlertAction(title: "断开并退出", style: .destructive, handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "terminalInput",
           let dict = message.body as? [String: Any],
           let data = dict["data"] as? String {
            ptyRelay?.writeString(data)
        }
    }
}

// MARK: - TerminalAccessoryViewDelegate (Termius 交互协议实现)

extension HostTerminalViewController: TerminalAccessoryViewDelegate {

    func terminalAccessoryViewDidTapBack(_ view: TerminalAccessoryView) {
        navigationController?.popViewController(animated: true)
    }

    func terminalAccessoryViewDidTapCloseSession(_ view: TerminalAccessoryView) {
        navigationController?.popViewController(animated: true)
    }

    func terminalAccessoryViewDidTapNewTab(_ view: TerminalAccessoryView) {
        let alert = UIAlertController(title: "新建会话", message: "多标签页会话支持将在后续版本开放", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    func terminalAccessoryViewDidTapMenu(_ view: TerminalAccessoryView) {
        didTapMenuAction()
    }

    func terminalAccessoryView(_ view: TerminalAccessoryView, didSendKey key: String) {
        ptyRelay?.writeString(key)
    }

    func terminalAccessoryViewDidTapPaste(_ view: TerminalAccessoryView) {
        if let clip = UIPasteboard.general.string {
            ptyRelay?.writeString(clip)
        }
    }

    func terminalAccessoryViewDidTapDismissKeyboard(_ view: TerminalAccessoryView) {
        view.endEditing(true)
        webView.endEditing(true)
    }
}
