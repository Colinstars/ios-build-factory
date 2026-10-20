import UIKit

/// 全局导航栏与标签栏视觉外观中枢。
///
/// 严格遵循 Apple HIG Navigation Bars 官方规范：
/// 1. 未滚动状态 (scrollEdgeAppearance)：
///    必须为绝对纯净透明 (configureWithTransparentBackground)，backgroundEffect 必须为 nil！
///    这样未滚动时大标题【主机】与顶部区域干净纯粹，彻底杜绝灵动岛下方的半死不活模糊白斑/灰斑！
/// 2. 向上滚动状态 (standardAppearance / compactAppearance)：
///    当内容向上滑入导航栏下方时，动态呼出 .systemUltraThinMaterial（超薄透光材质），
///    呈现晶莹通透的液态玻璃微透感，既有遮罩层次，又透光通透！
enum GlassBarStyler {

    static func applyLiquidGlassAppearance() {
        // MARK: - 1. 导航栏外观两态分离

        // 态 A：滚动穿透时的通透遮罩外观
        let activeAppearance = UINavigationBarAppearance()
        activeAppearance.configureWithTransparentBackground()
        activeAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        activeAppearance.shadowColor = .clear
        activeAppearance.backgroundColor = .clear

        // 态 B：未滚动时的静止纯净外观 (绝不添加任何模糊背景，消除灵动岛死斑)
        let edgeAppearance = UINavigationBarAppearance()
        edgeAppearance.configureWithTransparentBackground()
        edgeAppearance.backgroundEffect = nil
        edgeAppearance.shadowColor = .clear
        edgeAppearance.backgroundColor = .clear

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = activeAppearance
        navBar.compactAppearance = activeAppearance
        navBar.scrollEdgeAppearance = edgeAppearance
        navBar.tintColor = .systemBlue

        // MARK: - 2. 底部标签栏外观
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        tabAppearance.shadowColor = .clear
        tabAppearance.backgroundColor = .clear

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = tabAppearance
        }
        tabBar.tintColor = .systemBlue
    }
}
