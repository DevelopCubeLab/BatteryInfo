import Foundation

class BatteryDataController {

    // MARK: - 单例实现
    private static var instance: BatteryDataController?
    
    private let provider: BatteryDataProviderProtocol
    private var batteryInfo: BatteryRAWInfo?
    
    private let settingsUtils = SettingsUtils.instance
    
    init(provider: BatteryDataProviderProtocol) {
        self.provider = provider
    }
    
    func refreshBatteryInfo() {
        batteryInfo = provider.fetchBatteryInfo()
    }
    
    func getBatteryRAWInfo() -> BatteryRAWInfo? {
        return batteryInfo
    }
    
    static var getInstance: BatteryDataController {
        guard let instance = instance else {
            fatalError("BatteryDataController.shared must be configured before use")
        }
        return instance
    }

    static func configureInstance(provider: BatteryDataProviderProtocol) {
        instance = BatteryDataController(provider: provider)
    }

    static func resetInstance() {
        instance = nil
    }
    
    private func getBatteryBasicInfo() -> InfoItemGroup {
        
        let batteryBasicInfo = InfoItemGroup(id: 0)
        
        // 电池健康度
        if let maximumCapacity = calculateMaximumCapacity() {
            batteryBasicInfo.addItem(InfoItem(id: BatteryInfoItemID.maximumCapacity, text: String.localizedStringWithFormat(NSLocalizedString("MaximumCapacity", comment: ""), String(maximumCapacity))))
        } else {
            batteryBasicInfo.addItem(InfoItem(id: BatteryInfoItemID.maximumCapacity, text: String.localizedStringWithFormat(NSLocalizedString("MaximumCapacity", comment: ""), NSLocalizedString("Unknown", comment: ""))))
        }
        
        return batteryBasicInfo
    }
    
    // 计算电池的健康度
    private func calculateMaximumCapacity() -> String? {
        if let nominal = batteryInfo?.nominalChargeCapacity, let design = batteryInfo?.designCapacity, design > 0 {
            return BatteryFormatUtils.getFormatMaximumCapacity(nominalChargeCapacity: nominal, designCapacity: design, accuracy: settingsUtils.getMaximumCapacityAccuracy())
        } else {
            return nil
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    /// 设置中的电池健康数据
    struct SettingsBatteryData: Codable {
        var cycleCount: Int?
        var maximumCapacityPercent: Int?

        // 自定义 key 对应 JSON 字段
        enum CodingKeys: String, CodingKey {
            case cycleCount = "CycleCount"
            case maximumCapacityPercent = "Maximum Capacity Percent"
        }
    }
    
    // 检查Root权限的方法
    static func checkRunTimePermission() -> Bool {
        guard let batteryInfoDict = getBatteryInfo() as? [String: Any] else {
            print("Failed to fetch battery info")
            return false
        }
        let batteryInfo = BatteryRAWInfo(dict: batteryInfoDict)
        
        // 记录历史数据
        return batteryInfo.cycleCount != nil
    }
    
    // 检查Unsandbox权限的方法
    static func checkInstallPermission() -> Bool {
        let path = "/var/mobile/Library/Preferences"
        let writeable = access(path, W_OK) == 0
        return writeable
    }

    static func getSettingsBatteryInfoData() -> SettingsBatteryData? {

        // 获取当前包内 `SettingsBatteryHelper` 可执行文件的路径
        let executablePath = Bundle.main.url(forAuxiliaryExecutable: "SettingsBatteryHelper")?.path ?? "/"
        
        var stdOut: NSString?
        // 调用 `spawnRoot`
        spawnRoot(executablePath, nil, &stdOut, nil)
        
        if let stdOutString = stdOut as String?, let plistData = stdOutString.data(using: .utf8) {
            do {
                // 使用 Codable 解析 JSON
                let batteryData = try JSONDecoder().decode(SettingsBatteryData.self, from: plistData)
                
                return batteryData
                
            } catch {
                    print("BatteryInfo------> Error converting string to plist: \(error.localizedDescription)")
            }
        
        } else {
            NSLog("BatteryInfo------> RootHelper工作失败")
        }
        return nil
        
    }

    static func recordBatteryData(manualRecord: Bool, cycleCount: Int, nominalChargeCapacity: Int, designCapacity: Int) -> Bool {
        
        let databaseManager = BatteryRecordDatabaseManager.shared
        let settingsUtils = SettingsUtils.instance
        
        // 判断是否开启了记录
        if !settingsUtils.getEnableRecordBatteryData() {
            return true
        }
        
        if manualRecord { // 手动添加一条记录
            return databaseManager.insertRecord(BatteryDataRecord(cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity))
        }
        
        switch settingsUtils.getRecordFrequency() {
        case .Automatic:
            if databaseManager.getRecordCount() == 0 { // 如果数据库还没数据就直接先创建一个
                return databaseManager.insertRecord(BatteryDataRecord(cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity))
            }
            let lastRecord = databaseManager.getLatestRecord()
            if lastRecord != nil {
                if !BatteryFormatUtils.isSameDay(timestamp1: Int(Date().timeIntervalSince1970), timestamp2: Int(lastRecord?.createDate ?? 0)) ||
                    lastRecord?.cycleCount != cycleCount ||
                    lastRecord?.nominalChargeCapacity != nominalChargeCapacity {
                    return databaseManager.insertRecord(BatteryDataRecord(cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity))
                }
            }
            
        case .DataChanged:
            if databaseManager.getRecordCount() == 0 { // 如果数据库还没数据就直接先创建一个
                return databaseManager.insertRecord(BatteryDataRecord(cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity))
            }
            let lastRecord = databaseManager.getLatestRecord()
            if lastRecord != nil {
                if lastRecord?.cycleCount != cycleCount || lastRecord?.nominalChargeCapacity != nominalChargeCapacity {
                    return databaseManager.insertRecord(BatteryDataRecord(cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity))
                }
            }
        case .EveryDay:
            if databaseManager.getRecordCount() == 0 { // 如果数据库还没数据就直接先创建一个
                return databaseManager.insertRecord(BatteryDataRecord(cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity))
            }
            let lastRecord = databaseManager.getLatestRecord()
            if lastRecord != nil {
                if !BatteryFormatUtils.isSameDay(timestamp1: Int(Date().timeIntervalSince1970), timestamp2: Int(lastRecord?.createDate ?? 0)) { // 判断与当前的记录是否是同一天
                    return databaseManager.insertRecord(BatteryDataRecord(cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity))
                }
            }
            
        default: return false
        }
        
        
        return false
    }
    
}
