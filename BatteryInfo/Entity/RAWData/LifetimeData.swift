import Foundation

// 电池生命周期内数据
struct LifetimeData {
    var averageTemperature: Int?    // 平均温度
    var maximumTemperature: Int?    // 最高温度
    var minimumTemperature: Int?    // 最低温度
    var cycleCountLastQmax: Int?    //
    var maximumChargeCurrent: Int?  // 最大充电电流
    var maximumDischargeCurrent: Int? // 最大放电电流
    var maximumPackVoltage: Int?    // 电池组最高电压
    var minimumPackVoltage: Int?    // 电池组最低电压
    var maximumQmax: Int?           // 最大QMax
    var minimumQmax: Int?           // 最小QMax
    var totalOperatingTime: Int?    // 总工作时间 单位推测是小时
}

extension LifetimeData {
    init(dict: [String: Any]) {
        self.averageTemperature = dict["AverageTemperature"] as? Int
        self.maximumTemperature = dict["MaximumTemperature"] as? Int
        self.minimumTemperature = dict["MinimumTemperature"] as? Int
        self.cycleCountLastQmax = dict["CycleCountLastQmax"] as? Int
        self.maximumChargeCurrent = dict["MaximumChargeCurrent"] as? Int
        self.maximumDischargeCurrent = dict["MaximumDischargeCurrent"] as? Int
        self.maximumPackVoltage = dict["MaximumPackVoltage"] as? Int
        self.minimumPackVoltage = dict["MinimumPackVoltage"] as? Int
        self.maximumQmax = dict["MaximumQmax"] as? Int
        self.minimumQmax = dict["MinimumQmax"] as? Int
        self.totalOperatingTime = dict["TotalOperatingTime"] as? Int
    }
}
