import Foundation
import UIKit

class WorkModeSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var tableView = UITableView()
    
    private let settingsUtils = SettingsUtils.instance
    
    private let canUseIOKit = SettingsUtils.checkInstallPermission()
    
    private let tableCellList = [NSLocalizedString("WorkModeIOKit", comment: ""), NSLocalizedString("WorkModeViaServices", comment: "")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("WorkModeSettings", comment: "")
        
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
    
    // MARK: - 设置每个分组的Cell数量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableCellList.count
    }
    
    // MARK: - 设置每个分组的底部标题 可以为分组设置尾部文本，如果没有尾部可以返回 nil
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString("ComingSoon", comment: "")
    }
    
    // MARK: - 构造每个Cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        
        cell.textLabel?.text = tableCellList[indexPath.row]
        cell.textLabel?.numberOfLines = 0 // 允许换行
        
        cell.selectionStyle = .default
        if indexPath.row == settingsUtils.getApplicationWorkMode().rawValue {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textLabel?.isEnabled = canUseIOKit
                cell.isUserInteractionEnabled = canUseIOKit
            }
        }
        
        // MARK: = TODO 暂时未开发完成服务端，暂时禁止设置
        cell.textLabel?.isEnabled = false
        cell.isUserInteractionEnabled = false
        
        return cell
    }
    
    // MARK: - Cell的点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 && indexPath.row == 0{
            if !canUseIOKit {
                return
            }
        }
        
        // 取消之前的选择
        tableView.cellForRow(at: IndexPath(row: settingsUtils.getApplicationWorkMode().rawValue, section: indexPath.section))?.accessoryType = .none
        // 保存选项
        settingsUtils.setApplicationWorkMode(value: indexPath.row)
        // 设置当前的cell选中状态
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }
}
