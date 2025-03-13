import Foundation
import UIKit

func getDeviceModel() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
    return identifier
}

func isRunningOniPadOS() -> Bool {
    // 判断设备是否为 iPad
    if UIDevice.current.userInterfaceIdiom == .pad {
        // 判断系统版本是否大于等于 13.0
        if #available(iOS 13.0, *) {
            return true
        }
    }
    return false
}

func getSystemBuildVersion() -> String? {
    var size = 0
    sysctlbyname("kern.osversion", nil, &size, nil, 0)
    
    var build = [CChar](repeating: 0, count: size)
    sysctlbyname("kern.osversion", &build, &size, nil, 0)
    
    return String(cString: build)
}

func getDeviceUptime() -> String {
    let uptimeInSeconds = Int(ProcessInfo.processInfo.systemUptime)
    
    let days = Int(Double(uptimeInSeconds / (24 * 3600))) // 计算天数
    let hours = Int(Double((uptimeInSeconds % (24 * 3600)) / 3600)) // 计算小时数
    let minutes = Int(Double((uptimeInSeconds % 3600) / 60)) // 计算分钟数
    
    return String.localizedStringWithFormat(NSLocalizedString("DeviceUptime", comment: ""),days, hours, minutes)
}

func getDeviceUptimeUsingSysctl() -> String {
    var tv = timeval()
    var size = MemoryLayout<timeval>.stride
    var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]

    // **使用 withUnsafeMutablePointer 解决指针转换问题**
    _ = mib.withUnsafeMutableBufferPointer { mibPointer -> Bool in
        guard let baseAddress = mibPointer.baseAddress else { return false }
        return sysctl(baseAddress, 2, &tv, &size, nil, 0) == 0
    }

    // 计算设备已运行的秒数
    let bootTime = Date(timeIntervalSince1970: TimeInterval(tv.tv_sec))
    let uptimeInSeconds = Int(Date().timeIntervalSince(bootTime))

    // **计算天、小时、分钟**
    let days = uptimeInSeconds / (24 * 3600)
    let hours = (uptimeInSeconds % (24 * 3600)) / 3600
    let minutes = (uptimeInSeconds % 3600) / 60

    // **格式化字符串**
    return String.localizedStringWithFormat(
        NSLocalizedString("DeviceUptime", comment: "设备已运行时间"),
        days, hours, minutes
    )
}

// 设备是否正在充电，非Root设备也可以用
func isDeviceCharging() -> Bool {
    UIDevice.current.isBatteryMonitoringEnabled = true
    return UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
}

/// 获取当前设备的充电状态
func getBatteryState() -> UIDevice.BatteryState {
    UIDevice.current.isBatteryMonitoringEnabled = true
    return UIDevice.current.batteryState
}

// 获取电量百分比，非Root设备也可以用
func getBatteryPercentage() -> Int? {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let batteryLevel = UIDevice.current.batteryLevel
    
    if batteryLevel < 0 {
        return nil // -1 表示无法获取电池电量
    } else {
        return Int(batteryLevel * 100) // 转换为百分比
    }
}

// 获取设备总容量
func getTotalDiskSpace() -> Int64 {
    if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
       let totalSize = attributes[.systemSize] as? Int64 {
        return totalSize
    }
    return 0
}

// 获取设备总容量的近似
func getDiskTotalSpace() -> String {
    let totalSize = getTotalDiskSpace()
    let sizeInGB = Double(totalSize) / 1_000_000_000 // 转换为GB（基于10^9）

    // iOS 设备常见存储规格（按官方设备容量）
    let storageSizes: [Double] = [16, 32, 64, 128, 256, 512, 1024, 2048] // 单位 GB

    // 找到最接近的存储规格
    let closestSize = storageSizes.min(by: { abs($0 - sizeInGB) < abs($1 - sizeInGB) }) ?? sizeInGB

    return closestSize >= 1024 ? "\(Int(closestSize / 1024)) TB" : "\(Int(closestSize)) GB"
}

// 获取设备的型号代码
func getDeviceRegionCode() -> String? {
    let path = "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"

    // 读取 plist 文件
    guard let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
        NSLog("Battery Info----> 无法加载 MobileGestalt.plist")
        return nil
    }

    // 获取 `CacheExtra` 字典
    guard let cacheExtra = dict["CacheExtra"] as? [String: Any] else {
        NSLog("Battery Info----> MobileGestalt无法找到 `CacheExtra` 字典")
        return nil
    }

    // 先尝试直接获取 `zHeENZu+wbg7PUprwNwBWg`
    if let regionCode = cacheExtra["zHeENZu+wbg7PUprwNwBWg"] as? String {
        if isValidRegionCode(regionCode) {
            return regionCode
        }
    }

    // 遍历 `CacheExtra` 并匹配设备型号代码格式
    for (key, value) in cacheExtra {
        if let regionCode = value as? String, isValidRegionCode(regionCode) {
            NSLog("Battery Info----> MobileGestalt未找到默认 key，使用遍历找到的 key: \(key) -> \(regionCode)")
            return regionCode
        }
    }
    return nil
}

