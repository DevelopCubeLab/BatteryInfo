import Foundation

class BatteryFormatUtils {
    
    /// 通过配置文件来格式化显示电池的健康度
    static func getFormatMaximumCapacity(nominalChargeCapacity: Int, designCapacity: Int, accuracy: SettingsUtils.MaximumCapacityAccuracy) -> String {
        let rawValue = Double(nominalChargeCapacity) / Double(designCapacity) * 100.0
        
        switch accuracy {
        case .Keep:
            return String(Double(String(format: "%.2f", rawValue)) ?? rawValue)  // 保留两位小数
        case .Ceiling:
            return String(Int(ceil(rawValue)))  // 直接进1，解决用户强迫症问题 [Doge]
        case .Round:
            return String(Int(round(rawValue))) // 四舍五入
        case .Floor:
            return String(Int(floor(rawValue))) // 直接去掉小数
        }
    }
    
    /// 比较是否是同一天
    static func isSameDay(timestamp1: Int, timestamp2: Int) -> Bool {
        let date1 = Date(timeIntervalSince1970: TimeInterval(timestamp1))
        let date2 = Date(timeIntervalSince1970: TimeInterval(timestamp2))

        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    /// 格式化时间
    static func formatTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp)) // 时间戳转换为 Date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium  // 按用户地区自动适配年月日格式
        formatter.timeStyle = .short   // 按用户地区自动适配时分格式
        formatter.locale = Locale.autoupdatingCurrent // 自动适配用户的地区和语言
        
        return formatter.string(from: date)
    }
    
    /// 格式化为仅包含年月日的字符串
    static func formatDateOnly(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp)) // 时间戳转换为 Date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium  // 显示年月日，自动适配用户地区
        formatter.timeStyle = .none    // 不显示时间
        formatter.locale = Locale.autoupdatingCurrent // 自动适配用户的地区和语言

        return formatter.string(from: date)
    }
    
    /// 给序列号打上*号*
    static func maskSerialNumber(_ serial: String) -> String {
        guard serial.count >= 5 else {
            return serial // 如果长度小于 5，则直接返回
        }
        
        let prefix = serial.prefix(5) // 获取前 5 位
        let maskedPart = String(repeating: "*", count: serial.count - 5) // 剩余部分用 * 替代
        
        return prefix + maskedPart
    }
}
