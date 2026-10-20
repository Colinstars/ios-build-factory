import UIKit

/// 智能体 (AI Agent) 消息模型
struct AgentMessage: Identifiable, Hashable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let timestamp: Date = Date()
}

/// 第二项全局主模块：智能体 (AI Agent)
///
/// 遵循 Apple HIG 规范设计的现代化 AI 运维对话体验：
/// 1. 顶部大标题【智能体】，副标题显示『AI 运维专家 · 就绪』；
/// 2. 顶部提供 3 个一键提问快捷药丸 (Prompt Chips)；
/// 3. 对话气泡分层（User 蓝色沉浸气泡，AI 纯白卡片并支持排版）；
/// 4. 底部悬浮输入条，键盘弹起毫秒级联动，不遮挡内容。
final class AgentViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let promptChipsScrollView = UIScrollView()
    private let promptChipsStack = UIStackView()

    // 底部输入栏
    private let inputContainer = UIView()
    private let inputTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var inputBottomConstraint: NSLayoutConstraint?

    // 预置专业初始消息
    private var messages: [AgentMessage] = [
        AgentMessage(isUser: false, text: "你好！我是你的专属 AI 运维智能体。我已经接入当前主机监控管道，你可以向我询问：\n• 当前服务器负载为什么偏高？\n• 排查占用内存最大的进程\n• 检查 Docker 容器健康状况与日志")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "智能体"
        navigationController?.navigationBar.prefersLargeTitles = true

        view.backgroundColor = .systemGroupedBackground

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
            "⚡️ 全机健康体检",
            "🔍 排查高负载原因",
            "🧹 清理系统无用缓存",
            "📦 检查 Docker 容器"
        ]

        for p in prompts {
            let chip = UIButton(type: .system)
            chip.setTitle(p, for: .normal)
            chip.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            chip.setTitleColor(.label, for: .normal)
            chip.backgroundColor = .secondarySystemGroupedBackground
            chip.layer.cornerRadius = 15
            chip.layer.cornerCurve = .continuous
            chip.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
            chip.layer.borderWidth = 0.5
            chip.layer.borderColor = UIColor.separator.cgColor
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
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(AgentBubbleCell.self, forCellReuseIdentifier: "BubbleCell")
        

        view.addSubview(tableView)
    }

    private func setupInputBar() {
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.backgroundColor = .secondarySystemGroupedBackground
        inputContainer.layer.cornerRadius = 24
        inputContainer.layer.cornerCurve = .continuous
        inputContainer.layer.borderWidth = 0.5
        inputContainer.layer.borderColor = UIColor.separator.cgColor

        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.placeholder = "向智能体提问或下发运维指令..."
        inputTextField.font = .systemFont(ofSize: 15)
        inputTextField.textColor = .label
        inputTextField.returnKeyType = .send
        inputTextField.delegate = self

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: cfg), for: .normal)
        sendButton.tintColor = .systemBlue
        sendButton.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)

        inputContainer.addSubview(inputTextField)
        inputContainer.addSubview(sendButton)
        view.addSubview(inputContainer)

        let bottom = inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        self.inputBottomConstraint = bottom

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 46),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor, constant: -8),

            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottom,
            inputContainer.heightAnchor.constraint(equalToConstant: 48),

            inputTextField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            inputTextField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),

            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 32),
            sendButton.heightAnchor.constraint(equalToConstant: 32),
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

        let targetOffset = keyboardHeight > 0 ? -(keyboardHeight - view.safeAreaInsets.bottom + 8) : -10
        inputBottomConstraint?.constant = targetOffset

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
            self.scrollToBottom(animated: false)
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
        messages.append(AgentMessage(isUser: true, text: text))
        tableView.reloadData()
        scrollToBottom(animated: true)

        // 模拟智能体思考并秒级返回专业运维推导
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            let replyText = self.generateSmartReply(for: text)
            self.messages.append(AgentMessage(isUser: false, text: replyText))
            self.tableView.reloadData()
            self.scrollToBottom(animated: true)
        }
    }

    private func generateSmartReply(for input: String) -> String {
        if input.contains("体检") || input.contains("健康") {
            return "✅ 【全机健康巡检报告】\n• CPU 负载: 0.12 / 0.08 / 0.05 (极低负载)\n• 内存健康: 充足，无 Swap 挤压\n• 磁盘根目录: 已使用 28%，空间充裕\n• 僵尸进程: 0 个\n系统状态处于健康巅峰，无需人工干预。"
        } else if input.contains("负载") || input.contains("慢") {
            return "🔍 【负载深度排查结论】\n当前主机最近 15 分钟平均负载稳定在 0.05 左右，未发现计算峰值。Top 进程中无异常占用死锁。建议继续保持监控。"
        } else if input.contains("清理") || input.contains("缓存") {
            return "🧹 【智能运维执行建议】\n已准备好清理脚本：`sync; echo 3 > /proc/sys/vm/drop_caches`。\n该操作安全，可随时释放非活动文件页缓存。"
        } else {
            return "收到任务指令：『\(input)』\n智能体已解析语义。由于当前处于安全预览模式，自动化执行前将随时为你生成确认凭据。"
        }
    }

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        let ip = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: ip, at: .bottom, animated: animated)
    }
}

// MARK: - TableView

extension AgentViewController: UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BubbleCell", for: indexPath) as! AgentBubbleCell
        cell.configure(with: messages[indexPath.row])
        return cell
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didTapSend()
        return true
    }
}

// MARK: - 对话气泡 Cell

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
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.cornerCurve = .continuous

        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.numberOfLines = 0
        contentLabel.font = .systemFont(ofSize: 15, weight: .regular)

        bubbleView.addSubview(contentLabel)
        contentView.addSubview(bubbleView)

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
            bubbleView.backgroundColor = .systemBlue
            contentLabel.textColor = .white
            leadingConstraint?.isActive = false
            trailingConstraint?.isActive = true
        } else {
            bubbleView.backgroundColor = .secondarySystemGroupedBackground
            contentLabel.textColor = .label
            bubbleView.layer.borderWidth = 0.5
            bubbleView.layer.borderColor = UIColor.separator.cgColor
            trailingConstraint?.isActive = false
            leadingConstraint?.isActive = true
        }
    }
}
