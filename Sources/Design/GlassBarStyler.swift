import UIKit

/// 全局视觉外观中枢：
/// 统一管理整个 App 顶部的导航栏 (UINavigationBar) 与底部的标签栏 (UITabBar)。
/// 彻底落实 Apple 官方规范：
/// - 在 iOS 26+ 下：将 backgroundEffect 设为 UIGlassEffect(style: .clear)，恢复通透纯粹的液态玻璃折射质感！
/// - 在 iOS 18~25 下：采用 .systemUltraThinMaterial 超薄材质，透光通透，绝不发闷！
enum GlassBarStyler {

    static func applyLiquidGlassAppearance() {
        // 1. 导航栏全局通透遮罩
        let navAppearance = UINavigationBarAppearance()
        configureBarAppearance(navAppearance)
        
        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = navAppearance
        navBar.compactAppearance = navAppearance
        navBar.scrollEdgeAppearance = navAppearance

        // 2. 底部标签栏全局通透遮罩
        let tabAppearance = UITabBarAppearance()
        configureBarAppearance(tabAppearance)

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = tabAppearance
        }
    }

    private static func configureBarAppearance(_ appearance: UIBarAppearance) {
        // 先重置为完全透明基底，杜绝传统厚重乳白层
        appearance.configureWithTransparentBackground()

        // 核心参数：直接注入 backgroundEffect！
        if #available(iOS 26.0, *) {
            // iOS 26+ 官方液态玻璃 clear 变体，呈现纯正晶莹通透的折射流动感
            let glass = UIGlassEffect(style: .clear)
            appearance.backgroundEffect = glass
        } else {
            // iOS 18~25 超薄通透材质
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        }

        // 去除生硬的分隔线，完全依靠材质自身折射形成物理边界
        appearance.shadowColor = .clear
        appearance.backgroundColor = .clear
    }
}
