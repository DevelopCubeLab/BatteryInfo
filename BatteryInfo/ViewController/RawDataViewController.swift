import UIKit

class RawDataViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var batteryInfo: [(key: String, value: Any)] = []
    private var tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("RawData", comment: "")

        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            // Fallback on earlier versions
            view.backgroundColor = .white
        }
        
        // iOS 15 之后的版本使用新的UITableView样式
        if #available(iOS 15.0, *) {
            tableView = UITableView(frame: .zero, style: .insetGrouped)
        } else {
            tableView = UITableView(frame: .zero, style: .grouped)
        }
        
        // 初始化 UITableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        
        // 添加下拉刷新
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadBatteryInfo), for: .valueChanged)
        tableView.refreshControl = refreshControl

        // 添加右上角刷新按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(reloadBatteryInfo)
        )

        let copyButton = UIButton(type: .system)
        copyButton.setTitle(NSLocalizedString("CopyAllData", comment: ""), for: .normal)
        copyButton.addTarget(self, action: #selector(copyBatteryInfo), for: .touchUpInside)
        copyButton.backgroundColor = .systemBlue
        copyButton.setTitleColor(.white, for: .normal)
        copyButton.layer.cornerRadius = 8
        view.addSubview(copyButton)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        copyButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // TableView 约束
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: copyButton.topAnchor, constant: -10),
            
            // CopyButton 约束
            copyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            copyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            copyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            copyButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        reloadBatteryInfo()
    }
    
    @objc func reloadBatteryInfo() {
        // 获取电池信息
        if let info = fetchBatteryInfo() {
            batteryInfo = info.sorted { $0.key < $1.key } // key按照A->Z进行排序，不然每次进入的数据都是乱的
        }
        
        // 刷新 TableView
        tableView.reloadData()
        
        // 结束下拉刷新动画
        self.tableView.refreshControl?.endRefreshing()
    }

    // 获取电池信息
    func fetchBatteryInfo() -> [String: Any]? {
        return BatteryDataController.getInstance.getBatteryRAWInfo()
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return batteryInfo.count
    }

    // MARK: - 设置每个分组的底部标题 可以为分组设置尾部文本，如果没有尾部可以返回 nil
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return String.localizedStringWithFormat(NSLocalizedString("BatteryDataSourceMessage", comment: ""), BatteryDataController.getInstance.getProviderName(), BatteryDataController.getInstance.getFormatUpdateTime())
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // 直接从有序数组中取值，获取属性名和值
        let item = batteryInfo[indexPath.row]
        let key = item.key
        let value = item.value

        // 配置 Cell
        cell.textLabel?.text = "\"\(key)\": \"\(value)\","
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)

        return cell
    }
    
    // MARK: - Cell的点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    @objc func copyBatteryInfo() {
        // 将电池信息格式化为字符串
        let formattedInfo = batteryInfo.map { "\($0.key): \($0.value)" }.joined(separator: "\n")

        // 复制到剪贴板
        UIPasteboard.general.string = formattedInfo

        // 显示提示
        let alert = UIAlertController(title: NSLocalizedString("CopySuccessful", comment: ""), message: NSLocalizedString("RawDataCopySuccessfulMessage", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}
