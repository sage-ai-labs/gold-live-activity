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
            DynamicIsland {
                // Multiple expanded regions following OneSignal tutorial pattern
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        if let titleEmoji = context.state.data["titleEmoji"]?.asDict()?["en"]?.asString() {
                            Text(titleEmoji)
                                .font(.title2)
                                .foregroundColor(.orange)
                        } else {
                            Text("🔥")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                        Text(context.state.data["title"]?.asDict()?["en"]?.asString() ?? "Golden Hour")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        if let countdownSeconds = context.state.data["countdownSeconds"]?.asDouble() {
                            let endDate = Date().addingTimeInterval(countdownSeconds)
                            Text(timerInterval: Date()...endDate, countsDown: true)
                                .font(.title2.bold())
                                .monospacedDigit()
                            Text("remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if let countdownSecondsInt = context.state.data["countdownSeconds"]?.asInt() {
                            let endDate = Date().addingTimeInterval(Double(countdownSecondsInt))
                            Text(timerInterval: Date()...endDate, countsDown: true)
                                .font(.title2.bold())
                                .monospacedDigit()
                            Text("remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        if let subtitle = context.state.data["subtitle"]?.asDict()?["en"]?.asString() {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            } compactLeading: {
                if let titleEmoji = context.state.data["titleEmoji"]?.asDict()?["en"]?.asString() {
                    Text(titleEmoji)
                        .foregroundColor(.orange)
                } else {
                    Text("🔥")
                        .foregroundColor(.orange)
                }
            } compactTrailing: {
                if let countdownSeconds = context.state.data["countdownSeconds"]?.asDouble() {
                    let endDate = Date().addingTimeInterval(countdownSeconds)
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .font(.caption.bold())
                        .monospacedDigit()
                        .foregroundColor(.orange)
                } else if let countdownSecondsInt = context.state.data["countdownSeconds"]?.asInt() {
                    let endDate = Date().addingTimeInterval(Double(countdownSecondsInt))
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .font(.caption.bold())
                        .monospacedDigit()
                        .foregroundColor(.orange)
                } else {
                    Text("Live")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                }
            } minimal: {
                if let titleEmoji = context.state.data["titleEmoji"]?.asDict()?["en"]?.asString() {
                    Text(titleEmoji)
                        .foregroundColor(.orange)
                } else {
                    Text("🔥")
                        .foregroundColor(.orange)
                }
            }
            .widgetURL(URL(string: "usegold://golden-hour"))
            .keylineTint(Color.orange)
        }
    }
}

// MARK: - Color Extension
extension Color {
    static func fromHex(_ hexString: String?) -> Color {
        guard let hex = hexString else { 
            return Color(red: 1.0, green: 0.843, blue: 0.0) // Default gold
        }
        
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        if (cString.count) != 6, (cString.count) != 8 {
            return Color(red: 1.0, green: 0.843, blue: 0.0) // Default gold
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        if (cString.count) == 8 {
            return Color(
                .sRGB,
                red: Double((rgbValue >> 24) & 0xFF) / 255,
                green: Double((rgbValue >> 16) & 0xFF) / 255,
                blue: Double((rgbValue >> 08) & 0xFF) / 255,
                opacity: Double((rgbValue >> 00) & 0xFF) / 255
            )
        } else {
            return Color(
                .sRGB,
                red: Double((rgbValue >> 16) & 0xFF) / 255,
                green: Double((rgbValue >> 08) & 0xFF) / 255,
                blue: Double((rgbValue >> 00) & 0xFF) / 255,
                opacity: 1
            )
        }
    }
}
