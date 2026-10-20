import UIKit

/// 全局视觉外观中枢：
/// 统一管理整个 App 顶部的导航栏 (UINavigationBar) 与底部的标签栏 (UITabBar)。
/// 彻底落实 Apple 官方规范：
/// - UIBarAppearance.backgroundEffect 官方类型为 `UIBlurEffect?`
/// - 通过注入 `.systemUltraThinMaterial`（超薄材料），呈现通透且具有物理折射的液态玻璃微透感，
///   内容滚入导航栏或标签栏下方时，呈现透亮、不发灰、绝不发闷的现代 iOS 质感！
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

        // 核心参数：backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        // 这是官方在 UIKit 栏结构中支持的最透薄材质，恢复通透、晶莹的背景微透感！
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)

        // 去除生硬的分隔线，完全依靠材质自身折射形成物理边界
        appearance.shadowColor = .clear
        appearance.backgroundColor = .clear
    }
}
