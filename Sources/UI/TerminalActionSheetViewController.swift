import UIKit

/// 终端快捷操作面板
final class TerminalActionSheetViewController: UIViewController {

    var onClear: (() -> Void)?
    var onRedraw: (() -> Void)?
    var onReconnect: (() -> Void)?
    var onDisconnect: (() -> Void)?

    private let containerView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapDismiss))
        view.addGestureRecognizer(tap)

        setupContainer()
    }

    @objc private func didTapDismiss() {
        dismiss(animated: true)
    }

    private func setupContainer() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 28/255.0, green: 30/255.0, blue: 44/255.0, alpha: 0.98)
        containerView.layer.cornerRadius = 20
        containerView.layer.cornerCurve = .continuous
        containerView.clipsToBounds = true
        view.addSubview(containerView)

        let grabber = UIView()
        grabber.translatesAutoresizingMaskIntoConstraints = false
        grabber.backgroundColor = UIColor(white: 1.0, alpha: 0.25)
        grabber.layer.cornerRadius = 2.5
        containerView.addSubview(grabber)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Session Actions"
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = .white
        containerView.addSubview(titleLabel)

        let gridStack = UIStackView()
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        gridStack.axis = .horizontal
        gridStack.distribution = .fillEqually
        gridStack.spacing = 10
        containerView.addSubview(gridStack)

        let item1 = createGridButton(title: "Clear", icon: "trash", color: .systemOrange) { [weak self] in
            self?.dismiss(animated: true) { self?.onClear?() }
        }
        let item2 = createGridButton(title: "Redraw", icon: "arrow.clockwise", color: .systemBlue) { [weak self] in
            self?.dismiss(animated: true) { self?.onRedraw?() }
        }
        let item3 = createGridButton(title: "Reconnect", icon: "network", color: .systemGreen) { [weak self] in
            self?.dismiss(animated: true) { self?.onReconnect?() }
        }
        let item4 = createGridButton(title: "Close", icon: "xmark.circle", color: .systemRed) { [weak self] in
            self?.dismiss(animated: true) { self?.onDisconnect?() }
        }

        gridStack.addArrangedSubview(item1)
        gridStack.addArrangedSubview(item2)
        gridStack.addArrangedSubview(item3)
        gridStack.addArrangedSubview(item4)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            grabber.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            grabber.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 36),
            grabber.heightAnchor.constraint(equalToConstant: 5),

            titleLabel.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            gridStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            gridStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            gridStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            gridStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            gridStack.heightAnchor.constraint(equalToConstant: 80)
        ])
    }

    private func createGridButton(title: String, icon: String, color: UIColor, action: @escaping () -> Void) -> UIView {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        btn.layer.cornerRadius = 12
        btn.layer.cornerCurve = .continuous

        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        img.image = UIImage(systemName: icon, withConfiguration: cfg)
        img.tintColor = color
        img.contentMode = .scaleAspectFit
        btn.addSubview(img)

        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = title
        lbl.font = .systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = UIColor(white: 0.85, alpha: 1.0)
        lbl.textAlignment = .center
        btn.addSubview(lbl)

        NSLayoutConstraint.activate([
            img.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
            img.centerYAnchor.constraint(equalTo: btn.centerYAnchor, constant: -10),

            lbl.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
            lbl.topAnchor.constraint(equalTo: img.bottomAnchor, constant: 6)
        ])

        btn.addAction(UIAction(handler: { _ in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }), for: .touchUpInside)

        return btn
    }
}
