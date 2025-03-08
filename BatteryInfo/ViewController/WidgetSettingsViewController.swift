import Foundation
import UIKit

class WidgetSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var tableView = UITableView()
    
    private let tableTitleList = [nil, NSLocalizedString("WidgetSettings", comment: "")]
    
    private let tableCellList = [[NSLocalizedString("Enable", comment: "启用")], []]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("WidgetSettings", comment: "")
        
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
        }
        
        return cell
    }
    
    @objc func onSwitchChanged(_ sender: UISwitch) {
        if sender.tag == 0 {
            SettingsUtils.instance.setEnableWidget(enable: sender.isOn)
        }
    }
}
