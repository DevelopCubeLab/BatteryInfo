import Foundation
import UIKit

class AllBatteryDataViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    private var tableView = UITableView()
    
    private var batteryInfoGroups: [InfoItemGroup] = []
    
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

        batteryInfoGroups = BatteryDataController.getInstance.getAllBatteryInfoGroups()
        
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
        return batteryInfoGroups.count + 1
    }
    
    // MARK: - 列表总长度
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < batteryInfoGroups.count {
            return batteryInfoGroups[section].items.count
        } else if section == batteryInfoGroups.count {
            return 1
        } else {
            return 0
        }
    }
    
    // MARK: - 设置每个分组的顶部标题
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < batteryInfoGroups.count {
            return batteryInfoGroups[section].titleText
        }
        return nil
    }
    
    // MARK: - 设置每个分组的底部标题 可以为分组设置尾部文本，如果没有尾部可以返回 nil
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        if section < batteryInfoGroups.count {
            return batteryInfoGroups[section].footerText
        } else if section == batteryInfoGroups.count {
            return String.localizedStringWithFormat(NSLocalizedString("BatteryDataSourceMessage", comment: ""), BatteryDataController.getInstance.getProviderName(), BatteryDataController.getInstance.getFormatUpdateTime())
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.accessoryType = .none
        cell.textLabel?.numberOfLines = 0 // 允许换行
        
        if indexPath.section < batteryInfoGroups.count {
            cell.textLabel?.text = batteryInfoGroups[indexPath.section].items[indexPath.row].text
            cell.tag = batteryInfoGroups[indexPath.section].items[indexPath.row].id
        } else if indexPath.section == batteryInfoGroups.count {
            cell.textLabel?.text = NSLocalizedString("RawData", comment: "")
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
    
    // MARK: - Cell的点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section < batteryInfoGroups.count { // 隐藏序列号的操作
            let cell = tableView.cellForRow(at: indexPath)
            if let id = cell?.tag {
                switch id {
                case BatteryInfoItemID.batterySerialNumber, BatteryInfoItemID.chargerSerialNumber:
                    BatteryDataController.getInstance.toggleMaskSerialNumber()
                    loadBatteryData()
                default:
                    break
                }
            }
        } else if indexPath.section == batteryInfoGroups.count {
            let rawDataViewController = RawDataViewController()
            rawDataViewController.hidesBottomBarWhenPushed = true // 隐藏底部导航栏
            self.navigationController?.pushViewController(rawDataViewController, animated: true)
        }
    }
    
}
