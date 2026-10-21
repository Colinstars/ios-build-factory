import UIKit

protocol TerminalAccessoryViewDelegate: AnyObject {
    func terminalAccessoryView(_ view: TerminalAccessoryView, didTapKey key: String)
}

/// 工业级移动端终端辅助键盘工具条 (对标 Blink Shell / Termius 真实设计规范)
///
/// 遵循 iOS 规范：继承自 UIInputView(frame: ..., inputViewStyle: .keyboard)
/// 原生挂载于软键盘正上方，提供修饰键 (ESC, TAB, CTRL, 方向键, 常用符号)，带物理级微触感振动反馈！
final class TerminalAccessoryView: UIInputView {

    weak var delegate: TerminalAccessoryViewDelegate?

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let feedback = UISelectionFeedbackGenerator()

    // 默认高频键位定义
    private let keys: [(title: String, code: String)] = [
        ("ESC", "\u{1b}"),
        ("TAB", "\t"),
        ("CTRL-C", "\u{03}"),
        ("CTRL-D", "\u{04}"),
        ("CTRL-Z", "\u{1a}"),
        ("↑", "\u{1b}[A"),
        ("↓", "\u{1b}[B"),
        ("←", "\u{1b}[D"),
        ("→", "\u{1b}[C"),
        ("|", "|"),
        ("/", "/"),
        ("~", "~"),
        ("-", "-"),
        ("clear", "clear\r")
    ]

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 42), inputViewStyle: .keyboard)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.alignment = .center
        scrollView.addSubview(stackView)

        for item in keys {
            let btn = UIButton(type: .system)
            btn.setTitle(item.title, for: .normal)
            btn.titleLabel?.font = .monospacedSystemFont(ofSize: 13, weight: .bold)
            btn.setTitleColor(.label, for: .normal)
            btn.backgroundColor = UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(white: 0.28, alpha: 1.0)
                    : UIColor(white: 1.0, alpha: 0.9)
            }
            btn.layer.cornerRadius = 6
            btn.layer.cornerCurve = .continuous
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            btn.layer.shadowColor = UIColor.black.cgColor
            btn.layer.shadowOffset = CGSize(width: 0, height: 1)
            btn.layer.shadowOpacity = 0.15
            btn.layer.shadowRadius = 0.5
            
            // 绑定事件
            btn.addAction(UIAction(handler: { [weak self] _ in
                guard let self = self else { return }
                self.feedback.selectionChanged()
                self.delegate?.terminalAccessoryView(self, didTapKey: item.code)
            }), for: .touchUpInside)

            stackView.addArrangedSubview(btn)
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
        ])
    }
}
