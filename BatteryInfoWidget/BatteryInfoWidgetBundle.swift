import WidgetKit
import SwiftUI

@main
struct BatteryInfoWidgetBundle: WidgetBundle {
    var body: some Widget {
        BatteryInfoWidget()
        BatteryInfoWidgetSymbol()
    }
}
