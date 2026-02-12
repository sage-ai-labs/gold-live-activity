import ActivityKit
import SwiftUI
import WidgetKit
import OneSignalLiveActivities

// MARK: - Golden Hour Live Activity Widget (OneSignal Cross-Platform Implementation)
// Uses OneSignal's DefaultLiveActivityAttributes for cross-platform compatibility

@available(iOS 16.2, *)
struct LiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DefaultLiveActivityAttributes.self) { context in
            // Lock screen / banner UI using OneSignal's DefaultLiveActivityAttributes
            LiveActivityView(context: context)
        } dynamicIsland: { context in
            // Empty Dynamic Island for V1 - focus on lock screen UI
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }
            .widgetURL(URL(string: "gold-app://golden-hour"))
        }
    }
}
