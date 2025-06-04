import Foundation
import UIKit

class LanguageSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var tableView = UITableView()
    
    private let settingsUtils = SettingsUtils.instance
    
    private let tableCellList = [NSLocalizedString("UseSystemLanguage", comment: ""), "English", "简体中文", "Spanish"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("LanguageSettings", comment: "")
        
        // iOS 15 之后的版本使用新的UITableView样式
        if #available(iOS 15.0, *) {
            tableView = UITableView(frame: .zero, style: .insetGrouped)
        } else {
            tableView = UITableView(frame: .zero, style: .grouped)
        }

        // 设置表格视图的代理和数据源
        tableView.delegate = self
        tableView.dataSource = self
        
        // 注册表格单元格
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        // 将表格视图添加到主视图
        view.addSubview(tableView)

        // 设置表格视图的布局
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
    }
    
    // MARK: - 设置总分组数量
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // MARK: - 设置每个分组的Cell数量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableCellList.count
    }
    
    // MARK: - 构造每个Cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        
        cell.textLabel?.text = tableCellList[indexPath.row]
        cell.textLabel?.numberOfLines = 0 // 允许换行
        
        cell.selectionStyle = .default
        if indexPath.row == settingsUtils.getApplicationLanguage().rawValue {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
            
        return cell
    }
    
    // MARK: - Cell的点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 取消之前的选择
        tableView.cellForRow(at: IndexPath(row: settingsUtils.getApplicationLanguage().rawValue, section: indexPath.section))?.accessoryType = .none
        // 保存选项
        settingsUtils.setApplicationLanguage(value: indexPath.row)
        // 设置当前的cell选中状态
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        // 刷新界面显示
        ApplicationLanguageController.loadLanguageFromSettings()
        reloadAppRootView()
        
        // 重新初始化数据提供者，解决语言切换的小bug
        BatteryDataController.configureInstance(provider: IOKitBatteryDataProvider())
    }
    
    func reloadAppRootView() {
        guard let window = UIApplication.shared.windows.first else { return }

        let tabBarController = MainUITabBarController()
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()

        // 切换到设置 tab
        tabBarController.selectedIndex = settingsUtils.getShowHistoryRecordViewInHomeView() ? 2 : 1

        // 在设置导航控制器中重新 push LanguageSettingsViewController
        if let settingsNav = tabBarController.viewControllers?[2] as? UINavigationController {
            
            // 创建一个 SettingsViewController，并设置标题和 tabBarItem
            let settingsVC = SettingsViewController()
            settingsVC.title = NSLocalizedString("Settings", comment: "")
            settingsVC.tabBarItem = MainUITabBarController.createTabBarItem(title: "Settings", image: "gear", selectedImage: "gear.fill", fallbackImage: "")
            
            // 重建栈：Settings → LanguageSettings
            settingsNav.setViewControllers([settingsVC], animated: false)
            
            let languageVC = LanguageSettingsViewController()
            languageVC.hidesBottomBarWhenPushed = true // 隐藏底部导航栏
            settingsNav.pushViewController(languageVC, animated: false)
        }
        
    }
}
