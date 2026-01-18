import Foundation
import UIKit

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ScrollableToTop {
    
    private var tableView = UITableView()
    
    private var settingsUtils = SettingsUtils.instance
    
    private var batteryInfoGroups: [InfoItemGroup] = []
    
    private var refreshTimer: Timer?
    private var showOSBuildVersion = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            // Fallback on earlier versions
            view.backgroundColor = .white
        }
        
        title = NSLocalizedString("CFBundleDisplayName", comment: "")
        
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
        
        if !BatteryDataController.checkRunTimePermission() {
            
            if !BatteryDataController.checkInstallPermission() {
                let alert = UIAlertController(title: NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("NeedRunTimePermissionMessage", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel))
                present(alert, animated: true)
                
                return
            } else {
                let alert = UIAlertController(title: NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("TemporaryNotSupportMessage", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel))
                present(alert, animated: true)
                
                return
            }
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startAutoRefresh() // 页面回来时重新启动定时器和刷新界面
        self.loadBatteryData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoRefresh() // 页面离开时停止定时器
    }
    
    @objc private  func loadBatteryData() {
        
        batteryInfoGroups = BatteryDataController.getInstance.getHomeInfoGroups()
        
        // 防止 ViewController 释放后仍然执行 UI 更新
        DispatchQueue.main.async {
            if self.isViewLoaded && self.view.window != nil {
                // 刷新列表
                self.tableView.reloadDataSafely()
            }
        }
    }
    
    private func startAutoRefresh() {
        // 确保旧的定时器被清除，避免重复创建
        stopAutoRefresh()

        if settingsUtils.getAutoRefreshDataView() {
            // 创建新的定时器，每 3 秒刷新一次
            refreshTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(loadBatteryData), userInfo: nil, repeats: true)
        }
    }

    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - 设置总分组数量
    func numberOfSections(in tableView: UITableView) -> Int {
        return batteryInfoGroups.count + 2
    }
    
    // MARK: - 列表总长度
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { // 系统信息
            return 2
        } else if section >= 1 && section <= batteryInfoGroups.count { // batteryInfoGroups 动态数据
            return batteryInfoGroups[section - 1].items.count
        } else if section == batteryInfoGroups.count + 1 { // 最后一组（显示全部数据 / 原始数据）
            return 2
        } else {
            return 0
        }
    }
    
    // MARK: - 设置每个分组的顶部标题
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section >= 1 && section <= batteryInfoGroups.count {
            return batteryInfoGroups[section - 1].titleText
        }
        return nil
    }
    
    // MARK: - 设置每个分组的底部标题 可以为分组设置尾部文本，如果没有尾部可以返回 nil
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        if section >= 1 && section <= batteryInfoGroups.count {
            return batteryInfoGroups[section - 1].footerText
        } else if section == batteryInfoGroups.count + 1 {
            return String.localizedStringWithFormat(NSLocalizedString("BatteryDataSourceMessage", comment: ""), BatteryDataController.getInstance.getProviderName(), BatteryDataController.getInstance.getFormatUpdateTime())
        }
        return nil
    }
    
    // MARK: - 创建cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.numberOfLines = 0 // 允许换行
        
        if indexPath.section == 0 {
            if indexPath.row == 0 { // 系统版本号
                if !SystemInfoUtils.isRunningOniPadOS() {
                    cell.textLabel?.text = SystemInfoUtils.getDeviceName() + " " + SystemInfoUtils.getDiskTotalSpace() + " (" + String.localizedStringWithFormat(NSLocalizedString("iOSVersion", comment: ""), UIDevice.current.systemVersion) + ")"
                } else {
                    cell.textLabel?.text = SystemInfoUtils.getDeviceName() + " " + SystemInfoUtils.getDiskTotalSpace() + " (" + String.localizedStringWithFormat(NSLocalizedString("iPadOSVersion", comment: ""), UIDevice.current.systemVersion) + ")"
                }
                
                if self.showOSBuildVersion {
                    let buildVersion: String = " [" + (SystemInfoUtils.getSystemBuildVersion() ?? "") + "]"
                    cell.textLabel?.text = (cell.textLabel?.text)! + buildVersion
                }
                
                if let regionCode = SystemInfoUtils.getDeviceRegionCode() {
                    cell.textLabel?.text = (cell.textLabel?.text)! + " " + regionCode
                }
                
            } else if indexPath.row == 1 { // 设备启动时间
                cell.textLabel?.text = SystemInfoUtils.getDeviceUptimeUsingSysctl()
            }
        } else if indexPath.section >= 1 && indexPath.section <= batteryInfoGroups.count {
            let groupIndex = indexPath.section - 1
            if groupIndex < batteryInfoGroups.count, indexPath.row < batteryInfoGroups[groupIndex].items.count {
                cell.textLabel?.text = batteryInfoGroups[groupIndex].items[indexPath.row].text
                cell.tag = batteryInfoGroups[groupIndex].items[indexPath.row].id
            }
        } else if indexPath.section == batteryInfoGroups.count + 1 {
            cell.accessoryType = .disclosureIndicator
            if indexPath.row == 0 { // 显示全部数据
                cell.textLabel?.text = NSLocalizedString("AllData", comment: "")
            } else if indexPath.row == 1 { // 显示原始数据
                cell.textLabel?.text = NSLocalizedString("RawData", comment: "")
            }
        }
        return cell
    }
    
    // MARK: - Cell的点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 0 {
            self.showOSBuildVersion = !showOSBuildVersion
            tableView.reloadRows(at: [indexPath], with: .none)
        } else if indexPath.section >= 1 && indexPath.section <= batteryInfoGroups.count {
            if let cell = tableView.cellForRow(at: indexPath), cell.tag != 0 {
                let id = cell.tag
                switch id {
                case BatteryInfoItemID.batterySerialNumber, BatteryInfoItemID.chargerSerialNumber:
                    BatteryDataController.getInstance.toggleMaskSerialNumber()
                    loadBatteryData()
                default:
                    break
                }
            }
        } else if indexPath.section == batteryInfoGroups.count + 1 {
            if indexPath.row == 0 { // 显示全部数据
                let allBatteryDataViewController = AllBatteryDataViewController()
                allBatteryDataViewController.hidesBottomBarWhenPushed = true // 隐藏底部导航栏
                self.navigationController?.pushViewController(allBatteryDataViewController, animated: true)
            } else { // 显示原始数据
                let rawDataViewController = RawDataViewController()
                rawDataViewController.hidesBottomBarWhenPushed = true // 隐藏底部导航栏
                self.navigationController?.pushViewController(rawDataViewController, animated: true)
            }
            
        }
    }
    
    // 滚动UITableView到顶部
    func scrollToTop() {
        let offset = CGPoint(x: 0, y: -tableView.adjustedContentInset.top)
        tableView.setContentOffset(offset, animated: true)
    }

}

// MARK: - Safe reloadData extension
extension UITableView {
    func reloadDataSafely() {
        DispatchQueue.main.async {
            guard self.window != nil else { return }
            self.reloadData()
        }
    }
}
