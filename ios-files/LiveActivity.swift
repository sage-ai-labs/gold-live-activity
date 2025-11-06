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
                            HStack {
                                if let subtitleEmoji = context.state.data["subtitleEmoji"]?.asDict()?["en"]?.asString() {
                                    Text(subtitleEmoji)
                                }
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
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
