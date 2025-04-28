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
    
    // 计算电池的健康度
    private func calculateMaximumCapacity() -> String? {
        if let nominal = batteryInfo?.nominalChargeCapacity, let design = batteryInfo?.designCapacity, design > 0 {
            return BatteryFormatUtils.getFormatMaximumCapacity(nominalChargeCapacity: nominal, designCapacity: design, accuracy: settingsUtils.getMaximumCapacityAccuracy())
        } else {
            return nil
        }
    }
    
    // 获取电池健康度
    private func getMaximumCapacity() -> InfoItem {
        
        if let maximumCapacity = calculateMaximumCapacity() {
            return InfoItem(
                id: BatteryInfoItemID.maximumCapacity,
                text: String.localizedStringWithFormat(NSLocalizedString("MaximumCapacity", comment: ""), String(maximumCapacity))
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.maximumCapacity,
                text: String.localizedStringWithFormat(NSLocalizedString("MaximumCapacity", comment: ""), NSLocalizedString("Unknown", comment: ""))
             )
        }
    }
    
    // 获取电池循环次数
    private func getCycleCount() -> InfoItem {
        if let cycleCount = batteryInfo?.cycleCount {
            return InfoItem(
                id: BatteryInfoItemID.cycleCount,
                text: String.localizedStringWithFormat(NSLocalizedString("CycleCount", comment: ""), String(cycleCount))
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.cycleCount,
                text: String.localizedStringWithFormat(NSLocalizedString("CycleCount", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取电池设计容量
    private func getDesignCapacity() -> InfoItem {
        if let designCapacity = batteryInfo?.designCapacity {
            return InfoItem(
                id: BatteryInfoItemID.designCapacity,
                text: String.localizedStringWithFormat(NSLocalizedString("DesignCapacity", comment: ""), String(designCapacity))
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.designCapacity,
                text: String.localizedStringWithFormat(NSLocalizedString("DesignCapacity", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取电池剩余容量
    private func getNominalChargeCapacity() -> InfoItem {
        if let nominalChargeCapacity = batteryInfo?.nominalChargeCapacity {
            return InfoItem(
                id: BatteryInfoItemID.nominalChargeCapacity,
                text: String.localizedStringWithFormat(NSLocalizedString("RemainingCapacity", comment: ""), String(nominalChargeCapacity))
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.nominalChargeCapacity,
                text: String.localizedStringWithFormat(NSLocalizedString("RemainingCapacity", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取电池当前温度
    private func getBatteryTemperature() -> InfoItem {
        if let temperature = batteryInfo?.temperature {
            return InfoItem(
                id: BatteryInfoItemID.temperature,
                text: String.localizedStringWithFormat(NSLocalizedString("CurrentTemperature", comment: ""), String(format: "%.2f", Double(temperature) / 100.0))
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.temperature,
                text: String.localizedStringWithFormat(NSLocalizedString("CurrentTemperature", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取电池当前电量百分比
    private func getBatteryCurrentCapacity() -> InfoItem {
        if let currentCapacity = batteryInfo?.currentCapacity {
            return InfoItem(
                id: BatteryInfoItemID.currentCapacity,
                text: String.localizedStringWithFormat(NSLocalizedString("CurrentCapacity", comment: ""), String(currentCapacity))
            )
        } else if let currentCapacity = getBatteryPercentage() { // 非Root设备使用备用方法
            return InfoItem(
                id: BatteryInfoItemID.currentCapacity,
                text: String.localizedStringWithFormat(NSLocalizedString("CurrentCapacity", comment: ""), String(currentCapacity))
            )
        } else { // 还是无法获取到电池百分比就只能返回未知了
            return InfoItem(
                id: BatteryInfoItemID.currentCapacity,
                text: String.localizedStringWithFormat(NSLocalizedString("CurrentCapacity", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取电池当前实时容量
    private func getBatteryCurrentRAWCapacity() -> InfoItem {
        if let appleRawCurrentCapacity = batteryInfo?.appleRawCurrentCapacity {
            return InfoItem(
                id: BatteryInfoItemID.currentRAWCapacity,
                text: String.localizedStringWithFormat(NSLocalizedString("CurrentRAWCapacity", comment: ""), String(appleRawCurrentCapacity))
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.currentRAWCapacity,
                text: String.localizedStringWithFormat(NSLocalizedString("CurrentRAWCapacity", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取电池当前电压
    private func getCurrentVoltage() -> InfoItem {
        if let voltage = batteryInfo?.voltage {
            return InfoItem(
                id: BatteryInfoItemID.currentVoltage,
                text: String.localizedStringWithFormat(NSLocalizedString("CurrentVoltage", comment: ""), String(format: "%.2f", Double(voltage) / 1000))
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.currentVoltage,
                text: String.localizedStringWithFormat(NSLocalizedString("CurrentVoltage", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取电池当前电流
    private func getInstantAmperage() -> InfoItem {
        if let instantAmperage = batteryInfo?.instantAmperage {
            return InfoItem(
                id: BatteryInfoItemID.instantAmperage,
                text: String.localizedStringWithFormat(NSLocalizedString("InstantAmperage", comment: ""), String(instantAmperage))
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.instantAmperage,
                text: String.localizedStringWithFormat(NSLocalizedString("InstantAmperage", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取设备是否正在充电/充满
    private func getBatteryIsCharging() -> InfoItem {
        switch getBatteryState() {
        case.charging:
            return InfoItem(
                id: BatteryInfoItemID.isCharging,
                text: String.localizedStringWithFormat(NSLocalizedString("IsCharging", comment: ""), NSLocalizedString("Charging", comment: ""))
            )
        case.unplugged:
            return InfoItem(
                id: BatteryInfoItemID.isCharging,
                text: String.localizedStringWithFormat(NSLocalizedString("IsCharging", comment: ""), NSLocalizedString("NotCharging", comment: ""))
            )
        case.full:
            return InfoItem(
                id: BatteryInfoItemID.isCharging,
                text: String.localizedStringWithFormat(NSLocalizedString("IsCharging", comment: ""), NSLocalizedString("CharingFull", comment: ""))
            )
        default:
            return InfoItem(
                id: BatteryInfoItemID.isCharging,
                text: String.localizedStringWithFormat(NSLocalizedString("IsCharging", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取充电方式
    private func getBatteryChargeDescription() -> InfoItem {
        if let description = batteryInfo?.adapterDetails?.description {
            return InfoItem(
                id: BatteryInfoItemID.chargeDescription,
                text: String.localizedStringWithFormat(NSLocalizedString("ChargeDescription", comment: ""), description)
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.chargeDescription,
                text: String.localizedStringWithFormat(NSLocalizedString("ChargeDescription", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取是否是无线充电
    private func getIsWirelessCharger() -> InfoItem {
        if let isWirelessCharger = batteryInfo?.adapterDetails?.isWireless {
            return InfoItem(
                id: BatteryInfoItemID.isWirelessCharger,
                text: String.localizedStringWithFormat(NSLocalizedString("WirelessCharger", comment: ""), isWirelessCharger ? NSLocalizedString("Yes", comment: "") : NSLocalizedString("No", comment: ""))
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.isWirelessCharger,
                text: String.localizedStringWithFormat(NSLocalizedString("WirelessCharger", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取充电最大握手功率
    private func getMaximumChargingHandshakeWatts() -> InfoItem {
        if let watts = batteryInfo?.adapterDetails?.watts {
            return InfoItem(
                id: BatteryInfoItemID.maximumChargingHandshakeWatts,
                text: String.localizedStringWithFormat(NSLocalizedString("MaximumChargingHandshakeWatts", comment: ""), String(watts))
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.maximumChargingHandshakeWatts,
                text: String.localizedStringWithFormat(NSLocalizedString("MaximumChargingHandshakeWatts", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 当前使用的充电握手档位
    private func getPowerOptionDetail() -> InfoItem {
        if let index = batteryInfo?.adapterDetails?.usbHvcHvcIndex {
            
            var currentOption = ""
            
            if let usbOption = batteryInfo?.adapterDetails?.usbHvcMenu {
                
                if usbOption.count > index { // 协议列表中有当前的档位信息
                    let option = batteryInfo?.adapterDetails?.usbHvcMenu[index]
                    currentOption.append(
                        String.localizedStringWithFormat(
                            NSLocalizedString("PowerOptionDetail", comment: ""),
                            option!.index + 1, String(format: "%.2f", Double(option!.maxVoltage) / 1000), String(format: "%.2f", round(Double(option!.maxCurrent) / 1000))
                    ))
                } else { // 当前协议中没有档位信息
                    if let current = batteryInfo?.adapterDetails?.current, let adapterVoltage = batteryInfo?.adapterDetails?.adapterVoltage {
                        currentOption.append(
                            String.localizedStringWithFormat(
                                NSLocalizedString("PowerOptionDetail", comment: ""),
                                index + 1, String(format: "%.2f", Double(adapterVoltage) / 1000), String(format: "%.2f", round(Double(current) / 1000))
                        ))
                    }
                    
                }
                
            }
            return InfoItem(
                id: BatteryInfoItemID.powerOptionDetail,
                text: String.localizedStringWithFormat(NSLocalizedString("CurrentUseOption", comment: ""), currentOption)
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.powerOptionDetail,
                text: String.localizedStringWithFormat(NSLocalizedString("CurrentUseOption", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取充电可用功率档位
    private func getPowerOptions() -> InfoItem {
        if let usbHvcMenu = batteryInfo?.adapterDetails?.usbHvcMenu {
            
            let powerOptions = "\n".appending(usbHvcMenu.map { usbOption in
                String.localizedStringWithFormat(
                    NSLocalizedString("PowerOptionDetail", comment: ""),
                    usbOption.index + 1, String(format: "%.2f", Double(usbOption.maxVoltage) / 1000), String(format: "%.2f", round(Double(usbOption.maxCurrent) / 1000))
                )
            }.joined(separator: "\n"))
            
            if usbHvcMenu.count == 0 {
                return InfoItem(
                    id: BatteryInfoItemID.powerOptions,
                    text: String.localizedStringWithFormat(NSLocalizedString("PowerOptions", comment: ""), NSLocalizedString("Unknown", comment: ""))
                )
            } else {
                return InfoItem(
                    id: BatteryInfoItemID.powerOptions,
                    text: String.localizedStringWithFormat(NSLocalizedString("PowerOptions", comment: ""), powerOptions)
                )
            }
        } else {
            return InfoItem(
                id: BatteryInfoItemID.powerOptions,
                text: String.localizedStringWithFormat(NSLocalizedString("PowerOptions", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取充电限制电压
    private func getChargingLimitVoltage() -> InfoItem {
        if let limitVoltage = batteryInfo?.chargerData?.vacVoltageLimit {
            return InfoItem(
                id: BatteryInfoItemID.chargingLimitVoltage,
                text: String.localizedStringWithFormat(NSLocalizedString("LimitVoltage", comment: ""), String(format: "%.2f", Double(limitVoltage) / 1000))
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.chargingLimitVoltage,
                text: String.localizedStringWithFormat(NSLocalizedString("LimitVoltage", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取充电实时电压
    private func getChargingVoltage() -> InfoItem {
        if let voltage = batteryInfo?.chargerData?.chargingVoltage {
            return InfoItem(
                id: BatteryInfoItemID.chargingVoltage,
                text: String.localizedStringWithFormat(NSLocalizedString("ChargingVoltage", comment: ""), String(format: "%.2f", Double(voltage) / 1000))
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.chargingVoltage,
                text: String.localizedStringWithFormat(NSLocalizedString("ChargingVoltage", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取充电实时电流
    private func getChargingCurrent() -> InfoItem {
        if let current = batteryInfo?.chargerData?.chargingCurrent {
            return InfoItem(
                id: BatteryInfoItemID.chargingCurrent,
                text: String.localizedStringWithFormat(NSLocalizedString("ChargingCurrent", comment: ""), String(format: "%.2f", Double(current) / 1000))
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.chargingCurrent,
                text: String.localizedStringWithFormat(NSLocalizedString("ChargingCurrent", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取计算的充电功率
    private func calculatedChargingPower() -> InfoItem {
        if let current = batteryInfo?.chargerData?.chargingCurrent, let voltage = batteryInfo?.chargerData?.chargingVoltage {
            let power = (Double(voltage) / 1000) * (Double(current) / 1000)
            return InfoItem(
                id: BatteryInfoItemID.calculatedChargingPower,
                text: String.localizedStringWithFormat(NSLocalizedString("CalculatedChargingPower", comment: ""), String(format: "%.2f", power))
            )
        } else {
            return InfoItem(
                id: BatteryInfoItemID.calculatedChargingPower,
                text: String.localizedStringWithFormat(NSLocalizedString("CalculatedChargingPower", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取未充电原因
    private func getNotChargingReason() -> InfoItem {
        if let reason = batteryInfo?.chargerData?.notChargingReason {
            if reason == 0 { // 电池充电状态正常
                return InfoItem(
                    id: BatteryInfoItemID.notChargingReason,
                    text: NSLocalizedString("BatteryChargeNormal", comment: "")
                )
            } else if reason == 1 { // 电池已充满
                return InfoItem(
                    id: BatteryInfoItemID.notChargingReason,
                    text: String.localizedStringWithFormat(NSLocalizedString("NotChargingReason", comment: ""), NSLocalizedString("BatteryFullyCharged", comment: ""))
                )
            } else if reason == 128 { // 电池未在充电
                return InfoItem(
                    id: BatteryInfoItemID.notChargingReason,
                    text: String.localizedStringWithFormat(NSLocalizedString("NotChargingReason", comment: ""), NSLocalizedString("NotCharging", comment: ""))
                )
            } else if reason == 256 || reason == 272 { // 电池过热
                return InfoItem(
                    id: BatteryInfoItemID.notChargingReason,
                    text: String.localizedStringWithFormat(NSLocalizedString("NotChargingReason", comment: ""), NSLocalizedString("BatteryOverheating", comment: ""))
                )
            } else if reason == 1024 || reason == 8192 { // 正在与充电器握手
                return InfoItem(
                    id: BatteryInfoItemID.notChargingReason,
                    text: String.localizedStringWithFormat(NSLocalizedString("NotChargingReason", comment: ""), NSLocalizedString("NegotiatingWithCharger", comment: ""))
                )
            } else { // 其他状态还不知道含义，等遇到的时候再加上
                return InfoItem(
                    id: BatteryInfoItemID.notChargingReason,
                    text: String.localizedStringWithFormat(NSLocalizedString("NotChargingReason", comment: ""), String(reason))
                )
            }
        } else {
            return InfoItem(
                id: BatteryInfoItemID.notChargingReason,
                text: String.localizedStringWithFormat(NSLocalizedString("NotChargingReason", comment: ""), NSLocalizedString("Unknown", comment: ""))
            )
        }
    }
    
    // 获取电池基本信息组
    private func getBatteryBasicInfo() -> InfoItemGroup {
        
        let batteryBasicInfo = InfoItemGroup(id: BatteryInfoGroupID.basic)
        // 设置组标题
        batteryBasicInfo.titleText = NSLocalizedString("CFBundleDisplayName", comment: "")
        
        // 电池健康度
        batteryBasicInfo.addItem(getMaximumCapacity())
        // 电池循环次数
        batteryBasicInfo.addItem(getCycleCount())
        // 电池设计容量
        batteryBasicInfo.addItem(getDesignCapacity())
        // 电池剩余容量
        batteryBasicInfo.addItem(getNominalChargeCapacity())
        // 电池当前温度
        batteryBasicInfo.addItem(getBatteryTemperature())
        // 电池当前电量百分比
        batteryBasicInfo.addItem(getBatteryCurrentCapacity())
        // 电池当前实时容量
        batteryBasicInfo.addItem(getBatteryCurrentRAWCapacity())
        // 电池当前电压
        batteryBasicInfo.addItem(getCurrentVoltage())
        // 电池当前电流
        batteryBasicInfo.addItem(getInstantAmperage())
        
        return batteryBasicInfo
    }
    
    private func getChargeInfo() -> InfoItemGroup {
        
        let chargeInfo = InfoItemGroup(id: BatteryInfoGroupID.charge)
        // 分组底部文本
        chargeInfo.footerText = NSLocalizedString("ChargeInfo", comment: "")
        
        // 设备是否正在充电/充满
        chargeInfo.addItem(getBatteryIsCharging())
        
        // 强制显示所有充电数据
        if settingsUtils.getForceShowChargingData() {
            addStandardChargingItems(to: chargeInfo)
            // 添加未充电原因
            chargeInfo.addItem(getNotChargingReason())
            // 返回
            return chargeInfo
        }
        
        // 正常显示逻辑
        if isDeviceCharging() || isChargeByWatts() {
            // 添加充电数据
            addStandardChargingItems(to: chargeInfo)
            if isNotCharging() { // 判断是否停止充电
                // 添加未充电原因
                chargeInfo.addItem(getNotChargingReason())
            }
        }
        
        return chargeInfo
    }
    
    // UI获取数据的方法
    func getGroupedBatteryInfo() -> [InfoItemGroup] {
        let sequence = settingsUtils.getHomeItemGroupSequence()
        var result: [InfoItemGroup] = []
    
        for id in sequence {
            switch id {
            case BatteryInfoGroupID.basic:
                result.append(getBatteryBasicInfo())
            case BatteryInfoGroupID.charge:
                result.append(getChargeInfo())
            case BatteryInfoGroupID.settingsBatteryInfo:
                // 预留占位：未实现，填一个空 group
                result.append(InfoItemGroup(id: BatteryInfoGroupID.settingsBatteryInfo))
            default:
                break
            }
        }
    
        return result
    }
    
    // 辅助方法，减少代码的重复
    private func addStandardChargingItems(to chargeInfo: InfoItemGroup) {
        // 充电方式
        chargeInfo.addItem(getBatteryChargeDescription())
        // 是否是无线充电
        chargeInfo.addItem(getIsWirelessCharger())
        // 充电最大握手功率
        chargeInfo.addItem(getMaximumChargingHandshakeWatts())
        // 当前使用的充电握手档位
        chargeInfo.addItem(getPowerOptionDetail())
        // 充电可用功率档位
        chargeInfo.addItem(getPowerOptions())
        // 充电限制电压
        chargeInfo.addItem(getChargingLimitVoltage())
        // 充电实时电压
        chargeInfo.addItem(getChargingVoltage())
        // 充电实时电流
        chargeInfo.addItem(getChargingCurrent())
        // 计算的充电功率
        chargeInfo.addItem(calculatedChargingPower())
    }
    
    /// 判断是否在充电，用这个方法可以判断MagSafe外接电池
    private func isChargeByWatts() -> Bool {
        if let watts = batteryInfo?.adapterDetails?.watts {
            return watts > 0
        } else {
            return false
        }
    }
    
    /// 判断是否停止充电
    private func isNotCharging() -> Bool {
        if let reason = batteryInfo?.chargerData?.notChargingReason {
            if reason != 0 {
                if let current = batteryInfo?.chargerData?.chargingCurrent {
                    if current == 0 {
                        return true
                    }
                }
                return true
            }
            
        }
        return false
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
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
