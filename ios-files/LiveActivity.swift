import ActivityKit
import SwiftUI
import WidgetKit
import OneSignalLiveActivities
import os.log

private let fontLogger = Logger(subsystem: "com.usegold.app", category: "LiveActivityFont")

// MARK: - Shared Helpers for OneSignal data parsing

/// Safely parse a numeric value from OneSignal data.
/// OneSignal may send numbers as Double, Int, or String depending on the update method.
func getData(_ data: [String: OneSignalLiveActivities.AnyCodable], key: String, fallback: Double) -> Double {
    if let val = data[key]?.asDouble() {
        return val
    } else if let val = data[key]?.asInt() {
        return Double(val)
    } else if let str = data[key]?.asString(), let val = Double(str) {
        return val
    }
    return fallback
}

/// Log all available font families and their font names (call once for debugging)
func logAvailableFonts() {
    for family in UIFont.familyNames.sorted() {
        let names = UIFont.fontNames(forFamilyName: family)
        if family.lowercased().contains("gunterz") || family.lowercased().contains("manrope") {
            fontLogger.info("🔤 Font family: \(family) → \(names)")
        }
    }
}

/// Map a remote font family + weight string to a SwiftUI Font.
/// Uses UIFont to verify the font exists, with proper bold system fallback.
func getFont(_ data: [String: OneSignalLiveActivities.AnyCodable], familyKey: String, sizeKey: String, weightKey: String, fallbackSize: Double, fallbackWeight: Font.Weight = .regular) -> Font {
    let size = CGFloat(getData(data, key: sizeKey, fallback: fallbackSize))
    let family = data[familyKey]?.asString()?.lowercased()
    let weight = data[weightKey]?.asString()?.lowercased() ?? ""

    // System font fallback
    guard let family = family, family != "system" else {
        return .system(size: size, weight: swiftUIWeight(weight, fallback: fallbackWeight))
    }

    // Map to PostScript font names
    let fontName: String
    switch family {
    case "gunterz":
        switch weight {
        case "bold": fontName = "Gunterz-Bold"
        case "medium": fontName = "Gunterz-Medium"
        default: fontName = "Gunterz-Regular"
        }
    case "manrope":
        switch weight {
        case "bold": fontName = "Manrope-Bold"
        case "semibold": fontName = "Manrope-SemiBold"
        case "medium": fontName = "Manrope-Medium"
        default: fontName = "Manrope-Regular"
        }
    default:
        return .system(size: size, weight: swiftUIWeight(weight, fallback: fallbackWeight))
    }

    // Use UIFont to verify the font exists — if not, log and fall back to system with correct weight
    if let uiFont = UIFont(name: fontName, size: size) {
        fontLogger.info("✅ Font loaded: \(fontName) at \(size)pt")
        return Font(uiFont)
    } else {
        fontLogger.error("❌ Font NOT FOUND: \(fontName) — falling back to system. Available fonts for debugging:")
        logAvailableFonts()
        let uiWeight: UIFont.Weight
        switch weight {
        case "bold": uiWeight = .bold
        case "semibold": uiWeight = .semibold
        case "medium": uiWeight = .medium
        default: uiWeight = fallbackWeight == .bold ? .bold : .regular
        }
        return Font(UIFont.systemFont(ofSize: size, weight: uiWeight))
    }
}

/// Convert a weight string to SwiftUI Font.Weight
private func swiftUIWeight(_ weight: String, fallback: Font.Weight) -> Font.Weight {
    switch weight {
    case "regular": return .regular
    case "medium": return .medium
    case "semibold": return .semibold
    case "bold": return .bold
    case "heavy": return .heavy
    default: return fallback
    }
}

