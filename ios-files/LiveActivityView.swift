import SwiftUI
import WidgetKit
import OneSignalLiveActivities
import os.log

#if canImport(ActivityKit)

@available(iOS 16.1, *)
struct LiveActivityView: View {
    let context: ActivityViewContext<DefaultLiveActivityAttributes>
    private let logger = Logger(subsystem: "com.usegold.app", category: "LiveActivity")

    var body: some View {
        // Check if shouldShow is false
        if let shouldShow = context.state.data["shouldShow"]?.asBool(), !shouldShow {
            EmptyView()
        } else {
            // New 70/30 Layout
            VStack(spacing: 0) {
                // Top Section (70%) - App Icon, Title, Subtitle, Countdown
                HStack(spacing: 8) {
                    // Left: Title/Subtitle + Countdown
                    VStack(alignment: .leading, spacing: 4) {
                        // Row 1: App Icon + Title
                        HStack(spacing: 6) {
                            // App Icon
                            if let showAppIcon = context.state.data["showAppIcon"]?.asBool(), showAppIcon {
                                Image("GoldAppIcon")
                                    .resizable()
                                    .frame(width: getDouble("iconSize", fallback: 25.0), height: getDouble("iconSize", fallback: 25.0))
                                    .clipShape(RoundedRectangle(cornerRadius: getDouble("appIconBorderRadius", fallback: 5.0)))
                                    .background(isDebugSpacing ? Color.orange.opacity(0.5) : Color.clear)
                            }
                            
                            // App Name
                            Text(context.state.data["appName"]?.asString() ?? "GOLD APP")
                                .font(.system(size: getDouble("appNameSize", fallback: 17.0), weight: .bold))
                                .foregroundColor(Color.fromHex(context.state.data["appNameColor"]?.asString(), fallback: .black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .background(isDebugSpacing ? Color.cyan.opacity(0.4) : Color.clear)
                        }
                        
                        // Row 2: Subtitle
                        Text(context.state.data["subtitle"]?.asString() ?? "Your deals are expiring")
                            .font(.system(size: getDouble("subtitleSize", fallback: 15.0)))
                            .foregroundColor(Color.fromHex(context.state.data["subtitleColor"]?.asString(), fallback: .secondary))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .background(isDebugSpacing ? Color.mint.opacity(0.4) : Color.clear)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(isDebugSpacing ? Color.blue.opacity(0.2) : Color.clear)
                    
                    // Right: Countdown + Emoji
                    HStack(alignment: .center, spacing: getDouble("countdownEmojiSpacing", fallback: 4.0)) {
                        VStack(alignment: .center, spacing: 0) {
                            // "ENDS IN" label
                            Text(context.state.data["countdownLabel"]?.asString() ?? "ENDS IN")
                                .font(.system(size: getDouble("countdownLabelSize", fallback: 11.0), weight: .medium))
                                .foregroundColor(Color.fromHex(context.state.data["countdownLabelColor"]?.asString(), fallback: .secondary))
                                .background(isDebugSpacing ? Color.yellow.opacity(0.5) : Color.clear)
                            
                            // Countdown Timer
                            if let countdownSeconds = getCountdownSeconds() {
                                let endDate = Date().addingTimeInterval(countdownSeconds)
                                Text(timerInterval: Date()...endDate, countsDown: true)
                                    .font(.system(size: getDouble("countdownTimerSize", fallback: 24.0), weight: .bold))
                                    .monospacedDigit()
                                    .foregroundColor(Color.fromHex(context.state.data["countdownTimerColor"]?.asString(), fallback: .black))
                                    .frame(width: getDouble("countdownTimerWidth", fallback: 72.0))
                                    .background(isDebugSpacing ? Color.pink.opacity(0.4) : Color.clear)
                            } else {
                                Text("--:--")
                                    .font(.system(size: getDouble("countdownTimerSize", fallback: 24.0), weight: .bold))
                                    .monospacedDigit()
                                    .foregroundColor(Color.fromHex(context.state.data["countdownTimerColor"]?.asString(), fallback: .black))
                                    .frame(width: getDouble("countdownTimerWidth", fallback: 72.0))
                                    .background(isDebugSpacing ? Color.pink.opacity(0.4) : Color.clear)
                            }
                        }
                        .background(isDebugSpacing ? Color.purple.opacity(0.3) : Color.clear)
                        
                        // Emoji on the side
                        if let showEmoji = context.state.data["showEmoji"]?.asBool(), showEmoji {
                            Text(context.state.data["emojiCharacter"]?.asString() ?? "⏳")
                                .font(.system(size: getDouble("emojiSize", fallback: 20.0)))
                                .background(isDebugSpacing ? Color.red.opacity(0.4) : Color.clear)
                        }
                    }
                    .background(isDebugSpacing ? Color.red.opacity(0.2) : Color.clear)
                }
                .frame(height: 112) // ~70% of 160pt total
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Button Section (30%) - Visual CTA
                Text((context.state.data["buttonText"]?.asString() ?? "Claim your Deals") + " ↗")
                    .font(.system(size: getDouble("buttonTextSize", fallback: 16.0), weight: .bold))
                    .foregroundColor(Color.fromHex(context.state.data["buttonTextColor"]?.asString(), fallback: .black))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.fromHex(context.state.data["buttonColor"]?.asString(), fallback: Color(red: 0.89, green: 0.97, blue: 0.37)))
                    .cornerRadius(getDouble("buttonBorderRadius", fallback: 12.0))
                    .padding(.horizontal, 16)
                    .padding(.bottom, getDouble("buttonBottomPadding", fallback: 16.0))
            }
            .frame(height: 160) // Fixed height for V1
            .background(gradientBackground)
            .cornerRadius(16)
            .widgetURL(URL(string: context.state.data["deepLinkUrl"]?.asString() ?? "gold-app://golden-hour"))
            .id("\(getDouble("appNameSize", fallback: 17.0))-\(getDouble("subtitleSize", fallback: 15.0))-\(getDouble("emojiSize", fallback: 20.0))-\(getDouble("iconSize", fallback: 40.0))-\(getDouble("buttonBorderRadius", fallback: 12.0))")
            .onAppear {
                logReceivedData()
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var gradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.fromHex(context.state.data["backgroundColor1"]?.asString(), fallback: Color(red: 0.89, green: 0.97, blue: 0.37)),
                Color.fromHex(context.state.data["backgroundColor2"]?.asString(), fallback: .white)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Debug
    
    private var isDebugSpacing: Bool {
        context.state.data["debugSpacing"]?.asBool() ?? false
    }
    
    // MARK: - Helper Functions
    
    private func logReceivedData() {
        logger.info("🔄 [LiveActivity] Widget body rendering")
        logger.info("📊 [LiveActivity] appNameSize: \(getDouble("appNameSize", fallback: -1))")
        logger.info("📊 [LiveActivity] subtitleSize: \(getDouble("subtitleSize", fallback: -1))")
        logger.info("📊 [LiveActivity] iconSize: \(getDouble("iconSize", fallback: -1))")
        logger.info("📊 [LiveActivity] emojiSize: \(getDouble("emojiSize", fallback: -1))")
        logger.info("📊 [LiveActivity] countdownLabelSize: \(getDouble("countdownLabelSize", fallback: -1))")
        logger.info("📊 [LiveActivity] countdownTimerSize: \(getDouble("countdownTimerSize", fallback: -1))")
        logger.info("📊 [LiveActivity] countdownEmojiSpacing: \(getDouble("countdownEmojiSpacing", fallback: -1))")
        logger.info("📊 [LiveActivity] buttonBorderRadius: \(getDouble("buttonBorderRadius", fallback: -1))")
        logger.info("📝 [LiveActivity] appName: \(context.state.data["appName"]?.asString() ?? "nil")")
        logger.info("📝 [LiveActivity] subtitle: \(context.state.data["subtitle"]?.asString() ?? "nil")")
        logger.info("🎨 [LiveActivity] backgroundColor1: \(context.state.data["backgroundColor1"]?.asString() ?? "nil")")
        logger.info("🎨 [LiveActivity] backgroundColor2: \(context.state.data["backgroundColor2"]?.asString() ?? "nil")")
        logger.info("🎨 [LiveActivity] countdownLabelColor: \(context.state.data["countdownLabelColor"]?.asString() ?? "nil")")
        logger.info("🎨 [LiveActivity] countdownTimerColor: \(context.state.data["countdownTimerColor"]?.asString() ?? "nil")")
        
        // Log ALL keys in the data dictionary
        logger.info("🔑 [LiveActivity] All data keys: \(context.state.data.keys)")
    }
    
    /// Safely parse a numeric value from OneSignal data.
    /// OneSignal may send numbers as Double, Int, or String depending on the update method.
    private func getDouble(_ key: String, fallback: Double) -> Double {
        if let val = context.state.data[key]?.asDouble() {
            return val
        } else if let val = context.state.data[key]?.asInt() {
            return Double(val)
        } else if let str = context.state.data[key]?.asString(), let val = Double(str) {
            return val
        }
        return fallback
    }
    
    private func getCountdownSeconds() -> Double? {
        if let countdownSeconds = context.state.data["countdownSeconds"]?.asDouble() {
            return countdownSeconds
        } else if let countdownSecondsInt = context.state.data["countdownSeconds"]?.asInt() {
            return Double(countdownSecondsInt)
        } else if let countdownSecondsString = context.state.data["countdownSeconds"]?.asString(),
                  let countdownValue = Double(countdownSecondsString) {
            return countdownValue
        }
        return nil
    }
}

// MARK: - Color Extension (Backward Compatibility)
extension Color {
    static func fromHex(_ hexString: String?, fallback: Color = Color(red: 1.0, green: 0.843, blue: 0.0)) -> Color {
        guard let hex = hexString else { 
            return fallback
        }
        
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        if (cString.count) != 6, (cString.count) != 8 {
            return fallback
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        if cString.count == 6 {
            return Color(
                red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgbValue & 0x0000FF) / 255.0
            )
        } else if cString.count == 8 {
            return Color(
                red: Double((rgbValue & 0xFF000000) >> 24) / 255.0,
                green: Double((rgbValue & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgbValue & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgbValue & 0x000000FF) / 255.0
            )
        }
        
        return fallback
    }
}

#endif

