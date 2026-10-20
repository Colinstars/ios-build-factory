import UIKit

/// 扩展 UIScrollView / UITableView，应用 iOS 26 专属官方边缘柔和微透渐变效果。
///
/// 官方背景：
/// 在 iOS 26 中，Apple 引入了滚动边缘渐变效果 (Scroll Edge Effect)，默认以 .soft（柔和流动、极度微透自然）呈现；
/// 而在 iOS 27 中，系统为了强制强调对比度，默认将边缘效果收紧为更生硬的边界，甚至带硬边。
/// 苹果官方给出的恢复秘籍正是：
/// - SwiftUI: `.scrollEdgeEffectStyle(.soft, for: .top)`
/// - UIKit: `scrollView.topEdgeEffect?.style = .soft`
extension UIScrollView {

    /// 在 iOS 26+ (含 iOS 27) 激活并恢复 .soft 极度自然透亮的边缘渐变
    func applyLiquidGlassSoftEdgeEffect() {
        if #available(iOS 26.0, *) {
            // 设置顶部边缘为 .soft 柔和渐变
            if let topEffect = self.topEdgeEffect {
                topEffect.style = .soft
            }
            // 底部边缘同样设置为 .soft 柔和渐变
            if let bottomEffect = self.bottomEdgeEffect {
                bottomEffect.style = .soft
            }
        }
    }
}
