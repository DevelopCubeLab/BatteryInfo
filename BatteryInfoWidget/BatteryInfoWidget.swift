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
enum AppearanceType: String {
    case system = "system"
    case light = "light"
    case dark = "dark"

    static func from(intent: BatteryInfoWidgetIntent) -> AppearanceType {
        guard let appearanceString = intent.value(forKey: "Appearance") as? String else {
            return .system
        }
        return AppearanceType(rawValue: appearanceString) ?? .system
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
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    // 解析 Intent 设置，返回 `SimpleEntry`
    private func createEntry(with configuration: BatteryInfoWidgetIntent) -> SimpleEntry {
        let batteryData = WidgetController.instance.getWidgetBatteryData()
        let appearance = AppearanceType.from(intent: configuration)
        let showUpdateTime = configuration.ShowUpdateTime?.boolValue ?? false

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
        ZStack(alignment: .topLeading, content: {
            VStack(alignment: .leading, spacing: 5) {
                Text(String.localizedStringWithFormat(
                    NSLocalizedString("WidgetMaximumCapacity", comment: ""), entry.batteryData.maximumCapacity))
                .font(.footnote)

                Text(String.localizedStringWithFormat(
                    NSLocalizedString("CycleCount", comment: ""), String(entry.batteryData.cycleCount)))
                .font(.footnote)
                
                if entry.showUpdateTime {
                    Text(String.localizedStringWithFormat(
                        NSLocalizedString("UpdateTime", comment: ""), entry.batteryData.updateDate))
                    .font(.footnote)
                }
            }
            .padding(15)
        }).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.clear)
    }
}

// 带图标的Widget UI
struct BatteryInfoWidgetSymbolEntryView: View {
    
    var entry: Provider.Entry

    var body: some View {
        
        let data: [(symbol: String, value: String, applyFontRule: Bool)] = [
//            ("minus.plus.batteryblock.fill", "100%"),
//            ("arrow.triangle.2.circlepath.circle.fill", "99")
            
            ("cross.case.fill", entry.batteryData.maximumCapacity.appending("%"), true),
            ("minus.plus.batteryblock.fill", String(entry.batteryData.cycleCount), false),
            ("clock.fill", entry.batteryData.updateDate, false)
        ]
        
        let columns = [
            GridItem(.fixed(26), alignment: .center), // 图标
            GridItem(.flexible(), alignment: .leading) // 数值
        ]

        ZStack(alignment: .topLeading) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(data, id: \.symbol) { item in
                    Image(systemName: item.symbol)
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                    
                    Text(item.value)
                        .font(item.applyFontRule && (Double(item.value) ?? 0) > 100 ? .title3 : .title2) // 这里如果是高于100%那么久.title3
                }
            }
            .padding(15) // 添加边距，防止贴边
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
