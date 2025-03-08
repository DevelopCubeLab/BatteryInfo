import Foundation
import UIKit

class AllBatteryDataViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    private var tableView = UITableView()
    
    private var batteryInfo: BatteryRAWInfo?
    
    private var isMaskSerialNumber = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            // Fallback on earlier versions
            view.backgroundColor = .white
        }
        
        title = NSLocalizedString("AllData", comment: "")
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadBatteryData()
    }
    
    private func loadBatteryData() {
        guard let batteryInfoDict = getBatteryInfo() as? [String: Any] else {
            print("Failed to fetch battery info")
            return
        }
        batteryInfo = BatteryRAWInfo(dict: batteryInfoDict)
        
        // 防止 ViewController 释放后仍然执行 UI 更新
        DispatchQueue.main.async {
            if self.isViewLoaded && self.view.window != nil {
                // 刷新列表
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - 设置总分组数量
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    // MARK: - 列表总长度
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 2
        case 2: return 3
        case 3:
            if SettingsUtils.instance.getForceShowChargeingData() {
                return 8
            } else if isDeviceCharging() {
                if chargerHaveName() {
                    return 8
                }
                return 2
            } else {
                return 1
            }
        case 4: return 1
        default: return 0
        }
    }
    
    // MARK: - 设置每个分组的顶部标题
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 3 {
            return NSLocalizedString("ChargerInfo", comment: "")
        }
        return nil
    }
    
    // MARK: - 设置每个分组的底部标题 可以为分组设置尾部文本，如果没有尾部可以返回 nil
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        if section == 0 {
            return NSLocalizedString("ManufacturerDataSourceMessage", comment: "")
        } else if section == 3 {
            if chargerHaveName() {
                return NSLocalizedString("ChargerNameInfoFooterMessage", comment: "")
            }
        } else if section == 4 {
            return NSLocalizedString("BatteryDataSourceMessage", comment: "")
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.accessoryType = .none
        cell.textLabel?.numberOfLines = 0 // 允许换行
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                if let serialNumber = batteryInfo?.serialNumber {
                    if isMaskSerialNumber {
                        cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("SerialNumber", comment: ""), BatteryDataController.maskSerialNumber(serialNumber))
                    } else {
                        cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("SerialNumber", comment: ""), serialNumber)
                    }
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("SerialNumber", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 1 {
                if let serialNumber = batteryInfo?.serialNumber {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("BatteryManufacturer", comment: ""), BatteryDataController.getBatteryManufacturer(from: serialNumber))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("BatteryManufacturer", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                if let maximumQmax = batteryInfo?.batteryData?.lifetimeData?.maximumQmax {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("MaximumQmax", comment: ""), String(maximumQmax))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("MaximumQmax", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 1 {
                if let minimumQmax = batteryInfo?.batteryData?.lifetimeData?.minimumQmax {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("MinimumQmax", comment: ""), String(minimumQmax))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("MinimumQmax", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            }
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                if let batteryInstalled = batteryInfo?.batteryInstalled {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("BatteryInstalled", comment: ""), batteryInstalled == 1 ? NSLocalizedString("Yes", comment: "") : NSLocalizedString("No", comment: ""))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("BatteryInstalled", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 1 {
                if let bootVoltage = batteryInfo?.bootVoltage {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("BootVoltage", comment: ""), String(format: "%.2f", Double(bootVoltage) / 1000))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("BootVoltage", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 2 {
                if let limitVoltage = batteryInfo?.chargerData?.vacVoltageLimit {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("LimitVoltage", comment: ""), String(format: "%.2f", Double(limitVoltage) / 1000))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("LimitVoltage", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 3 {
                if let bestAdapterIndex = batteryInfo?.bestAdapterIndex {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("BestAdapterInfo", comment: ""), String(bestAdapterIndex + 1))
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("BestAdapterInfo", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            }
        } else if indexPath.section == 3 {
            if indexPath.row == 0 {
                switch getBatteryState() {
                case.charging: cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("IsCharging", comment: ""), NSLocalizedString("Charging", comment: ""))
                case.unplugged: cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("IsCharging", comment: ""), NSLocalizedString("NotCharging", comment: ""))
                case.full: cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("IsCharging", comment: ""), NSLocalizedString("CharingFull", comment: ""))
                default: cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("IsCharging", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 1 {
                if let description = batteryInfo?.adapterDetails?.description {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargeDescription", comment: ""), description)
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargeDescription", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 2 {
                if let chargerName = batteryInfo?.adapterDetails?.name {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargerName", comment: ""), chargerName)
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargerName", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 3 {
                if let chargerManufacturer = batteryInfo?.adapterDetails?.manufacturer {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargerManufacturer", comment: ""), chargerManufacturer)
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargerManufacturer", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 4 {
                if let chargerModel = batteryInfo?.adapterDetails?.model {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargerModel", comment: ""), chargerModel)
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargerModel", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 5 {
                if let chargerSerialNumber = batteryInfo?.adapterDetails?.serialString {
                    if isMaskSerialNumber {
                        cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("SerialNumber", comment: ""), BatteryDataController.maskSerialNumber(chargerSerialNumber))
                    } else {
                        cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("SerialNumber", comment: ""), chargerSerialNumber)
                    }
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("SerialNumber", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 6 {
                if let chargerHardwareVersion = batteryInfo?.adapterDetails?.hwVersion {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargerHardwareVersion", comment: ""), chargerHardwareVersion)
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargerHardwareVersion", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            } else if indexPath.row == 7 {
                if let chargerFirmwareVersion = batteryInfo?.adapterDetails?.fwVersion {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargerFirmwareVersion", comment: ""), chargerFirmwareVersion)
                } else {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("ChargerFirmwareVersion", comment: ""), NSLocalizedString("Unknown", comment: ""))
                }
            }
        } else if indexPath.section == 4 {
            cell.textLabel?.text = NSLocalizedString("RawData", comment: "")
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
    
    // MARK: - Cell的点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 && indexPath.row == 0 {
            self.isMaskSerialNumber = !isMaskSerialNumber
            tableView.reloadRows(at: [indexPath, IndexPath(row: 5, section: 3)], with: .none)
        } else if indexPath.section == 3 && indexPath.row == 5 {
            self.isMaskSerialNumber = !isMaskSerialNumber
            tableView.reloadRows(at: [indexPath, IndexPath(row: 0, section: 0)], with: .none)
        } else if indexPath.section == 4 {
            let rawDataViewController = RawDataViewController()
            rawDataViewController.hidesBottomBarWhenPushed = true // 隐藏底部导航栏
            self.navigationController?.pushViewController(rawDataViewController, animated: true)
        }
        
        
    }
    
    // 判断充电器是否有厂商信息
    func chargerHaveName() -> Bool {
        return (batteryInfo?.adapterDetails?.name) != nil
    }
}
