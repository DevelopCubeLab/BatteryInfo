import Foundation

// 电池信息组的ID集合
enum BatteryInfoGroupID: Int {
    case basic = 1
    case charge = 2
    case settingsBatteryInfo = 3
    case batterySerialNumber = 4
    case batteryQmax = 5
    case charger = 6
    case batteryVoltage = 7
    case batteryLifeTime = 8
    case notChargeReason = 9
    case chargingPowerAndNotChargeReason = 10
    case accessoryDetails = 11

    static var allCases: [BatteryInfoGroupID] {
        return [
            .basic,
            .charge,
            .settingsBatteryInfo,
            .batterySerialNumber,
            .batteryQmax,
            .charger,
            .batteryVoltage,
            .batteryLifeTime,
            .notChargeReason,
            .chargingPowerAndNotChargeReason,
            .accessoryDetails
        ]
    }
}

// 电池信息组
enum BatteryInfoGroupName {
    static func getName(for id: Int) -> String {
        switch id {
        case BatteryInfoGroupID.basic.rawValue:
            return NSLocalizedString("GroupBasic", comment: "电池基础信息组")
        case BatteryInfoGroupID.charge.rawValue:
            return NSLocalizedString("GroupCharge", comment: "充电信息组")
        case BatteryInfoGroupID.settingsBatteryInfo.rawValue:
            return NSLocalizedString("GroupSettingsBatteryInfo", comment: "设置中的电池信息组")
        case BatteryInfoGroupID.batterySerialNumber.rawValue:
            return NSLocalizedString("GroupBatterySerial", comment: "电池序列号信息组")
        case BatteryInfoGroupID.batteryQmax.rawValue:
            return NSLocalizedString("GroupBatteryQmax", comment: "电池Qmax信息组")
        case BatteryInfoGroupID.charger.rawValue:
            return NSLocalizedString("GroupCharger", comment: "充电器信息组")
        case BatteryInfoGroupID.batteryVoltage.rawValue:
            return NSLocalizedString("GroupBatteryVoltage", comment: "电池电压信息组")
        case BatteryInfoGroupID.batteryLifeTime.rawValue:
            return NSLocalizedString("GroupBatteryLifeTime", comment: "电池生命周期信息组")
        case BatteryInfoGroupID.notChargeReason.rawValue:
            return NSLocalizedString("GroupNotChargeReason", comment: "不充电原因组")
        case BatteryInfoGroupID.chargingPowerAndNotChargeReason.rawValue:
            return NSLocalizedString("GroupChargingPowerNotChargeReason", comment: "充电功率和不充电原因组")
        case BatteryInfoGroupID.accessoryDetails.rawValue:
            return NSLocalizedString("GroupAccessoryDetails", comment: "外接配件信息组")
        default:
            return NSLocalizedString("GroupUnknown", comment: "未知")
        }
    }
}

// 电池信息每一项的ID集合
enum BatteryInfoItemID {
    static let maximumCapacity = 101
    static let cycleCount = 102
    static let designCapacity = 103
    static let nominalChargeCapacity = 104
    static let temperature = 105
    static let currentCapacity = 106
    static let currentRAWCapacity = 107
    static let currentVoltage = 108
    static let instantAmperage = 109
    
    static let isCharging = 201
    static let chargeDescription = 202
    static let isWirelessCharger = 203
    static let maximumChargingHandshakeWatts = 204
    static let powerOptionDetail = 205
    static let powerOptions = 206
    static let chargingLimitVoltage = 207
    static let chargingVoltage = 208
    static let chargingCurrent = 209
    static let calculatedChargingPower = 210
    static let notChargingReason = 211
    
    static let possibleRefreshDate = 303
    
    static let batterySerialNumber = 401
    static let batteryManufacturer = 402
    
    static let maximumQmax = 501
    static let minimumQmax = 502
    
    static let chargerName = 601
    static let chargerModel = 602
    static let chargerManufacturer = 603
    static let chargerSerialNumber = 604
    static let chargerHardwareVersion = 605
    static let chargerFirmwareVersion = 606
    
    static let batteryInstalled = 701
    static let bootVoltage = 702
    static let limitVoltage = 703
    
    static let averageTemperature = 801
    static let maximumTemperature = 802
    static let minimumTemperature = 803
    
    static let accessoryCurrentCapacity = 1101
    static let accessoryIsCharging = 1102
    static let accessoryExternalConnected = 1103
    
}
