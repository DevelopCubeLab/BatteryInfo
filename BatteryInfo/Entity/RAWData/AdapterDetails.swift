import Foundation

// 适配器详情
struct AdapterDetails {
    var adapterID: Int?
    var adapterVoltage: Int?
    var current: Int?
    var description: String?
    var familyCode: String?
    var isWireless: Bool?
    var pmuConfiguration: Int?
    var sharedSource: Bool?
    var source: Int?
    var usbHvcHvcIndex: Int?
    var usbHvcMenu: [UsbHvcOption] = []
    var voltage: Int?
    var watts: Int?
    var name: String?           // 充电器名字
    var manufacturer: String?   // 充电器的制造厂家
    var model: String?          // 充电器型号
    var serialString: String?   // 充电器的序列号
    var hwVersion: String?      // 充电器的硬件版本
    var fwVersion: String?      // 充电器的软件版本

    // 解析字典数据
    init(dict: [String: Any]) {
        self.adapterID = dict["AdapterID"] as? Int
        self.adapterVoltage = dict["AdapterVoltage"] as? Int
        self.current = dict["Current"] as? Int
        self.description = dict["Description"] as? String
        self.familyCode = dict["FamilyCode"] as? String
        self.isWireless = (dict["IsWireless"] as? Int) == 1
        self.pmuConfiguration = dict["PMUConfiguration"] as? Int
        self.sharedSource = (dict["SharedSource"] as? Int) == 1
        self.source = dict["Source"] as? Int
        self.usbHvcHvcIndex = dict["UsbHvcHvcIndex"] as? Int
        self.voltage = dict["Voltage"] as? Int
        self.watts = dict["Watts"] as? Int
        
        self.name = dict["Name"] as? String
        self.model = dict["Model"] as? String
        self.manufacturer = dict["Manufacturer"] as? String
        self.serialString = dict["SerialString"] as? String
        self.hwVersion = dict["HwVersion"] as? String
        self.fwVersion = dict["FwVersion"] as? String
        
        // 解析 USB HVC 选项
        if let usbHvcMenuArray = dict["UsbHvcMenu"] as? [[String: Any]] {
            self.usbHvcMenu = usbHvcMenuArray.map { UsbHvcOption(dict: $0) }
        }
    }
}

// 适配器的 USB HVC 选项
struct UsbHvcOption {
    var index: Int
    var maxCurrent: Int
    var maxVoltage: Int
}

extension UsbHvcOption {
    init(dict: [String: Any]) {
        self.index = dict["Index"] as? Int ?? 0
        self.maxCurrent = dict["MaxCurrent"] as? Int ?? 0
        self.maxVoltage = dict["MaxVoltage"] as? Int ?? 0
    }
}

