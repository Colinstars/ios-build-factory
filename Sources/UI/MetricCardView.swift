import UIKit

/// 内容层通用分组指标卡片组件 (遵循 HIG 标准材质规范，纯色圆角背板，语义色图标)
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
        valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
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
