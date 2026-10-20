import UIKit

/// 服务器控制中心 (Server Hub):
/// 采用顶部 SegmentedControl 在四大子面板间无缝切换，彻底告别单调指标：
/// 1. [状态] (Status) - 实时 CPU/内存/磁盘与系统信息
/// 2. [终端] (Terminal) - 真实交互式 PTY 终端 (集成液态玻璃悬浮辅助按键)
/// 3. [文件] (Files) - 远程 Linux 文件管理器与极速文本预览
/// 4. [容器] (Docker) - Docker 容器状态实时监控、启动、重启与停止
/// 5. [更多] (Ops) - Top 进程实时分析与常用维护命令
final class ServerDetailViewController: UIViewController {

    private let server: Server
    private let session: SSHSession

    // 顶部模式切换器 (iOS 原生分段控制器)
    private let segmentedControl = UISegmentedControl(items: ["状态", "终端", "文件", "容器", "更多"])
    private let containerView = UIView()

    // 预加载各子模块控制器
    private lazy var statusVC = ServerStatusViewController(session: session)
    private lazy var terminalVC = TerminalViewController(session: session)
    private lazy var filesVC = FilesViewController(session: session)
    private lazy var dockerVC = DockerViewController(session: session)
    private lazy var opsVC = ServerOpsViewController(session: session)

    private var currentChildVC: UIViewController?

    init(server: Server) {
        self.server = server
        self.session = SSHSession(server: server)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = server.name
        view.backgroundColor = .systemGroupedBackground

        setupNavigationBar()
        setupSegmentedControl()
        setupContainerView()

        // 默认进入状态面板
        switchTab(index: 0)
    }

    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
    }

    private func setupSegmentedControl() {
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(didChangeSegment(_:)), for: .valueChanged)
        view.addSubview(segmentedControl)

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    private func setupContainerView() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func didChangeSegment(_ sender: UISegmentedControl) {
        switchTab(index: sender.selectedSegmentIndex)
    }

    private func switchTab(index: Int) {
        let targetVC: UIViewController
        switch index {
        case 0: targetVC = statusVC
        case 1: targetVC = terminalVC
        case 2: targetVC = filesVC
        case 3: targetVC = dockerVC
        case 4: targetVC = opsVC
        default: return
        }

        if let current = currentChildVC {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        addChild(targetVC)
        targetVC.view.frame = containerView.bounds
        targetVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(targetVC.view)
        targetVC.didMove(toParent: self)
        currentChildVC = targetVC
    }
}

// MARK: - ServerStatusViewController (原监控状态面板)

final class ServerStatusViewController: UIViewController {

    private let session: SSHSession
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private let cpuCard = MetricCardView(title: "负载 (1m / 5m / 15m)", icon: "cpu")
    private let memCard = MetricCardView(title: "内存使用", icon: "memorychip")
    private let diskCard = MetricCardView(title: "磁盘使用 (/)", icon: "internaldrive")
    private let infoCard = MetricCardView(title: "系统概览", icon: "info.circle")

    private var pollTimer: Timer?
    private var isFetching = false

    init(session: SSHSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        fetchOnce()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startPolling()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPolling()
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 14

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        stackView.addArrangedSubview(cpuCard)
        stackView.addArrangedSubview(memCard)
        stackView.addArrangedSubview(diskCard)
        stackView.addArrangedSubview(infoCard)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])
    }

    private func startPolling() {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.fetchOnce()
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func fetchOnce() {
        guard !isFetching else { return }
        isFetching = true

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let metrics = try await self.session.fetchMetrics()
                await MainActor.run {
                    self.updateUI(with: metrics)
                    self.isFetching = false
                }
            } catch {
                await MainActor.run {
                    self.infoCard.setValue("连接错误: \(error.localizedDescription)")
                    self.isFetching = false
                }
            }
        }
    }

    private func updateUI(with m: ServerMetrics) {
        cpuCard.setValue(String(format: "%.2f  /  %.2f  /  %.2f", m.load1, m.load5, m.load15))
        memCard.setValue(String(format: "%.0f%%  (可用 %.1f GB / 总 %.1f GB)",
                                m.memUsedPercent, m.memAvailableMB / 1024.0, m.memTotalMB / 1024.0))
        diskCard.setValue(String(format: "%.0f%%  (可用 %.1f GB / 总 %.1f GB)",
                                 m.diskUsedPercent, m.diskAvailGB, m.diskTotalGB))
        infoCard.setValue("\(m.osString)\n\(m.uptimeString)")
    }
}

// MARK: - MetricCardView (内容层标准材质)

final class MetricCardView: UIView {

    private let titleLabel = UILabel()
    private let iconView = UIImageView()
    private let valueLabel = UILabel()

    init(title: String, icon: String) {
        super.init(frame: .zero)
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        setup(title: title, icon: icon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(title: String, icon: String) {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .secondaryLabel

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = "等待采集..."
        valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 0

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(valueLabel)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            valueLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
        ])
    }

    func setValue(_ v: String) {
        valueLabel.text = v
    }
}
