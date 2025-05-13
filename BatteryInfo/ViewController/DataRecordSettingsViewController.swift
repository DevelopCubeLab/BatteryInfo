import Foundation
import UIKit

class DataRecordSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var tableView = UITableView()
    
    private let settingsUtils = SettingsUtils.instance
    
    private let tableTitleList = [nil, NSLocalizedString("RecordFrequencySettings", comment: "记录频率设置"), nil, nil]
    
    private let tableCellList = [[NSLocalizedString("Enable", comment: "启用"), NSLocalizedString("HistoryRecordViewInHomeView", comment: "在主界面显示历史记录界面"), NSLocalizedString("RecordShowDesignCapacity", comment: ""), NSLocalizedString("EnableHistoryStatistics", comment: "")], [NSLocalizedString("Automatic", comment: ""), NSLocalizedString("DataChanged", comment: ""), NSLocalizedString("EveryDay", comment: ""), NSLocalizedString("Manual", comment: "")], [NSLocalizedString("ExportAllRecordsToCSV", comment: "")], [NSLocalizedString("DeleteAllRecords", comment: "")]]
    
    private var reloadMainTabBar = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("DataRecordSettings", comment: "")
        
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
    
    override func viewDidDisappear(_ animated: Bool) {
        if reloadMainTabBar {
            NotificationCenter.default.post(name: Notification.Name("ShowHistoryViewChanged"), object: nil) // 通知主界面更新视图
        }
    }
    
    // MARK: - 设置总分组数量
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableTitleList.count
    }
    
    // MARK: - 设置每个分组的Cell数量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableCellList[section].count
    }
    
    // MARK: - 设置每个分组的顶部标题
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableTitleList[section]
    }
    
    // MARK: - 构造每个Cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        
        cell.textLabel?.text = tableCellList[indexPath.section][indexPath.row]
        cell.textLabel?.numberOfLines = 0 // 允许换行
        
        if indexPath.section == 0 {
            let switchView = UISwitch(frame: .zero)
            switchView.tag = indexPath.row // 设置识别id
            switchView.addTarget(self, action: #selector(self.onSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                switchView.isOn = SettingsUtils.instance.getEnableRecordBatteryData()
            } else if indexPath.row == 1 {
                switchView.isOn = SettingsUtils.instance.getShowHistoryRecordViewInHomeView()
            } else if indexPath.row == 2 {
                switchView.isOn = SettingsUtils.instance.getRecordShowDesignCapacity()
            } else if indexPath.row == 3 {
                switchView.isOn = SettingsUtils.instance.getEnableHistoryStatistics()
            }
        } else if indexPath.section == 1 {
            cell.selectionStyle = .default
            if indexPath.row == (settingsUtils.getRecordFrequency().rawValue - 1) {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else if indexPath.section == 2 {
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = .systemBlue
        } else if indexPath.section == 3 {
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = .systemRed
        }
        
        return cell
    }
    
    // MARK: - Cell的点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            // 取消之前的选择
            tableView.cellForRow(at: IndexPath(row: settingsUtils.getRecordFrequency().rawValue - 1, section: indexPath.section))?.accessoryType = .none
            // 保存选项
            settingsUtils.setRecordFrequency(value: indexPath.row + 1)
            // 设置当前的cell选中状态
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        } else if indexPath.section == 2 {
            // 导出记录为CSV
            if let csvFileURL = BatteryRecordDatabaseManager.shared.exportToCSV() {
                let activityVC = UIActivityViewController(activityItems: [csvFileURL], applicationActivities: nil)
                present(activityVC, animated: true, completion: nil)
            }
        } else if indexPath.section == 3 {
            // 删除全部数据的按钮
            let alert = UIAlertController(
                title: NSLocalizedString("DeleteAllRecordsTitle", comment: "确定要删除所有数据吗？"),
                message: NSLocalizedString("DeleteAllRecordsMessage", comment: "此操作会删除所有历史记录"),
                preferredStyle: .alert
            )

            // "确定" 按钮（红色，左边）
            let deleteAction = UIAlertAction(title: NSLocalizedString("Confirm", comment: ""), style: .destructive) { _ in
                BatteryRecordDatabaseManager.shared.deleteAllRecords()
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
        
        if sender.tag == 0 { // 启用的开关
            settingsUtils.setRecordFrequency(value: .Toggle) // 切换启用的开关
        } else if sender.tag == 1 {
            settingsUtils.setShowHistoryRecordViewInHomeView(value: sender.isOn) // 切换显示在主界面的开关
            reloadMainTabBar = true // 更改刷新标记
        } else if sender.tag == 2 {
            settingsUtils.setRecordShowDesignCapacity(value: sender.isOn) // 切换显示设计容量开关
        } else if sender.tag == 3 {
            settingsUtils.setEnableHistoryStatistics(value: sender.isOn) // 切换启用历史数据统计
        }
    }
    
}
