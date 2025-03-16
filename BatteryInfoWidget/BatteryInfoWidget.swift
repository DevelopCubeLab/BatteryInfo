import WidgetKit
import SwiftUI
import Intents

// 数据模型（时间轴的 Entry）
struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: BatteryInfoWidgetIntent // 用户配置
    let batteryData: WidgetBatteryData // 电池数据
    // 小组件自己的设置
    let appearance: AppearanceType // 外观
    let showUpdateTime: Bool
}

// 定义外观枚举，匹配 Intent
enum AppearanceType: Int {
    case system = 1
    case light = 2
    case dark = 3
    case black = 4
    case blueWhiteTheme = 5
    case blueCyanTheme = 6

    static func from(intent: BatteryInfoWidgetIntent) -> AppearanceType {
        let rawValue = intent.Appearance.rawValue
        return AppearanceType(rawValue: rawValue) ?? .system
    }
}



// Timeline Provider（提供 Widget 数据）
struct Provider: IntentTimelineProvider {
    // 占位符
    func placeholder(in context: Context) -> SimpleEntry {
        let intent = BatteryInfoWidgetIntent()
        return createEntry(with: intent)
    }

    // 获取快照
    func getSnapshot(for configuration: BatteryInfoWidgetIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = createEntry(with: configuration)
        completion(entry)
    }

    // 获取时间线
    func getTimeline(for configuration: BatteryInfoWidgetIntent, in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = createEntry(with: configuration)
        
        // 如果 updateTimeStamp 为 0，表示数据无效
        if entry.batteryData.updateTimeStamp == 0 {
            // 立即刷新 widget 并显示占位符
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
            return
        }
        
        // 获取当前时间戳和数据时间戳
        let currentTimeStamp = Int(Date().timeIntervalSince1970)
        let dataTimeStamp = entry.batteryData.updateTimeStamp
        
        // 判断数据是否更新（5 分钟内更新过）
        let hasNewData = currentTimeStamp - dataTimeStamp < 60 * 5
        
        if hasNewData {
            let timeline = Timeline(entries: [entry], policy: .atEnd) // 立即刷新
            completion(timeline)
        } else {
            // 45分钟刷新一次，防止浪费Widget的刷新次数
            let nextUpdate = Date().addingTimeInterval(60 * 45)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
        
//        let nextUpdate = hasNewData ? Date().addingTimeInterval(60 * 5) : Date().addingTimeInterval(60 * 45)
//        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
//        completion(timeline)
    }

    // 解析 Intent 设置，返回 `SimpleEntry`
    private func createEntry(with configuration: BatteryInfoWidgetIntent) -> SimpleEntry {
        let batteryData = WidgetController.instance.getWidgetBatteryData()
        let appearance = AppearanceType.from(intent: configuration)
        let showUpdateTime = configuration.ShowUpdateTime?.boolValue ?? true

        return SimpleEntry(
            date: Date(),
            configuration: configuration,
            batteryData: batteryData,
            appearance: appearance,
            showUpdateTime: showUpdateTime
        )
    }


}

// 默认的Widget UI
struct BatteryInfoWidgetEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 5) {
                Text(String.localizedStringWithFormat(
                    NSLocalizedString("WidgetMaximumCapacity", comment: ""), entry.batteryData.maximumCapacity))
                .font(.footnote)
                .foregroundColor(getTextColor(for: entry.appearance))
                
                Text(String.localizedStringWithFormat(
                    NSLocalizedString("CycleCount", comment: ""), String(entry.batteryData.cycleCount)))
                .font(.footnote)
                .foregroundColor(getTextColor(for: entry.appearance))
                
                if entry.showUpdateTime {
                    Text(String.localizedStringWithFormat(
                        NSLocalizedString("UpdateTime", comment: ""), entry.batteryData.updateDate))
                    .font(.footnote)
                    .foregroundColor(getTextColor(for: entry.appearance))
                }
            }
            .padding(getBackgroundPadding())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .applyBackground(for: entry.appearance)
//        .background(getBackgroundColor(for: entry.appearance))
    }
    
}

