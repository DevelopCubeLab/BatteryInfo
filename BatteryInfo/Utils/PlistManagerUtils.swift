import Foundation

class PlistManagerUtils {

    // 单例实例
    private static var instances: [String: PlistManagerUtils] = [:]

    private var plistFileURL: URL
    private var plistExist: Bool = false
    private var preferences: [String: Any]
    private var cachedChanges: [String: Any] = [:]
    private var isDirty = false

    // 获取实例方法（支持多实例 + 自定义路径）
    static func instance(for plistName: String, customPath: String? = nil) -> PlistManagerUtils {
        let key = customPath ?? "DEFAULT" // 如果没有自定义路径，就用 "DEFAULT"
        let instanceKey = "\(plistName)-\(key)"

        // 如果实例已存在，则返回现有实例
        if let instance = instances[instanceKey] {
            return instance
        }

        // 创建新的实例并存储
        let instance = PlistManagerUtils(plistName: plistName, customPath: customPath)
        instances[instanceKey] = instance
        return instance
    }

    // 初始化 PlistManager，支持自定义路径
    private init(plistName: String, customPath: String? = nil) {
        if let customPath = customPath {
            let customDirectory = URL(fileURLWithPath: customPath, isDirectory: true)
            self.plistFileURL = customDirectory.appendingPathComponent("\(plistName).plist")
        } else {
            // 默认存储到 Preferences 目录
            let preferencesDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            let preferencesPath = preferencesDirectory.appendingPathComponent("Preferences")
            self.plistFileURL = preferencesPath.appendingPathComponent("\(plistName).plist")
        }

        // 如果 plist 文件不存在，则创建一个空的文件
        if !FileManager.default.fileExists(atPath: plistFileURL.path) {
            preferences = [:]
            save()
            plistExist = false //增加一个标识，让外界知道这个配置文件是新创建的
        } else {
            self.preferences = PlistManagerUtils.loadPreferences(from: plistFileURL)
            plistExist = true
        }
    }

    // 加载 plist 文件中的数据
    private static func loadPreferences(from url: URL) -> [String: Any] {
        guard let data = try? Data(contentsOf: url),
              let preferences = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return [:]
        }
        return preferences
    }

    // 保存数据到 plist 文件
    private func save() {
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: preferences, format: .xml, options: 0)
            try data.write(to: plistFileURL)
        } catch {
            NSLog("Error saving \(plistFileURL) preferences to plist: \(error.localizedDescription)")
        }
    }
    

    // 获取 plist 文件是否存在
    func isPlistExist() -> Bool {
        return plistExist
    }

    // 获取指定 key 对应的 Int 值
    func getInt(key: String, defaultValue: Int) -> Int {
        return preferences[key] as? Int ?? defaultValue
    }

    // 获取指定 key 对应的 Bool 值
    func getBool(key: String, defaultValue: Bool) -> Bool {
        return preferences[key] as? Bool ?? defaultValue
    }

    // 获取指定 key 对应的 String 值
    func getString(key: String, defaultValue: String) -> String {
        return preferences[key] as? String ?? defaultValue
    }

    // 获取指定 key 对应的 Float 值
    func getFloat(key: String, defaultValue: Float) -> Float {
        return preferences[key] as? Float ?? defaultValue
    }

    // 获取指定 key 对应的 Double 值
    func getDouble(key: String, defaultValue: Double) -> Double {
        return preferences[key] as? Double ?? defaultValue
    }

    // 获取指定 key 对应的 Data 值
    func getData(key: String, defaultValue: Data) -> Data {
        return preferences[key] as? Data ?? defaultValue
    }

    // 获取指定 key 对应的 URL 值
    func getURL(key: String, defaultValue: URL) -> URL {
        return preferences[key] as? URL ?? defaultValue
    }

    // 获取指定 key 对应的 Array 值
    func getArray(key: String, defaultValue: [Any]) -> [Any] {
        return preferences[key] as? [Any] ?? defaultValue
    }

    // 获取指定 key 对应的 Dictionary 值
    func getDictionary(key: String, defaultValue: [String: Any]) -> [String: Any] {
        return preferences[key] as? [String: Any] ?? defaultValue
    }

    // 设置 Int 值
    func setInt(key: String, value: Int) {
        cachedChanges[key] = value
        isDirty = true
    }

    // 设置 Bool 值
    func setBool(key: String, value: Bool) {
        cachedChanges[key] = value
        isDirty = true
    }

    // 设置 String 值
    func setString(key: String, value: String) {
        cachedChanges[key] = value
        isDirty = true
    }

    // 设置 Float 值
    func setFloat(key: String, value: Float) {
        cachedChanges[key] = value
        isDirty = true
    }

    // 设置 Double 值
    func setDouble(key: String, value: Double) {
        cachedChanges[key] = value
        isDirty = true
    }

    // 设置 Data 值
    func setData(key: String, value: Data) {
        cachedChanges[key] = value
        isDirty = true
    }

    // 设置 URL 值
    func setURL(key: String, value: URL) {
        cachedChanges[key] = value
        isDirty = true
    }

    // 设置 Array 值
    func setArray(key: String, value: [Any]) {
        cachedChanges[key] = value
        isDirty = true
    }

    // 设置 Dictionary 值
    func setDictionary(key: String, value: [String: Any]) {
        cachedChanges[key] = value
        isDirty = true
    }

    // 删除指定 key 的数据
    func remove(key: String) {
        cachedChanges[key] = NSNull()
        isDirty = true
    }

    // 清除 plist 文件（删除整个文件）
    func clear() {
        do {
            try FileManager.default.removeItem(at: plistFileURL)
            preferences = [:]
        } catch {
            print("Error clearing \(plistFileURL) plist file: \(error.localizedDescription)")
        }
    }

    func commit() {
        self.apply()
    }

    // 将更改保存到 plist
    func apply() {
        // 只有在有修改的情况下才进行保存
        if isDirty {
            // 将所有更改合并到 preferences 中，覆盖掉已存在的相同键
            for (key, value) in cachedChanges {
                if value is NSNull {
                    preferences.removeValue(forKey: key)
                } else {
                    preferences[key] = value
                }
            }

            // 执行保存操作
            save()

            // 重置缓存和脏标记
            cachedChanges.removeAll()
            isDirty = false
        }
    }

}
