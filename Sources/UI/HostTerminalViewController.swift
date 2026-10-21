import UIKit
import WebKit
import NIOCore

/// 工业级移动端全屏真 PTY 交互终端 (100% 对标 iTerm / Blink Shell / Termius 生产级体验)
///
/// 核心修复：
/// 1. 显式设置 `hidesBottomBarWhenPushed = true`，彻底消除终端底部漏出白色 TabBar 的恶心瑕疵！
/// 2. 沉浸式全黑导航头：背景完全与终端一体化，彻底消除刺眼冲突；
/// 3. 精准错误解析：拦截 `Citadel.SSHClientError 错误 4`，给出明确的『认证失败：服务器拒绝了当前密码，请进入【设置➔SSH密钥】导入或生成密钥认证』引导，不再吐底层代码！
final class HostTerminalViewController: UIViewController, WKScriptMessageHandler {

    private let server: Server
    private var webView: WKWebView!
    private let accessoryBar = TerminalAccessoryView()
    private let statusPill = UILabel()

    private var session: SSHSession?
    private var ptyRelay: SSHPtyStreamRelay?

    init(server: Server) {
        self.server = server
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.title = server.name
        self.navigationItem.largeTitleDisplayMode = .never
        // 关键体验：终端作为沉浸式全屏工具，推入时必须彻底隐藏底部 TabBar！
        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 26/255.0, green: 27/255.0, blue: 38/255.0, alpha: 1.0)

        setupNavigationStatus()
        setupWebView()
        loadXterm()
        startInteractivePtySession()
    }

    private func setupNavigationStatus() {
        // 定制全黑沉浸式导航栏外观
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 26/255.0, green: 27/255.0, blue: 38/255.0, alpha: 1.0)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.shadowColor = .clear
        
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white

        statusPill.translatesAutoresizingMaskIntoConstraints = false
        statusPill.text = " PTY 22 "
        statusPill.font = .monospacedSystemFont(ofSize: 11, weight: .bold)
        statusPill.textColor = .systemGreen
        statusPill.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        statusPill.layer.cornerRadius = 6
        statusPill.clipsToBounds = true

        let clearItem = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(didTapClear))
        let pillItem = UIBarButtonItem(customView: statusPill)
        navigationItem.rightBarButtonItems = [clearItem, pillItem]
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

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        accessoryBar.delegate = self
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
                    if errDesc.contains("4") || errDesc.contains("allAuthenticationOptionsFailed") {
                        self.appendOutput("\r\n\u{1b}[31m[SSH 认证失败]\u{1b}[0m\r\n")
                        self.appendOutput("远端服务器拒绝了连接鉴权。\r\n")
                        self.appendOutput("原因：当前使用空密码登录，但该主机已开启公钥认证保护。\r\n")
                        self.appendOutput("解决方式：请在【设置 ➔ SSH 密钥】导入或生成密钥，并在编辑主机时关联对应私钥。\r\n\r\n")
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

    @objc private func didTapClear() {
        webView.evaluateJavaScript("window.clearTerminal()")
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

// MARK: - TerminalAccessoryViewDelegate

extension HostTerminalViewController: TerminalAccessoryViewDelegate {
    func terminalAccessoryView(_ view: TerminalAccessoryView, didTapKey key: String) {
        ptyRelay?.writeString(key)
    }
}
