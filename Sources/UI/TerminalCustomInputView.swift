import UIKit

/// 终端自定义键盘扩展面板
/// 提供四类专属功能：
/// 1. 扩展按键矩阵 (F1~F12, Home, End, PgUp, PgDn, 特殊符号)
/// 2. 代码片段快速注入 (Snippets)
/// 3. 历史输入指令回溯 (History)
/// 4. 终端配色主题实时预览切换 (Themes)
final class TerminalCustomInputView: UIInputView {

    var onSendKey: ((String) -> Void)?
    var onSwitchToSystemKeyboard: (() -> Void)?
    var onSelectTheme: ((String) -> Void)?

    private let tabBar = UIView()
    private let contentView = UIView()

    private let tabButtons: [UIButton] = []
    private var currentTabIndex: Int = 0

    // 四大容器页面
    private let keysView = UIView()
    private let snippetsView = UIView()
    private let historyView = UIView()
    private let themesView = UIView()

    init() {
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 320)
        super.init(frame: frame, inputViewStyle: .keyboard)
        backgroundColor = UIColor(red: 22/255.0, green: 24/255.0, blue: 34/255.0, alpha: 1.0)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // 底部 TabBar（6 个切换图标，右侧独立切回软键盘按钮）
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.backgroundColor = UIColor(red: 18/255.0, green: 20/255.0, blue: 28/255.0, alpha: 1.0)
        addSubview(tabBar)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        setupTabBarItems()
        setupKeysPage()
        setupSnippetsPage()
        setupHistoryPage()
        setupThemesPage()

        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: 48),

            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
        ])

        switchTab(to: 0)
    }

    private func setupTabBarItems() {
        let tabs = [
            ("square.grid.2x2", 0),  // 0: 常用快捷键大盘
            ("curlybraces", 1),       // 1: Snippets 代码片段
            ("clock", 2),             // 2: 历史命令 History
            ("paintpalette", 3)       // 3: 终端主题配色 Themes
        ]

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        tabBar.addSubview(stack)

        for item in tabs {
            let btn = UIButton(type: .system)
            let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
            btn.setImage(UIImage(systemName: item.0, withConfiguration: cfg), for: .normal)
            btn.tintColor = UIColor(white: 0.6, alpha: 1.0)
            btn.tag = item.1
            btn.layer.cornerRadius = 8
            btn.addAction(UIAction(handler: { [weak self] _ in
                UISelectionFeedbackGenerator().selectionChanged()
                self?.switchTab(to: btn.tag)
            }), for: .touchUpInside)
            stack.addArrangedSubview(btn)
        }

        // 最右侧独立的切回系统键盘按钮
        let switchKbBtn = UIButton(type: .system)
        switchKbBtn.translatesAutoresizingMaskIntoConstraints = false
        let kbCfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        switchKbBtn.setImage(UIImage(systemName: "keyboard", withConfiguration: kbCfg), for: .normal)
        switchKbBtn.tintColor = .white
        switchKbBtn.backgroundColor = UIColor(white: 1.0, alpha: 0.12)
        switchKbBtn.layer.cornerRadius = 8
        switchKbBtn.addAction(UIAction(handler: { [weak self] _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self?.onSwitchToSystemKeyboard?()
        }), for: .touchUpInside)
        tabBar.addSubview(switchKbBtn)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor, constant: 12),
            stack.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor, constant: -4),
            stack.trailingAnchor.constraint(equalTo: switchKbBtn.leadingAnchor, constant: -16),

            switchKbBtn.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor, constant: -12),
            switchKbBtn.centerYAnchor.constraint(equalTo: tabBar.centerYAnchor),
            switchKbBtn.widthAnchor.constraint(equalToConstant: 44),
            switchKbBtn.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func switchTab(to index: Int) {
        currentTabIndex = index
        keysView.isHidden = (index != 0)
        snippetsView.isHidden = (index != 1)
        historyView.isHidden = (index != 2)
        themesView.isHidden = (index != 3)
    }

    // 1. 全键盘方块按键页
    private func setupKeysPage() {
        keysView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(keysView)
        pinView(keysView, to: contentView)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        keysView.addSubview(scrollView)
        pinView(scrollView, to: keysView)

        let mainStack = UIStackView()
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.axis = .vertical
        mainStack.spacing = 6
        mainStack.isLayoutMarginsRelativeArrangement = true
        mainStack.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        scrollView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            mainStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // F1~F12 规整行
        let fKeys = [
            ("F1", "\u{1b}OP"), ("F2", "\u{1b}OQ"), ("F3", "\u{1b}OR"), ("F4", "\u{1b}OS"),
            ("F5", "\u{1b}[15~"), ("F6", "\u{1b}[17~"), ("F7", "\u{1b}[18~"), ("F8", "\u{1b}[19~"),
            ("F9", "\u{1b}[20~"), ("F10", "\u{1b}[21~"), ("F11", "\u{1b}[23~"), ("F12", "\u{1b}[24~")
        ]
        mainStack.addArrangedSubview(createKeyRow(fKeys.prefix(6).map { ($0.0, $0.1) }))
        mainStack.addArrangedSubview(createKeyRow(fKeys.suffix(6).map { ($0.0, $0.1) }))

        // 编辑控制行
        let editKeys = [
            ("home", "\u{1b}[H"), ("pgUp", "\u{1b}[5~"), ("pgDn", "\u{1b}[6~"), ("end", "\u{1b}[F"),
            ("ins", "\u{1b}[2~"), ("del", "\u{1b}[3~")
        ]
        mainStack.addArrangedSubview(createKeyRow(editKeys))

        // 常用符号行
        let symKeys = [
            ("{", "{"), ("}", "}"), ("[", "["), ("]", "]"), ("<", "<"), (">", ">"),
            ("|", "|"), ("~", "~"), ("=", "="), ("_", "_"), ("/", "/"), ("\\", "\\")
        ]
        mainStack.addArrangedSubview(createKeyRow(symKeys.prefix(6).map { ($0.0, $0.1) }))
        mainStack.addArrangedSubview(createKeyRow(symKeys.suffix(6).map { ($0.0, $0.1) }))
    }

    private func createKeyRow(_ items: [(String, String)]) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 6
        row.heightAnchor.constraint(equalToConstant: 38).isActive = true

        for item in items {
            let btn = UIButton(type: .system)
            btn.setTitle(item.0, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            btn.setTitleColor(.white, for: .normal)
            btn.backgroundColor = UIColor(white: 1.0, alpha: 0.10)
            btn.layer.cornerRadius = 6
            btn.layer.cornerCurve = .continuous
            btn.addAction(UIAction(handler: { [weak self] _ in
                UISelectionFeedbackGenerator().selectionChanged()
                self?.onSendKey?(item.1)
            }), for: .touchUpInside)
            row.addArrangedSubview(btn)
        }
        return row
    }

    // 2. Snippets 代码片段页
    private func setupSnippetsPage() {
        snippetsView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(snippetsView)
        pinView(snippetsView, to: contentView)

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        snippetsView.addSubview(scroll)
        pinView(scroll, to: snippetsView)

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        let snippets = [
            ("psswd", "passwd\n"),
            ("sudo systemctl enable docker", "sudo systemctl enable docker\n"),
            ("vim /etc/ssh/sshd_config", "vim /etc/ssh/sshd_config\n"),
            ("docker ps -a", "docker ps -a\n"),
            ("journalctl -u ssh -n 50", "journalctl -u ssh -n 50\n"),
            ("df -h", "df -h\n"),
            ("free -m", "free -m\n")
        ]

        for item in snippets {
            let card = UIButton(type: .system)
            card.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
            card.layer.cornerRadius = 10
            card.layer.cornerCurve = .continuous
            card.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)

            let hStack = UIStackView()
            hStack.isUserInteractionEnabled = false
            hStack.translatesAutoresizingMaskIntoConstraints = false
            hStack.axis = .horizontal
            hStack.spacing = 10
            hStack.alignment = .center

            let img = UIImageView(image: UIImage(systemName: "curlybraces"))
            img.tintColor = AppTheme.accent
            img.widthAnchor.constraint(equalToConstant: 20).isActive = true
            img.heightAnchor.constraint(equalToConstant: 20).isActive = true
            hStack.addArrangedSubview(img)

            let lbl = UILabel()
            lbl.text = item.0
            lbl.textColor = .white
            lbl.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
            hStack.addArrangedSubview(lbl)

            card.addSubview(hStack)
            NSLayoutConstraint.activate([
                hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
                hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
                hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
                hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8)
            ])

            card.addAction(UIAction(handler: { [weak self] _ in
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                self?.onSendKey?(item.1)
            }), for: .touchUpInside)

            stack.addArrangedSubview(card)
        }
    }

    // 3. 历史命令页
    private func setupHistoryPage() {
        historyView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(historyView)
        pinView(historyView, to: contentView)

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        historyView.addSubview(scroll)
        pinView(scroll, to: historyView)

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        let historyItems = ["agy", "tmux attach -t agy", "agy-go", "ls", "opencode", "htop", "clear"]
        for cmd in historyItems {
            let card = UIButton(type: .system)
            card.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
            card.layer.cornerRadius = 10
            card.layer.cornerCurve = .continuous
            card.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)

            let hStack = UIStackView()
            hStack.isUserInteractionEnabled = false
            hStack.translatesAutoresizingMaskIntoConstraints = false
            hStack.axis = .horizontal
            hStack.spacing = 10
            hStack.alignment = .center

            let img = UIImageView(image: UIImage(systemName: "clock"))
            img.tintColor = UIColor(white: 0.6, alpha: 1.0)
            img.widthAnchor.constraint(equalToConstant: 18).isActive = true
            img.heightAnchor.constraint(equalToConstant: 18).isActive = true
            hStack.addArrangedSubview(img)

            let lbl = UILabel()
            lbl.text = cmd
            lbl.textColor = .white
            lbl.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
            hStack.addArrangedSubview(lbl)

            card.addSubview(hStack)
            NSLayoutConstraint.activate([
                hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
                hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
                hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
                hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8)
            ])

            card.addAction(UIAction(handler: { [weak self] _ in
                UISelectionFeedbackGenerator().selectionChanged()
                self?.onSendKey?("\(cmd)\n")
            }), for: .touchUpInside)

            stack.addArrangedSubview(card)
        }
    }

    // 4. 配色主题页
    private func setupThemesPage() {
        themesView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(themesView)
        pinView(themesView, to: contentView)

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        themesView.addSubview(scroll)
        pinView(scroll, to: themesView)

        let grid = UIStackView()
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.axis = .vertical
        grid.spacing = 12
        grid.isLayoutMarginsRelativeArrangement = true
        grid.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        scroll.addSubview(grid)

        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: scroll.topAnchor),
            grid.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            grid.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            grid.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            grid.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        let themes = [
            ("Classic Dark", UIColor(red: 18/255.0, green: 20/255.0, blue: 30/255.0, alpha: 1.0)),
            ("Tokyo Night", UIColor(red: 26/255.0, green: 27/255.0, blue: 38/255.0, alpha: 1.0)),
            ("Kanagawa Wave", UIColor(red: 31/255.0, green: 31/255.0, blue: 40/255.0, alpha: 1.0)),
            ("Dracula", UIColor(red: 40/255.0, green: 42/255.0, blue: 54/255.0, alpha: 1.0))
        ]

        for t in themes {
            let card = UIButton(type: .system)
            card.backgroundColor = t.1
            card.layer.cornerRadius = 12
            card.layer.cornerCurve = .continuous
            card.layer.borderWidth = 1
            card.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
            card.heightAnchor.constraint(equalToConstant: 54).isActive = true

            let lbl = UILabel()
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.text = t.0
            lbl.textColor = .white
            lbl.font = .systemFont(ofSize: 15, weight: .semibold)
            card.addSubview(lbl)

            NSLayoutConstraint.activate([
                lbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                lbl.centerYAnchor.constraint(equalTo: card.centerYAnchor)
            ])

            card.addAction(UIAction(handler: { [weak self] _ in
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                self?.onSelectTheme?(t.0)
            }), for: .touchUpInside)

            grid.addArrangedSubview(card)
        }
    }

    private func pinView(_ v: UIView, to parent: UIView) {
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: parent.topAnchor),
            v.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            v.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ])
    }
}