/// Parse countdown seconds from OneSignal data
func getCountdownSecondsFromData(_ data: [String: OneSignalLiveActivities.AnyCodable]) -> Double? {
    if let countdownSeconds = data["countdownSeconds"]?.asDouble() {
        return countdownSeconds
    } else if let countdownSecondsInt = data["countdownSeconds"]?.asInt() {
        return Double(countdownSecondsInt)
    } else if let countdownSecondsString = data["countdownSeconds"]?.asString(),
              let countdownValue = Double(countdownSecondsString) {
        return countdownValue
    }
    return nil
}

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
                // MARK: - Expanded (long-press)
                DynamicIslandExpandedRegion(.leading) {
                    DynamicIslandLeadingView(data: context.state.data)
                }

                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }

                DynamicIslandExpandedRegion(.trailing) {
                    DynamicIslandTrailingView(data: context.state.data)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    DynamicIslandBottomView(data: context.state.data)
                }
            } compactLeading: {
                // MARK: - Compact Leading (icon or emoji)
                if (context.state.data["diCompactLeadingType"]?.asString() ?? "icon") == "emoji" {
                    Text(context.state.data["emojiCharacter"]?.asString() ?? "⏳")
                        .font(.system(size: CGFloat(getData(context.state.data, key: "diCompactLeadingEmojiSize", fallback: 16.0))))
                } else {
                    Image("GoldAppIcon")
                        .resizable()
                        .frame(
                            width: CGFloat(getData(context.state.data, key: "diCompactLeadingIconSize", fallback: 20.0)),
                            height: CGFloat(getData(context.state.data, key: "diCompactLeadingIconSize", fallback: 20.0))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: CGFloat(getData(context.state.data, key: "diCompactLeadingIconBorderRadius", fallback: 5.0))))
                }
            } compactTrailing: {
                // MARK: - Compact Trailing
                if let seconds = getCountdownSecondsFromData(context.state.data), seconds > 0 {
                    Text(timerInterval: Date()...Date().addingTimeInterval(seconds), countsDown: true)
                        .font(.system(size: CGFloat(getData(context.state.data, key: "diCompactTrailingCountdownSize", fallback: 14.0)), weight: .bold))
                        .monospacedDigit()
                        .foregroundColor(Color.fromHex(context.state.data["diCompactTrailingCountdownColor"]?.asString(), fallback: .white))
                        .frame(width: CGFloat(getData(context.state.data, key: "diCompactTrailingCountdownWidth", fallback: 50.0)))
                } else {
                    Text(context.state.data["emojiCharacter"]?.asString() ?? "⏳")
                        .font(.system(size: 14))
                }
            } minimal: {
                // MARK: - Minimal (icon or emoji)
                if (context.state.data["diMinimalType"]?.asString() ?? "icon") == "emoji" {
                    Text(context.state.data["emojiCharacter"]?.asString() ?? "⏳")
                        .font(.system(size: CGFloat(getData(context.state.data, key: "diMinimalEmojiSize", fallback: 16.0))))
                } else {
                    Image("GoldAppIcon")
                        .resizable()
                        .frame(
                            width: CGFloat(getData(context.state.data, key: "diMinimalIconSize", fallback: 20.0)),
                            height: CGFloat(getData(context.state.data, key: "diMinimalIconSize", fallback: 20.0))
                        )
                        .clipShape(Circle())
                }
            }
            .widgetURL(URL(string: context.state.data["deepLinkUrl"]?.asString() ?? "gold-app://golden-hour"))
        }
    }
}

// MARK: - Dynamic Island Sub-Views
// Extracted into separate structs to avoid @ViewBuilder complexity in DynamicIsland closures

@available(iOS 16.2, *)
struct DynamicIslandCompactLeadingView: View {
    let data: [String: OneSignalLiveActivities.AnyCodable]

    private var showDI: Bool { data["showDynamicIsland"]?.asBool() ?? true }
    private var emoji: String { data["emojiCharacter"]?.asString() ?? "⏳" }
    private var leadingType: String { data["diCompactLeadingType"]?.asString() ?? "icon" }

    var body: some View {
        if showDI && leadingType == "emoji" {
            Text(emoji)
                .font(.system(size: CGFloat(getData(data, key: "diCompactLeadingEmojiSize", fallback: 16.0))))
        } else {
            Image("GoldAppIcon")
                .resizable()
                .frame(
                    width: CGFloat(getData(data, key: "diCompactLeadingIconSize", fallback: 20.0)),
                    height: CGFloat(getData(data, key: "diCompactLeadingIconSize", fallback: 20.0))
                )
                .clipShape(RoundedRectangle(cornerRadius: CGFloat(getData(data, key: "diCompactLeadingIconBorderRadius", fallback: 5.0))))
        }
    }
}

@available(iOS 16.2, *)
struct DynamicIslandCompactTrailingView: View {
    let data: [String: OneSignalLiveActivities.AnyCodable]

    private var showDI: Bool { data["showDynamicIsland"]?.asBool() ?? true }
    private var emoji: String { data["emojiCharacter"]?.asString() ?? "⏳" }

