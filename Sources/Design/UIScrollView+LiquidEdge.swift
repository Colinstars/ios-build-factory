import UIKit

/// 扩展 UIScrollView / UITableView，应用 iOS 26 专属官方边缘柔和微透渐变效果。
///
/// 官方背景：
/// 在 iOS 26 中，Apple 引入了滚动边缘渐变效果 (Scroll Edge Effect)，默认以 .soft（柔和流动、极度微透自然）呈现；
/// 而在 iOS 27 中，系统为了强制强调对比度，默认将边缘效果收紧为更生硬的边界 (hard)。
/// 苹果官方给出的恢复秘籍正是：
/// - SwiftUI: `.scrollEdgeEffectStyle(.soft, for: .top)`
/// - UIKit: `scrollView.topEdgeEffect.style = .soft` (非可选型对象，直接赋值)
extension UIScrollView {

    /// 在 iOS 26+ (含 iOS 27) 激活并恢复 .soft 极度自然透亮的边缘渐变
    func applyLiquidGlassSoftEdgeEffect() {
        if #available(iOS 26.0, *) {
            // topEdgeEffect 与 bottomEdgeEffect 在 iOS 26 SDK 中为非可选型属性
            self.topEdgeEffect.style = .soft
            self.bottomEdgeEffect.style = .soft
        }
    }
}
