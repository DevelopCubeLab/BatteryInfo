import Foundation

class BatteryDataRecord {
    
    enum BatteryDataRecordType: Int {
        case Automatic = 0      // 自动记录
        case ManualAdd = 1      // 手动记录，但是数据是API的
        case AutomaticOCR = 2   // 自动记录，是OCR导入的
        case ManualRecord = 3   // 手动记录，但是数据是自己填写的
    }
    
    // 数据库表的
    private let dbTableVersion = 1
    
    // 自增ID
    let id: Int
    
    // 新增UUID
    var uuid: String = UUID().uuidString
    
    // 记录的日期
    let createDate: Int
    
    // 记录的类型
    let recordType: BatteryDataRecordType
    
    // 循环次数
    let cycleCount: Int
    
    // 电池当前容量
    var nominalChargeCapacity: Int?
    
    // 电池设计容量
    var designCapacity: Int?
    
    // 电池健康度
    var maximumCapacity: String?
    
    // 电池最大QMax
    var maximumQMax: Int?
    
    // 电池最小QMax
    var minimumQMax: Int?
    
    // 电池限制电压
    var limitVoltage: Int?
    
    // 数据来源的设备Id
    var originDeviceId: String?
    
    // 数据来源的设备名称
    var originDeviceName: String?

    // 用于新建记录 旧版
    init(cycleCount: Int, nominalChargeCapacity: Int, designCapacity: Int) {
        self.id = 0
        self.createDate = 0
        self.recordType = .Automatic
        self.cycleCount = cycleCount
        self.nominalChargeCapacity = nominalChargeCapacity
        self.designCapacity = designCapacity
    }
    
    init(createDate: Int, cycleCount: Int, nominalChargeCapacity: Int, designCapacity: Int) {
        self.id = 0
        self.createDate = createDate
        self.recordType = .Automatic
        self.cycleCount = cycleCount
        self.nominalChargeCapacity = nominalChargeCapacity
        self.designCapacity = designCapacity
    }
    
    // 用于新建记录 新版
    init(cycleCount: Int, nominalChargeCapacity: Int, designCapacity: Int, maximumQMax: Int, minimumQMax: Int, limitVoltage: Int) {
        self.id = 0
        self.createDate = 0
        self.recordType = .Automatic
        self.cycleCount = cycleCount
        self.nominalChargeCapacity = nominalChargeCapacity
        self.designCapacity = designCapacity
        self.maximumQMax = maximumQMax
        self.minimumQMax = minimumQMax
        self.limitVoltage = limitVoltage
    }
    
    // 用于从数据库还原时
    init(id: Int, uuid: String, createDate: Int, recordType: BatteryDataRecordType, cycleCount: Int, nominalChargeCapacity: Int? = nil, designCapacity: Int? = nil, maximumCapacity: String? = nil, maximumQMax: Int? = nil, minimumQMax: Int? = nil, limitVoltage: Int? = nil, originDeviceId: String? = nil, originDeviceName: String? = nil) {
        self.id = id
        self.uuid = uuid
        self.createDate = createDate
        self.recordType = recordType
        self.cycleCount = cycleCount
        self.nominalChargeCapacity = nominalChargeCapacity
        self.designCapacity = designCapacity
        self.maximumCapacity = maximumCapacity
        self.maximumQMax = maximumQMax
        self.minimumQMax = minimumQMax
        self.limitVoltage = limitVoltage
        self.originDeviceId = originDeviceId
        self.originDeviceName = originDeviceName
    }
}
