import UIKit

/// 扩展 UIScrollView / UITableView，应用 iOS 26 专属官方边缘柔和微透渐变效果。
///
/// 官方规范落地：
/// 在截图对比中：
/// - 左图 (iOS 26 Default): scrollEdgeEffectStyle(.soft, for: .vertical)
/// - 中图 (iOS 27 Default): scrollEdgeEffectStyle(.hard, for: .vertical) <- 用户当前看到的生硬状态！
/// - 右图 (iOS 27 修复后): scrollEdgeEffectStyle(.soft, for: .vertical)
///
/// 必须对纵向的全部边缘 (topEdgeEffect, bottomEdgeEffect, leftEdgeEffect, rightEdgeEffect)
/// 全量赋值为 .soft，同时将 isHidden 设为 false，确保 UIKit 彻底覆盖 iOS 27 的默认 .hard 硬边缘！
extension UIScrollView {

    /// 强制激活 iOS 26 原生全向 .soft 柔和液态流动边缘，彻底消灭 iOS 27 的 .hard 生硬死边
    func applyLiquidGlassSoftEdgeEffect() {
        if #available(iOS 26.0, *) {
            // 顶部与底部边缘效果全部切换为 .soft
            self.topEdgeEffect.style = .soft
            self.bottomEdgeEffect.style = .soft
            self.leftEdgeEffect.style = .soft
            self.rightEdgeEffect.style = .soft

            self.topEdgeEffect.isHidden = false
            self.bottomEdgeEffect.isHidden = false
        }
    }
}
