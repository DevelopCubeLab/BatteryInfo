import Foundation

class WidgetBatteryData {
    
    let maximumCapacity: String
    
    let cycleCount: Int
    
    let updateDate: String
    
    let updateTimeStamp: Int
    
    init(maximumCapacity: String, cycleCount: Int, updateDate: String, updateTimeStamp: Int) {
        self.maximumCapacity = maximumCapacity
        self.cycleCount = cycleCount
        self.updateDate = updateDate
        self.updateTimeStamp = updateTimeStamp
    }
    
    init(maximumCapacity: String, cycleCount: Int) { // 新数据的构造方法
        self.maximumCapacity = maximumCapacity
        self.cycleCount = cycleCount
        self.updateDate = WidgetUtils.getCurrentTimeFormatted() // 获取当前的时间当作更新时间
        self.updateTimeStamp = Int(Date().timeIntervalSince1970)
    }
}
