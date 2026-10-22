import UIKit
import SwiftTerm
import NIOCore

/// 移动端全屏真 PTY 交互终端
final class HostTerminalViewController: UIViewController {

    private let server: Server
    private var terminalView: TerminalView!
    private var accessoryBar: TerminalAccessoryView!
    private var customInputView: TerminalCustomInputView!

    private var session: SSHSession?
    private var ptyRelay: SSHPtyStreamRelay?

    private var currentCols: Int = 80
    private var currentRows: Int = 24
    private var isUsingCustomKeyboard: Bool = false

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
        view.backgroundColor = AppTheme.pageBackground

        setupTerminalView()
        setupCustomInputView()
        startInteractivePtySession()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func setupTerminalView() {
        terminalView = TerminalView(frame: .zero)
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        terminalView.terminalDelegate = self
        terminalView.backgroundColor = AppTheme.pageBackground

        // 等宽字体：Menlo 12pt
        terminalView.font = UIFont(name: "Menlo-Regular", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        terminalView.caretColor = AppTheme.accent

        accessoryBar = TerminalAccessoryView(serverTitle: server.name)
        accessoryBar.delegate = self
        accessoryBar.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 86)
        terminalView.inputAccessoryView = accessoryBar

        view.addSubview(terminalView)

        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            terminalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            terminalView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapTerminal))
        terminalView.addGestureRecognizer(tap)
    }

    private func setupCustomInputView() {
        customInputView = TerminalCustomInputView()
        customInputView.onSendKey = { [weak self] code in
            self?.ptyRelay?.writeString(code)
        }
        customInputView.onSwitchToSystemKeyboard = { [weak self] in
            self?.switchToSystemKeyboard()
        }
        customInputView.onSelectTheme = { [weak self] themeName in
            self?.applyTerminalTheme(themeName)
        }
    }

    @objc private func didTapTerminal() {
        terminalView.becomeFirstResponder()
    }

    private func switchToCustomKeyboard() {
        isUsingCustomKeyboard = true
        terminalView.inputView = customInputView
        terminalView.reloadInputViews()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func switchToSystemKeyboard() {
        isUsingCustomKeyboard = false
        terminalView.inputView = nil
        terminalView.reloadInputViews()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func applyTerminalTheme(_ name: String) {
        if name.contains("Tokyo") {
            terminalView.backgroundColor = UIColor(red: 26/255.0, green: 27/255.0, blue: 38/255.0, alpha: 1.0)
        } else if name.contains("Kanagawa") {
            terminalView.backgroundColor = UIColor(red: 31/255.0, green: 31/255.0, blue: 40/255.0, alpha: 1.0)
        } else if name.contains("Dracula") {
            terminalView.backgroundColor = UIColor(red: 40/255.0, green: 42/255.0, blue: 54/255.0, alpha: 1.0)
        } else {
            terminalView.backgroundColor = AppTheme.pageBackground
        }
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
}

// MARK: - TerminalViewDelegate

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

// MARK: - TerminalAccessoryViewDelegate

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

    /// 点击四宫格：直接无缝切换为原厂多 Tab 极客扩展键盘！
    func terminalAccessoryViewDidTapGridMenu(_ view: TerminalAccessoryView) {
        if isUsingCustomKeyboard {
            switchToSystemKeyboard()
        } else {
            switchToCustomKeyboard()
        }
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
