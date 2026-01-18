import Foundation

class ApplicationLanguageController {

    private static var bundle: Bundle?

    // 应用启动或语言切换时调用
    static func setLanguage(_ languageCode: String?) {
        guard let languageCode = languageCode,
              let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let langBundle = Bundle(path: path) else {
            bundle = nil
            return
        }
        bundle = langBundle
    }

    // 从语言文件中获取文本
    static func localizedString(forKey key: String, comment: String = "") -> String {
        return bundle?.localizedString(forKey: key, value: nil, table: nil)
            ?? Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }
    
    static func localizedString(forKey key: String, table: String?, comment: String = "") -> String {
        return bundle?.localizedString(forKey: key, value: nil, table: table)
            ?? Bundle.main.localizedString(forKey: key, value: nil, table: table)
    }

    // 应用启动时自动加载设置
    static func loadLanguageFromSettings() {
        let settingLanguage = SettingsUtils.instance.getApplicationLanguage()
        switch settingLanguage {
        case .English:
            setLanguage("en")
        case .SimplifiedChinese:
            setLanguage("zh-Hans")
        case .Spanish:
            setLanguage("es-ES")
        case .System:
            setLanguage(nil)
        }
        
    }
}

/// 替代 NSLocalizedString 的封装
func NSLocalizedString(_ key: String, comment: String = "") -> String {
    return ApplicationLanguageController.localizedString(forKey: key, comment: comment)
}

func NSLocalizedString(_ key: String, tableName: String?, comment: String = "") -> String {
    return ApplicationLanguageController.localizedString(forKey: key, table: tableName, comment: comment)
}

