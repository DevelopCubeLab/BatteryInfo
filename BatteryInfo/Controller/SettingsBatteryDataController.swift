import Foundation

class SettingsBatteryDataController {

    
    private static var lastUpdate: Date? // 内部缓存，每6小时重新填充一次性电池信息以避免频繁读取
    private static var cachedData: SettingsBatteryData?

    static func getSettingsBatteryInfoData(forceRefresh: Bool = false) -> SettingsBatteryData? {
        // 缓存逻辑：如果在6小时内已有数据且非强制刷新，直接返回缓存
        if let last = lastUpdate, let cached = cachedData,
           !forceRefresh, Date().timeIntervalSince(last) < 6 * 60 * 60 {
            return cached
        }

        // 获取当前包内 `SettingsBatteryHelper` 可执行文件的路径
        let executablePath = Bundle.main.url(forAuxiliaryExecutable: "SettingsBatteryHelper")?.path ?? "/"
        
        var stdOut: NSString?
        // 调用 `spawnRoot`
        spawnRoot(executablePath, nil, &stdOut, nil)
        
        if let stdOutString = stdOut as String?, let plistData = stdOutString.data(using: .utf8) {
            do {
                // 使用 Codable 解析 JSON
                let batteryData = try JSONDecoder().decode(SettingsBatteryData.self, from: plistData)

                // 更新缓存
                lastUpdate = Date()
                cachedData = batteryData
                
                return batteryData
                
            } catch {
                print("BatteryInfo------> Error converting string to plist: \(error.localizedDescription)")
            }
        
        } else {
            NSLog("BatteryInfo------> RootHelper工作失败")
        }
        // 如果失败则返回旧数据（可能为 nil）
        return cachedData
    }

    static func clearCache() {
        lastUpdate = nil
        cachedData = nil
    }
}
