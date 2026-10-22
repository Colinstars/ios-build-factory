import UIKit

protocol TerminalAccessoryViewDelegate: AnyObject {
    func terminalAccessoryViewDidTapBack(_ view: TerminalAccessoryView)
    func terminalAccessoryViewDidTapCloseSession(_ view: TerminalAccessoryView)
    func terminalAccessoryViewDidTapNewTab(_ view: TerminalAccessoryView)
    func terminalAccessoryViewDidTapGridMenu(_ view: TerminalAccessoryView)
    func terminalAccessoryView(_ view: TerminalAccessoryView, didSendKey key: String)
    func terminalAccessoryViewDidTapPaste(_ view: TerminalAccessoryView)
    func terminalAccessoryViewDidTapDismissKeyboard(_ view: TerminalAccessoryView)
}

/// 终端专用输入辅助栏组件 (支持右侧固定独立收起键盘按钮与等宽统一按键)
final class TerminalAccessoryView: UIView {

    weak var delegate: TerminalAccessoryViewDelegate?

    private let topSessionBar = UIView()
    private let backButton = UIButton(type: .system)
    private let sessionPill = UIView()
    private let sessionIcon = UIImageView()
    private let sessionTitleLabel = UILabel()
    private let sessionCloseBtn = UIButton(type: .system)
    private let addTabButton = UIButton(type: .system)
    private let menuButton = UIButton(type: .system)

    // 第二层：左侧横向滚动按键区 + 右侧固定独立收起键盘按钮
    private let bottomToolbar = UIView()
    private let bottomKeyScrollView = UIScrollView()
    private let bottomKeyStack = UIStackView()
    private let fixedDismissKeyboardButton = UIButton(type: .system)

    private let feedback = UISelectionFeedbackGenerator()
    private var isCtrlActive: Bool = false
    private var ctrlButton: UIButton?

