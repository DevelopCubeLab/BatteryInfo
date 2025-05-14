import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // 设置App语言（必须在加载 UI 之前）
        ApplicationLanguageController.loadLanguageFromSettings()
        
        // 初始化数据提供者
        BatteryDataController.configureInstance(provider: IOKitBatteryDataProvider())
        // 加载root view
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = MainUITabBarController()
        window!.makeKeyAndVisible()
        return true
    }

}
