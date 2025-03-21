import Foundation
import UIKit

class WidgetSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var tableView = UITableView()
    
    private let tableTitleList = [nil, nil, NSLocalizedString("WidgetSandBoxPath", comment: ""),nil]
    
    private var tableCellList = [
        [NSLocalizedString("Enable", comment: "启用")],
        [NSLocalizedString("FixedTime5Minutes", comment: ""), NSLocalizedString("DataChanged", comment: ""), NSLocalizedString("RefreshDataEveryTime", comment: ""), NSLocalizedString("Manual", comment: "")],
        [NSLocalizedString("ForceRefreshWidget", comment: "")],
        [],
        [NSLocalizedString("ResetWidgetSandBoxPath", comment: "")]
    ]
    
    private let widgetController = WidgetController.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("WidgetSettings", comment: "")
        
        loadWidgetSandboxDirectory()
        
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
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//    }
    
    private func loadWidgetSandboxDirectory() {
        tableCellList[3] = [] // 先清空
        if let widgetSandBoxPath = widgetController.getWidgetSandboxDirectory() {
            tableCellList[3].append(widgetSandBoxPath) // 加载widget的沙盒目录
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
        cell.accessoryView = .none
        cell.selectionStyle = .none
        
        cell.textLabel?.text = tableCellList[indexPath.section][indexPath.row]
        cell.textLabel?.numberOfLines = 0 // 允许换行
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let switchView = UISwitch(frame: .zero)
                switchView.tag = indexPath.row // 设置识别id
                if indexPath.row == 0 {
                    switchView.isOn = SettingsUtils.instance.getEnableWidget()
                }
                switchView.addTarget(self, action: #selector(self.onSwitchChanged(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
            }
        } else if indexPath.section == 2 {
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .default
            cell.textLabel?.textColor = .systemBlue
        } else if indexPath.section == 4 {
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .default
            cell.textLabel?.textColor = .systemRed
        }
        
        return cell
    }
    
    // MARK: - Cell的点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 2 {
            widgetController.refreshWidget()
        } else if indexPath.section == 4 {
            if widgetController.reloadWidgetSandboxPathRecord() {
                loadWidgetSandboxDirectory() // 刷新数据
                tableView.reloadData() // 刷新UI
                NSLog("重置Widget沙盒成功")
            }
        }
    }
    
    @objc func onSwitchChanged(_ sender: UISwitch) {
        if sender.tag == 0 {
            SettingsUtils.instance.setEnableWidget(enable: sender.isOn)
        }
    }
}
