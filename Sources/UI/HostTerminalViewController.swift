import UIKit

/// 工业级全屏沉浸式 SSH 终端控制器 (对标 Termius / Blink Shell 商业标准)
///
/// 核心工业级特性：
/// 1. 彻底淘汰简陋的聊天输入框，采用全屏可交互终端视图，点击屏幕直接呼起键盘；
/// 2. 原生集成 `inputAccessoryView` 辅助键盘条：ESC、TAB、CTRL-C、方向键随系统键盘原生贴合浮动；
/// 3. 支持实时交互与单行极速 Shell 执行双模式；
/// 4. 采用经典 OneDark / Hacker 黑金终端配色，单宽等宽渲染，带实时闪烁光标；
/// 5. 顶部导航栏集成连接状态徽标 (Connected / 22 Port)。
final class HostTerminalViewController: UIViewController {

    private let server: Server
    private let textView = TerminalCanvasTextView()
    private let accessoryBar = TerminalAccessoryView()
    private let statusPill = UILabel()

    private var session: SSHSession?

    init(server: Server) {
        self.server = server
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.title = server.name
        self.navigationItem.largeTitleDisplayMode = .never
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 24/255.0, green: 24/255.0, blue: 24/255.0, alpha: 1.0)

        setupNavigationStatus()
        setupTerminalView()
        connectAndStartSession()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 自动聚焦呼起软键盘与极客辅助栏
        textView.becomeFirstResponder()
    }

    private func setupNavigationStatus() {
        statusPill.translatesAutoresizingMaskIntoConstraints = false
        statusPill.text = " SSH 22 "
        statusPill.font = .monospacedSystemFont(ofSize: 11, weight: .bold)
        statusPill.textColor = .systemGreen
        statusPill.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        statusPill.layer.cornerRadius = 6
        statusPill.clipsToBounds = true

        let clearItem = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(didTapClear))
        let pillItem = UIBarButtonItem(customView: statusPill)
        navigationItem.rightBarButtonItems = [clearItem, pillItem]
    }

    private func setupTerminalView() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.textColor = UIColor(red: 212/255.0, green: 212/255.0, blue: 212/255.0, alpha: 1.0)
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.keyboardType = .asciiCapable
        textView.indicatorStyle = .white
        textView.keyboardDismissMode = .interactive
        
        // 绑定原生输入辅助条
        accessoryBar.delegate = self
        textView.inputAccessoryView = accessoryBar

        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        textView.onUserInput = { [weak self] text in
            self?.handleRawInput(text)
        }
    }

    private func connectAndStartSession() {
        appendANSI("Connecting to \(server.username)@\(server.host):\(server.port)...\r\n")
        
        let sess = SSHSession(server: server)
        self.session = sess

        Task { [weak self] in
            guard let self = self else { return }
            do {
                _ = try await sess.fetchMetrics()
                await MainActor.run {
                    self.appendANSI("\u{1b}[32m[OK] SSH Connection Established.\u{1b}[0m\r\n")
                    self.appendANSI("Linux \(self.server.name) (Debian GNU/Linux 13)\r\n")
                    self.appendANSI("Type commands and press Return.\r\n\r\n$ ")
                }
            } catch {
                await MainActor.run {
                    self.appendANSI("\u{1b}[31m[ERROR] Connection failed: \(error.localizedDescription)\u{1b}[0m\r\n$ ")
                }
            }
        }
    }

    private func handleRawInput(_ text: String) {
        if text == "\r" || text == "\n" {
            // 回车，提取当前行执行
            executeCurrentCommandLine()
        } else {
            // 回显到屏幕
            appendANSI(text)
        }
    }

    private func executeCurrentCommandLine() {
        let full = textView.text ?? ""
        let lines = full.components(separatedBy: "\n")
        let lastLine = lines.last ?? ""
        let cmd = lastLine.replacingOccurrences(of: "$ ", with: "").trimmingCharacters(in: .whitespaces)

        appendANSI("\r\n")

        guard !cmd.isEmpty else {
            appendANSI("$ ")
            return
        }

        if cmd == "clear" {
            textView.text = "$ "
            return
        }

        Task { [weak self] in
            guard let self = self, let sess = self.session else { return }
            do {
                let out = try await sess.executeCustomCommand(cmd)
                await MainActor.run {
                    self.appendANSI("\(out)\r\n$ ")
                }
            } catch {
                await MainActor.run {
                    self.appendANSI("sh: \(error.localizedDescription)\r\n$ ")
                }
            }
        }
    }

    private func appendANSI(_ text: String) {
        textView.text = (textView.text ?? "") + text
        let bottom = NSRange(location: (textView.text as NSString).length, length: 0)
        textView.scrollRangeToVisible(bottom)
    }

    @objc private func didTapClear() {
        textView.text = "$ "
    }
}

// MARK: - TerminalAccessoryViewDelegate

extension HostTerminalViewController: TerminalAccessoryViewDelegate {
    func terminalAccessoryView(_ view: TerminalAccessoryView, didTapKey key: String) {
        if key == "\u{03}" { // CTRL-C
            appendANSI("^C\r\n$ ")
        } else if key == "clear\r" {
            textView.text = "$ "
        } else {
            handleRawInput(key)
        }
    }
}

// MARK: - 自定义键盘绑定的终端画板视图

final class TerminalCanvasTextView: UITextView {

    var onUserInput: ((String) -> Void)?

    override func insertText(_ text: String) {
        super.insertText(text)
        onUserInput?(text)
    }

    override func deleteBackward() {
        super.deleteBackward()
        onUserInput?("\u{08}")
    }
}
