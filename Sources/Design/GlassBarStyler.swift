import UIKit

/// 全局导航栏与标签栏视觉外观中枢。
///
/// 严格遵循 Apple 官方文档与 HIG 规范：
/// 1. 彻底消灭顶部生硬的横线 (Hairline Divider)：
///    官方规定：必须同时指定 shadowColor = .clear 并且传入空的 shadowImage = UIImage()，
///    才能在 iOS 26/27 动态对比度提权下 100% 阻断系统的 1px 分割线资产渲染！
/// 2. 恢复 iOS 26 超自然通透质感 (Translucent Liquid Glass feel)：
///    - 静止状态 (scrollEdgeAppearance)：保持 100% 绝对纯净透明 (backgroundEffect = nil)，
///      大标题【主机】和灵动岛下方完全透亮，零死斑、零灰暗白斑！
///    - 滚动穿透状态 (standardAppearance / compactAppearance)：
///      配置 UIBlurEffect(style: .systemUltraThinMaterial) + 零底色，
///      内容滑入导航栏下方时呈现晶莹剔透、呼吸感极强的自然超薄微透折射！
///    - 强制开启 isTranslucent = true，建立物理穿透契约！
enum GlassBarStyler {

    static func applyLiquidGlassAppearance() {
        // MARK: - 1. 导航栏外观两态分离

        // 态 A：滚动穿透时的超薄晶莹微透外观
        let activeAppearance = UINavigationBarAppearance()
        activeAppearance.configureWithTransparentBackground()
        activeAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        activeAppearance.backgroundColor = .clear
        
        // 关键：彻底双重阻断分割横线！
        activeAppearance.shadowColor = .clear
        activeAppearance.shadowImage = UIImage()

        // 态 B：未滚动时的静止绝对纯净外观 (零死斑模糊，零分割线)
        let edgeAppearance = UINavigationBarAppearance()
        edgeAppearance.configureWithTransparentBackground()
        edgeAppearance.backgroundEffect = nil
        edgeAppearance.backgroundColor = .clear
        
        // 关键：未滚动时也坚决杜绝分割横线！
        edgeAppearance.shadowColor = .clear
        edgeAppearance.shadowImage = UIImage()

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = activeAppearance
        navBar.compactAppearance = activeAppearance
        navBar.scrollEdgeAppearance = edgeAppearance
        if #available(iOS 15.0, *) {
            navBar.compactScrollEdgeAppearance = edgeAppearance
        }
        
        // 开启系统级物理通透开关
        navBar.isTranslucent = true
        navBar.tintColor = .systemBlue

        // MARK: - 2. 底部标签栏外观 (同样彻底消除顶部横线，保持纯净通透)
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
