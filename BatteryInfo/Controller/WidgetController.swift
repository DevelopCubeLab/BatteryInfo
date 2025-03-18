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
    func checkWidgetSandBoxPathExist(widgetSandBoxBasePath: [String]) -> Bool {
        for path in widgetSandBoxBasePath {
            if !FileManager.default.fileExists(atPath: path) {
                
                return false
            }
        }
        return true
    }
    
    // 获取 Widget 的沙盒目录
    func getWidgetSandboxDirectory() -> [String] {
        let pluginKitPath = "/var/mobile/Containers/Data/PluginKitPlugin/"
        let fileManager = FileManager.default
        // 这里出现了一个TrollStore的bug，错误的将Widget的沙盒目录指向了这个地方
        let targetBundleIDs = ["com.developlab.BatteryInfo.BatteryInfoWidget", "com.icraze.gtatracker"]
        var matchingPaths: [String] = []
        
        do {
            // 遍历 PluginKitPlugin 目录
            let contents = try fileManager.contentsOfDirectory(atPath: pluginKitPath)
            for uuid in contents {
                let widgetPath = pluginKitPath + uuid + "/"
                
                // 检查是否是目标 Widget
                if isTargetWidgetDirectory(widgetPath, bundleIDs: targetBundleIDs) {
                    matchingPaths.append(widgetPath)
                }
            }
        } catch {
            NSLog("Failed to access PluginKitPlugin directory: \(error)")
        }
        
        // iOS 14 and iOS 17.0 path
        if let bugPath = getWidgetSandboxDirectoryWithBug() {
            matchingPaths.append(bugPath)
        }
        
        return matchingPaths
    }
    
    // iOS 14 和 iOS 17.0会遇到这个问题
    private func getWidgetSandboxDirectoryWithBug() -> String? {
        
        var runWithBugVersion = false
        
        if #available(iOS 14.0, *) {
            if #unavailable(iOS 15.0) {
                print("Running on iOS 14")
                runWithBugVersion = true
            }
        }
        
        if #available(iOS 17.0, *) {
            if #unavailable(iOS 17.1) {
                print("Running on iOS 17.0")
                runWithBugVersion = true
            }
        }
        
        if runWithBugVersion {
            let pluginKitPath = "/var/mobile/Containers/Data/Application/"
            let fileManager = FileManager.default
            
            do {
                // 遍历 PluginKitPlugin 目录
                let contents = try fileManager.contentsOfDirectory(atPath: pluginKitPath)
                for uuid in contents {
                    let widgetPath = pluginKitPath + uuid + "/"
                    
                    // 检查是否是目标 Widget
                    if isTargetWidgetDirectory(widgetPath, bundleID: "com.icraze.gtatracker") {
                        return widgetPath
                    }
                }
            } catch {
                NSLog("Failed to access PluginKitPlugin directory: \(error)")
            }
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
    
    private func isTargetWidgetDirectory(_ path: String, bundleIDs: [String]) -> Bool {
        let metadataPlistPath = path + ".com.apple.mobile_container_manager.metadata.plist"
        if FileManager.default.fileExists(atPath: metadataPlistPath) {
            if let metadata = NSDictionary(contentsOfFile: metadataPlistPath),
               let bundleIdentifier = metadata["MCMMetadataIdentifier"] as? String {
                // 这里出现了一个TrollStore的bug，错误的将Widget的沙盒目录指向了这个地方
                return bundleIDs.contains(bundleIdentifier)
            }
        }
        return false
    }
    
    // 给widget用的获取电池数据
    func getWidgetBatteryData() -> WidgetBatteryData {
        
        // 获取 Library 目录的所有路径
        let libraryURLs = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)

        // 遍历并输出每个路径
        for (index, url) in libraryURLs.enumerated() {
            print("BatteryInfoWidget-----> Library Directory \(index + 1): \(url)")
        }
        
        let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        NSLog("BatteryInfoWidget-----> libraryURL:" + libraryURL.path)
        let preferencesPath = libraryURL.appendingPathComponent("Preferences").path
        NSLog("BatteryInfoWidget-----> preferencesPath:" + preferencesPath)
        let dataManager = PlistManagerUtils.instance(for: widgetBatteryDataPlistName, customPath: preferencesPath)
//        let dataManager = PlistManagerUtils.instance(for: widgetBatteryDataPlistName)
        
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
    func setWidgetBatteryData(batteryData: WidgetBatteryData) -> Bool {
        
        // 主程序设置的实例
        let settingsUtils = SettingsUtils.instance
        
        if !settingsUtils.getEnableWidget() { // 先判断下用户是否启用了Widget
            return false
        }
        NSLog("BatteryInfo-----> 获取Widget沙盒目录")
        let widgetSandBoxBasePaths = settingsUtils.getWidgetSandboxDirectoryPath()
        
        // 检查沙盒目录是否存在
        if !checkWidgetSandBoxPathExist(widgetSandBoxBasePath: widgetSandBoxBasePaths) {
            NSLog("BatteryInfo-----> 开始检测沙盒目录")
            if !reloadWidgetSandboxPathRecord() { // 目录不存在则刷新
                NSLog("BatteryInfo-----> 沙盒目录不存在，已经重建")
                return false
            }
        }
        
        var hasSaved = false // 记录是否成功保存过至少一次数据
        NSLog("BatteryInfo-----> 开始获取数据")
        for widgetSandBoxBasePath in widgetSandBoxBasePaths {
            
            // 构造 Widget 沙盒的 Preferences 目录
            let preferencesPath = widgetSandBoxBasePath + "Library/Preferences"
            let dataManager = PlistManagerUtils.instance(for: widgetBatteryDataPlistName, customPath: preferencesPath)
            NSLog("BatteryInfo-----> 写入目录 \(preferencesPath)")
            // 存储电池数据
            dataManager.setString(key: "maximumCapacity", value: batteryData.maximumCapacity)
            dataManager.setInt(key: "cycleCount", value: batteryData.cycleCount)
            dataManager.setString(key: "updateDate", value: batteryData.updateDate)
            dataManager.setInt(key: "updateTimeStamp", value: batteryData.updateTimeStamp)
            dataManager.apply() // 保存到 Widget 的沙盒目录下
            
            hasSaved = true // 至少成功保存了一次
        }

        return hasSaved
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
        
        let paths = getWidgetSandboxDirectory()  // 重新获取Widget沙盒目录
        
        if !paths.isEmpty {
            settingsUtils.setWidgetSandboxDirectoryPath(paths: paths)
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
