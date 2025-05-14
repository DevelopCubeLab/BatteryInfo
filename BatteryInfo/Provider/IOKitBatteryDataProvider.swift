import Foundation

class IOKitBatteryDataProvider: BatteryDataProviderProtocol {
    
    
    // 注册数据来源
    let providerName: String = NSLocalizedString("ProviderIOKit", comment: "")
    
    // 获取是否包含设置中的电池健康信息
    let isIncludeSettingsBatteryInfo: Bool = true
    
    // 获取电池数据的原始数据
    func fetchBatteryRAWInfo() -> [String : Any]? {
        return getBatteryInfo() as? [String: Any]
    }
    
    // 获取数据来源
    func fetchBatteryInfo() -> BatteryRAWInfo? {
        guard let batteryInfoDict = fetchBatteryRAWInfo() else {
            print("Failed to fetch IOKit battery info")
            return nil
        }
        // 返回数据
        return BatteryRAWInfo(dict: batteryInfoDict)
    }
    
}