extension View { // 兼容iOS 17.0导致的背景颜色的问题
    func applyBackground(for appearance: AppearanceType) -> some View {
        if #available(iOS 17.0, *) {
            return self.containerBackground(getBackgroundColor(for: appearance), for: .widget)
        } else {
            return self.background(getBackgroundColor(for: appearance))
        }
    }
}

private func getBackgroundColor(for appearance: AppearanceType) -> Color {
    switch appearance {
    case .system: return Color(UIColor.systemBackground) // 跟随系统
    case .light: return Color.white
    case .black: return Color.black
    case .dark: return Color(UIColor(red: 28/255.0, green: 28/255.0, blue: 30/255.0, alpha: 1.0)) // 系统Dark mode的widget的背景颜色
    case .blueWhiteTheme: return Color(UIColor(red: 50/255.0, green: 165/255.0, blue: 231/255.0, alpha: 1.0)) // 图标的蓝色
    case .blueCyanTheme: return Color(UIColor(red: 125/255.0, green: 205/255.0, blue: 255/255.0, alpha: 1.0)) // 蓝色
    }
}

private func getTextColor(for appearance: AppearanceType) -> Color {
    switch appearance {
    case .system: return Color(UIColor.label) // 跟随系统
    case .light: return Color.black
    case .dark: return Color.white
    case .black: return Color.white
    case .blueWhiteTheme: return Color.white
    case .blueCyanTheme: return Color(UIColor(red: 30/255.0, green: 65/255.0, blue: 125/255.0, alpha: 1.0))
    }
}

private func getBackgroundPadding() -> CGFloat { // 解决iOS 17.0开始的边距问题
    if #available(iOS 17.0, macOS 14.0, *) {
        return 0
    } else {
        return 15
    }
}

// 带图标的Widget UI
struct BatteryInfoWidgetSymbolEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        
        let data: [(symbol: String, value: String, applyFontRule: Bool)] = [
            ("cross.case.fill", entry.batteryData.maximumCapacity.appending("%"), true),
            ("minus.plus.batteryblock.fill", String(entry.batteryData.cycleCount), false)
        ] + (entry.showUpdateTime ? [("clock.fill", entry.batteryData.updateDate, false)] : [])


        let columns = [
            GridItem(.fixed(26), alignment: .center), // 图标列
            GridItem(.flexible(), alignment: .leading) // 数值列
        ]

        ZStack(alignment: .topLeading) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(data, id: \.symbol) { item in
                    Image(systemName: item.symbol)
                        .font(.system(size: 22))
                        .foregroundColor(getTextColor(for: entry.appearance))
                    
                    Text(item.value)
                        .font(item.applyFontRule && (Double(item.value) ?? 0) > 100 ? .title3 : .title2)
                        .foregroundColor(getTextColor(for: entry.appearance))
                }
            }
            .padding(getBackgroundPadding())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .applyBackground(for: entry.appearance)
//        .background(getBackgroundColor(for: entry.appearance))
    }
}


/// @See https://stackoverflow.com/questions/76595240/widget-on-ios-17-beta-device-adopt-containerbackground-api
//extension View {
//    func widgetBackground(_ backgroundView: some View) -> some View {
//        if #available(iOSApplicationExtension 17.0, *) {
//            return containerBackground(for: .widget) {
//                backgroundView
//            }
//        } else {
//            return background(backgroundView)
//        }
//    }
//}

// Widget 配置
struct BatteryInfoWidget: Widget {
    let kind: String = "BatteryInfoWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: BatteryInfoWidgetIntent.self, provider: Provider()) { entry in
            BatteryInfoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("CFBundleDisplayName", comment: ""))
        .description("CFBundleDisplayName")
        .supportedFamilies([.systemSmall]) // 只支持最小尺寸的widget
    }
}

struct BatteryInfoWidgetSymbol: Widget {
    let kind: String = "BatteryInfoSymbolWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: BatteryInfoWidgetIntent.self, provider: Provider()) { entry in
            BatteryInfoWidgetSymbolEntryView(entry: entry)
        }
        .configurationDisplayName("CFBundleDisplayName")
        .description("CFBundleDisplayName")
        .supportedFamilies([.systemSmall]) // 只支持最小尺寸的widget
    }
}
