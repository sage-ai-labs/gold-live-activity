import SwiftUI
import WidgetKit
import OneSignalLiveActivities
import os.log

#if canImport(ActivityKit)

@available(iOS 16.1, *)
struct LiveActivityView: View {
    let context: ActivityViewContext<DefaultLiveActivityAttributes>
    private let logger = Logger(subsystem: "com.usegold.app", category: "LiveActivity")

    private var layoutVariant: String {
        context.state.data["layoutVariant"]?.asString() ?? "tiffany"
    }

    var body: some View {
        if let shouldShow = context.state.data["shouldShow"]?.asBool(), !shouldShow {
            EmptyView()
        } else {
            Group {
                switch layoutVariant {
                case "tiffany":
                    tiffanyLayout
                default:
                    javiLayout
                }
            }
            .frame(height: 160)
            .background(gradientBackground)
            .cornerRadius(16)
            .onesignalWidgetURL(URL(string: context.state.data["deepLinkUrl"]?.asString() ?? "gold-app://golden-hour"), context: context)
            .onAppear {
                logReceivedData()
            }
        }
    }

    // MARK: - Javi Layout (original)

    private var javiLayout: some View {
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
                        Text(context.state.data["title"]?.asString() ?? "GOLD APP")
                            .font(getFont(context.state.data, familyKey: "titleFont", sizeKey: "titleSize", weightKey: "titleWeight", fallbackSize: 17.0, fallbackWeight: .bold))
                            .foregroundColor(Color.fromHex(context.state.data["titleColor"]?.asString(), fallback: .black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .background(isDebugSpacing ? Color.cyan.opacity(0.4) : Color.clear)
                    }

                    // Row 2: Subtitle
                    Text(context.state.data["subtitle"]?.asString() ?? "Your deals are expiring")
                        .font(getFont(context.state.data, familyKey: "subtitleFont", sizeKey: "subtitleSize", weightKey: "subtitleWeight", fallbackSize: 15.0, fallbackWeight: .regular))
                        .foregroundColor(Color.fromHex(context.state.data["subtitleColor"]?.asString(), fallback: .secondary))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .background(isDebugSpacing ? Color.mint.opacity(0.4) : Color.clear)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isDebugSpacing ? Color.blue.opacity(0.2) : Color.clear)

                // Right: Countdown + Emoji
                HStack(alignment: .center, spacing: getDouble("countdownEmojiSpacing", fallback: 4.0)) {
                    if context.state.data["showCountdown"]?.asBool() ?? true {
                        VStack(alignment: .leading, spacing: 0) {
                            // "ENDS IN" label
                            Text(context.state.data["countdownLabel"]?.asString() ?? "ENDS IN")
                                .font(getFont(context.state.data, familyKey: "countdownLabelFont", sizeKey: "countdownLabelSize", weightKey: "countdownLabelWeight", fallbackSize: 11.0, fallbackWeight: .medium))
                                .foregroundColor(Color.fromHex(context.state.data["countdownLabelColor"]?.asString(), fallback: .secondary))
                                .background(isDebugSpacing ? Color.yellow.opacity(0.5) : Color.clear)

                            // Countdown Timer
                            if let countdownSeconds = getCountdownSeconds() {
                                let endDate = Date().addingTimeInterval(countdownSeconds)
                                Text(timerInterval: Date()...endDate, countsDown: true)
                                    .font(getFont(context.state.data, familyKey: "countdownTimerFont", sizeKey: "countdownTimerSize", weightKey: "countdownTimerWeight", fallbackSize: 24.0, fallbackWeight: .bold))
                                    .monospacedDigit()
                                    .foregroundColor(Color.fromHex(context.state.data["countdownTimerColor"]?.asString(), fallback: .black))
                                    .frame(width: getDouble("countdownTimerWidth", fallback: 72.0))
                                    .background(isDebugSpacing ? Color.pink.opacity(0.4) : Color.clear)
                            } else {
                                Text("--:--")
                                    .font(getFont(context.state.data, familyKey: "countdownTimerFont", sizeKey: "countdownTimerSize", weightKey: "countdownTimerWeight", fallbackSize: 24.0, fallbackWeight: .bold))
                                    .monospacedDigit()
                                    .foregroundColor(Color.fromHex(context.state.data["countdownTimerColor"]?.asString(), fallback: .black))
                                    .frame(width: getDouble("countdownTimerWidth", fallback: 72.0))
                                    .background(isDebugSpacing ? Color.pink.opacity(0.4) : Color.clear)
                            }
                        }
                        .background(isDebugSpacing ? Color.purple.opacity(0.3) : Color.clear)
                    }

                    // Emoji on the side
                    if let showEmoji = context.state.data["showEmoji"]?.asBool(), showEmoji {
                        Text(context.state.data["emojiCharacter"]?.asString() ?? "⏳")
                            .font(.system(size: getDouble("emojiSize", fallback: 20.0)))
                            .background(isDebugSpacing ? Color.red.opacity(0.4) : Color.clear)
                    }
                }
                .background(isDebugSpacing ? Color.red.opacity(0.2) : Color.clear)
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

            // Button Section (30%) - Visual CTA
            if context.state.data["showButton"]?.asBool() ?? true {
                let btnTextColor = Color.fromHex(context.state.data["buttonTextColor"]?.asString(), fallback: .black)
                let btnSize = CGFloat(getDouble("buttonTextSize", fallback: 16.0))
                (Text(context.state.data["buttonText"]?.asString() ?? "Claim your Deals")
                    .font(getFont(context.state.data, familyKey: "buttonFont", sizeKey: "buttonTextSize", weightKey: "buttonWeight", fallbackSize: 16.0, fallbackWeight: .bold))
                + Text(" \u{2197}")
                    .font(.system(size: btnSize, weight: .bold)))
                    .foregroundColor(btnTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.fromHex(context.state.data["buttonColor"]?.asString(), fallback: Color(red: 0.89, green: 0.97, blue: 0.37)))
                    .cornerRadius(getDouble("buttonBorderRadius", fallback: 12.0))
                    .padding(.horizontal, 16)
                    .padding(.bottom, getDouble("buttonBottomPadding", fallback: 16.0))
            }
        }
    }

    // MARK: - Tiffany Layout
    //
    // ┌──────────────────────────────────────────┐
    // │                                 [ℹ️ icon]│
    // │ GOLDEN HOUR ENDS                  11:01  │
    // │ SOON                                     │
    // │                                          │
    // │ ┌──────────────────────────────────────┐ │
    // │ │       Claim your Deals ↗             │ │
    // │ └──────────────────────────────────────┘ │
    // └──────────────────────────────────────────┘

    private var tiffanyLayout: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Top section: Title + Countdown side by side
                GeometryReader { geo in
                    let titleMaxWidth = geo.size.width * CGFloat(getDouble("titleMaxWidthFraction", fallback: 0.45))
                    HStack(alignment: .center, spacing: CGFloat(getDouble("titleCountdownSpacing", fallback: 16.0))) {
                        // Left: Multi-line title (capped width so countdown always has room)
                        Text(context.state.data["title"]?.asString() ?? "GOLDEN HOUR ENDS SOON")
                            .font(getFont(context.state.data, familyKey: "titleFont", sizeKey: "titleSize", weightKey: "titleWeight", fallbackSize: 24.0, fallbackWeight: .bold))
                            .foregroundColor(Color.fromHex(context.state.data["titleColor"]?.asString(), fallback: .black))
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                            .padding(.leading, CGFloat(getDouble("titleLeftPadding", fallback: 0.0)))
                            .frame(maxWidth: titleMaxWidth, alignment: .leading)
                            .background(isDebugSpacing ? Color.cyan.opacity(0.4) : Color.clear)

                        Spacer(minLength: 0)

                        // Right: Large countdown timer (pushed to trailing edge)
                        if context.state.data["showCountdown"]?.asBool() ?? true {
                            if let countdownSeconds = getCountdownSeconds() {
                                let endDate = Date().addingTimeInterval(countdownSeconds)
                                Text(timerInterval: Date()...endDate, countsDown: true)
                                    .font(getFont(context.state.data, familyKey: "countdownTimerFont", sizeKey: "countdownTimerSize", weightKey: "countdownTimerWeight", fallbackSize: 48.0, fallbackWeight: .bold))
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .foregroundColor(Color.fromHex(context.state.data["countdownTimerColor"]?.asString(), fallback: .black))
                                    .frame(width: getDouble("countdownTimerWidth", fallback: 145.0), alignment: .trailing)
                                    .clipped()
                                    .layoutPriority(1)
                                    .background(isDebugSpacing ? Color.pink.opacity(0.4) : Color.clear)
                            } else {
                                Text("--:--")
                                    .font(getFont(context.state.data, familyKey: "countdownTimerFont", sizeKey: "countdownTimerSize", weightKey: "countdownTimerWeight", fallbackSize: 48.0, fallbackWeight: .bold))
                                    .monospacedDigit()
                                    .foregroundColor(Color.fromHex(context.state.data["countdownTimerColor"]?.asString(), fallback: .black))
                                    .frame(width: getDouble("countdownTimerWidth", fallback: 145.0), alignment: .trailing)
                                    .clipped()
                                    .layoutPriority(1)
                                    .background(isDebugSpacing ? Color.pink.opacity(0.4) : Color.clear)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Button Section
                if context.state.data["showButton"]?.asBool() ?? true {
                    let btnTextColor = Color.fromHex(context.state.data["buttonTextColor"]?.asString(), fallback: .black)
                    let btnSize = CGFloat(getDouble("buttonTextSize", fallback: 16.0))
                    (Text(context.state.data["buttonText"]?.asString() ?? "Claim your Deals")
                        .font(getFont(context.state.data, familyKey: "buttonFont", sizeKey: "buttonTextSize", weightKey: "buttonWeight", fallbackSize: 16.0, fallbackWeight: .bold))
                    + Text(" \u{2197}")
                        .font(.system(size: btnSize, weight: .bold)))
                        .foregroundColor(btnTextColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.fromHex(context.state.data["buttonColor"]?.asString(), fallback: Color(red: 0.89, green: 0.97, blue: 0.37)))
                        .cornerRadius(getDouble("buttonBorderRadius", fallback: 50.0))
                        .padding(.horizontal, 16)
                        .padding(.bottom, getDouble("buttonBottomPadding", fallback: 16.0))
                }
            }

            // Info icon badge (top-right)
            if context.state.data["showInfoIcon"]?.asBool() ?? true {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: getDouble("infoIconSize", fallback: 24.0)))
                    .foregroundColor(.red)
                    .padding(.top, CGFloat(getDouble("infoIconTopPadding", fallback: 12.0)))
                    .padding(.trailing, CGFloat(getDouble("infoIconTrailingPadding", fallback: 16.0)))
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
        logger.info("🔄 [LiveActivity] Widget body rendering (variant: \(layoutVariant))")
        logger.info("📊 [LiveActivity] titleSize: \(getDouble("titleSize", fallback: -1))")
        logger.info("📊 [LiveActivity] subtitleSize: \(getDouble("subtitleSize", fallback: -1))")
        logger.info("📊 [LiveActivity] iconSize: \(getDouble("iconSize", fallback: -1))")
        logger.info("📊 [LiveActivity] emojiSize: \(getDouble("emojiSize", fallback: -1))")
        logger.info("📊 [LiveActivity] countdownLabelSize: \(getDouble("countdownLabelSize", fallback: -1))")
        logger.info("📊 [LiveActivity] countdownTimerSize: \(getDouble("countdownTimerSize", fallback: -1))")
        logger.info("📊 [LiveActivity] countdownEmojiSpacing: \(getDouble("countdownEmojiSpacing", fallback: -1))")
        logger.info("📊 [LiveActivity] buttonBorderRadius: \(getDouble("buttonBorderRadius", fallback: -1))")
        logger.info("📝 [LiveActivity] title: \(context.state.data["title"]?.asString() ?? "nil")")
        logger.info("📝 [LiveActivity] subtitle: \(context.state.data["subtitle"]?.asString() ?? "nil")")
        logger.info("🎨 [LiveActivity] backgroundColor1: \(context.state.data["backgroundColor1"]?.asString() ?? "nil")")
        logger.info("🎨 [LiveActivity] backgroundColor2: \(context.state.data["backgroundColor2"]?.asString() ?? "nil")")
        logger.info("🎨 [LiveActivity] countdownLabelColor: \(context.state.data["countdownLabelColor"]?.asString() ?? "nil")")
        logger.info("🎨 [LiveActivity] countdownTimerColor: \(context.state.data["countdownTimerColor"]?.asString() ?? "nil")")

        // Log ALL keys in the data dictionary
        logger.info("🔑 [LiveActivity] All data keys: \(context.state.data.keys)")
    }

    /// Convenience wrapper around the shared getData helper
    private func getDouble(_ key: String, fallback: Double) -> Double {
        return getData(context.state.data, key: key, fallback: fallback)
    }

    private func getCountdownSeconds() -> Double? {
        return getCountdownSecondsFromData(context.state.data)
    }
}

#endif

