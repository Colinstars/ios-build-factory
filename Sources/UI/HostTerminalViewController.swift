import UIKit
import SwiftTerm
import NIOCore

/// 工业级移动端全屏原生真 PTY 交互终端 (基于 migueldeicaza/SwiftTerm 官方原生 UIKit 引擎)
///
/// 针对 tmux / curses 全屏交互软件的物理级深度优化：
/// 1. 【动态 SIGWINCH 联动】：在 `sizeChanged` 回调中将实际终端行列数 (cols/rows) 瞬时同步给远端 Linux 内核，让 tmux 准确得知手机屏幕尺寸，彻底杜绝换行错乱与重影！
/// 2. 【高阶按键完备映射】：为 accessoryBar 扩展 F1~F12、Home、End、PageUp、PageDown、Insert 及方向键的完整 ANSI Escape 序列；
/// 3. 【原生等宽字体与自适应网格】：使用 Menlo / SF Mono 等宽核心字体，确保制表符、方框边框（UTF-8 Box Drawing）像素级严丝合缝！
final class HostTerminalViewController: UIViewController {

    private let server: Server
    private var terminalView: TerminalView!
    private var accessoryContainer: TerminalAccessoryView!
    private var accessoryBottomConstraint: NSLayoutConstraint?

    private var session: SSHSession?
    private var ptyRelay: SSHPtyStreamRelay?

    // 记录最新终端字符网格尺寸
    private var currentCols: Int = 80
    private var currentRows: Int = 24

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
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 22/255.0, green: 23/255.0, blue: 33/255.0, alpha: 1.0)

        setupTerminalView()
        setupAccessoryBar()
        setupKeyboardObservers()
        startInteractivePtySession()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func setupTerminalView() {
        terminalView = TerminalView(frame: .zero)
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        terminalView.terminalDelegate = self
        terminalView.backgroundColor = UIColor(red: 22/255.0, green: 23/255.0, blue: 33/255.0, alpha: 1.0)

        // 核心等宽字体配置：12pt Menlo，为 ASCII / Unicode 框线提供严苛的 1:2 几何对齐
        terminalView.font = UIFont(name: "Menlo-Regular", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        terminalView.caretColor = UIColor(red: 122/255.0, green: 162/255.0, blue: 247/255.0, alpha: 1.0)

        view.addSubview(terminalView)

        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            terminalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapTerminal))
        terminalView.addGestureRecognizer(tap)
    }

    @objc private func didTapTerminal() {
        terminalView.becomeFirstResponder()
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

            terminalView.bottomAnchor.constraint(equalTo: accessoryContainer.topAnchor)
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
        })
    }

    /// 核心架构：启动真正的远程 Linux PTY 会话并与 SwiftTerm 直连
    private func startInteractivePtySession() {
        terminalView.feed(text: "Connecting to \(server.username)@\(server.host):\(server.port) via native PTY...\r\n")

        let sess = SSHSession(server: server)
        self.session = sess

        // 获取终端初始行列，默认 80x24
        let initialCols = max(20, currentCols)
        let initialRows = max(10, currentRows)

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let relay = try await sess.startInteractivePty(cols: initialCols, rows: initialRows) { [weak self] buffer in
                    var buf = buffer
                    if let text = buf.readString(length: buf.readableBytes) {
                        DispatchQueue.main.async {
                            self?.terminalView.feed(text: text)
                        }
                    }
                }

                await MainActor.run {
                    self.ptyRelay = relay
                    // 连通后立即触发一次当前真实尺寸的同步广播，确保远端 tmux 立刻自适应
                    relay.resize(cols: self.currentCols, rows: self.currentRows)
                    self.terminalView.becomeFirstResponder()
                }
            } catch {
                await MainActor.run {
                    let errDesc = error.localizedDescription
                    if case .sshKey = self.server.authType {
                        self.terminalView.feed(text: "\r\n\u{1b}[31m[SSH 密钥认证失败]\u{1b}[0m\r\n远端拒绝公钥鉴权。\r\n\(errDesc)\r\n\r\n")
                    } else if errDesc.contains("4") || errDesc.contains("allAuthenticationOptionsFailed") {
                        self.terminalView.feed(text: "\r\n\u{1b}[31m[SSH 认证失败: 服务器仅允许私钥登录]\u{1b}[0m\r\n\r\n")
                    } else {
                        self.terminalView.feed(text: "\r\n\u{1b}[31m[PTY Error: \(errDesc)]\u{1b}[0m\r\n\r\n")
                    }
                }
            }
        }
    }

    private func didTapMenuAction() {
        let alert = UIAlertController(title: server.name, message: "\(server.host):\(server.port)", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "清空终端 (Clear)", style: .default, handler: { [weak self] _ in
            self?.terminalView.feed(text: "\u{1b}[2J\u{1b}[H")
        }))
        alert.addAction(UIAlertAction(title: "强制刷新屏幕 (Redraw)", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            // 发送 tmux 强制重绘快捷键 (Ctrl+L) 并重发窗口尺寸
            self.ptyRelay?.writeString("\u{0c}")
            self.ptyRelay?.resize(cols: self.currentCols, rows: self.currentRows)
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
}

// MARK: - TerminalViewDelegate (SwiftTerm 原生事件回调)

extension HostTerminalViewController: TerminalViewDelegate {

    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        if let str = String(bytes: data, encoding: .utf8) {
            ptyRelay?.writeString(str)
        } else {
            let str = String(decoding: data, as: UTF8.self)
            ptyRelay?.writeString(str)
        }
    }

    func scrolled(source: TerminalView, position: Double) {}

    func setTerminalTitle(source: TerminalView, title: String) {
        DispatchQueue.main.async {
            self.accessoryContainer.updateServerTitle(title.isEmpty ? self.server.name : title)
        }
    }

    /// 核心生命周期修复：当屏幕旋转、软键盘高度变化导致终端字符网格尺寸改变时，向远端 Linux / tmux 发送动态 SIGWINCH！
    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        guard newCols > 0, newRows > 0 else { return }
        self.currentCols = newCols
        self.currentRows = newRows
        self.ptyRelay?.resize(cols: newCols, rows: newRows)
    }

    func clipboardCopy(source: TerminalView, content: Data) {
        if let str = String(data: content, encoding: .utf8) {
            UIPasteboard.general.string = str
        }
    }

    func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    func requestOpenLink(source: TerminalView, link: String, params: [String : String]) {
        if let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }

    func bell(source: TerminalView) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
        terminalView.resignFirstResponder()
    }
}