// 匹配设备发售型号格式
private func isValidRegionCode(_ code: String) -> Bool {
    let pattern = "^[A-Z]{2}/A$"  // 匹配 XX/A 格式，例如 CH/A、LL/A、ZA/A
    return code.range(of: pattern, options: .regularExpression) != nil
}

func getDeviceName() -> String {
    switch getDeviceModel() {
        
        case "iPhone1,1": return "iPhone"
        case "iPhone1,2": return "iPhone 3G"
        case "iPhone2,1": return "iPhone 3GS"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3": return "iPhone 4"
        case "iPhone4,1": return "iPhone 4S"
        case "iPhone5,1": return "iPhone 5 (GSM)"
        case "iPhone5,2": return "iPhone 5 (GSM+CDMA)"
        case "iPhone5,3": return "iPhone 5C (GSM)"
        case "iPhone5,4": return "iPhone 5C (Global)"
        case "iPhone6,1": return "iPhone 5S (GSM)"
        case "iPhone6,2": return "iPhone 5S (Global)"
        case "iPhone7,1": return "iPhone 6 Plus"
        case "iPhone7,2": return "iPhone 6"
        case "iPhone8,1": return "iPhone 6s"
        case "iPhone8,2": return "iPhone 6s Plus"
        case "iPhone8,4": return "iPhone SE (1st Gen)"
        case "iPhone9,1", "iPhone9,3": return "iPhone 7"
        case "iPhone9,2", "iPhone9,4": return "iPhone 7 Plus"
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone12,8": return "iPhone SE (2nd Gen)"
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,6": return "iPhone SE (3rd Gen)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        case "iPhone17,5": return "iPhone 16e" // 新2025.2.19 新增iPhone 16e
            
        // iPod
        case "iPod1,1": return "iPod Touch (1st Gen)"
        case "iPod2,1": return "iPod Touch (2nd Gen)"
        case "iPod3,1": return "iPod Touch (3rd Gen)"
        case "iPod4,1": return "iPod Touch (4th Gen)"
        case "iPod5,1": return "iPod Touch (5th Gen)"
        case "iPod7,1": return "iPod Touch (6th Gen)"
        case "iPod9,1": return "iPod Touch (7th Gen)"
            
        // iPad
        case "iPad1,1": return "iPad (1st Gen)"
        case "iPad1,2": return "iPad (1st Gen, 3G)"
        case "iPad2,1": return "iPad 2 (WiFi)"
        case "iPad2,2": return "iPad 2 (GSM)"
        case "iPad2,3": return "iPad 2 (CDMA)"
        case "iPad2,4": return "iPad 2 (Rev A)"
        case "iPad2,5": return "iPad Mini (1st Gen)"
        case "iPad2,6": return "iPad Mini (1st Gen, GSM+LTE)"
        case "iPad2,7": return "iPad Mini (1st Gen, CDMA+LTE)"
        case "iPad3,1": return "iPad (3rd Gen, WiFi)"
        case "iPad3,2": return "iPad (3rd Gen, CDMA)"
        case "iPad3,3": return "iPad (3rd Gen, GSM)"
        case "iPad3,4": return "iPad (4th Gen, WiFi)"
        case "iPad3,5": return "iPad (4th Gen, GSM+LTE)"
        case "iPad3,6": return "iPad (4th Gen, CDMA+LTE)"
        case "iPad4,1": return "iPad Air (WiFi)"
        case "iPad4,2": return "iPad Air (GSM+CDMA)"
        case "iPad4,3": return "iPad Air (China)"
        case "iPad4,4": return "iPad Mini 2 (WiFi)"
        case "iPad4,5": return "iPad Mini 2 (GSM+CDMA)"
        case "iPad4,6": return "iPad Mini 2 (China)"
        case "iPad4,7": return "iPad Mini 3 (WiFi)"
        case "iPad4,8": return "iPad Mini 3 (GSM+CDMA)"
        case "iPad4,9": return "iPad Mini 3 (China)"
        case "iPad5,1": return "iPad Mini 4 (WiFi)"
        case "iPad5,2": return "iPad Mini 4 (WiFi+Cellular)"
        case "iPad5,3": return "iPad Air 2 (WiFi)"
        case "iPad5,4": return "iPad Air 2 (Cellular)"
        case "iPad6,3": return "iPad Pro (9.7 inch, WiFi)"
        case "iPad6,4": return "iPad Pro (9.7 inch, WiFi+LTE)"
        case "iPad6,7": return "iPad Pro (12.9 inch, WiFi)"
        case "iPad6,8": return "iPad Pro (12.9 inch, WiFi+LTE)"
        case "iPad6,11": return "iPad (5th Gen, WiFi)"
        case "iPad6,12": return "iPad (5th Gen, WiFi+Cellular)"
        case "iPad7,1": return "iPad Pro 2nd Gen (12.9 inch, WiFi)"
        case "iPad7,2": return "iPad Pro 2nd Gen (12.9 inch, WiFi+Cellular)"
        case "iPad7,3": return "iPad Pro 10.5-inch (WiFi)"
        case "iPad7,4": return "iPad Pro 10.5-inch (WiFi+Cellular)"
        case "iPad7,5": return "iPad (6th Gen, WiFi)"
        case "iPad7,6": return "iPad (6th Gen, WiFi+Cellular)"
        case "iPad7,11": return "iPad (7th Gen, 10.2 inch, WiFi)"
        case "iPad7,12": return "iPad (7th Gen, 10.2 inch, WiFi+Cellular)"
        case "iPad8,1": return "iPad Pro 11 inch (3rd Gen, WiFi)"
        case "iPad8,2": return "iPad Pro 11 inch (3rd Gen, 1TB, WiFi)"
        case "iPad8,3": return "iPad Pro 11 inch (3rd Gen, WiFi+Cellular)"
        case "iPad8,4": return "iPad Pro 11 inch (3rd Gen, 1TB, WiFi+Cellular)"
        case "iPad8,5": return "iPad Pro 12.9 inch (3rd Gen, WiFi)"
        case "iPad8,6": return "iPad Pro 12.9 inch (3rd Gen, 1TB, WiFi)"
        case "iPad8,7": return "iPad Pro 12.9 inch (3rd Gen, WiFi+Cellular)"
        case "iPad8,8": return "iPad Pro 12.9 inch (3rd Gen, 1TB, WiFi+Cellular)"
        case "iPad8,9": return "iPad Pro 11 inch (4th Gen, WiFi)"
        case "iPad8,10": return "iPad Pro 11 inch (4th Gen, WiFi+Cellular)"
        case "iPad8,11": return "iPad Pro 12.9 inch (4th Gen, WiFi)"
        case "iPad8,12": return "iPad Pro 12.9 inch (4th Gen, WiFi+Cellular)"
        case "iPad11,1": return "iPad Mini (5th Gen, WiFi)"
        case "iPad11,2": return "iPad Mini (5th Gen, WiFi+Cellular)"
        case "iPad11,3": return "iPad Air (3rd Gen, WiFi)"
        case "iPad11,4": return "iPad Air (3rd Gen, WiFi+Cellular)"
        case "iPad11,6": return "iPad (8th Gen, WiFi)"
        case "iPad11,7": return "iPad (8th Gen, WiFi+Cellular)"
        case "iPad12,1": return "iPad (9th Gen, WiFi)"
        case "iPad12,2": return "iPad (9th Gen, WiFi+Cellular)"
        case "iPad13,1": return "iPad Air (4th Gen, WiFi)"
        case "iPad13,2": return "iPad Air (4th Gen, WiFi+Cellular)"
        case "iPad13,4": return "iPad Pro 11 inch (5th Gen)"
        case "iPad13,5": return "iPad Pro 11 inch (5th Gen)"
        case "iPad13,6": return "iPad Pro 11 inch (5th Gen)"
        case "iPad13,7": return "iPad Pro 11 inch (5th Gen)"
        case "iPad13,8": return "iPad Pro 12.9 inch (5th Gen)"
        case "iPad13,9": return "iPad Pro 12.9 inch (5th Gen)"
        case "iPad13,10": return "iPad Pro 12.9 inch (5th Gen)"
        case "iPad13,11": return "iPad Pro 12.9 inch (5th Gen)"
        case "iPad13,16": return "iPad Air (5th Gen, WiFi)"
        case "iPad13,17": return "iPad Air (5th Gen, WiFi+Cellular)"
        case "iPad13,18": return "iPad (10th Gen)"
        case "iPad13,19": return "iPad (10th Gen)"
        case "iPad14,1": return "iPad Mini (6th Gen, WiFi)"
        case "iPad14,2": return "iPad Mini (6th Gen, WiFi+Cellular)"
        case "iPad14,3": return "iPad Pro 11 inch (4th Gen)"
        case "iPad14,4": return "iPad Pro 11 inch (4th Gen)"
        case "iPad14,5": return "iPad Pro 12.9 inch (6th Gen)"
        case "iPad14,6": return "iPad Pro 12.9 inch (6th Gen)"
        case "iPad14,8": return "iPad Air (6th Gen)"
        case "iPad14,9": return "iPad Air (6th Gen)"
        case "iPad14,10": return "iPad Air (7th Gen)"
        case "iPad14,11": return "iPad Air (7th Gen)"
        case "iPad16,1": return "iPad Mini (7th Gen, WiFi)"
        case "iPad16,2": return "iPad Mini (7th Gen, WiFi+Cellular)"
        case "iPad16,3": return "iPad Pro 11 inch (5th Gen)"
        case "iPad16,4": return "iPad Pro 11 inch (5th Gen)"
        case "iPad16,5": return "iPad Pro 12.9 inch (7th Gen)"
        case "iPad16,6": return "iPad Pro 12.9 inch (7th Gen)"
        
        case "arm64": return "Simulator (arm64)"
        
        // 未知设备
        default: return getDeviceModel()
    }
}

