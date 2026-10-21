import UIKit

protocol TerminalAccessoryViewDelegate: AnyObject {
    func terminalAccessoryViewDidTapBack(_ view: TerminalAccessoryView)
    func terminalAccessoryViewDidTapCloseSession(_ view: TerminalAccessoryView)
    func terminalAccessoryViewDidTapNewTab(_ view: TerminalAccessoryView)
    func terminalAccessoryViewDidTapMenu(_ view: TerminalAccessoryView)
    func terminalAccessoryView(_ view: TerminalAccessoryView, didSendKey key: String)
    func terminalAccessoryViewDidTapPaste(_ view: TerminalAccessoryView)
    func terminalAccessoryViewDidTapDismissKeyboard(_ view: TerminalAccessoryView)
}

/// 100% 对标 Termius 官方真机布局的双层终端辅助控制栏
///
/// 第一层：会话标签栏 (Session Tab Bar)
///  [ < 返回 ]  [ 🐚 DMIT-LAX  ⓧ ]  [ + ]  [ 田 ]
///
/// 第二层：专业按键行 (Key Toolbar)
///  [shift tab] [?] [/] [📋] [esc] [tab] [ctrl] [alt] [^C] [⌨️收起]
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

    private let bottomKeyScrollView = UIScrollView()
    private let bottomKeyStack = UIStackView()

    private let feedback = UISelectionFeedbackGenerator()
    private var isCtrlActive: Bool = false
    private var ctrlButton: UIButton?

    init(serverTitle: String) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 82))
        backgroundColor = UIColor(red: 22/255.0, green: 23/255.0, blue: 33/255.0, alpha: 0.98)
        setupViews(serverTitle: serverTitle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews(serverTitle: String) {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // 顶部分隔细线
        let sep = UIView()
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        addSubview(sep)

        // 1. 第一层：Session Tab Bar
        topSessionBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topSessionBar)

        // 返回按钮
        backButton.translatesAutoresizingMaskIntoConstraints = false
        let backCfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: backCfg), for: .normal)
        backButton.tintColor = UIColor(white: 0.85, alpha: 1.0)
        backButton.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        backButton.layer.cornerRadius = 8
        backButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self = self else { return }
            self.feedback.selectionChanged()
            self.delegate?.terminalAccessoryViewDidTapBack(self)
        }), for: .touchUpInside)
        topSessionBar.addSubview(backButton)

        // 会话药丸胶囊 (Session Pill)
        sessionPill.translatesAutoresizingMaskIntoConstraints = false
        sessionPill.backgroundColor = UIColor(white: 1.0, alpha: 0.12)
        sessionPill.layer.cornerRadius = 16
        sessionPill.clipsToBounds = true
        topSessionBar.addSubview(sessionPill)

        sessionIcon.translatesAutoresizingMaskIntoConstraints = false
        let iconCfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        sessionIcon.image = UIImage(systemName: "terminal.fill", withConfiguration: iconCfg)
        sessionIcon.tintColor = UIColor(red: 122/255.0, green: 162/255.0, blue: 247/255.0, alpha: 1.0)
        sessionIcon.contentMode = .scaleAspectFit
        sessionPill.addSubview(sessionIcon)

        sessionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        sessionTitleLabel.text = serverTitle
        sessionTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        sessionTitleLabel.textColor = .white
        sessionTitleLabel.lineBreakMode = .byTruncatingTail
        sessionPill.addSubview(sessionTitleLabel)

        sessionCloseBtn.translatesAutoresizingMaskIntoConstraints = false
        let closeCfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        sessionCloseBtn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: closeCfg), for: .normal)
        sessionCloseBtn.tintColor = UIColor(white: 0.6, alpha: 1.0)
        sessionCloseBtn.addAction(UIAction(handler: { [weak self] _ in
            guard let self = self else { return }
            self.feedback.selectionChanged()
            self.delegate?.terminalAccessoryViewDidTapCloseSession(self)
        }), for: .touchUpInside)
        sessionPill.addSubview(sessionCloseBtn)

        // + 按钮
        addTabButton.translatesAutoresizingMaskIntoConstraints = false
        let addCfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        addTabButton.setImage(UIImage(systemName: "plus", withConfiguration: addCfg), for: .normal)
        addTabButton.tintColor = UIColor(white: 0.85, alpha: 1.0)
        addTabButton.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        addTabButton.layer.cornerRadius = 8
        addTabButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self = self else { return }
            self.feedback.selectionChanged()
            self.delegate?.terminalAccessoryViewDidTapNewTab(self)
        }), for: .touchUpInside)
        topSessionBar.addSubview(addTabButton)

        // 四宫格菜单按钮
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        let gridCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        menuButton.setImage(UIImage(systemName: "square.grid.2x2", withConfiguration: gridCfg), for: .normal)
        menuButton.tintColor = UIColor(white: 0.85, alpha: 1.0)
        menuButton.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        menuButton.layer.cornerRadius = 8
        menuButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self = self else { return }
            self.feedback.selectionChanged()
            self.delegate?.terminalAccessoryViewDidTapMenu(self)
        }), for: .touchUpInside)
        topSessionBar.addSubview(menuButton)

        // 2. 第二层：Key Toolbar (滚动条)
        bottomKeyScrollView.translatesAutoresizingMaskIntoConstraints = false
        bottomKeyScrollView.showsHorizontalScrollIndicator = false
        bottomKeyScrollView.showsVerticalScrollIndicator = false
        addSubview(bottomKeyScrollView)

        bottomKeyStack.translatesAutoresizingMaskIntoConstraints = false
        bottomKeyStack.axis = .horizontal
        bottomKeyStack.spacing = 6
        bottomKeyStack.alignment = .center
        bottomKeyScrollView.addSubview(bottomKeyStack)

        setupKeyButtons()

        // 布局约束
        NSLayoutConstraint.activate([
            sep.topAnchor.constraint(equalTo: topAnchor),
            sep.leadingAnchor.constraint(equalTo: leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5),

            // Session Bar
            topSessionBar.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            topSessionBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            topSessionBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            topSessionBar.heightAnchor.constraint(equalToConstant: 34),

            backButton.leadingAnchor.constraint(equalTo: topSessionBar.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: topSessionBar.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            menuButton.trailingAnchor.constraint(equalTo: topSessionBar.trailingAnchor),
            menuButton.centerYAnchor.constraint(equalTo: topSessionBar.centerYAnchor),
            menuButton.widthAnchor.constraint(equalToConstant: 36),
            menuButton.heightAnchor.constraint(equalToConstant: 32),

            addTabButton.trailingAnchor.constraint(equalTo: menuButton.leadingAnchor, constant: -8),
            addTabButton.centerYAnchor.constraint(equalTo: topSessionBar.centerYAnchor),
            addTabButton.widthAnchor.constraint(equalToConstant: 36),
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

            // Key Toolbar
            bottomKeyScrollView.topAnchor.constraint(equalTo: topSessionBar.bottomAnchor, constant: 4),
            bottomKeyScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            bottomKeyScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            bottomKeyScrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            bottomKeyStack.topAnchor.constraint(equalTo: bottomKeyScrollView.topAnchor),
            bottomKeyStack.leadingAnchor.constraint(equalTo: bottomKeyScrollView.leadingAnchor),
            bottomKeyStack.trailingAnchor.constraint(equalTo: bottomKeyScrollView.trailingAnchor),
            bottomKeyStack.bottomAnchor.constraint(equalTo: bottomKeyScrollView.bottomAnchor),
            bottomKeyStack.heightAnchor.constraint(equalTo: bottomKeyScrollView.heightAnchor)
        ])
    }

    private func setupKeyButtons() {
        // 对标 Termius 物理键盘排布
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
            ("↑", nil, "\u{1b}[A"),
            ("↓", nil, "\u{1b}[B"),
            ("←", nil, "\u{1b}[D"),
            ("→", nil, "\u{1b}[C"),
            ("", "keyboard.chevron.compact.down", "DISMISS_KEYBOARD")
        ]

        for item in items {
            let btn = UIButton(type: .system)
            if let sym = item.symbol {
                let cfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
                btn.setImage(UIImage(systemName: sym, withConfiguration: cfg), for: .normal)
            } else {
                btn.setTitle(item.title, for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            }

            btn.setTitleColor(.white, for: .normal)
            btn.tintColor = .white
            btn.backgroundColor = UIColor(white: 1.0, alpha: 0.12)
            btn.layer.cornerRadius = 6
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)

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
        case "DISMISS_KEYBOARD":
            delegate?.terminalAccessoryViewDidTapDismissKeyboard(self)
        case "TOGGLE_CTRL":
            isCtrlActive.toggle()
            ctrlButton?.backgroundColor = isCtrlActive
                ? UIColor.systemBlue
                : UIColor(white: 1.0, alpha: 0.12)
        default:
            if isCtrlActive {
                isCtrlActive = false
                ctrlButton?.backgroundColor = UIColor(white: 1.0, alpha: 0.12)
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
}
