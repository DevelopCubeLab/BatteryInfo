import Foundation
import SwiftUI
import WidgetKit

struct LockScreenEntry: TimelineEntry {
    let date: Date
}

struct SimpleLockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenEntry {
        return LockScreenEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LockScreenEntry) -> Void) {
        let entry = LockScreenEntry(date: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenEntry>) -> Void) {
        let entry = LockScreenEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct BatteryInfoLockScreenWidget: Widget {
    let kind: String = "BatteryInfoLockScreenWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleLockScreenProvider()) { entry in
            BatteryInfoLockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("CFBundleDisplayName", comment: ""))
        .description("CFBundleDisplayName")
        .supportedFamilies([.accessoryCircular])
    }
}

struct BatteryInfoLockScreenWidgetView: View {
    var entry: LockScreenEntry
    
    var body: some View {
        ZStack {
            Image(systemName: "battery.100")
                .resizable()
                .scaledToFit()
                .padding(5)
        }
        .applyLockScreenBackground() // 背景
    }
}

extension View {
    @ViewBuilder
    func applyLockScreenBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
//            self.containerBackground(.fill.tertiary, for: .widget)
            self.containerBackground(Color.blue, for: .widget)
        } else { // iOS 16 fallback
            self.background(Color.clear)
        }
    }
}

