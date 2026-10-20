import UIKit

/// 恢复 Apple 出厂原生的导航栏与标签栏材质。
///
/// 之前「全透、滑动也全透、没有蒙版过渡」的原因：
/// 上一版把外观覆盖全部删掉了，导航栏退回「完全无背景」状态，系统不再绘制
/// 材质蒙版，内容直接从栏下穿过，所以从静止到滑动都是全透。
///
/// 这里不再手搓任何模糊/色块，只用 Apple 自己的 `configureWithDefaultBackground()`：
/// - 材质、明暗、透明度全部由系统按当前底色自适应
/// - 深色模式不会再出现「灰块 vs 纯黑」的断层切线
/// - 内容滑到栏下时呈现系统原生的半透明蒙版过渡
enum NavBarChrome {

    static func apply() {
        // 导航栏：标准的系统自适应材质
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()

        // 唯一的手动干预：去掉那条硬分割线（Apple 允许清除，不影响材质本身）
        navAppearance.shadowColor = .clear

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = navAppearance
        navBar.compactAppearance = navAppearance
        navBar.scrollEdgeAppearance = navAppearance
        if #available(iOS 15.0, *) {
            navBar.compactScrollEdgeAppearance = navAppearance
        }

        // 标签栏：同样使用系统原生材质
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.shadowColor = .clear

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = tabAppearance
        }
    }
}
