import UIKit

/// 功能层玻璃容器。
///
/// HIG 约束：Liquid Glass 只能用于**功能层**（控件与导航），不得进入内容层。
/// 因此本类只应挂载在浮动按钮、浮动工具栏、浮层面板之上，
/// 绝不用于列表行、卡片背板、整屏背景。
///
/// iOS 26+ 使用官方 `UIGlassEffect`；
/// iOS 18~25 降级为 `UIBlurEffect(.systemThinMaterial)` + 仿高光描边。
final class GlassSurface: UIView {

    enum Variant {
        case regular
        case clear
    }

    private let effectView = UIVisualEffectView()
    private let highlight = CAGradientLayer()
    private let highlightMask = CAShapeLayer()
    private let cornerRadiusValue: CGFloat

    private(set) var variant: Variant
    private(set) var usesOfficialGlass = false

    init(variant: Variant = .regular, cornerRadius: CGFloat = 20) {
        self.variant = variant
        self.cornerRadiusValue = cornerRadius
        super.init(frame: .zero)
        backgroundColor = .clear
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous

        effectView.frame = bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effectView.layer.cornerRadius = cornerRadius
        effectView.layer.cornerCurve = .continuous
        effectView.clipsToBounds = true
        addSubview(effectView)

        applyEffect()
        installHighlightIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Effect

    private func applyEffect() {
        if #available(iOS 26.0, *) {
            usesOfficialGlass = true
            let style: UIGlassEffect.Style = (variant == .clear) ? .clear : .regular
            let effect = UIGlassEffect(style: style)
            effect.isInteractive = false
            effectView.effect = effect
        } else {
            usesOfficialGlass = false
            effectView.effect = UIBlurEffect(style: .systemThinMaterial)
        }
    }

    /// 官方玻璃自带镜面边光；降级路径手工补一层渐变描边模拟厚度。
    private func installHighlightIfNeeded() {
        guard !usesOfficialGlass else { return }

        highlight.colors = [
            UIColor.white.withAlphaComponent(0.35).cgColor,
            UIColor.white.withAlphaComponent(0.05).cgColor
        ]
        highlight.startPoint = CGPoint(x: 0, y: 0)
        highlight.endPoint = CGPoint(x: 1, y: 1)

        highlightMask.fillColor = UIColor.clear.cgColor
        highlightMask.strokeColor = UIColor.white.cgColor
        highlightMask.lineWidth = 1
        highlight.mask = highlightMask

        layer.addSublayer(highlight)
        updateHighlightPath()
    }

    private func updateHighlightPath() {
        highlight.frame = bounds
        highlightMask.frame = bounds
        let path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: cornerRadiusValue
        )
        highlightMask.path = path.cgPath
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !usesOfficialGlass {
            updateHighlightPath()
        }
    }

    // MARK: - Interactive feedback

    /// 触摸反馈。官方玻璃设 isInteractive 后由系统处理折射；降级路径用缩放 + 提亮模拟。
    func setInteractive(_ interactive: Bool) {
        interactiveEnabled = interactive
        if interactive, #available(iOS 26.0, *) {
            if let effect = effectView.effect as? UIGlassEffect {
                effect.isInteractive = true
            }
        }
    }

    private var interactiveEnabled = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard interactiveEnabled, !usesOfficialGlass else { return }
        UIView.animate(withDuration: 0.12) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            self.alpha = 0.92
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        endFeedback()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        endFeedback()
    }

    private func endFeedback() {
        guard interactiveEnabled, !usesOfficialGlass else { return }
        UIView.animate(withDuration: 0.18) {
            self.transform = .identity
            self.alpha = 1.0
        }
    }
}