    init(serverTitle: String) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 86))
        backgroundColor = UIColor(red: 24/255.0, green: 26/255.0, blue: 36/255.0, alpha: 0.98)
        setupViews(serverTitle: serverTitle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews(serverTitle: String) {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let topBorder = UIView()
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        topBorder.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        addSubview(topBorder)

        // 第一层：Session 状态标签栏
        topSessionBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topSessionBar)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        let backCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: backCfg), for: .normal)
        backButton.tintColor = UIColor(white: 0.85, alpha: 1.0)
        backButton.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        backButton.layer.cornerRadius = 8
        backButton.layer.cornerCurve = .continuous
        backButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self = self else { return }
            self.feedback.selectionChanged()
            self.delegate?.terminalAccessoryViewDidTapBack(self)
        }), for: .touchUpInside)
        topSessionBar.addSubview(backButton)

        sessionPill.translatesAutoresizingMaskIntoConstraints = false
        sessionPill.backgroundColor = UIColor(white: 1.0, alpha: 0.12)
        sessionPill.layer.cornerRadius = 16
        sessionPill.layer.cornerCurve = .continuous
        sessionPill.clipsToBounds = true
        topSessionBar.addSubview(sessionPill)

        sessionIcon.translatesAutoresizingMaskIntoConstraints = false
        let iconCfg = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        sessionIcon.image = UIImage(systemName: "terminal.fill", withConfiguration: iconCfg)
        sessionIcon.tintColor = UIColor(red: 122/255.0, green: 162/255.0, blue: 247/255.0, alpha: 1.0)
        sessionIcon.contentMode = .scaleAspectFit
        sessionPill.addSubview(sessionIcon)

        sessionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        sessionTitleLabel.text = serverTitle
        sessionTitleLabel.font = .monospacedSystemFont(ofSize: 13, weight: .semibold)
        sessionTitleLabel.textColor = .white
        sessionTitleLabel.lineBreakMode = .byTruncatingTail
        sessionPill.addSubview(sessionTitleLabel)

        sessionCloseBtn.translatesAutoresizingMaskIntoConstraints = false
        let closeCfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        sessionCloseBtn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: closeCfg), for: .normal)
        sessionCloseBtn.tintColor = UIColor(white: 0.55, alpha: 1.0)
        sessionCloseBtn.addAction(UIAction(handler: { [weak self] _ in
            guard let self = self else { return }
            self.feedback.selectionChanged()
            self.delegate?.terminalAccessoryViewDidTapCloseSession(self)
        }), for: .touchUpInside)
        sessionPill.addSubview(sessionCloseBtn)

        addTabButton.translatesAutoresizingMaskIntoConstraints = false
        let addCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        addTabButton.setImage(UIImage(systemName: "plus", withConfiguration: addCfg), for: .normal)
        addTabButton.tintColor = UIColor(white: 0.85, alpha: 1.0)
        addTabButton.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        addTabButton.layer.cornerRadius = 8
        addTabButton.layer.cornerCurve = .continuous
        addTabButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self = self else { return }
            self.feedback.selectionChanged()
            self.delegate?.terminalAccessoryViewDidTapNewTab(self)
        }), for: .touchUpInside)
        topSessionBar.addSubview(addTabButton)

        menuButton.translatesAutoresizingMaskIntoConstraints = false
        let gridCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        menuButton.setImage(UIImage(systemName: "square.grid.2x2", withConfiguration: gridCfg), for: .normal)
        menuButton.tintColor = UIColor(white: 0.85, alpha: 1.0)
        menuButton.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        menuButton.layer.cornerRadius = 8
        menuButton.layer.cornerCurve = .continuous
        menuButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self = self else { return }
            self.feedback.selectionChanged()
            self.delegate?.terminalAccessoryViewDidTapGridMenu(self)
        }), for: .touchUpInside)
        topSessionBar.addSubview(menuButton)

        // 第二层：左侧滚动工具栏 + 右侧固定独立键盘收起按钮
        bottomToolbar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomToolbar)

        bottomKeyScrollView.translatesAutoresizingMaskIntoConstraints = false
        bottomKeyScrollView.showsHorizontalScrollIndicator = false
        bottomKeyScrollView.showsVerticalScrollIndicator = false
        bottomToolbar.addSubview(bottomKeyScrollView)

        bottomKeyStack.translatesAutoresizingMaskIntoConstraints = false
        bottomKeyStack.axis = .horizontal
        bottomKeyStack.spacing = 6
        bottomKeyStack.alignment = .center
        bottomKeyScrollView.addSubview(bottomKeyStack)

        // 右侧固定常驻的键盘收起按钮
        fixedDismissKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        let kbCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        fixedDismissKeyboardButton.setImage(UIImage(systemName: "keyboard.chevron.compact.down", withConfiguration: kbCfg), for: .normal)
        fixedDismissKeyboardButton.tintColor = UIColor(white: 0.85, alpha: 1.0)
        fixedDismissKeyboardButton.backgroundColor = UIColor(white: 1.0, alpha: 0.12)
        fixedDismissKeyboardButton.layer.cornerRadius = 6
        fixedDismissKeyboardButton.layer.cornerCurve = .continuous
        fixedDismissKeyboardButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self = self else { return }
            self.feedback.selectionChanged()
            self.delegate?.terminalAccessoryViewDidTapDismissKeyboard(self)
        }), for: .touchUpInside)
        bottomToolbar.addSubview(fixedDismissKeyboardButton)

        setupKeyButtons()

        NSLayoutConstraint.activate([
            topBorder.topAnchor.constraint(equalTo: topAnchor),
            topBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: 0.5),

            topSessionBar.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            topSessionBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            topSessionBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            topSessionBar.heightAnchor.constraint(equalToConstant: 34),

            backButton.leadingAnchor.constraint(equalTo: topSessionBar.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: topSessionBar.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 34),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            menuButton.trailingAnchor.constraint(equalTo: topSessionBar.trailingAnchor),
            menuButton.centerYAnchor.constraint(equalTo: topSessionBar.centerYAnchor),
            menuButton.widthAnchor.constraint(equalToConstant: 34),
            menuButton.heightAnchor.constraint(equalToConstant: 32),

            addTabButton.trailingAnchor.constraint(equalTo: menuButton.leadingAnchor, constant: -8),
            addTabButton.centerYAnchor.constraint(equalTo: topSessionBar.centerYAnchor),
            addTabButton.widthAnchor.constraint(equalToConstant: 34),
            addTabButton.heightAnchor.constraint(equalToConstant: 32),

            sessionPill.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            sessionPill.trailingAnchor.constraint(equalTo: addTabButton.leadingAnchor, constant: -8),
            sessionPill.centerYAnchor.constraint(equalTo: topSessionBar.centerYAnchor),
            sessionPill.heightAnchor.constraint(equalToConstant: 32),

            sessionIcon.leadingAnchor.constraint(equalTo: sessionPill.leadingAnchor, constant: 10),
            sessionIcon.centerYAnchor.constraint(equalTo: sessionPill.centerYAnchor),
            sessionIcon.widthAnchor.constraint(equalToConstant: 16),
            sessionIcon.heightAnchor.constraint(equalToConstant: 16),

            sessionCloseBtn.trailingAnchor.constraint(equalTo: sessionPill.trailingAnchor, constant: -6),
            sessionCloseBtn.centerYAnchor.constraint(equalTo: sessionPill.centerYAnchor),
            sessionCloseBtn.widthAnchor.constraint(equalToConstant: 20),
            sessionCloseBtn.heightAnchor.constraint(equalToConstant: 20),

            sessionTitleLabel.leadingAnchor.constraint(equalTo: sessionIcon.trailingAnchor, constant: 6),
            sessionTitleLabel.trailingAnchor.constraint(equalTo: sessionCloseBtn.leadingAnchor, constant: -6),
            sessionTitleLabel.centerYAnchor.constraint(equalTo: sessionPill.centerYAnchor),

            // 第二层整体容器
            bottomToolbar.topAnchor.constraint(equalTo: topSessionBar.bottomAnchor, constant: 4),
            bottomToolbar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            bottomToolbar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            bottomToolbar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),

            // 右侧固定收起按钮：宽度 38，高度 32，固定在最右边
            fixedDismissKeyboardButton.trailingAnchor.constraint(equalTo: bottomToolbar.trailingAnchor),
            fixedDismissKeyboardButton.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            fixedDismissKeyboardButton.widthAnchor.constraint(equalToConstant: 38),
            fixedDismissKeyboardButton.heightAnchor.constraint(equalToConstant: 32),

            // 左侧滚动区域：右侧紧贴固定按钮
            bottomKeyScrollView.topAnchor.constraint(equalTo: bottomToolbar.topAnchor),
            bottomKeyScrollView.leadingAnchor.constraint(equalTo: bottomToolbar.leadingAnchor),
            bottomKeyScrollView.trailingAnchor.constraint(equalTo: fixedDismissKeyboardButton.leadingAnchor, constant: -6),
            bottomKeyScrollView.bottomAnchor.constraint(equalTo: bottomToolbar.bottomAnchor),

            bottomKeyStack.topAnchor.constraint(equalTo: bottomKeyScrollView.topAnchor),
            bottomKeyStack.leadingAnchor.constraint(equalTo: bottomKeyScrollView.leadingAnchor),
            bottomKeyStack.trailingAnchor.constraint(equalTo: bottomKeyScrollView.trailingAnchor),
            bottomKeyStack.bottomAnchor.constraint(equalTo: bottomKeyScrollView.bottomAnchor),
            bottomKeyStack.heightAnchor.constraint(equalTo: bottomKeyScrollView.heightAnchor)
        ])
    }

    private func setupKeyButtons() {
        // 标准高频按键：统一度量衡，规整等高统一内边距
        let items: [(title: String, symbol: String?, code: String)] = [
            ("shift tab", nil, "\u{1b}[Z"),
            ("?", nil, "?"),
            ("/", nil, "/"),
            ("", "paperclip", "PASTE_CLIPBOARD"),
            ("esc", nil, "\u{1b}"),
            ("tab", nil, "\t"),
            ("ctrl", nil, "TOGGLE_CTRL"),
            ("alt", nil, "\u{1b}"),
            ("^C", nil, "\u{03}"),
            ("^B", nil, "\u{02}"),
            ("↑", nil, "\u{1b}[A"),
            ("↓", nil, "\u{1b}[B"),
            ("←", nil, "\u{1b}[D"),
            ("→", nil, "\u{1b}[C")
        ]

        for item in items {
            let btn = UIButton(type: .system)
            if let sym = item.symbol {
                let cfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                btn.setImage(UIImage(systemName: sym, withConfiguration: cfg), for: .normal)
            } else {
                btn.setTitle(item.title, for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            }

            btn.setTitleColor(.white, for: .normal)
            btn.tintColor = .white
            btn.backgroundColor = UIColor(white: 1.0, alpha: 0.10)
            btn.layer.cornerRadius = 6
            btn.layer.cornerCurve = .continuous
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            btn.heightAnchor.constraint(equalToConstant: 32).isActive = true

            if item.code == "TOGGLE_CTRL" {
                self.ctrlButton = btn
            }

            btn.addAction(UIAction(handler: { [weak self] _ in
                guard let self = self else { return }
                self.feedback.selectionChanged()
                self.handleKeyAction(code: item.code)
            }), for: .touchUpInside)

            bottomKeyStack.addArrangedSubview(btn)
        }
    }

    private func handleKeyAction(code: String) {
        switch code {
        case "PASTE_CLIPBOARD":
            delegate?.terminalAccessoryViewDidTapPaste(self)
        case "TOGGLE_CTRL":
            isCtrlActive.toggle()
            ctrlButton?.backgroundColor = isCtrlActive
                ? UIColor.systemBlue
                : UIColor(white: 1.0, alpha: 0.10)
        default:
            if isCtrlActive {
                isCtrlActive = false
                ctrlButton?.backgroundColor = UIColor(white: 1.0, alpha: 0.10)
                if let firstChar = code.lowercased().first, let ascii = firstChar.asciiValue, ascii >= 97 && ascii <= 122 {
                    let ctrlVal = Character(UnicodeScalar(ascii - 96))
                    delegate?.terminalAccessoryView(self, didSendKey: String(ctrlVal))
                    return
                }
            }
            delegate?.terminalAccessoryView(self, didSendKey: code)
        }
    }

    func updateServerTitle(_ title: String) {
        sessionTitleLabel.text = title
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 86)
    }
}
