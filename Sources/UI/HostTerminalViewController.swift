import UIKit

/// 某台主机的专属纯原生交互终端界面 (对标 Termius Terminal 纯净原生设计)
/// 零 HTML/JS 依赖，纯 Swift 打造，带有顶部 SSH 会话状态条、单宽等宽终端字体与实时指令交互
final class HostTerminalViewController: UIViewController {

    private let server: Server
    private let textView = UITextView()
    private let commandInputBar = UIView()
    private let commandField = UITextField()
    private let sendBtn = UIButton(type: .system)

    private var inputBottomConstraint: NSLayoutConstraint?

    init(server: Server) {
        self.server = server
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.title = "\(server.name) - 终端"
        self.navigationItem.largeTitleDisplayMode = .never
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 13/255.0, green: 17/255.0, blue: 23/255.0, alpha: 1.0)

        setupTerminalViews()
        setupKeyboardObservers()
        appendLog("Connecting to \(server.username)@\(server.host):\(server.port)...\n")
        appendLog("Welcome to \(server.name) (Linux Debian GNU/Linux 13)\n")
        appendLog("Type command below to execute remote Shell.\n\n")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupTerminalViews() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.textColor = UIColor(red: 201/255.0, green: 209/255.0, blue: 217/255.0, alpha: 1.0)
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.isEditable = false
        view.addSubview(textView)

        commandInputBar.translatesAutoresizingMaskIntoConstraints = false
        commandInputBar.backgroundColor = UIColor(red: 22/255.0, green: 27/255.0, blue: 34/255.0, alpha: 1.0)
        commandInputBar.layer.cornerRadius = 12
        commandInputBar.layer.borderWidth = 0.5
        commandInputBar.layer.borderColor = UIColor.darkGray.cgColor

        commandField.translatesAutoresizingMaskIntoConstraints = false
        commandField.placeholder = "输入 Shell 命令 (如 uname -a, htop, df -h)"
        commandField.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        commandField.textColor = .white
        commandField.autocapitalizationType = .none
        commandField.autocorrectionType = .no
        commandField.returnKeyType = .send
        commandField.delegate = self

        sendBtn.translatesAutoresizingMaskIntoConstraints = false
        sendBtn.setTitle("发送", for: .normal)
        sendBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        sendBtn.tintColor = .systemBlue
        sendBtn.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)

        commandInputBar.addSubview(commandField)
        commandInputBar.addSubview(sendBtn)
        view.addSubview(commandInputBar)

        let bottom = commandInputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        self.inputBottomConstraint = bottom

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            textView.bottomAnchor.constraint(equalTo: commandInputBar.topAnchor, constant: -8),

            commandInputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            commandInputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            bottom,
            commandInputBar.heightAnchor.constraint(equalToConstant: 44),

            commandField.leadingAnchor.constraint(equalTo: commandInputBar.leadingAnchor, constant: 12),
            commandField.centerYAnchor.constraint(equalTo: commandInputBar.centerYAnchor),
            commandField.trailingAnchor.constraint(equalTo: sendBtn.leadingAnchor, constant: -8),

            sendBtn.trailingAnchor.constraint(equalTo: commandInputBar.trailingAnchor, constant: -12),
            sendBtn.centerYAnchor.constraint(equalTo: commandInputBar.centerYAnchor),
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
        let targetOffset = keyboardHeight > 0 ? -(keyboardHeight - view.safeAreaInsets.bottom + 8) : -8

        inputBottomConstraint?.constant = targetOffset
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func didTapSend() {
        guard let text = commandField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        commandField.text = ""
        appendLog("$ \(text)\n")

        // 模拟执行或通过 SSH 执行
        Task { [weak self] in
            guard let self = self else { return }
            let session = SSHSession(server: self.server)
            do {
                let out = try await session.executeCustomCommand(text)
                await MainActor.run {
                    self.appendLog("\(out)\n")
                }
            } catch {
                await MainActor.run {
                    self.appendLog("Error: \(error.localizedDescription)\n")
                }
            }
        }
    }

    private func appendLog(_ msg: String) {
        textView.text = (textView.text ?? "") + msg
        let bottom = NSRange(location: (textView.text as NSString).length, length: 0)
        textView.scrollRangeToVisible(bottom)
    }
}

extension HostTerminalViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didTapSend()
        return true
    }
}
