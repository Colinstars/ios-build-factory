import UIKit

/// 单机深度控制面板：
/// 当用户在首页【状态】列表点击某台特定服务器下钻时展示。
/// 顶部提供精准指标切片与快捷操作。
final class ServerDetailViewController: UIViewController {

    private let server: Server
    private let session: SSHSession

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private let cpuCard = MetricCardView(title: "负载 (1m / 5m / 15m)", icon: "cpu")
    private let memCard = MetricCardView(title: "内存使用", icon: "memorychip")
    private let diskCard = MetricCardView(title: "磁盘使用 (/)", icon: "internaldrive")
    private let infoCard = MetricCardView(title: "系统概览", icon: "info.circle")

    // 快捷行动区
    private let actionsCard = MetricCardView(title: "节点会话", icon: "bolt.horizontal.fill")

    private var pollTimer: Timer?
    private var isFetching = false

    init(server: Server) {
        self.server = server
        self.session = SSHSession(server: server)
        super.init(nibName: nil, bundle: nil)
        // 关键修复：绝不能调用 self.title = server.name！
        // 因为 UIViewController.title 会级联向上篡改 UITabBarController 对应 TabBarItem 的文本！
        // 只赋值 navigationItem.title，确保底部 Tab 始终是【状态】，永不被篡改为 DMIT 示例！
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

        actionsCard.setValue("已设为当前活跃主机\n可在底部【智能体/文件/容器/更多】无缝协同。")
        stackView.addArrangedSubview(actionsCard)
        
        // 核心参数：开启 iOS 26 专属 .soft 柔和极透边缘效果！
        scrollView.applyLiquidGlassSoftEdgeEffect()

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
