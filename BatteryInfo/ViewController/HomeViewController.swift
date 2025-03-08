import Foundation
import UIKit
#if canImport(WidgetKit)
//import WidgetKit
//import AppIntents
#endif

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var tableView = UITableView()
    
    private var settingsUtils = SettingsUtils.instance
    
    private var batteryInfo: BatteryRAWInfo?
    private var settingsBatteryInfo: BatteryDataController.SettingsBatteryData?
    
    private var refreshTimer: Timer?
    private var showOSBuildVersion = false
    
    private var allDatainSection = 4
    
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
                let alert = UIAlertController(title: NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("NeedRunTimePremissionMessage", comment: ""), preferredStyle: .alert)
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
        startAutoRefresh() // 页面回来时重新启动定时器
        loadBatteryData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoRefresh() // 页面离开时停止定时器
    }
    
    @objc private  func loadBatteryData() {
        guard let batteryInfoDict = getBatteryInfo() as? [String: Any] else {
            print("Failed to fetch battery info")
            return
        }
        batteryInfo = BatteryRAWInfo(dict: batteryInfoDict)
        
        if settingsUtils.getShowSettingsBatteryInfo() { // 只有启动这个功能的时候才会去获取数据
            settingsBatteryInfo = BatteryDataController.getSettingsBatteryInfoData()
        }
        
        // 记录历史数据和给Widget传递数据
        if let cycleCount = batteryInfo?.cycleCount, let nominalChargeCapacity = batteryInfo?.nominalChargeCapacity, let designCapacity = batteryInfo?.designCapacity, let maximumCapacity = batteryInfo?.maximumCapacity {
            
            if BatteryDataController.recordBatteryData(manualRecord: false, cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity) {
                print("历史记录增加新的记录成功")
            }
            
            if #available(iOS 14.0, *) {
                if WidgetController.instance.setWidgetBatteryData(batteryData: WidgetBatteryData(maximumCapacity: maximumCapacity, cycleCount: cycleCount)) {
//                    WidgetCenter.shared.reloadAllTimelines()
//                    WidgetCenter.shared.reloadTimelines(ofKind: "BatteryInfoWidget")
//                    WidgetCenter.shared.reloadTimelines(ofKind: "BatteryInfoSymbolWidget")
                    NSLog("给Widget数据保存成功,已经刷新Widget")
                } else {
                    NSLog("给Widget数据保存失败")
                }
            }
        }
        
        // 防止 ViewController 释放后仍然执行 UI 更新
        DispatchQueue.main.async {
            if self.isViewLoaded && self.view.window != nil {
                // 刷新列表
//                self.tableView.reloadSections(IndexSet(integer: 1), with: .none)
                self.tableView.reloadData()
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
        if settingsUtils.getShowSettingsBatteryInfo() {
            allDatainSection = 4
            return 5
        } else {
            allDatainSection = 3
            return 4
        }
    }
    
    // MARK: - 列表总长度
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0: // 系统信息
//            if settingsUtils.getShowCPUFrequency() {
//                return 3
//            }
            return 2
        case 1: return 9 // 电池信息
        case 2: // 充电信息
            if settingsUtils.getForceShowChargeingData() {
                return 11
            } else {
                if isDeviceCharging() || isChargeByWatts() {
                    if isNotCharging() { // 判断是否停止充电
                        return 11
                    } else {
                        return 10
                    }
                } else {
                    return 1
                }
            }
        case 3: // 设置中的电池健康信息
//            if settingsUtils.getShowSettingsBatteryInfo() {
//                return 2
//            } else {
//                return 0
//            }
            return 2
        case 4: return 2
        default: return 0
        }
    }
    
    // MARK: - 设置每个分组的顶部标题
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return NSLocalizedString("CFBundleDisplayName", comment: "")
        } else if section == 2 {
            return NSLocalizedString("ChargeInfo", comment: "")
        } else if section == 3 {
            if settingsUtils.getShowSettingsBatteryInfo() {
                return NSLocalizedString("SettingsBatteryInfo", comment: "")
            }
        }
        return nil
    }
    
    // MARK: - 设置每个分组的底部标题 可以为分组设置尾部文本，如果没有尾部可以返回 nil
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        if section == 2 {
            if isDeviceCharging() {
                return NSLocalizedString("ChargeInfoFooterMessage", comment: "")
            }
        } else if section == 3 {
            if settingsUtils.getShowSettingsBatteryInfo() {
                return NSLocalizedString("SettingsBatteryInfoFooterMessage", comment: "")
            } else {
                return NSLocalizedString("BatteryDataSourceMessage", comment: "")
            }
        } else if section == 4 {
            return NSLocalizedString("BatteryDataSourceMessage", comment: "")
        }
        return nil
    }
    
    // MARK: - 创建cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.numberOfLines = 0 // 允许换行
        
        if indexPath.section == 0 {
            if indexPath.row == 0 { // 系统版本号
                if !isRunningOniPadOS() {
                    cell.textLabel?.text = getDeviceName() + " " + getDiskTotalSpace() + " (" + String.localizedStringWithFormat(NSLocalizedString("iOSVersion", comment: ""), UIDevice.current.systemVersion) + ")"
                } else {
                    cell.textLabel?.text = getDeviceName() + " " + getDiskTotalSpace() + " (" + String.localizedStringWithFormat(NSLocalizedString("iPadOSVersion", comment: ""), UIDevice.current.systemVersion) + ")"
                }
                
                if self.showOSBuildVersion {
                    let buildVersion: String = " [" + (getSystemBuildVersion() ?? "") + "]"
                    cell.textLabel?.text = (cell.textLabel?.text)! + buildVersion
                }
                
                if let regionCode = getDeviceRegionCode() {
                    cell.textLabel?.text = (cell.textLabel?.text)! + " " + regionCode
                }
                
            } else if indexPath.row == 1 { // 设备启动时间
                cell.textLabel?.text = getDeviceUptimeUsingSysctl()
            }
        } else if indexPath.section == 1 { // 电池信息
            if indexPath.row == 0 { // 电池健康度
                if let maximumCapacity = batteryInfo?.maximumCapacity {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("MaximumCapacity", comment: ""), String(maximumCapacity))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("MaximumCapacity", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 1 { // 电池循环次数
                if let cycleCount = batteryInfo?.cycleCount {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CycleCount", comment: ""), String(cycleCount))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CycleCount", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 2 { // 电池设计容量
                if let designCapacity = batteryInfo?.designCapacity {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("DesignCapacity", comment: ""), String(designCapacity))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("DesignCapacity", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 3 { // 电池剩余容量
                if let nominalChargeCapacity = batteryInfo?.nominalChargeCapacity {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("RemainingCapacity", comment: ""), String(nominalChargeCapacity))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("RemainingCapacity", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 4 { // 电池当前温度
                if let temperature = batteryInfo?.temperature {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CurrentTemperature", comment: ""), String(format: "%.2f", Double(temperature) / 100.0))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CurrentTemperature", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 5 { // 电池当前电量百分比
                if let currentCapacity = batteryInfo?.currentCapacity {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CurrentCapacity", comment: ""), String(currentCapacity))
                } else if let currentCapacity = getBatteryPercentage() { // 非Root设备使用备用方法
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CurrentCapacity", comment: ""), String(currentCapacity))
                } else { // 还是无法获取到电池百分比就只能返回未知了
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CurrentCapacity", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 6 { // 电池当前实时容量
                if let appleRawCurrentCapacity = batteryInfo?.appleRawCurrentCapacity {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CurrentRAWCapacity", comment: ""), String(appleRawCurrentCapacity))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CurrentRAWCapacity", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 7 { // 电池当前电压
                if let voltage = batteryInfo?.voltage {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CurrentVoltage", comment: ""), String(format: "%.2f", Double(voltage) / 1000))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CurrentVoltage", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 8 { // 电池当前电流
                if let instantAmperage = batteryInfo?.instantAmperage {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("InstantAmperage", comment: ""), String(instantAmperage))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("InstantAmperage", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            }
            
        } else if indexPath.section == 2 {
            if indexPath.row == 0 { // 获取设备是否正在充电/充满
                
                switch getBatteryState() {
                case.charging: cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("IsCharging", comment: ""), NSLocalizedString("Charging", comment: ""))
                case.unplugged: cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("IsCharging", comment: ""), NSLocalizedString("NotCharging", comment: ""))
                case.full: cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("IsCharging", comment: ""), NSLocalizedString("CharingFull", comment: ""))
                default: cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("IsCharging", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
                
//                if let isCharging = batteryInfo?.isCharging {
//                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("IsCharging", comment: ""), isCharging ? NSLocalizedString("Charging", comment: "") : NSLocalizedString("NotCharging", comment: ""))
//                } else { // 如果没有Root权限，就用官方提供的方法来检查设备是否在充电
//                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("IsCharging", comment: ""), isDeviceCharging() ? NSLocalizedString("Charging", comment: "") : NSLocalizedString("NotCharging", comment: ""))
//                }
                
            } else if indexPath.row == 1 { // 充电方式
                if let description = batteryInfo?.adapterDetails?.description {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargeDescription", comment: ""), description)
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargeDescription", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 2 { // 是否是无线充电
                if let isWirelessCharger = batteryInfo?.adapterDetails?.isWireless {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("WirelessCharger", comment: ""), isWirelessCharger ? NSLocalizedString("Yes", comment: "") : NSLocalizedString("No", comment: ""))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("WirelessCharger", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 3 { // 充电最大握手功率
                if let watts = batteryInfo?.adapterDetails?.watts {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("MaximumChargingHandshakeWatts", comment: ""), String(watts))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("MaximumChargingHandshakeWatts", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 4 { // 当前使用的充电握手档位
                if let index = batteryInfo?.adapterDetails?.usbHvcHvcIndex {
                    
                    var currentOption = ""
                    
                    if let usbOption = batteryInfo?.adapterDetails?.usbHvcMenu {
                        
                        if usbOption.count > index { // 协议列表中有当前的档位信息
                            let option = batteryInfo?.adapterDetails?.usbHvcMenu[index]
                            currentOption.append(
                                String.localizedStringWithFormat(
                                    NSLocalizedString("PowerOptionDetail", comment: ""),
                                    option!.index + 1, String(format: "%.2f", Double(option!.maxVoltage) / 1000), String(format: "%.2f", round(Double(option!.maxCurrent) / 1000))
                            ))
                        } else { // 当前协议中没有档位信息
                            if let current = batteryInfo?.adapterDetails?.current, let adapterVoltage = batteryInfo?.adapterDetails?.adapterVoltage {
                                currentOption.append(
                                    String.localizedStringWithFormat(
                                        NSLocalizedString("PowerOptionDetail", comment: ""),
                                        index + 1, String(format: "%.2f", Double(adapterVoltage) / 1000), String(format: "%.2f", round(Double(current) / 1000))
                                ))
                            }
                            
                        }
                        
                    }
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CurrentUseOption", comment: ""), currentOption)
                    
                    
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CurrentUseOption", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 5 { // 充电可用功率档位
                if let usbHvcMenu = batteryInfo?.adapterDetails?.usbHvcMenu {
                    
                    let powerOptions = "\n".appending(usbHvcMenu.map { usbOption in
                        String.localizedStringWithFormat(
                            NSLocalizedString("PowerOptionDetail", comment: ""),
                            usbOption.index + 1, String(format: "%.2f", Double(usbOption.maxVoltage) / 1000), String(format: "%.2f", round(Double(usbOption.maxCurrent) / 1000))
                        )
                    }.joined(separator: "\n"))
                    
                    if usbHvcMenu.count == 0 {
                        cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("PowerOptions", comment: ""), NSLocalizedString("Unknown", comment: ""))
                    } else {
                        cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("PowerOptions", comment: ""), powerOptions)
                    }
                    
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("PowerOptions", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 6 { // 限制电压
                if let limitVoltage = batteryInfo?.chargerData?.vacVoltageLimit {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("LimitVoltage", comment: ""), String(format: "%.2f", Double(limitVoltage) / 1000))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("LimitVoltage", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 7 { // 充电实时电压
                if let voltage = batteryInfo?.chargerData?.chargingVoltage {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargingVoltage", comment: ""), String(format: "%.2f", Double(voltage) / 1000))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargingVoltage", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 8 { // 充电实时电流
                if let current = batteryInfo?.chargerData?.chargingCurrent {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargingCurrent", comment: ""), String(format: "%.2f", Double(current) / 1000))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargingCurrent", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 9 { // 计算的充电功率
                if let current = batteryInfo?.chargerData?.chargingCurrent, let voltage = batteryInfo?.chargerData?.chargingVoltage {
                    let power = (Double(voltage) / 1000) * (Double(current) / 1000)
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CalculatedChargingPower", comment: ""), String(format: "%.2f", power))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CalculatedChargingPower", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 10 {
                if let reason = batteryInfo?.chargerData?.notChargingReason {
                    if reason == 0 { // 电池充电状态正常
                        cell.textLabel?.text = NSLocalizedString("BatteryChargeNormal", comment: "")
                    } else if reason == 1 { // 电池已充满
                        cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("NotChargingReason", comment: ""), NSLocalizedString("BatteryFullyCharged", comment: ""))
                    } else if reason == 128 { // 电池未在充电
                        cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("NotChargingReason", comment: ""), NSLocalizedString("NotCharging", comment: ""))
                    } else if reason == 256 || reason == 272 { // 电池过热
                        cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("NotChargingReason", comment: ""), NSLocalizedString("BatteryOverheating", comment: ""))
                    } else if reason == 1024 || reason == 8192 { // 正在与充电器握手
                        cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("NotChargingReason", comment: ""), NSLocalizedString("NegotiatingWithCharger", comment: ""))
                    } else { // 其他状态还不知道含义，等遇到的时候再加上
                        cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("NotChargingReason", comment: ""), String(reason))
                    }
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("NotChargingReason", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            }
        }
        
        if settingsUtils.getShowSettingsBatteryInfo() {
            if indexPath.section == 3 { // 设置中的电池数据
                if indexPath.row == 0 { // 电池健康度
                    if let maximumCapacity = settingsBatteryInfo?.maximumCapacityPercent {
                        cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("MaximumCapacity", comment: ""), String(maximumCapacity))
                    } else {
                        cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("MaximumCapacity", comment: ""), NSLocalizedString("Unknown", comment: ""))
                    }
                } else if indexPath.row == 1 { // 电池循环次数
                    if let cycleCount = settingsBatteryInfo?.cycleCount {
                        if cycleCount >= 0 {
                            cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CycleCount", comment: ""), String(cycleCount))
                        } else {
                            cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CycleCount", comment: ""), NSLocalizedString("NotIncluded", comment: ""))
                        }
                    } else {
                        cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("CycleCount", comment: ""), NSLocalizedString("Unknown", comment: ""))
                    }
                }
            }
        }
        
        if indexPath.section == allDatainSection {
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
        } else if indexPath.section == allDatainSection {
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
    
    /// 判断是否在充电，用这个方法可以判断MagSafe外接电池
    private func isChargeByWatts() -> Bool {
        if let watts = batteryInfo?.adapterDetails?.watts {
            return watts > 0
        } else {
            return false
        }
    }
    
    /// 判断是否停止充电
    private func isNotCharging() -> Bool {
        if let reason = batteryInfo?.chargerData?.notChargingReason {
            if reason != 0 {
                if let current = batteryInfo?.chargerData?.chargingCurrent {
                    if current == 0 {
                        return true
                    }
                }
                return true
            }
            
        }
        return false
    }

}
