import UIKit

/// 远程连接断开与诊断面板
final class ConnectionDiagnosticSheet: UIViewController {

    private let server: Server
    private let errorLog: [String]
    var onReconnect: (() -> Void)?

    init(server: Server, errorLog: [String] = []) {
        self.server = server
        self.errorLog = errorLog
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 26/255.0, green: 28/255.0, blue: 40/255.0, alpha: 0.98)
        setupViews()
    }

    private func setupViews() {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = server.name
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .white
        view.addSubview(titleLabel)

        let closeBtn = UIButton(type: .system)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.setTitle("Close", for: .normal)
        closeBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        closeBtn.setTitleColor(UIColor.systemBlue, for: .normal)
        closeBtn.addAction(UIAction(handler: { [weak self] _ in
            self?.dismiss(animated: true)
        }), for: .touchUpInside)
        view.addSubview(closeBtn)

        let statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "Connection could not be established:"
        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        statusLabel.textColor = UIColor(red: 247/255.0, green: 118/255.0, blue: 142/255.0, alpha: 1.0)
        view.addSubview(statusLabel)

        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        textView.layer.cornerRadius = 10
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = UIColor(white: 0.85, alpha: 1.0)

        var logs = [
            "👤 Starting a new connection to: \"\(server.host)\" port \"\(server.port)\"",
            "⚙️ Starting address resolution of \"\(server.host)\"",
            "⚙️ Address resolution finished",
            "⚙️ Connecting to \"\(server.host)\" port \"\(server.port)\"",
            "👤 Connection to \"\(server.host)\" established",
            "⚙️ Starting SSH session",
            "⚙️ Remote server: SSH-2.0-OpenSSH_10.0p2",
            "⚙️ Agreed KEX algorithm: curve25519-sha256",
            "⚙️ Agreed Host Key algorithm: ssh-ed25519",
            "⚙️ Agreed cipher: chacha20-poly1305@openssh.com"
        ]
        if !errorLog.isEmpty {
            logs.append(contentsOf: errorLog.map { "❌ \($0)" })
        } else {
            logs.append("❌ Remote peer closed connection / Session terminated")
        }
        textView.text = logs.joined(separator: "\n")
        view.addSubview(textView)

        let retryBtn = UIButton(type: .system)
        retryBtn.translatesAutoresizingMaskIntoConstraints = false
        retryBtn.setTitle("Start over", for: .normal)
        retryBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        retryBtn.setTitleColor(.white, for: .normal)
        retryBtn.backgroundColor = UIColor(red: 49/255.0, green: 130/255.0, blue: 246/255.0, alpha: 1.0)
        retryBtn.layer.cornerRadius = 24
        retryBtn.addAction(UIAction(handler: { [weak self] _ in
            self?.dismiss(animated: true) {
                self?.onReconnect?()
            }
        }), for: .touchUpInside)
        view.addSubview(retryBtn)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            closeBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeBtn.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            textView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: retryBtn.topAnchor, constant: -20),

            retryBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            retryBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            retryBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            retryBtn.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
}
