import UIKit

/// 100% 对齐 Termius 官方工业级极客暗黑设计规范的全局主题中枢
///
/// 彻底根除“有的灰有的黑”的劣质拼凑感，全仓统一收敛：
/// 1. `pageBackground`: 终极纯正沉浸深蓝黑 (#12141E) - 严禁使用系统默认土灰 systemGroupedBackground！
/// 2. `cardBackground`: 极客卡片微透深色底座 (#1A1C28)
/// 3. `accent`: Termius 官方标志性电光蓝 (#3182F6)
/// 4. `textPrimary`: 纯白文字，`textSecondary`: 优雅浅灰 (#8E92A8)
enum AppTheme {
    /// 页面背景 (Termius 纯深蓝黑)
    static let pageBackground = UIColor(red: 18/255.0, green: 20/255.0, blue: 30/255.0, alpha: 1.0)
    
    /// 悬浮卡片/列表单元格背景
    static let cardBackground = UIColor(red: 26/255.0, green: 28/255.0, blue: 40/255.0, alpha: 1.0)

    /// 次级衬底/输入框/芯片背景
    static let inputBackground = UIColor(red: 34/255.0, green: 37/255.0, blue: 52/255.0, alpha: 1.0)

    /// 统一高亮品牌色 (电光蓝)
    static let accent = UIColor(red: 49/255.0, green: 130/255.0, blue: 246/255.0, alpha: 1.0)

    /// 边框与极细分割线
    static let separator = UIColor(white: 1.0, alpha: 0.08)

    /// 全局应用外观配置 (导航栏与 TabBar 彻底沉浸黑化)
    static func applyGlobalAppearance() {
        // 1. NavigationBar 全黑沉浸外观
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = pageBackground
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = accent

        // 2. TabBar 全黑沉浸外观
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = pageBackground
        tabBarAppearance.shadowColor = separator

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = accent
        UITabBar.appearance().unselectedItemTintColor = UIColor(red: 142/255.0, green: 146/255.0, blue: 168/255.0, alpha: 1.0)
    }
}