    var body: some View {
        if showDI {
            countdownOrText
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var countdownOrText: some View {
        if data["diCompactTrailingShowCountdown"]?.asBool() ?? true {
            countdownView
        } else {
            textOrEmojiFallback
        }
    }

    @ViewBuilder
    private var countdownView: some View {
        if let seconds = getCountdownSecondsFromData(data), seconds > 0 {
            Text(timerInterval: Date()...Date().addingTimeInterval(seconds), countsDown: true, showsHours: data["diCompactTrailingShowHours"]?.asBool() ?? false)
                .font(.system(size: CGFloat(getData(data, key: "diCompactTrailingCountdownSize", fallback: 14.0)), weight: .bold))
                .monospacedDigit()
                .foregroundColor(Color.fromHex(data["diCompactTrailingCountdownColor"]?.asString(), fallback: .white))
                .frame(width: CGFloat(getData(data, key: "diCompactTrailingCountdownWidth", fallback: 50.0)))
        } else {
            Text(emoji)
                .font(.system(size: 14))
        }
    }

    @ViewBuilder
    private var textOrEmojiFallback: some View {
        if let text = data["diCompactTrailingText"]?.asString(), !text.isEmpty {
            Text(text)
                .font(.system(size: CGFloat(getData(data, key: "diCompactTrailingTextSize", fallback: 14.0)), weight: .bold))
                .foregroundColor(Color.fromHex(data["diCompactTrailingTextColor"]?.asString(), fallback: .white))
        } else {
            Text(emoji)
                .font(.system(size: 14))
        }
    }
}

@available(iOS 16.2, *)
struct DynamicIslandLeadingView: View {
    let data: [String: OneSignalLiveActivities.AnyCodable]

    private var showDI: Bool { data["showDynamicIsland"]?.asBool() ?? true }
    private var emoji: String { data["emojiCharacter"]?.asString() ?? "⏳" }

    var body: some View {
        if showDI {
            if (data["diExpandedLeadingType"]?.asString() ?? "icon") == "emoji" {
                Text(emoji)
                    .font(.system(size: CGFloat(getData(data, key: "diExpandedEmojiSize", fallback: 24.0))))
                    .padding(.leading, 4)
                    .padding(.top, 4)
            } else {
                Image("GoldAppIcon")
                    .resizable()
                    .frame(
                        width: CGFloat(getData(data, key: "diExpandedIconSize", fallback: 28.0)),
                        height: CGFloat(getData(data, key: "diExpandedIconSize", fallback: 28.0))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: CGFloat(getData(data, key: "diExpandedIconBorderRadius", fallback: 6.0))))
                    .padding(.leading, 4)
                    .padding(.top, 4)
            }
        }
    }
}

@available(iOS 16.2, *)
struct DynamicIslandBottomView: View {
    let data: [String: OneSignalLiveActivities.AnyCodable]

    private var showDI: Bool { data["showDynamicIsland"]?.asBool() ?? true }

    var body: some View {
        if showDI {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(data["diExpandedTitle"]?.asString()
                         ?? data["title"]?.asString()
                         ?? "GOLD APP")
                        .font(getFont(data, familyKey: "diExpandedTitleFont", sizeKey: "diExpandedTitleSize", weightKey: "diExpandedTitleWeight", fallbackSize: 16.0, fallbackWeight: .bold))
                        .foregroundColor(Color.fromHex(data["diExpandedTitleColor"]?.asString(), fallback: .white))
                        .lineLimit(1)

                    if data["diExpandedShowSubtitle"]?.asBool() ?? true {
                        Text(data["diExpandedSubtitle"]?.asString()
                             ?? data["subtitle"]?.asString()
                             ?? "Your deals are expiring")
                            .font(getFont(data, familyKey: "diExpandedSubtitleFont", sizeKey: "diExpandedSubtitleSize", weightKey: "diExpandedSubtitleWeight", fallbackSize: 14.0, fallbackWeight: .regular))
                            .foregroundColor(Color.fromHex(data["diExpandedSubtitleColor"]?.asString(), fallback: .secondary))
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(.leading, 4)
            .padding(.bottom, 4)
        }
    }
}

@available(iOS 16.2, *)
struct DynamicIslandTrailingView: View {
    let data: [String: OneSignalLiveActivities.AnyCodable]

    private var showDI: Bool { data["showDynamicIsland"]?.asBool() ?? true }
    private var emoji: String { data["emojiCharacter"]?.asString() ?? "⏳" }

    var body: some View {
        if showDI, data["diExpandedShowCountdown"]?.asBool() ?? true {
            if let seconds = getCountdownSecondsFromData(data), seconds > 0 {
                Text(timerInterval: Date()...Date().addingTimeInterval(seconds), countsDown: true, showsHours: data["diExpandedShowHours"]?.asBool() ?? false)
                    .font(.system(size: CGFloat(getData(data, key: "diExpandedCountdownSize", fallback: 20.0)), weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(Color.fromHex(data["diExpandedCountdownColor"]?.asString(), fallback: .white))
                    .frame(width: CGFloat(getData(data, key: "diExpandedCountdownWidth", fallback: 60.0)))
            } else {
                Text(emoji)
                    .font(.system(size: 20))
            }
        }
    }
}

@available(iOS 16.2, *)
struct DynamicIslandMinimalView: View {
    let data: [String: OneSignalLiveActivities.AnyCodable]

    private var showDI: Bool { data["showDynamicIsland"]?.asBool() ?? true }
    private var emoji: String { data["emojiCharacter"]?.asString() ?? "⏳" }

    var body: some View {
        if showDI && (data["diMinimalType"]?.asString() ?? "icon") == "emoji" {
            Text(emoji)
                .font(.system(size: CGFloat(getData(data, key: "diMinimalEmojiSize", fallback: 16.0))))
        } else {
            Image("GoldAppIcon")
                .resizable()
                .frame(
                    width: CGFloat(getData(data, key: "diMinimalIconSize", fallback: 20.0)),
                    height: CGFloat(getData(data, key: "diMinimalIconSize", fallback: 20.0))
                )
                .clipShape(Circle())
        }
    }
}
