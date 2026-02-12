import SwiftUI
import WidgetKit
import OneSignalLiveActivities

#if canImport(ActivityKit)

@available(iOS 16.1, *)
struct LiveActivityView: View {
    let context: ActivityViewContext<DefaultLiveActivityAttributes>

    var body: some View {
        // Check if shouldShow is false
        if let shouldShow = context.state.data["shouldShow"]?.asBool(), !shouldShow {
            EmptyView()
        } else {
            // New 70/30 Layout
            VStack(spacing: 0) {
                // Top Section (70%) - App Icon, Title, Subtitle, Countdown
                HStack(spacing: 12) {
                    // Left: App Icon + Title + Subtitle (70%)
                    HStack(alignment: .center, spacing: 8) {
                        // App Icon
                        if let showAppIcon = context.state.data["showAppIcon"]?.asBool(), showAppIcon {
                            Image("AppIcon", bundle: .main)
                                .resizable()
                                .frame(width: context.state.data["iconSize"]?.asDouble() ?? 40.0, height: context.state.data["iconSize"]?.asDouble() ?? 40.0)
                                .clipShape(Circle())
                        }
                        
                        // Title & Subtitle
                        VStack(alignment: .leading, spacing: 2) {
                            // App Name
                            Text(context.state.data["appName"]?.asString() ?? "GOLD APP")
                                .font(.system(size: context.state.data["appNameSize"]?.asDouble() ?? 17.0, weight: .bold))
                                .foregroundColor(Color.fromHex(context.state.data["appNameColor"]?.asString(), fallback: .black))
                            
                            // Subtitle
                            Text(context.state.data["subtitle"]?.asString() ?? "Your deals are expiring")
                                .font(.system(size: context.state.data["subtitleSize"]?.asDouble() ?? 15.0))
                                .foregroundColor(Color.fromHex(context.state.data["subtitleColor"]?.asString(), fallback: .secondary))
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    // Right: Countdown Section (30%)
                    HStack(alignment: .center, spacing: 6) {
                        VStack(alignment: .center, spacing: 0) {
                            // "ENDS IN" label
                            Text(context.state.data["countdownLabel"]?.asString() ?? "ENDS IN")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.fromHex(context.state.data["countdownLabelColor"]?.asString(), fallback: .secondary))
                            
                            // Countdown Timer
                            if let countdownSeconds = getCountdownSeconds() {
                                let endDate = Date().addingTimeInterval(countdownSeconds)
                                Text(timerInterval: Date()...endDate, countsDown: true)
                                    .font(.system(size: 24, weight: .bold))
                                    .monospacedDigit()
                                    .foregroundColor(Color.fromHex(context.state.data["countdownTimerColor"]?.asString(), fallback: .black))
                            } else {
                                Text("--:--")
                                    .font(.system(size: 24, weight: .bold))
                                    .monospacedDigit()
                                    .foregroundColor(Color.fromHex(context.state.data["countdownTimerColor"]?.asString(), fallback: .black))
                            }
                        }
                        
                        // Emoji on the side
                        if let showHourglassEmoji = context.state.data["showHourglassEmoji"]?.asBool(), showHourglassEmoji {
                            Text(context.state.data["emojiCharacter"]?.asString() ?? "⏳")
                                .font(.system(size: 60))
                                .scaleEffect((context.state.data["emojiSize"]?.asDouble() ?? 20.0) / 60.0)
                        }
                    }
                }
                .frame(height: 112) // ~70% of 160pt total
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Button Section (30%) - Visual CTA
                Text((context.state.data["buttonText"]?.asString() ?? "Claim your Deals") + " ↗")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.fromHex(context.state.data["buttonTextColor"]?.asString(), fallback: .black))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.fromHex(context.state.data["buttonColor"]?.asString(), fallback: Color(red: 0.89, green: 0.97, blue: 0.37)))
                    .cornerRadius(context.state.data["buttonBorderRadius"]?.asDouble() ?? 12.0)
                    .padding(.horizontal, 16)
                    .padding(.bottom, context.state.data["buttonBottomPadding"]?.asDouble() ?? 16.0)
            }
            .frame(height: 160) // Fixed height for V1
            .background(gradientBackground)
            .cornerRadius(16)
            .widgetURL(URL(string: context.state.data["deepLinkUrl"]?.asString() ?? "gold-app://golden-hour"))
            .id("\(context.state.data["appNameSize"]?.asDouble() ?? 17.0)-\(context.state.data["emojiSize"]?.asDouble() ?? 20.0)-\(context.state.data["buttonBorderRadius"]?.asDouble() ?? 12.0)")
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
    
    // MARK: - Helper Functions
    
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

