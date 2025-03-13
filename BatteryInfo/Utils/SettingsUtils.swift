import Foundation

class SettingsUtils {
    
    // 单例实例
    static let instance = SettingsUtils()
    
    // 私有的 PlistManagerUtils 实例，用于管理特定的 plist 文件
    private let plistManager: PlistManagerUtils
    
    enum MaximumCapacityAccuracy: Int {
        case Keep = 0       // 保留原始数据
        case Ceiling = 1    // 向上取整
        case Round = 2      // 四舍五入
        case Floor = 3      // 向下取整
    }
    
    enum RecordFrequency: Int {
        case Toogle = 0       // 禁用的时候下面的值变成负数,启用的时候是正数
        case Automatic = 1    // 自动，每天或者电池剩余容量发生变化或者电池循环次数变化时保存
        case DataChanged = 2  // 数据发生改变时记录，电池剩余容量发生变化或者电池循环次数变化时保存
        case EveryDay = 3     // 每天打开App的时候记录
        case Manual = 4       // 手动
    }
    
    private init() {
        // 初始化
        self.plistManager = PlistManagerUtils.instance(for: "Settings")
    }
    
    private func setDefaultSettings() {
        
        if self.plistManager.isPlistExist() {
            return
        }
        
    }
    
    func getAutoRefreshDataView() -> Bool {
        return plistManager.getBool(key: "AutoRefreshDataView", defaultValue: true)
    }
    
    func setAutoRefreshDataView(value: Bool) {
        plistManager.setBool(key: "AutoRefreshDataView", value: value)
        plistManager.apply()
    }
    
    func getForceShowChargeingData() -> Bool {
        return plistManager.getBool(key: "ForceShowChargeingData", defaultValue: false)
    }
    
    func setForceShowChargeingData(value: Bool) {
        plistManager.setBool(key: "ForceShowChargeingData", value: value)
        plistManager.apply()
    }
    
    func getShowSettingsBatteryInfo() -> Bool {
        return plistManager.getBool(key: "ShowSettingsBatteryInfo", defaultValue: false)
    }
    
    func setShowSettingsBatteryInfo(value: Bool) {
        plistManager.setBool(key: "ShowSettingsBatteryInfo", value: value)
        plistManager.apply()
    }
    
    /// 获取健康度准确度设置
    /// - return 返回选项 默认值向上取整，减少用户对电池健康的焦虑 [Doge]
    func getMaximumCapacityAccuracy() -> MaximumCapacityAccuracy {
        let value = plistManager.getInt(key: "MaximumCapacityAccuracy", defaultValue: MaximumCapacityAccuracy.Ceiling.rawValue)
        return MaximumCapacityAccuracy(rawValue: value) ?? MaximumCapacityAccuracy.Ceiling
    }
    
    /// 设置健康度准确度设置
    func setMaximumCapacityAccuracy(value: MaximumCapacityAccuracy) {
        setMaximumCapacityAccuracy(value: value.rawValue)
    }
    
    /// 设置健康度准确度设置
    func setMaximumCapacityAccuracy(value: Int) {
        plistManager.setInt(key: "MaximumCapacityAccuracy", value: value)
        plistManager.apply()
    }
    
    private func getRecordFrequencyRawValue() -> Int {
        return plistManager.getInt(key: "RecordFrequency", defaultValue: RecordFrequency.Automatic.rawValue)
    }
    
    func getEnableRecordBatteryData() -> Bool {
        return getRecordFrequencyRawValue() > 0
    }
    
    // 获取在主界面显示历史记录界面的设置
    func getShowHistoryRecordViewInHomeView() -> Bool {
        return plistManager.getBool(key: "ShowHistoryRecordViewInHomeView", defaultValue: true)
    }
    
    func setShowHistoryRecordViewInHomeView(value: Bool) {
        plistManager.setBool(key: "ShowHistoryRecordViewInHomeView", value: value)
        plistManager.apply()
    }
    
    // 获取是否在历史记录中显示设计容量
    func getRecordShowDesignCapacity() -> Bool {
        return plistManager.getBool(key: "RecordShowDesignCapacity", defaultValue: true)
    }
    
    func setRecordShowDesignCapacity(value: Bool) {
        plistManager.setBool(key: "RecordShowDesignCapacity", value: value)
        plistManager.apply()
    }
    
    /// 获取记录电池记录频率设置
    func getRecordFrequency() -> RecordFrequency {
        var value = getRecordFrequencyRawValue()
        if value == 0 {
            return .Automatic
        }
        if value < 0 { // 判断下是不是关闭记录了
            value = -value
        }
        return RecordFrequency(rawValue: value) ?? RecordFrequency.Automatic
    }
    
    /// 设置记录电池记录频率设置
    func setRecordFrequency(value: RecordFrequency) {
        setRecordFrequency(value: value.rawValue)
    }
    
    /// 设置记录电池记录频率设置
    func setRecordFrequency(value: Int) {
        let originalValue = getRecordFrequencyRawValue() // 获取原始值
        var changedValue = value
        if changedValue > 0 { // 已启用
            if originalValue < 0 { // 如果小于0就是禁用状态下，但是更改了记录频率
                changedValue = -changedValue
            }
        } else { // = 0 就是切换状态,因为提供的参数不可能小于0
            changedValue = -originalValue
        }
        // 保存数据
        plistManager.setInt(key: "RecordFrequency", value: changedValue)
        plistManager.apply()
    }
    
    /// 获取是否启用Widget
    func getEnableWidget() -> Bool {
        if #available(iOS 14.0, *) {
            return plistManager.getBool(key: "EnableWidget", defaultValue: true)
        } else { // iOS 14.0开始才支持Widget
            return false
        }
    }
    
    /// 设置是否启用Widget
    func setEnableWidget(enable: Bool) {
        if #available(iOS 14.0, *) {
            plistManager.setBool(key: "EnableWidget", value: enable)
        } else {
            plistManager.setBool(key: "EnableWidget", value: false)
        }
        plistManager.apply()
    }
    
    /// 获取Widget沙盒的根目录
    func getWidgetSandboxDirectoryPath() -> [String] {
        return plistManager.getArray(key: "WidgetSandboxPath", defaultValue: []) as? [String] ?? []
    }
    
    /// 设置Widget沙盒的根目录
    func setWidgetSandboxDirectoryPath(path: String) {
        plistManager.setString(key: "WidgetSandboxPath", value: path)
        plistManager.apply()
    }
    
    func setWidgetSandboxDirectoryPath(paths: [String]) {
        plistManager.setArray(key: "WidgetSandboxPath", value: paths)
        plistManager.apply()
    }
    
    /// 删除Widget沙盒目录
    func removeWidgetSandboxDirectoryPath() {
        plistManager.remove(key: "WidgetSandboxPath")
        plistManager.apply()
    }
}
