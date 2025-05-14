import Foundation
import UIKit

class HistoryStatisticsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("HistoryStatistics", comment: "")
        
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
    
    // MARK: - 列表总长度
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // MARK: - 创建cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.numberOfLines = 0

        do {
            let records = BatteryRecordDatabaseManager.shared.fetchAllRecords()
            guard records.count >= 2 else {
                throw NSError(domain: "BatteryStats", code: 1, userInfo: nil)
            }

            guard let first = records.last, let last = records.first else {
                throw NSError(domain: "BatteryStats", code: 3, userInfo: nil)
            }

            let totalRecords = records.count
            let timeInterval = max(1, last.createDate - first.createDate)
            let days = Double(timeInterval) / 86400.0
            let totalDays = String(Int(days))

            let healthValues = records.map { $0.nominalChargeCapacity ?? 0 }
            guard let minHealth = healthValues.min(), let maxHealth = healthValues.max(), let designCapacity = last.designCapacity else {
                throw NSError(domain: "BatteryStats", code: 2, userInfo: nil)
            }
            
            guard designCapacity != 0 else {
                throw NSError(domain: "BatteryStats", code: 4, userInfo: nil)
            }

            let deltaHealth = Double(minHealth - maxHealth) / Double(designCapacity) * 100
            let deltaCapacity = minHealth - maxHealth
            let deltaCycles = last.cycleCount - first.cycleCount
            let avgCyclePerDay = Double(deltaCycles) / days

            cell.textLabel?.text = String(format: NSLocalizedString("BatteryHistorySummaryContent", comment: ""),
                                          String(totalRecords),
                                          String(totalDays),
                                          String(format: "%.2f", deltaHealth),
                                          String(deltaCapacity),
                                          String(maxHealth),
                                          String(minHealth),
                                          String(deltaCycles),
                                          String(format: "%.2f", avgCyclePerDay)
            )
        } catch {
            cell.textLabel?.text = NSLocalizedString("NotEnoughData", comment: "")
        }

        return cell
    }
    
    // MARK: - Cell的点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let cell = tableView.cellForRow(at: indexPath)
        let text = cell?.textLabel?.text
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let copyAction = UIAction(title: NSLocalizedString("Copy", comment: ""), image: UIImage(systemName: "doc.on.doc")) { _ in
                UIPasteboard.general.string = text
            }
            return UIMenu(title: "", children: [copyAction])
        }
    }
}
