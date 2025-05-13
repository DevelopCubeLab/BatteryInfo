import Foundation
import UIKit

class DisplaySettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var tableView = UITableView()
    
    private let settingsUtils = SettingsUtils.instance
    
    private let tableTitleList = [nil, NSLocalizedString("DisplayedHomeGroups", comment: ""), NSLocalizedString("AvailableGroups", comment: ""), nil]
    
    private let tableCellList = [[NSLocalizedString("AutoRefreshDataViewSetting", comment: ""), NSLocalizedString("ForceShowChargingData", comment: ""), NSLocalizedString("ShowSettingsBatteryInfo", comment: ""), NSLocalizedString("UseHistoryRecordToCalculateSettingsBatteryInfoRefreshDate", comment: ""), NSLocalizedString("DoubleClickTabBarButtonToScrollToTop", comment: "")], [], [], [NSLocalizedString("ResetDisplayedHomeGroups", comment: "")]]
    
    private var homeGroupIDs: [Int] = []
    
    private var allGroupIDs: [Int] {
        BatteryInfoGroupID.allCases.map { $0.rawValue }
    }
    
    private var availableGroupIDs: [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("DisplaySettings", comment: "")
        
        // iOS 15 之后的版本使用新的UITableView样式
        if #available(iOS 15.0, *) {
            tableView = UITableView(frame: .zero, style: .insetGrouped)
        } else {
            tableView = UITableView(frame: .zero, style: .grouped)
        }
        
        // 允许UITableView可以编辑
        tableView.isEditing = true
        tableView.allowsSelectionDuringEditing = true

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
        
        reloadGroupIDs()
    }
    
    private func reloadGroupIDs() {
        homeGroupIDs = settingsUtils.getHomeItemGroupSequence()
        availableGroupIDs = allGroupIDs.filter { !homeGroupIDs.contains($0) }
    }
    
    // MARK: - 设置总分组数量
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableTitleList.count
    }
    
    // MARK: - 设置每个分组的Cell数量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 || section == 3 {
            return tableCellList[section].count
        } else if section == 1 {
            return homeGroupIDs.count
        } else if section == 2 {
            return availableGroupIDs.count
        }
        return 0
    }
    
    // MARK: - 设置每个分组的顶部标题
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableTitleList[section]
    }
    
    // MARK: - 设置每个分组的底部标题 可以为分组设置尾部文本，如果没有尾部可以返回 nil
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        if section == 0 {
            return NSLocalizedString("DisplayGeneralSettingsFooterMessage", comment: "")
        } else if section == 1 {
            return NSLocalizedString("DisplayedHomeGroupsFooterMessage", comment: "")
        }
        
        return nil
    }
    
    // MARK: - 构造每个Cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.accessoryView = .none
        cell.selectionStyle = .none
        cell.accessoryView = nil
        
        cell.textLabel?.numberOfLines = 0 // 允许换行
        
        if indexPath.section == 0 {
            cell.textLabel?.text = tableCellList[indexPath.section][indexPath.row]
            
            let switchView = UISwitch(frame: .zero)
            switchView.tag = indexPath.row // 设置识别id
            if indexPath.row == 0 {
                switchView.isOn = SettingsUtils.instance.getAutoRefreshDataView()
            } else if indexPath.row == 1 {
                switchView.isOn = SettingsUtils.instance.getForceShowChargingData()
            } else if indexPath.row == 2 {
                switchView.isOn = SettingsUtils.instance.getShowSettingsBatteryInfo()
            } else if indexPath.row == 3 {
                switchView.isOn = SettingsUtils.instance.getUseHistoryRecordToCalculateSettingsBatteryInfoRefreshDate()
                switchView.isEnabled = SettingsUtils.instance.getEnableRecordBatteryData()
                cell.isUserInteractionEnabled = SettingsUtils.instance.getEnableRecordBatteryData()
            }else if indexPath.row == 4 {
                switchView.isOn = SettingsUtils.instance.getDoubleClickTabBarButtonToScrollToTop()
            }
            switchView.addTarget(self, action: #selector(self.onSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
        } else if indexPath.section == 1 {
            let groupID = homeGroupIDs[indexPath.row]
            cell.textLabel?.text = BatteryInfoGroupName.getName(for: groupID)
            cell.selectionStyle = .none
            cell.accessoryType = .none // explicitly no accessory
        } else if indexPath.section == 2 {
            let groupID = availableGroupIDs[indexPath.row]
            cell.textLabel?.text = BatteryInfoGroupName.getName(for: groupID)
            cell.selectionStyle = .default
            cell.imageView?.tintColor = .systemGreen
            if #available(iOS 13.0, *) {
                cell.imageView?.image = UIImage(systemName: "plus.circle")
            } else {
                cell.imageView?.image = UIImage(named: "plus.circle")
            }
            cell.imageView?.isUserInteractionEnabled = true
            cell.imageView?.tag = groupID
            cell.accessoryView = nil
        } else if indexPath.section == 3 {
            cell.textLabel?.text = tableCellList[indexPath.section][indexPath.row]
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = .systemRed
            cell.selectionStyle = .default
        }
        return cell
    }
    
    // MARK: - Cell的点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 2 { // 将第三组的item添加到第二组
            let selectedID = availableGroupIDs[indexPath.row]
            var updated = homeGroupIDs
            updated.append(selectedID)
            SettingsUtils.instance.setHomeItemGroupSequence(updated) // 保存数据
            reloadGroupIDs() // 刷新数据
            // 来个动画
            let newItemRow = homeGroupIDs.firstIndex(of: selectedID) ?? homeGroupIDs.count - 1
            tableView.beginUpdates()
            tableView.insertRows(at: [IndexPath(row: newItemRow, section: 1)], with: .automatic)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
        } else if indexPath.section == 3 { // 恢复首页信息组显示的默认设置
            // 恢复默认首页排序
            let alert = UIAlertController(
                title: NSLocalizedString("Alert", comment: "确定重置首页显示的信息组吗？"),
                message: NSLocalizedString("ResetDisplayedHomeGroupsMessage", comment: "此操作会重置为默认的首页显示排序"),
                preferredStyle: .alert
            )

            // "确定" 按钮（红色，左边）
            let deleteAction = UIAlertAction(title: NSLocalizedString("Confirm", comment: ""), style: .destructive) { _ in
                self.settingsUtils.resetHomeItemGroupSequence()
                self.reloadGroupIDs()
                self.tableView.reloadData()
            }

            // "取消" 按钮（蓝色，右边）
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)

            // 添加按钮，iOS 会自动按照规范排列
            alert.addAction(deleteAction) // 红色
            alert.addAction(cancelAction) // 蓝色

            // 显示弹窗
            present(alert, animated: true, completion: nil)
        }
    }

    @objc func onSwitchChanged(_ sender: UISwitch) {
        if sender.tag == 0 {
            SettingsUtils.instance.setAutoRefreshDataView(value: sender.isOn)
        } else if sender.tag == 1 {
            SettingsUtils.instance.setForceShowChargingData(value: sender.isOn)
        } else if sender.tag == 2 {
            SettingsUtils.instance.setShowSettingsBatteryInfo(value: sender.isOn)
        } else if sender.tag == 3 {
            SettingsUtils.instance.setUseHistoryRecordToCalculateSettingsBatteryInfoRefreshDate(value: sender.isOn)
        } else if sender.tag == 4 {
            SettingsUtils.instance.setDoubleClickTabBarButtonToScrollToTop(value: sender.isOn)
        }
    }
    
    // MARK: - 只允许第二组编辑
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 {
            // 如果只剩下一个，就不允许编辑
            return homeGroupIDs.count > 1
        }
        return false
    }
    
    // MARK: - 只允许第2组拖动
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    // MARK: - 第二组拖动的范围
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                   toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if (sourceIndexPath.section == 1 || sourceIndexPath.section == 2) && proposedDestinationIndexPath.section == 1 {
            return proposedDestinationIndexPath
        }
        // 强制拖动只允许落在 section 1
        return sourceIndexPath
    }

    // MARK: - 第一组的排序
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard sourceIndexPath.section == 1, destinationIndexPath.section == 1 else { return }
        var updated = homeGroupIDs
        let moved = updated.remove(at: sourceIndexPath.row)
        updated.insert(moved, at: destinationIndexPath.row)
        SettingsUtils.instance.setHomeItemGroupSequence(updated)
        reloadGroupIDs()
        tableView.reloadData()
    }
    
    // MARK: - 允许删除 section 1 的行
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 1 {
            return .delete
        }
        return .none
    }

    // MARK: - 删除行为处理
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.section == 1 {
            var updated = homeGroupIDs
            let removedID = updated.remove(at: indexPath.row)
            SettingsUtils.instance.setHomeItemGroupSequence(updated)

            // Pre-update data source before animation
            homeGroupIDs = updated
            availableGroupIDs = allGroupIDs.filter { !homeGroupIDs.contains($0) }

            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            // Find where to insert the row back into section 2
            if let insertRow = availableGroupIDs.firstIndex(of: removedID) {
                tableView.insertRows(at: [IndexPath(row: insertRow, section: 2)], with: .automatic)
            }
            tableView.endUpdates()
        }
    }
}
