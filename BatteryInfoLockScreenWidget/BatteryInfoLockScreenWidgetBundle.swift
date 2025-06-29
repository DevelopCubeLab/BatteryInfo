import WidgetKit
import SwiftUI

@main
@available(iOSApplicationExtension 16.0, *)
struct BatteryInfoLockScreenWidgetBundle: WidgetBundle {
    var body: some Widget {
        BatteryInfoLockScreenWidget()
    }
}
