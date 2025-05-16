import Foundation
import WidgetKit

class WidgetController {
    
    // 单例
    static let instance = WidgetController()
    
    private init() {
        //
    }
    
    private let widgetBatteryDataPlistName = "BatteryData"
    
    // 检查当前的Widget的沙盒目录是否正确
    func checkWidgetSandBoxPathExist(widgetSandBoxBasePath: String) -> Bool {
        return FileManager.default.fileExists(atPath: widgetSandBoxBasePath)
    }
    
    // 获取 Widget 的沙盒目录
    func getWidgetSandboxDirectory() -> String? {
        let pluginKitPath = "/var/mobile/Containers/Data/PluginKitPlugin/"
        let fileManager = FileManager.default
        
        do {
            // 遍历 PluginKitPlugin 目录
            let contents = try fileManager.contentsOfDirectory(atPath: pluginKitPath)
            for uuid in contents {
                let widgetPath = pluginKitPath + uuid + "/"
                
                // 检查是否是目标 Widget
                if isTargetWidgetDirectory(widgetPath, bundleID: "com.developlab.BatteryInfo.BatteryInfoWidget") {
                    return widgetPath
                }
            }
        } catch {
            NSLog("Failed to access PluginKitPlugin directory: \(error)")
        }
        
        return nil
    }

    // 检查是否是目标 Widget 目录
    private func isTargetWidgetDirectory(_ path: String, bundleID: String) -> Bool {
        // 通过plist文件中的 Bundle Identifier 识别
        let metadataPlistPath = path + ".com.apple.mobile_container_manager.metadata.plist"
        if FileManager.default.fileExists(atPath: metadataPlistPath) {
            if let metadata = NSDictionary(contentsOfFile: metadataPlistPath),
               let bundleIdentifier = metadata["MCMMetadataIdentifier"] as? String {
//                return bundleIdentifier == "com.developlab.BatteryInfo.BatteryInfoWidget"
//                return bundleIdentifier == "com.icraze.gtatracker"
                return bundleIdentifier == bundleID
            }
        }
        return false
    }
    
    // 给widget用的获取电池数据
    func getWidgetBatteryData() -> WidgetBatteryData {
        
        let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        NSLog("BatteryInfoWidget-----> libraryURL:" + libraryURL.path)
        let preferencesPath = libraryURL.appendingPathComponent("Preferences").path
        NSLog("BatteryInfoWidget-----> preferencesPath:" + preferencesPath)
        let dataManager = PlistManagerUtils.instance(for: widgetBatteryDataPlistName, customPath: preferencesPath)
        
        let maximumCapacity = dataManager.getString(key: "maximumCapacity", defaultValue: "--")
        let cycleCount = dataManager.getInt(key: "cycleCount", defaultValue: 0)
        let updateDate = dataManager.getString(key: "updateDate", defaultValue: NSLocalizedString("NoData", comment: ""))
        let updateTimeStamp = dataManager.getInt(key: "updateTimeStamp", defaultValue: 0)
            
        
        NSLog("BatteryInfoWidget-----> maximumCapacity:" + maximumCapacity)
        NSLog("BatteryInfoWidget-----> cycleCount: \(cycleCount)")
        NSLog("BatteryInfoWidget-----> updateDate:" + updateDate)
        NSLog("BatteryInfoWidget-----> updateTimeStamp: \(updateTimeStamp)")
        
        return WidgetBatteryData(maximumCapacity: maximumCapacity, cycleCount: cycleCount, updateDate: updateDate, updateTimeStamp: updateTimeStamp)
    }
    
    // 给主程序保存电池数据
    func setWidgetBatteryData(batteryData: WidgetBatteryData) {
        
        // 主程序设置的实例
        let settingsUtils = SettingsUtils.instance
        
        if #unavailable(iOS 14.0) { // Widget最低iOS 14.0开始支持
            return
        }
        
        if !settingsUtils.getEnableWidget() { // 先判断下用户是否启用了Widget
            return
        }
        
        let widgetSandBoxBasePath = settingsUtils.getWidgetSandboxDirectoryPath()
        
