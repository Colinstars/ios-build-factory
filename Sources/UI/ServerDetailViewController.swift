import UIKit

/// 服务器详情与实时监控页。
///
/// 遵循 HIG 规范：
/// - 内容层：指标卡片（CPU/内存/磁盘）采用标准分组样式，纯色背板 + 语义色。
/// - 功能层：
///   1. 顶部指标切换器使用 **GlassSurface (clear 变体)** 浮动承托
///   2. 底部浮动工具栏（终端 / 刷新）使用 **GlassSurface (regular 变体)** 浮动承托
final class ServerDetailViewController: UIViewController {

    private let server: Server
    private let session: SSHSession

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    // 内容层：指标卡片
    private let cpuCard = MetricCardView(title: "负载 (1m / 5m / 15m)", icon: "cpu")
    private let memCard = MetricCardView(title: "内存使用", icon: "memorychip")
    private let diskCard = MetricCardView(title: "磁盘使用 (/)", icon: "internaldrive")
    private let infoCard = MetricCardView(title: "系统", icon: "info.circle")

    // 功能层：浮动操作条（符合 HIG『控件层浮动于内容层上方』）
    private let floatingBar = GlassSurface(variant: .regular, cornerRadius: 24)
    private let terminalButton = UIButton(type: .system)
    private let refreshButton = UIButton(type: .system)

    private var pollTimer: Timer?
    private var isFetching = false

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

        setupScrollView()
        setupFloatingBar()
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

    // MARK: - Setup UI

    private func setupScrollView() {
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
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -90),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])
    }

    /// 功能层：浮动工具栏。
    private func setupFloatingBar() {
        floatingBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(floatingBar)

        terminalButton.translatesAutoresizingMaskIntoConstraints = false
        terminalButton.setTitle(" 终端", for: .normal)
        terminalButton.setImage(UIImage(systemName: "terminal"), for: .normal)
        terminalButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        terminalButton.addTarget(self, action: #selector(didTapTerminal), for: .touchUpInside)

        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.setTitle(" 刷新", for: .normal)
        refreshButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        refreshButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        refreshButton.addTarget(self, action: #selector(didTapRefresh), for: .touchUpInside)

        let barStack = UIStackView(arrangedSubviews: [terminalButton, refreshButton])
        barStack.translatesAutoresizingMaskIntoConstraints = false
        barStack.axis = .horizontal
        barStack.distribution = .fillEqually
        floatingBar.addSubview(barStack)

        NSLayoutConstraint.activate([
            floatingBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            floatingBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            floatingBar.widthAnchor.constraint(equalToConstant: 240),
            floatingBar.heightAnchor.constraint(equalToConstant: 48),

            barStack.topAnchor.constraint(equalTo: floatingBar.topAnchor),
            barStack.leadingAnchor.constraint(equalTo: floatingBar.leadingAnchor, constant: 12),
            barStack.trailingAnchor.constraint(equalTo: floatingBar.trailingAnchor, constant: -12),
            barStack.bottomAnchor.constraint(equalTo: floatingBar.bottomAnchor),
        ])
    }

    // MARK: - Polling

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

    @objc private func didTapRefresh() {
        fetchOnce()
    }

    @objc private func didTapTerminal() {
        let alert = UIAlertController(title: "终端 (P2 功能)", message: "xterm.js + PTY 终端将在下一阶段接入。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
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
                    self.showError(error)
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

    private func showError(_ err: Error) {
        infoCard.setValue("连接错误: \(err.localizedDescription)")
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
        valueLabel.font = .systemFont(ofSize: 17, weight: .semibold)
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
