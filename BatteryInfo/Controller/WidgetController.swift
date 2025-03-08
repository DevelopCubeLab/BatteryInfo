import Foundation

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
                if isTargetWidgetDirectory(widgetPath) {
                    return widgetPath
                }
            }
        } catch {
            NSLog("Failed to access PluginKitPlugin directory: \(error)")
        }
        
        return nil
    }

    // 检查是否是目标 Widget 目录
    private func isTargetWidgetDirectory(_ path: String) -> Bool {
        // 通过plist文件中的 Bundle Identifier 识别
        let metadataPlistPath = path + ".com.apple.mobile_container_manager.metadata.plist"
        if FileManager.default.fileExists(atPath: metadataPlistPath) {
            if let metadata = NSDictionary(contentsOfFile: metadataPlistPath),
               let bundleIdentifier = metadata["MCMMetadataIdentifier"] as? String {
//                return bundleIdentifier == "com.developlab.BatteryInfo.BatteryInfoWidget"
                return bundleIdentifier == "com.icraze.gtatracker" // 这里出现了一个TrollStore的bug，错误的将Widget的沙盒目录指向了这个地方
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
        
        NSLog("BatteryInfoWidget-----> maximumCapacity:" + maximumCapacity)
        NSLog("BatteryInfoWidget-----> cycleCount: \(cycleCount)")
        NSLog("BatteryInfoWidget-----> updateDate:" + updateDate)
        
        return WidgetBatteryData(maximumCapacity: maximumCapacity, cycleCount: cycleCount, updateDate: updateDate)
    }
    
    // 给主程序保存电池数据
    func setWidgetBatteryData(batteryData: WidgetBatteryData) -> Bool {
        
        // 主程序设置的实例
        let settingsUtils = SettingsUtils.instance
        
        if !settingsUtils.getEnableWidget() { // 先判断下用户是否启用了Widget
            return false
        }
        
        let widgetSandBoxBasePath = settingsUtils.getWidgetSandboxDirectoryPath()
        
        if !checkWidgetSandBoxPathExist(widgetSandBoxBasePath: widgetSandBoxBasePath) { // 先检查这个沙盒目录是否存在
            if !reloadWidgetSandboxPathRecord() { // 目录不存在重新刷新，然后再决定是否重新写入
                return false
            }
        }
        
        // 构造 Widget 沙盒的 Preferences 目录
        let preferencesPath = widgetSandBoxBasePath + "Library/Preferences"
        let dataManager = PlistManagerUtils.instance(for: widgetBatteryDataPlistName, customPath: preferencesPath)
        
        dataManager.setString(key: "maximumCapacity", value: batteryData.maximumCapacity)
        dataManager.setInt(key: "cycleCount", value: batteryData.cycleCount)
        dataManager.setString(key: "updateDate", value: batteryData.updateDate)
        dataManager.apply() // 保存到Widget的沙盒目录下
        
        return true
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
        }
        return true
    }
    
}
