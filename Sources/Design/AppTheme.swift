import UIKit

/// 界面基础主题配置
enum AppTheme {
    /// 页面深暗色背景
    static let pageBackground = UIColor(red: 18/255.0, green: 20/255.0, blue: 30/255.0, alpha: 1.0)
    
    /// 卡片底座背景
    static let cardBackground = UIColor(red: 26/255.0, green: 28/255.0, blue: 40/255.0, alpha: 1.0)

    /// 输入框与操作项背景
    static let inputBackground = UIColor(red: 34/255.0, green: 37/255.0, blue: 52/255.0, alpha: 1.0)

    /// 品牌主高亮色
    static let accent = UIColor(red: 49/255.0, green: 130/255.0, blue: 246/255.0, alpha: 1.0)

    /// 细边框与分割线
    static let separator = UIColor(white: 1.0, alpha: 0.08)

    /// 全局应用外观配置
    static func applyGlobalAppearance() {
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
