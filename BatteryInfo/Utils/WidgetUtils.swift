import Foundation

class WidgetUtils {
    
    /// 获取当前时间，格式化为 `HH:mm`，自动适配 12/24 小时制
    static func getCurrentTimeFormatted() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current // 自动适配系统语言
        formatter.dateFormat = is24HourFormat() ? "HH:mm" : "hh:mm"
        return formatter.string(from: Date())
    }

    /// 判断当前系统是否使用 24 小时制
    private static func is24HourFormat() -> Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeStyle = .short
        let dateString = formatter.string(from: Date())

        // 如果时间格式包含 AM/PM，则是 12 小时制，否则是 24 小时制
        return !dateString.contains("AM") && !dateString.contains("PM")
    }
}
