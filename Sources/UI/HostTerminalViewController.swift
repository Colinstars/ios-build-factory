import UIKit
import SwiftTerm
import NIOCore

/// 工业级移动端全屏原生真 PTY 交互终端 (对齐 Termius 官方真机 inputAccessoryView 架构)
///
/// 核心修复根因：
/// 1. 【inputAccessoryView 官方标准实现】：彻底抛弃手写 AutoLayout 约束浮动！直接把双层控制条赋值给 `terminalView.inputAccessoryView`。这样当软键盘弹起时，控制条由 iOS 系统窗口层直接贴合在键盘顶部；当键盘收起时，终端 100% 独占整个屏幕直至屏幕最底部（Safe Area Bottom），绝不会悬空截断！
/// 2. 【tmux 状态栏贴底机制】：终端视口铺满全屏，tmux 的绿色状态栏自然位于视口最后一行（贴合最底部）；
/// 3. 【自动尺寸动态上报】：键盘弹起时系统挤压视口，SwiftTerm 会实时调用 `sizeChanged` 通知远端重绘；
final class HostTerminalViewController: UIViewController {

    private let server: Server
    private var terminalView: TerminalView!
    private var accessoryBar: TerminalAccessoryView!

    private var session: SSHSession?
    private var ptyRelay: SSHPtyStreamRelay?

    private var currentCols: Int = 80
    private var currentRows: Int = 24

    var onSessionDisconnected: ((Server, String?) -> Void)?

    init(server: Server, preconnectedSession: SSHSession? = nil) {
        self.server = server
        self.session = preconnectedSession
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

        // 等宽字体：Menlo 12pt
        terminalView.font = UIFont(name: "Menlo-Regular", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        terminalView.caretColor = UIColor(red: 122/255.0, green: 162/255.0, blue: 247/255.0, alpha: 1.0)

        // 核心：使用官方标准的 inputAccessoryView 挂载双层控制栏
        accessoryBar = TerminalAccessoryView(serverTitle: server.name)
        accessoryBar.delegate = self
        // 设置自定义高度为 82
        accessoryBar.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 82)
        terminalView.inputAccessoryView = accessoryBar

        view.addSubview(terminalView)

        // 终端铺满整个屏幕，从顶部 Safe Area 一直打到最底部屏幕边缘
        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            terminalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            terminalView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapTerminal))
        terminalView.addGestureRecognizer(tap)
    }

    @objc private func didTapTerminal() {
        terminalView.becomeFirstResponder()
    }

    /// 启动远程 Linux PTY 会话
    private func startInteractivePtySession() {
        let sess = self.session ?? SSHSession(server: server)
        self.session = sess

        let initialCols = max(20, currentCols)
        let initialRows = max(10, currentRows)

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let relay = try await sess.startInteractivePty(cols: initialCols, rows: initialRows, onOutput: { [weak self] buffer in
                    var buf = buffer
                    if let text = buf.readString(length: buf.readableBytes) {
                        DispatchQueue.main.async {
                            self?.terminalView.feed(text: text)
                        }
                    }
                }, onTerminate: { [weak self] errorDesc in
                    // 100% 对齐 Termius：一旦断连，立刻发出错误触感震动，退出终端回到列表，并弹出诊断抽屉！
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        self.navigationController?.popViewController(animated: true)
                        self.onSessionDisconnected?(self.server, errorDesc)
                    }
                })

                await MainActor.run {
                    self.ptyRelay = relay
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
        let sheet = TerminalActionSheetViewController()
        sheet.modalPresentationStyle = .overFullScreen
        sheet.modalTransitionStyle = .crossDissolve

        sheet.onClear = { [weak self] in
            self?.terminalView.feed(text: "\u{1b}[2J\u{1b}[H")
        }
        sheet.onRedraw = { [weak self] in
            guard let self = self else { return }
            self.ptyRelay?.writeString("\u{0c}")
            self.ptyRelay?.resize(cols: self.currentCols, rows: self.currentRows)
        }
        sheet.onReconnect = { [weak self] in
            self?.startInteractivePtySession()
        }
        sheet.onDisconnect = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        present(sheet, animated: true)
    }
}

// MARK: - TerminalViewDelegate (SwiftTerm 原生事件回调)

extension HostTerminalViewController: TerminalViewDelegate {

    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        ptyRelay?.writeBytes(Array(data))
    }

    func scrolled(source: TerminalView, position: Double) {}

    func setTerminalTitle(source: TerminalView, title: String) {
        DispatchQueue.main.async {
            self.accessoryBar.updateServerTitle(title.isEmpty ? self.server.name : title)
        }
    }

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
