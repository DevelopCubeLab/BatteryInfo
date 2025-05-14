import Foundation

/// 设置中的电池健康数据
struct SettingsBatteryData: Codable {
    var cycleCount: Int?
    var maximumCapacityPercent: Int?

    // 自定义 key 对应 JSON 字段
    enum CodingKeys: String, CodingKey {
        case cycleCount = "CycleCount"
        case maximumCapacityPercent = "Maximum Capacity Percent"
    }
}
