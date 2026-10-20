import UIKit
import WebKit
import NIOCore

/// 原生级终端控制器：内嵌 xterm 引擎 + 顶部浮动液态玻璃辅助按键栏
///
/// 遵循 Apple HIG Keyboards 规范：
/// 监听键盘尺寸事件，动态收缩终端视口与上抬悬浮液态玻璃操作栏，杜绝输入被遮挡！
final class TerminalViewController: UIViewController, WKScriptMessageHandler {

    private let session: SSHSession
    private var webView: WKWebView!
    private var writeInput: (@Sendable (String) async throws -> Void)?

    // 功能层：浮动液态玻璃辅助按键栏 (Ctrl, Esc, Tab, 方向键)
    private let accessoryGlassBar = GlassSurface(variant: .regular, cornerRadius: 20)
    private let statusIndicator = UIActivityIndicatorView(style: .medium)

    private var accessoryBottomConstraint: NSLayoutConstraint?

    init(session: SSHSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 13/255.0, green: 17/255.0, blue: 23/255.0, alpha: 1.0)
        setupWebView()
        setupAccessoryBar()
        setupKeyboardObservers()
        loadTerminalHTML()
        startShellSession()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: "terminalInput")
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.bounces = false
        view.addSubview(webView)

        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        statusIndicator.hidesWhenStopped = true
        view.addSubview(statusIndicator)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            statusIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    /// 符合 HIG 规范的功能层玻璃组件：浮动在终端黑色背景之上的辅助工具条
    private func setupAccessoryBar() {
        accessoryGlassBar.translatesAutoresizingMaskIntoConstraints = false
        accessoryGlassBar.setInteractive(true)
        view.addSubview(accessoryGlassBar)

        let keys = ["ESC", "TAB", "CTRL-C", "CLEAR", "LS"]
        var buttons: [UIButton] = []

        for key in keys {
            let btn = UIButton(type: .system)
            btn.setTitle(key, for: .normal)
            btn.titleLabel?.font = .monospacedSystemFont(ofSize: 11, weight: .bold)
            btn.setTitleColor(.label, for: .normal)
            btn.tag = keys.firstIndex(of: key) ?? 0
            btn.addTarget(self, action: #selector(didTapAccessoryKey(_:)), for: .touchUpInside)
            buttons.append(btn)
        }

        let stack = UIStackView(arrangedSubviews: buttons)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        accessoryGlassBar.addSubview(stack)

        let bottom = accessoryGlassBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        self.accessoryBottomConstraint = bottom

        NSLayoutConstraint.activate([
            accessoryGlassBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottom,
            accessoryGlassBar.widthAnchor.constraint(equalToConstant: 320),
            accessoryGlassBar.heightAnchor.constraint(equalToConstant: 40),

            stack.topAnchor.constraint(equalTo: accessoryGlassBar.topAnchor),
            stack.leadingAnchor.constraint(equalTo: accessoryGlassBar.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: accessoryGlassBar.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: accessoryGlassBar.bottomAnchor),
        ])
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
            return
        }

        let viewFrame = view.convert(view.bounds, to: nil)
        let intersection = viewFrame.intersection(endFrame)
        let keyboardHeight = intersection.height

        let targetOffset = keyboardHeight > 0 ? -(keyboardHeight - view.safeAreaInsets.bottom + 8) : -12

        accessoryBottomConstraint?.constant = targetOffset
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func didTapAccessoryKey(_ sender: UIButton) {
        let mapping = [
            0: "\u{1b}",         // ESC
            1: "\t",             // TAB
            2: "\u{03}",         // CTRL-C
            3: "clear\r",        // CLEAR
            4: "ls -la\r"        // LS
        ]
        if let cmd = mapping[sender.tag] {
            sendInput(cmd)
        }
    }

    private func loadTerminalHTML() {
        if let url = Bundle.main.url(forResource: "terminal", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    private func startShellSession() {
        statusIndicator.startAnimating()

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let sender = try await self.session.startInteractiveShell { [weak self] byteBuffer in
                    var buf = byteBuffer
                    if let str = buf.readString(length: buf.readableBytes) {
                        let base64 = str.data(using: .utf8)?.base64EncodedString() ?? ""
                        DispatchQueue.main.async {
                            self?.webView.evaluateJavaScript("window.writeToTerminal('\(base64)')")
                        }
                    }
                }

                await MainActor.run {
                    self.writeInput = sender
                    self.statusIndicator.stopAnimating()
                }
            } catch {
                await MainActor.run {
                    self.statusIndicator.stopAnimating()
                    let b64 = "连接 SSH PTY 失败: \(error.localizedDescription)\r\n".data(using: .utf8)?.base64EncodedString() ?? ""
                    self.webView.evaluateJavaScript("window.writeToTerminal('\(b64)')")
                }
            }
        }
    }

    private func sendInput(_ text: String) {
        Task { [weak self] in
            try? await self?.writeInput?(text)
        }
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "terminalInput",
           let dict = message.body as? [String: Any],
           let key = dict["key"] as? String {
            sendInput(key)
        }
    }
}
