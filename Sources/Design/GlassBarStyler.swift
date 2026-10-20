import UIKit

/// 全局导航栏与标签栏视觉外观中枢。
///
/// 针对最新暗黑模式真机截图（顶部深灰导航栏与纯黑内容产生断崖式巨大横线、大标题折叠消失）的彻底根治：
/// 1. 彻底恢复系统原生纯净通透生命周期：
///    未滚动时（scrollEdgeAppearance）：完全透明！零模糊！零阴影！零横线！零背景！
///    无论在浅色还是深色模式下，从状态栏、大标题【主机】到下方内容是一体化纯粹底色，彻底消灭那条巨大的断层切刀线！
/// 2. 只有当用户用手指滑动卡片向上穿透时（standardAppearance）：
///    才平滑淡入超薄微透材质 (.systemUltraThinMaterial)，配合 .soft 柔和边缘，杜绝任何硬边与分割线！
enum GlassBarStyler {

    static func applyLiquidGlassAppearance() {
        // MARK: - 1. 导航栏外观两态分离

        // 态 A：滚动穿透时的超薄晶莹微透外观 (向上滑动时才唤醒)
        let activeAppearance = UINavigationBarAppearance()
        activeAppearance.configureWithTransparentBackground()
        activeAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        activeAppearance.backgroundColor = .clear
        activeAppearance.shadowColor = .clear
        activeAppearance.shadowImage = UIImage()

        // 态 B：未滚动时的静止绝对纯净外观 (未滑动时必须彻底纯透明！杜绝死斑与断崖切线！)
        let edgeAppearance = UINavigationBarAppearance()
        edgeAppearance.configureWithTransparentBackground()
        edgeAppearance.backgroundEffect = nil
        edgeAppearance.backgroundColor = .clear
        edgeAppearance.shadowColor = .clear
        edgeAppearance.shadowImage = UIImage()

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = activeAppearance
        navBar.compactAppearance = activeAppearance
        navBar.scrollEdgeAppearance = edgeAppearance
        if #available(iOS 15.0, *) {
            navBar.compactScrollEdgeAppearance = edgeAppearance
        }
        navBar.isTranslucent = true
        navBar.tintColor = .systemBlue

        // MARK: - 2. 底部标签栏外观
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        tabAppearance.backgroundColor = .clear
        tabAppearance.shadowColor = .clear
        tabAppearance.shadowImage = UIImage()

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = tabAppearance
        }
        tabBar.isTranslucent = true
        tabBar.tintColor = .systemBlue
    }
}
