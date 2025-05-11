import Foundation
import UIKit

class MainUITabBarController: UITabBarController {
    
    private let homeViewController = HomeViewController()
    private let historyRecordViewController = HistoryRecordViewController()
    private let settingsViewController = SettingsViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            // Fallback on earlier versions
            view.backgroundColor = .white
        }
        
        // 隐藏iPad OS 18开始的顶部TabBar
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            setOverrideTraitCollection(UITraitCollection(horizontalSizeClass: .compact), forChild: self)
        }
        
        homeViewController.tabBarItem = MainUITabBarController.createTabBarItem(title: "Home", image: "house", selectedImage: "house.fill", fallbackImage: "")
        historyRecordViewController.tabBarItem = MainUITabBarController.createTabBarItem(title: "History", image: "list.dash", selectedImage: "list.bullet", fallbackImage: "")
        settingsViewController.tabBarItem = MainUITabBarController.createTabBarItem(title: "Settings", image: "gear", selectedImage: "gear.fill", fallbackImage: "")
        
        updateTabBarControllers(selfLoad: true)
        
        // 监听设置变化，动态更新 tab
        NotificationCenter.default.addObserver(self, selector: #selector(updateTabBarControllers), name: Notification.Name("ShowHistoryViewChanged"), object: nil)
        
    }
    
    static func createTabBarItem(title: String, image: String, selectedImage: String,fallbackImage: String) -> UITabBarItem {
        let localizedTitle = NSLocalizedString(title, comment: "")
        if #available(iOS 13.0, *) {
            return UITabBarItem(title: localizedTitle, image: UIImage(systemName: image), selectedImage: UIImage(systemName: selectedImage))
        } else {
            return UITabBarItem(title: localizedTitle, image: UIImage(named: fallbackImage), selectedImage: UIImage(named: fallbackImage))
        }
    }
    
    @objc private func updateTabBarControllers(selfLoad: Bool) {
        let homeNav = UINavigationController(rootViewController: homeViewController)
        let settingsNav = UINavigationController(rootViewController: settingsViewController)

        var newViewControllers: [UIViewController] = [homeNav]

        if SettingsUtils.instance.getShowHistoryRecordViewInHomeView() {
            let historyNav = UINavigationController(rootViewController: historyRecordViewController)
            newViewControllers.append(historyNav)
        }

        newViewControllers.append(settingsNav)
        
        // 更新 `viewControllers`
        self.viewControllers = newViewControllers
        
        // 判断是否是其他ViewController通过通知的调用
        if !selfLoad {
            selectedIndex = newViewControllers.count == 2 ? 1 : 2
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
