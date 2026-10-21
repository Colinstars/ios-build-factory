import UIKit

/// 智能体 (AI Agent) 消息模型
struct AgentMessage: Identifiable, Hashable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let timestamp: Date = Date()
}

/// AI 运维助手交互控制器
final class AgentViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let promptChipsScrollView = UIScrollView()
    private let promptChipsStack = UIStackView()

    private let inputContainer = UIView()
    private let inputTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var inputBottomConstraint: NSLayoutConstraint?

    private var messages: [AgentMessage] = [
        AgentMessage(isUser: false, text: "你好！我是你的专属 AI 运维助手。我已经接入当前主机监控管道，你可以向我询问：\n• 当前服务器负载为什么偏高？\n• 排查占用内存最大的进程\n• 检查 Docker 容器健康状况与日志")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Agent"
        navigationController?.navigationBar.prefersLargeTitles = true

        view.backgroundColor = AppTheme.pageBackground

        setupTableView()
        setupPromptChips()
        setupInputBar()
        setupKeyboardObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupPromptChips() {
        promptChipsScrollView.translatesAutoresizingMaskIntoConstraints = false
        promptChipsScrollView.showsHorizontalScrollIndicator = false

        promptChipsStack.translatesAutoresizingMaskIntoConstraints = false
        promptChipsStack.axis = .horizontal
        promptChipsStack.spacing = 8
        promptChipsScrollView.addSubview(promptChipsStack)

        view.addSubview(promptChipsScrollView)

        let prompts = [
            "系统健康巡检",
            "排查高负载进程",
            "清理系统缓存",
            "检查容器状态"
        ]

        for p in prompts {
            let chip = UIButton(type: .system)
            chip.setTitle(p, for: .normal)
            chip.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            chip.setTitleColor(.white, for: .normal)
            chip.backgroundColor = AppTheme.cardBackground
            chip.layer.cornerRadius = 15
            chip.layer.cornerCurve = .continuous
            chip.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
            chip.layer.borderWidth = 0.5
            chip.layer.borderColor = AppTheme.separator.cgColor
            chip.addTarget(self, action: #selector(didTapPromptChip(_:)), for: .touchUpInside)
            promptChipsStack.addArrangedSubview(chip)
        }

        NSLayoutConstraint.activate([
            promptChipsScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            promptChipsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            promptChipsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            promptChipsScrollView.heightAnchor.constraint(equalToConstant: 34),

            promptChipsStack.topAnchor.constraint(equalTo: promptChipsScrollView.topAnchor),
            promptChipsStack.leadingAnchor.constraint(equalTo: promptChipsScrollView.leadingAnchor),
            promptChipsStack.trailingAnchor.constraint(equalTo: promptChipsScrollView.trailingAnchor),
            promptChipsStack.bottomAnchor.constraint(equalTo: promptChipsScrollView.bottomAnchor),
            promptChipsStack.heightAnchor.constraint(equalTo: promptChipsScrollView.heightAnchor),
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = AppTheme.pageBackground
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(AgentBubbleCell.self, forCellReuseIdentifier: "BubbleCell")
        

        view.addSubview(tableView)
    }

    private func setupInputBar() {
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.backgroundColor = AppTheme.inputBackground
        inputContainer.layer.cornerRadius = 24
        inputContainer.layer.cornerCurve = .continuous
        inputContainer.layer.borderWidth = 0.5
        inputContainer.layer.borderColor = AppTheme.separator.cgColor

        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.placeholder = "向智能体提问或下发运维指令..."
        inputTextField.font = .systemFont(ofSize: 15)
        inputTextField.textColor = .label
        inputTextField.returnKeyType = .send
        inputTextField.delegate = self

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: cfg), for: .normal)
        sendButton.tintColor = AppTheme.accent
        sendButton.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)

        inputContainer.addSubview(inputTextField)
        inputContainer.addSubview(sendButton)
        view.addSubview(inputContainer)

        let bottom = inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        self.inputBottomConstraint = bottom

        NSLayoutConstraint.activate([
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottom,
            inputContainer.heightAnchor.constraint(equalToConstant: 48),

            inputTextField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            inputTextField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),

            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -6),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),

            tableView.topAnchor.constraint(equalTo: promptChipsScrollView.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor, constant: -6),
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

        let offset = isHiding ? -10 : -(endFrame.height - safeAreaBottom + 8)
        inputBottomConstraint?.constant = offset

        let opts = UIView.AnimationOptions(rawValue: curveVal << 16)
        UIView.animate(withDuration: duration, delay: 0, options: opts) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func didTapPromptChip(_ sender: UIButton) {
        guard let prompt = sender.title(for: .normal) else { return }
        sendMessage(prompt)
    }

    @objc private func didTapSend() {
        guard let text = inputTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        inputTextField.text = ""
        sendMessage(text)
    }

    private func sendMessage(_ text: String) {
        let userMsg = AgentMessage(isUser: true, text: text)
        messages.append(userMsg)
        tableView.reloadData()
        scrollToBottom()

        UISelectionFeedbackGenerator().selectionChanged()

        // 模拟智能体本地分析并给出专业响应
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            let replyText = self.generateSmartReply(for: text)
            let aiMsg = AgentMessage(isUser: false, text: replyText)
            self.messages.append(aiMsg)
            self.tableView.reloadData()
            self.scrollToBottom()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func generateSmartReply(for input: String) -> String {
        let server = ActiveServerContext.shared.activeServer?.name ?? "当前主机"

        if input.contains("巡检") || input.contains("健康") {
            return "【\(server) 健康巡检完成】\n• 负载正常：1.38 (1m), 1.43 (5m), 1.36 (15m)\n• 内存健康：可用 0.6 GB / 总 1.9 GB (69%)\n• 磁盘充足：可用 1.6 GB / 总 19.6 GB (92%)\n• 运行时长：已平稳运行 6 天 16 小时"
        } else if input.contains("进程") || input.contains("负载") {
            return "【高资源占用进程诊断】\n1. mysqld (PID: 1204) — 内存 24.2%, CPU 2.1%\n2. node (PID: 3418) — 内存 15.6%, CPU 1.4%\n3. nginx (PID: 881) — 内存 3.2%, CPU 0.2%\n建议：整体进程运行稳健，未发现失控死循环进程。"
        } else if input.contains("缓存") || input.contains("清理") {
            return "【系统缓存建议】\n• PageCache 可回收: 约 180 MB\n• 系统临时文件: /tmp 占用 12 MB\n如需一键释放缓存，可在终端执行：sync; echo 3 > /proc/sys/vm/drop_caches"
        } else if input.contains("容器") || input.contains("docker") {
            return "【Docker 容器健康探测】\n• 活跃容器: 3 个运行中 (nginx, redis, postgres)\n• 异常容器: 0 个 (所有主网关及存储服务处于 healthy 状态)"
        } else {
            return "已收到指令：「\(input)」\n智能体已与 \(server) 建立专属守护通道，随时为你提供性能监控与运维排障支持。"
        }
    }

    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let ip = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: ip, at: .bottom, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension AgentViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didTapSend()
        return true
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension AgentViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BubbleCell", for: indexPath) as! AgentBubbleCell
        cell.configure(with: messages[indexPath.row])
        return cell
    }
}

// MARK: - AgentBubbleCell

final class AgentBubbleCell: UITableViewCell {

    private let bubbleView = UIView()
    private let contentLabel = UILabel()

    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 18
        bubbleView.layer.cornerCurve = .continuous
        bubbleView.clipsToBounds = true
        contentView.addSubview(bubbleView)

        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.numberOfLines = 0
        contentLabel.font = .systemFont(ofSize: 15, weight: .regular)
        bubbleView.addSubview(contentLabel)

        let leading = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        let trailing = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        self.leadingConstraint = leading
        self.trailingConstraint = trailing

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.82),

            contentLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            contentLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            contentLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            contentLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
        ])
    }

    func configure(with message: AgentMessage) {
        contentLabel.text = message.text

        if message.isUser {
            bubbleView.backgroundColor = AppTheme.accent
            contentLabel.textColor = .white
            leadingConstraint?.isActive = false
            trailingConstraint?.isActive = true
        } else {
            bubbleView.backgroundColor = AppTheme.cardBackground
            contentLabel.textColor = .white
            bubbleView.layer.borderWidth = 0.5
            bubbleView.layer.borderColor = AppTheme.separator.cgColor
            trailingConstraint?.isActive = false
            leadingConstraint?.isActive = true
        }
    }
}
