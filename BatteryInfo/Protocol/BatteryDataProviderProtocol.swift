import Foundation

protocol BatteryDataProviderProtocol {
    // 数据提供者的名称
    var providerName: String { get }
    // 获取是否包含设置中的电池健康信息
    var isIncludeSettingsBatteryInfo: Bool { get }
    // 获取电池原始数据
    func fetchBatteryRAWInfo() -> [String: Any]?
    // 获取电池格式化后的数据
    func fetchBatteryInfo() -> BatteryRAWInfo?
}
