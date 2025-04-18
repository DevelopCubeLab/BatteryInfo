import Foundation

protocol BatteryDataProviderProtocol {
    // 数据提供者的名称
    var providerName: String { get }
    // 获取电池数据
    func fetchBatteryInfo() -> BatteryRAWInfo?
}
