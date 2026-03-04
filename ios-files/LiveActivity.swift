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

/// Pure function: parse an ISO 8601 string and return seconds until that date, or nil if past/invalid.
/// Extracted for testability — no OneSignal dependency.
func secondsUntilISO8601Date(_ isoString: String) -> Double? {
    let formatter = ISO8601DateFormatter()

    // Try with fractional seconds first (e.g. "2026-01-16T02:45:00.000Z")
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let endDate = formatter.date(from: isoString) {
        let seconds = endDate.timeIntervalSinceNow
        return seconds > 0 ? seconds : nil
    }

    // Fallback: without fractional seconds (e.g. "2026-01-16T02:45:00Z")
    formatter.formatOptions = [.withInternetDateTime]
    if let endDate = formatter.date(from: isoString) {
        let seconds = endDate.timeIntervalSinceNow
        return seconds > 0 ? seconds : nil
    }

    return nil
}

/// Parse countdown seconds from OneSignal data
func getCountdownSecondsFromData(_ data: [String: OneSignalLiveActivities.AnyCodable]) -> Double? {
    // Legacy duration from server (upper bound — used to cap end-time calculation)
    let legacySeconds: Double? = {
        if let v = data["countdownSeconds"]?.asDouble() { return v }
        if let v = data["countdownSeconds"]?.asInt() { return Double(v) }
        if let s = data["countdownSeconds"]?.asString(), let v = Double(s) { return v }
        return nil
    }()

    // Prefer absolute end time for accuracy (handles late delivery)
    if let isoString = data["goldenHourEndTime"]?.asString(),
       let endTimeSeconds = secondsUntilISO8601Date(isoString) {
        // Cap at legacySeconds if present — end time should never exceed what server promised
        if let cap = legacySeconds {
            return min(endTimeSeconds, cap)
        }
        return endTimeSeconds
    }

    return legacySeconds
}

// MARK: - Golden Hour Live Activity Widget (OneSignal Cross-Platform Implementation)
// Uses OneSignal's DefaultLiveActivityAttributes for cross-platform compatibility

@available(iOS 16.2, *)
struct LiveActivity: Widget {
    var body: some WidgetConfiguration {
        let config = ActivityConfiguration(for: DefaultLiveActivityAttributes.self) { context in
            // Lock screen / banner + Apple Watch supplemental band
            LiveActivityContentView(context: context)
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
                        .clipShape(Circle())
                }
            } compactTrailing: {
                // MARK: - Compact Trailing
                if let seconds = getCountdownSecondsFromData(context.state.data), seconds > 0 {
                    Text(timerInterval: Date()...Date().addingTimeInterval(seconds), countsDown: true)
                        .font(getFont(context.state.data, familyKey: "diCompactTrailingFont", sizeKey: "diCompactTrailingCountdownSize", weightKey: "diCompactTrailingWeight", fallbackSize: 14.0, fallbackWeight: .bold))
                        .monospacedDigit()
                        .foregroundColor(Color.fromHex(context.state.data["diCompactTrailingCountdownColor"]?.asString(), fallback: .white))
                        .frame(width: CGFloat(getData(context.state.data, key: "diCompactTrailingCountdownWidth", fallback: 50.0)), alignment: .trailing)
                        .multilineTextAlignment(.trailing)
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
            .onesignalWidgetURL(URL(string: context.state.data["deepLinkUrl"]?.asString() ?? "gold-app://golden-hour"), context: context)
        }

        if #available(iOS 18.0, *) {
            return config.supplementalActivityFamilies([.small])
        } else {
            return config
        }
    }
}

// MARK: - Content View Router (iPhone lock screen vs Apple Watch)

@available(iOS 16.2, *)
struct LiveActivityContentView: View {
    let context: ActivityViewContext<DefaultLiveActivityAttributes>

    var body: some View {
        if #available(iOS 18.0, *) {
            LiveActivityContentViewiOS18(context: context)
        } else {
            LiveActivityView(context: context)
        }
    }
}

@available(iOS 18.0, *)
struct LiveActivityContentViewiOS18: View {
    let context: ActivityViewContext<DefaultLiveActivityAttributes>
    @Environment(\.activityFamily) var activityFamily

    var body: some View {
        switch activityFamily {
        case .small:
            WatchBandView(data: context.state.data)
        default:
            LiveActivityView(context: context)
        }
    }
}

// MARK: - Apple Watch Supplemental Band View

@available(iOS 16.2, *)
struct WatchBandView: View {
    let data: [String: OneSignalLiveActivities.AnyCodable]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Row 1: icon + countdown
            HStack(spacing: 6) {
                Image("GoldAppIcon")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                if let seconds = getCountdownSecondsFromData(data), seconds > 0 {
                    Text(timerInterval: Date()...Date().addingTimeInterval(seconds), countsDown: true)
                        .font(.system(size: 18, weight: .bold))
                        .monospacedDigit()
                        .foregroundColor(.white)
                }

                Spacer()
            }

            // Title
            Text(data["watchTitle"]?.asString()
                 ?? data["title"]?.asString()
                 ?? "GOLDEN HOUR")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            // Subtitle
            if let subtitle = data["watchSubtitle"]?.asString()
                              ?? data["subtitle"]?.asString() {
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
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
                    .font(getFont(data, familyKey: "diExpandedCountdownFont", sizeKey: "diExpandedCountdownSize", weightKey: "diExpandedCountdownWeight", fallbackSize: 20.0, fallbackWeight: .bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(Color.fromHex(data["diExpandedCountdownColor"]?.asString(), fallback: .white))
                    .frame(width: CGFloat(getData(data, key: "diExpandedCountdownWidth", fallback: 90.0)))
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

// MARK: - Tiffany Dynamic Island Expanded Bottom
// Layout: icon + label on left, centered countdown


