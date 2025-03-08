import Foundation

class WidgetBatteryData {
    
    let maximumCapacity: String
    
    let cycleCount: Int
    
    let updateDate: String
    
    init(maximumCapacity: String, cycleCount: Int, updateDate: String) {
        self.maximumCapacity = maximumCapacity
        self.cycleCount = cycleCount
        self.updateDate = updateDate
    }
    
    init(maximumCapacity: String, cycleCount: Int) { // 新数据的构造方法
        self.maximumCapacity = maximumCapacity
        self.cycleCount = cycleCount
        self.updateDate = WidgetUtils.getCurrentTimeFormatted() // 获取当前的时间当作更新时间
    }
}