        if !checkWidgetSandBoxPathExist(widgetSandBoxBasePath: widgetSandBoxBasePath) { // 先检查这个沙盒目录是否存在
            if !reloadWidgetSandboxPathRecord() { // 目录不存在重新刷新，然后再决定是否重新写入
                return
            }
        }
        
        // 构造 Widget 沙盒的 Preferences 目录
        let preferencesPath = widgetSandBoxBasePath + "Library/Preferences"
        let dataManager = PlistManagerUtils.instance(for: widgetBatteryDataPlistName, customPath: preferencesPath)
        
        let previousDataManager = PlistManagerUtils.instance(for: widgetBatteryDataPlistName, customPath: preferencesPath)
        let previousMaximumCapacity = previousDataManager.getString(key: "maximumCapacity", defaultValue: "--")
        let previousCycleCount = previousDataManager.getInt(key: "cycleCount", defaultValue: 0)
        let previousTimestamp = previousDataManager.getInt(key: "updateTimeStamp", defaultValue: 0)
        let currentTimestamp = Int(Date().timeIntervalSince1970)
        
        var shouldWrite = false
        var shouldRefresh = false

        switch settingsUtils.getWidgetRefreshFrequency() {
        case .DataChanged:
            if previousMaximumCapacity != batteryData.maximumCapacity || previousCycleCount != batteryData.cycleCount {
                shouldWrite = true
                shouldRefresh = true
            }

        case .RefreshDataEveryTime:
            shouldWrite = true
            shouldRefresh = true

        case .Manual:
            if previousMaximumCapacity != batteryData.maximumCapacity || previousCycleCount != batteryData.cycleCount {
                shouldWrite = true
                shouldRefresh = false
            }

        case .Fixed5Minutes:
            if currentTimestamp - previousTimestamp >= 300 {
                shouldWrite = true
                shouldRefresh = true
            }
        }

        if shouldWrite {
            dataManager.setString(key: "maximumCapacity", value: batteryData.maximumCapacity)
            dataManager.setInt(key: "cycleCount", value: batteryData.cycleCount)
            dataManager.setString(key: "updateDate", value: batteryData.updateDate)
            dataManager.setInt(key: "updateTimeStamp", value: currentTimestamp)
            dataManager.apply()

            if shouldRefresh {
                WidgetController.instance.refreshWidget()
                NSLog("给Widget数据保存成功,已经刷新Widget")
            } else {
                NSLog("给Widget数据保存成功，但未刷新Widget")
            }
        }
    }
    
    func reloadWidgetSandboxPathRecord() -> Bool {
        
        if #unavailable(iOS 14.0) { // iOS 14.0以下不能用
            return false
        }
        
        // 主程序设置的实例
        let settingsUtils = SettingsUtils.instance
        
        if !settingsUtils.getEnableWidget() { // 先判断下用户是否启用了Widget
            return false
        }
        
        settingsUtils.removeWidgetSandboxDirectoryPath() // 先清除掉目录地址
                
        if let path = getWidgetSandboxDirectory() { // 重新获取Widget沙盒目录
            settingsUtils.setWidgetSandboxDirectoryPath(path: path)
            return true
        } else {
            return false
        }
    }
    
    func setEnableWidget(enable: Bool) -> Bool {
        if #unavailable(iOS 14.0) { // iOS 14.0以下不能用
            return false
        }
        
        // 主程序设置的实例
        let settingsUtils = SettingsUtils.instance
        settingsUtils.setEnableWidget(enable: enable)
        if enable {
            return reloadWidgetSandboxPathRecord()
        } else {
            settingsUtils.removeWidgetSandboxDirectoryPath()
            // TODO 这里别忘删除数据文件
        }
        return true
    }
    
    func refreshWidget() {
        
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            WidgetCenter.shared.reloadTimelines(ofKind: "BatteryInfoWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "BatteryInfoSymbolWidget")
            NSLog("BatteryInfo-----> 已经通知系统刷新Widget")
        }
        
        
    }
}
