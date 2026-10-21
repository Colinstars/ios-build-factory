import UIKit

/// 单机深度控制面板：
/// 当用户在首页【主机】列表点击某台特定服务器下钻时展示。
/// 顶部展示实时状态指标，下方提供一键进入该主机的专属交互式终端操作。
final class ServerDetailViewController: UIViewController {

    private let server: Server
    private let session: SSHSession

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private let cpuCard = MetricCardView(title: "负载 (1m / 5m / 15m)", icon: "cpu")
    private let memCard = MetricCardView(title: "内存使用", icon: "memorychip")
    private let diskCard = MetricCardView(title: "磁盘使用 (/)", icon: "internaldrive")
    private let infoCard = MetricCardView(title: "系统概览", icon: "info.circle")

    // 核心会话操作卡片 (支持一键打开专属终端)
    private let openTerminalButton = UIButton(type: .system)

    private var pollTimer: Timer?
    private var isFetching = false

    init(server: Server) {
        self.server = server
        self.session = SSHSession(server: server)
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.title = server.name
        self.navigationItem.largeTitleDisplayMode = .never
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

        // 现代 iOS 样式的一键打开终端主操作按钮
        openTerminalButton.translatesAutoresizingMaskIntoConstraints = false
        openTerminalButton.setTitle(" 打开 SSH 终端会话", for: .normal)
        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        openTerminalButton.setImage(UIImage(systemName: "terminal.fill", withConfiguration: cfg), for: .normal)
        openTerminalButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        openTerminalButton.backgroundColor = .systemBlue
        openTerminalButton.tintColor = .white
        openTerminalButton.layer.cornerRadius = 14
        openTerminalButton.layer.cornerCurve = .continuous
        openTerminalButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        openTerminalButton.addTarget(self, action: #selector(didTapOpenTerminal), for: .touchUpInside)

        stackView.addArrangedSubview(openTerminalButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 14),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])
    }

    @objc private func didTapOpenTerminal() {
        let terminalVC = HostTerminalViewController(server: server)
        navigationController?.pushViewController(terminalVC, animated: true)
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
