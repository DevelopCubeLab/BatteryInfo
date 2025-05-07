import Foundation

// 电池信息组的ID集合
enum BatteryInfoGroupID {
    static let basic = 1
    static let charge = 2
    static let settingsBatteryInfo = 3
    static let batterySerialNumber = 4
    static let batteryQmax = 5
    static let charger = 6
    static let batteryVoltage = 7
    static let batteryLifeCycle = 8
    static let notChargeReason = 9
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
}
