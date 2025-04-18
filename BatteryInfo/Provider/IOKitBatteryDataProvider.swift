import Foundation

class IOKitBatteryDataProvider: BatteryDataProviderProtocol {
    // 注册数据来源
    let providerName: String = "IOKit"
    
    // 获取数据来源
    func fetchBatteryInfo() -> BatteryRAWInfo? {
        guard let batteryInfoDict = getBatteryInfo() as? [String: Any] else {
            print("Failed to fetch IOKit battery info")
            return nil
        }
        // 返回数据
        return BatteryRAWInfo(dict: batteryInfoDict)
    }
    
}

