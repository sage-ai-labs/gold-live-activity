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
            VStack {
                Spacer()
                
                // Deal Title from static attributes
                Text("Title: " + (context.attributes.data["title"]?.asString() ?? "Golden Hour"))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // Status Message from dynamic state
                HStack {
                    Spacer()
                    Text(context.state.data["message"]?.asDict()?["en"]?.asString() ?? "Golden Hour is active!")
                        .font(.body)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                
                // Golden Hour Phase
                if let phase = context.state.data["phase"]?.asString() {
                    Text("Phase: " + phase.replacingOccurrences(of: "_", with: " "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Countdown Timer
                if let timerEndDate = context.state.data["timerEndDate"]?.asDouble() {
                    Text(timerInterval: Date(timeIntervalSince1970: timerEndDate / 1000)...Date(timeIntervalSince1970: timerEndDate / 1000), countsDown: true)
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                }
                
                // Current Bid (from dynamic state)
                Text("Current Bid: $" + String(context.state.data["currentBid"]?.asInt() ?? 0))
                    .font(.caption)
                
                // Debug info for OneSignal data types
                Text("INT: " + String(context.state.data["intValue"]?.asInt() ?? 0))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("DBL: " + String(context.state.data["doubleValue"]?.asDouble() ?? 0.0))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("BOL: " + String(context.state.data["boolValue"]?.asBool() ?? false))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .activitySystemActionForegroundColor(.black)
            .activityBackgroundTint(
                Color.fromHex(context.attributes.data["backgroundColor"]?.asString())
            )
        } dynamicIsland: { context in
            DynamicIsland {
                // Multiple expanded regions following OneSignal tutorial pattern
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("🔥")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text(context.attributes.data["title"]?.asString() ?? "Golden Hour")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("$" + String(context.state.data["currentBid"]?.asInt() ?? 0))
                            .font(.title2.bold())
                        if let timerEndDate = context.state.data["timerEndDate"]?.asDouble() {
                            Text("ends soon")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        Text(context.state.data["message"]?.asDict()?["en"]?.asString() ?? "Golden Hour is active!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        if let phase = context.state.data["phase"]?.asString() {
                            Text("Phase: \(phase.replacingOccurrences(of: "_", with: " "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } compactLeading: {
                Text("🔥")
                    .foregroundColor(.orange)
            } compactTrailing: {
                Text("$" + String(context.state.data["currentBid"]?.asInt() ?? 0))
                    .font(.caption.bold())
            } minimal: {
                Text("🔥")
                    .foregroundColor(.orange)
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
