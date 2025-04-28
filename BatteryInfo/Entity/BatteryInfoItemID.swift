import Foundation

enum BatteryInfoGroupID {
    static let basic = 1
    static let charge = 2
    static let settingsBatteryInfo = 3
    static let charger = 4
    static let Qmax = 5
}

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
}
