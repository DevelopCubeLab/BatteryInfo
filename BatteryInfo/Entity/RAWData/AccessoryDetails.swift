import Foundation

struct AccessoryDetails { // 扩展配件的信息
    var currentCapacity: Int?
    var isCharging: Bool?
    var externalConnected: Bool?
}

extension AccessoryDetails {
    init(dict: [String: Any]) {
        self.currentCapacity = dict["CurrentCapacity"] as? Int
        self.isCharging = (dict["IsCharging"] as? Int) == 1
        self.externalConnected = (dict["ExternalConnected"] as? Int) == 1
    }
}

