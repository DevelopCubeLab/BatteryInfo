import Foundation
import UIKit

class HistoryRecordViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ScrollableToTop {
    
    private var tableView = UITableView()
    
    private var historyDataRecords: [BatteryDataRecord] = []
    
    private var recordShowDesignCapacity = SettingsUtils.instance.getRecordShowDesignCapacity()
    
    private var capacityAccuracy: SettingsUtils.MaximumCapacityAccuracy?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            // Fallback on earlier versions
            view.backgroundColor = .white
        }
        
        title = NSLocalizedString("History", comment: "")
        
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
        // 右上角增加统计按钮
        if SettingsUtils.instance.getEnableHistoryStatistics() {
            if #available(iOS 13.0, *) {
                navigationItem.rightBarButtonItem = UIBarButtonItem(
                    image: UIImage(systemName: "chart.pie"),
                    style: .plain,
                    target: self,
                    action: #selector(onClickStatisticsButton)
                )
            } else {
                navigationItem.rightBarButtonItem = UIBarButtonItem(
                    title: NSLocalizedString("HistoryStatistics", comment: "统计"),
                    style: .plain,
                    target: self,
                    action: #selector(onClickStatisticsButton)
                )
            }
        } else {
            navigationItem.rightBarButtonItem = nil
        }
        
        // 获取容量准确度参数
        self.capacityAccuracy = SettingsUtils.instance.getMaximumCapacityAccuracy()
        // 重新加载历史数据
        loadHistoryDataRecords()
        
        // 防止 ViewController 释放后仍然执行 UI 更新
        DispatchQueue.main.async {
            if self.isViewLoaded && self.view.window != nil {
                self.recordShowDesignCapacity = SettingsUtils.instance.getRecordShowDesignCapacity()
                // 刷新列表
                self.tableView.reloadData()
            }
        }
        
    }
    
    // MARK: - 加载历史数据
    private func loadHistoryDataRecords() {
        historyDataRecords = BatteryRecordDatabaseManager.shared.fetchAllRecords()
    }
    
    // MARK: - 设置总分组数量
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    // MARK: - 列表总长度
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return historyDataRecords.count
        }
        return 1
    }
    
    // MARK: - 设置每个分组的顶部标题
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 && historyDataRecords.count == 0 {
            return NSLocalizedString("NoRecord", comment: "")
        }
        return nil
    }
    
    // MARK: - 创建cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        
        // 防止出现复用bug
        cell.textLabel?.textAlignment = .natural
        
        if indexPath.section == 0 {
            cell.textLabel?.text = NSLocalizedString("ManualAddRecord", comment: "")
            cell.textLabel?.textAlignment = .center
        } else if indexPath.section == 1 {
            let recordData = self.historyDataRecords[indexPath.row]
            
            if let maximumCapacity = recordData.maximumCapacity {
                // 这种情况下应该是用户自己添加的
                cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("MaximumCapacity", comment: ""), String(maximumCapacity)) + "\n" +
                String.localizedStringWithFormat(NSLocalizedString("CycleCount", comment: ""), String(recordData.cycleCount)) + "\n" +
                String.localizedStringWithFormat(NSLocalizedString("RecordCreateDate", comment: ""), BatteryFormatUtils.formatTimestamp(recordData.createDate))
            } else {
                // 自动记录的
                if let nominal = recordData.nominalChargeCapacity, let design = recordData.designCapacity {
                    cell.textLabel?.text = String.localizedStringWithFormat(NSLocalizedString("MaximumCapacity", comment: ""), BatteryFormatUtils.getFormatMaximumCapacity(nominalChargeCapacity: nominal, designCapacity: design, accuracy: capacityAccuracy!)) + "\n" +
                    String.localizedStringWithFormat(NSLocalizedString("CycleCount", comment: ""), String(recordData.cycleCount)) + "\n" +
                    String.localizedStringWithFormat(NSLocalizedString("RemainingCapacity", comment: ""), String(nominal)) + "\n"
                    
                    if self.recordShowDesignCapacity { // 是否显示设计容量
                        cell.textLabel?.text = cell.textLabel?.text?.appending(
                            String.localizedStringWithFormat(NSLocalizedString("DesignCapacity", comment: ""), String(design)) + "\n" +
                            String.localizedStringWithFormat(NSLocalizedString("RecordCreateDate", comment: ""), BatteryFormatUtils.formatTimestamp(recordData.createDate)))
                    } else {
                        cell.textLabel?.text = cell.textLabel?.text?.appending(
                            String.localizedStringWithFormat(NSLocalizedString("RecordCreateDate", comment: ""), BatteryFormatUtils.formatTimestamp(recordData.createDate)))
                    }
                }
                
            }
        }
        
        cell.textLabel?.numberOfLines = 0 // 允许换行
        
        return cell
    }
    
    // MARK: - Cell的点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            
            guard let batteryInfoDict = getBatteryInfo() as? [String: Any] else {
                return
            }
            
            let batteryInfo = BatteryRAWInfo(dict: batteryInfoDict)
            
            // 记录历史数据
            if let cycleCount = batteryInfo.cycleCount, let nominalChargeCapacity = batteryInfo.nominalChargeCapacity, let designCapacity = batteryInfo.designCapacity {
                
                if BatteryDataController.recordBatteryData(manualRecord: true, cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity) {
                    loadHistoryDataRecords()
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
                }
            }
        }
        
    }
    
    // MARK: - iOS 13+ 长按菜单 (UIContextMenuConfiguration)
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if indexPath.section == 1 {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                let editAction = UIAction(title: NSLocalizedString("Copy", comment: ""), image: UIImage(systemName: "doc.on.doc")) { _ in
                    self.copyRecord(forRowAt: indexPath)
                }
                
                let deleteAction = UIAction(title: NSLocalizedString("Delete", comment: ""), image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                    self.deleteRecord(forRowAt: indexPath)
                }
                
                return UIMenu(title: "", children: [editAction, deleteAction])
            }
        }
        return nil
    }
    
    // MARK: - 左侧添加“复制”按钮
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if indexPath.section == 1 {
            let copyAction = UIContextualAction(style: .normal, title: NSLocalizedString("Copy", comment: "")) { (action, view, completionHandler) in
                self.copyRecord(forRowAt: indexPath)
                completionHandler(true)
            }
            copyAction.backgroundColor = .systemBlue // 复制按钮颜色
            
            return UISwipeActionsConfiguration(actions: [copyAction])
        }
        return nil
    }
    
    // MARK: - 让 section = 1 才能删除
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1  // 仅允许 section 1 可以删除
    }
    
    // MARK: - 滑动删除功能
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if editingStyle == .delete {
                deleteRecord(forRowAt: indexPath)
            }
        }
    }
    
    private func copyRecord(forRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        UIPasteboard.general.string = cell?.textLabel?.text
    }
    
    private func deleteRecord(forRowAt indexPath: IndexPath) {
        let alert = UIAlertController(title: NSLocalizedString("DeleteRecordMessage", comment: ""), message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Confirm", comment: ""), style: .default, handler: { _ in
            // 删除记录
            if BatteryRecordDatabaseManager.shared.deleteRecord(byID: self.historyDataRecords[indexPath.row].id) {
                self.loadHistoryDataRecords()
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }))
        present(alert, animated: true)
    }
    
    // 滚动UITableView到顶部
    func scrollToTop() {
        let offset = CGPoint(x: 0, y: -tableView.adjustedContentInset.top)
        tableView.setContentOffset(offset, animated: true)
    }
    
    // 点击历史数据统计按钮
    @objc private func onClickStatisticsButton() {
        let historyStatisticsViewController = HistoryStatisticsViewController()
        historyStatisticsViewController.hidesBottomBarWhenPushed = true // 隐藏底部导航栏
        self.navigationController?.pushViewController(historyStatisticsViewController, animated: true)
    }
}
