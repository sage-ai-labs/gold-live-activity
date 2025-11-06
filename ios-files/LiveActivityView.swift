import SwiftUI
import WidgetKit
import OneSignalLiveActivities

#if canImport(ActivityKit)

@available(iOS 16.1, *)
struct LiveActivityView: View {
    let context: ActivityViewContext<DefaultLiveActivityAttributes>

    var body: some View {
      // Check if shouldShow is false, if so, don't render any UI
      if let shouldShow = context.state.data["shouldShow"]?.asBool(), !shouldShow {
        EmptyView()
      } else {
        VStack(spacing: 0) {
          // Title from OneSignal state - now controllable
          if let showTitle = context.state.data["showTitle"]?.asBool(), showTitle {
            Text(context.state.data["title"]?.asDict()?["en"]?.asString() ?? "🏆 Golden Hour")
              .font(parseFont(context.state.data["titleFont"]?.asString(), size: 17, fallbackWeight: parseFontWeight(context.state.data["titleFontWeight"]?.asString())))
              .fontWeight(context.state.data["titleFont"]?.asString() != nil ? .regular : parseFontWeight(context.state.data["titleFontWeight"]?.asString()))
              .multilineTextAlignment(.center)
              .foregroundColor(parseColor(context.state.data["titleColor"]?.asString()) ?? Color.black.opacity(0.85))
          } else if context.state.data["showTitle"] == nil {
            // Default behavior when showTitle is not specified - show title
            Text(context.state.data["title"]?.asDict()?["en"]?.asString() ?? "🏆 Golden Hour")
              .font(parseFont(context.state.data["titleFont"]?.asString(), size: 17, fallbackWeight: parseFontWeight(context.state.data["titleFontWeight"]?.asString())))
              .fontWeight(context.state.data["titleFont"]?.asString() != nil ? .regular : parseFontWeight(context.state.data["titleFontWeight"]?.asString()))
              .multilineTextAlignment(.center)
              .foregroundColor(parseColor(context.state.data["titleColor"]?.asString()) ?? Color.black.opacity(0.85))
          }

          // Golden Hour countdown timer - now controllable
          if let showCountdown = context.state.data["showCountdown"]?.asBool(), showCountdown {
            countdownTimerView
          } else if context.state.data["showCountdown"] == nil {
            // Default behavior when showCountdown is not specified - show countdown
            countdownTimerView
          }

          // Progress bar (comes before subtitle) - now controllable
          if let showProgressBar = context.state.data["showProgressBar"]?.asBool(), showProgressBar {
            let progressValue: Double = {
              if let progress = context.state.data["progressValue"]?.asDouble() {
                return progress
              } else if let countdownSeconds = context.state.data["countdownSeconds"]?.asDouble() {
                // Calculate progress based on countdown (assuming 3600 seconds total)
                return max(0.0, min(1.0, countdownSeconds / 3600.0))
              } else if let countdownSecondsInt = context.state.data["countdownSeconds"]?.asInt() {
                // Calculate progress based on countdown as Int
                let countdown = Double(countdownSecondsInt)
                return max(0.0, min(1.0, countdown / 3600.0))
              } else if let countdownSecondsString = context.state.data["countdownSeconds"]?.asString(),
                        let countdownValue = Double(countdownSecondsString) {
                // Calculate progress based on countdown as String
                return max(0.0, min(1.0, countdownValue / 3600.0))
              } else {
                // No countdownSeconds provided, using 1-hour default, so start at 100% (full time remaining)
                return 1.0
              }
            }()
            
            ProgressView(value: progressValue)
              .progressViewStyle(LinearProgressViewStyle(tint: parseColor(context.state.data["progressBarColor"]?.asString()) ?? Color.orange))
              .scaleEffect(x: 1, y: 2, anchor: .center)
          } else if context.state.data["showProgressBar"] == nil {
            // Default behavior when showProgressBar is not specified - show progress bar
            let progressValue: Double = {
              if let progress = context.state.data["progressValue"]?.asDouble() {
                return progress
              } else if let countdownSeconds = context.state.data["countdownSeconds"]?.asDouble() {
                // Calculate progress based on countdown (assuming 3600 seconds total)
                return max(0.0, min(1.0, countdownSeconds / 3600.0))
              } else if let countdownSecondsInt = context.state.data["countdownSeconds"]?.asInt() {
                // Calculate progress based on countdown as Int
                let countdown = Double(countdownSecondsInt)
                return max(0.0, min(1.0, countdown / 3600.0))
              } else if let countdownSecondsString = context.state.data["countdownSeconds"]?.asString(),
                        let countdownValue = Double(countdownSecondsString) {
                // Calculate progress based on countdown as String
                return max(0.0, min(1.0, countdownValue / 3600.0))
              } else {
                // No countdownSeconds provided, using 1-hour default, so start at 100% (full time remaining)
                return 1.0
              }
            }()
            
            ProgressView(value: progressValue)
              .progressViewStyle(LinearProgressViewStyle(tint: parseColor(context.state.data["progressBarColor"]?.asString()) ?? Color.orange))
              .scaleEffect(x: 1, y: 2, anchor: .center)
          }

          // Subtitle from OneSignal state - now controllable
          if let showSubtitle = context.state.data["showSubtitle"]?.asBool(), showSubtitle {
            if let subtitle = context.state.data["subtitle"]?.asDict()?["en"]?.asString() {
              Text(subtitle)
                .font(parseFont(context.state.data["subtitleFont"]?.asString(), size: 15, fallbackWeight: parseFontWeight(context.state.data["subtitleFontWeight"]?.asString())))
                .fontWeight(context.state.data["subtitleFont"]?.asString() != nil ? .regular : parseFontWeight(context.state.data["subtitleFontWeight"]?.asString()))
                .multilineTextAlignment(.center)
                .foregroundColor(parseColor(context.state.data["subtitleColor"]?.asString()) ?? Color.black.opacity(0.7))
                .padding(.top, 8)
            }
          } else if context.state.data["showSubtitle"] == nil {
            // Default behavior when showSubtitle is not specified - show subtitle
            if let subtitle = context.state.data["subtitle"]?.asDict()?["en"]?.asString() {
              Text(subtitle)
                .font(parseFont(context.state.data["subtitleFont"]?.asString(), size: 15, fallbackWeight: parseFontWeight(context.state.data["subtitleFontWeight"]?.asString())))
                .fontWeight(context.state.data["subtitleFont"]?.asString() != nil ? .regular : parseFontWeight(context.state.data["subtitleFontWeight"]?.asString()))
                .multilineTextAlignment(.center)
                .foregroundColor(parseColor(context.state.data["subtitleColor"]?.asString()) ?? Color.black.opacity(0.7))
                .padding(.top, 8)
            }
          }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
          // Use backgroundColor from OneSignal state, fallback to default golden color
          Color.fromHex(context.state.data["backgroundColor"]?.asString() ?? "#F4FFB0")
        )
        .cornerRadius(16)
      }
    }
    
    // MARK: - Helper Views and Functions
    
    private var countdownTimerView: some View {
      Group {
        if let countdownSeconds = context.state.data["countdownSeconds"]?.asDouble() {
          let endDate = Date().addingTimeInterval(countdownSeconds)
          Text(timerInterval: Date()...endDate, countsDown: true)
            .font(parseCountdownFont(context.state.data["countdownFont"]?.asString(), size: 48, fallbackWeight: parseFontWeight(context.state.data["countdownFontWeight"]?.asString())))
            .fontWeight(context.state.data["countdownFont"]?.asString() != nil ? .regular : parseFontWeight(context.state.data["countdownFontWeight"]?.asString()))
            .monospacedDigit()
            .foregroundColor(parseColor(context.state.data["countdownColor"]?.asString()) ?? Color.black.opacity(0.9))
            .multilineTextAlignment(.center)
        } else if let countdownSecondsInt = context.state.data["countdownSeconds"]?.asInt() {
          // Try parsing as Int in case it's sent as integer
          let endDate = Date().addingTimeInterval(Double(countdownSecondsInt))
          Text(timerInterval: Date()...endDate, countsDown: true)
            .font(parseCountdownFont(context.state.data["countdownFont"]?.asString(), size: 48, fallbackWeight: parseFontWeight(context.state.data["countdownFontWeight"]?.asString())))
            .fontWeight(context.state.data["countdownFont"]?.asString() != nil ? .regular : parseFontWeight(context.state.data["countdownFontWeight"]?.asString()))
            .monospacedDigit()
            .foregroundColor(parseColor(context.state.data["countdownColor"]?.asString()) ?? Color.black.opacity(0.9))
            .multilineTextAlignment(.center)
        } else if let countdownSecondsString = context.state.data["countdownSeconds"]?.asString() {
          // Try parsing as String in case OneSignal sends it as string in push updates
          if let countdownValue = Double(countdownSecondsString) {
            let endDate = Date().addingTimeInterval(countdownValue)
            Text(timerInterval: Date()...endDate, countsDown: true)
              .font(parseCountdownFont(context.state.data["countdownFont"]?.asString(), size: 48, fallbackWeight: parseFontWeight(context.state.data["countdownFontWeight"]?.asString())))
              .fontWeight(context.state.data["countdownFont"]?.asString() != nil ? .regular : parseFontWeight(context.state.data["countdownFontWeight"]?.asString()))
              .monospacedDigit()
              .foregroundColor(parseColor(context.state.data["countdownColor"]?.asString()) ?? Color.black.opacity(0.9))
              .multilineTextAlignment(.center)
          } else {
            // Fallback with debug info
            Text("1:00:00 (String: \(countdownSecondsString))")
              .font(parseCountdownFont(context.state.data["countdownFont"]?.asString(), size: 48, fallbackWeight: parseFontWeight(context.state.data["countdownFontWeight"]?.asString())))
              .fontWeight(context.state.data["countdownFont"]?.asString() != nil ? .regular : parseFontWeight(context.state.data["countdownFontWeight"]?.asString()))
              .monospacedDigit()
              .foregroundColor(parseColor(context.state.data["countdownColor"]?.asString()) ?? Color.black.opacity(0.9))
              .multilineTextAlignment(.center)
          }
        } else {
          // Default 1-hour countdown if no countdownSeconds provided
          let defaultEndTime = Date().addingTimeInterval(3600) // 1 hour from now
          Text(timerInterval: Date()...defaultEndTime, countsDown: true)
            .font(parseCountdownFont(context.state.data["countdownFont"]?.asString(), size: 48, fallbackWeight: parseFontWeight(context.state.data["countdownFontWeight"]?.asString())))
            .fontWeight(context.state.data["countdownFont"]?.asString() != nil ? .regular : parseFontWeight(context.state.data["countdownFontWeight"]?.asString()))
            .monospacedDigit()
            .foregroundColor(parseColor(context.state.data["countdownColor"]?.asString()) ?? Color.black.opacity(0.9))
            .multilineTextAlignment(.center)
        }
      }
    }
    
    private func parseColor(_ colorString: String?) -> Color? {
      guard let colorString = colorString else { return nil }
      return Color.fromHex(colorString)
    }
    
    private func parseFontWeight(_ fontWeightString: String?) -> Font.Weight {
      guard let fontWeightString = fontWeightString?.lowercased() else { return .regular }
      
      switch fontWeightString {
      case "ultralight": return .ultraLight
      case "thin": return .thin
      case "light": return .light
      case "regular": return .regular
      case "medium": return .medium
      case "semibold": return .semibold
      case "bold": return .bold
      case "heavy": return .heavy
      case "black": return .black
      default: return .regular
      }
    }
    
    private func parseFont(_ fontName: String?, size: CGFloat, fallbackWeight: Font.Weight = .regular) -> Font {
      guard let fontName = fontName, !fontName.isEmpty else {
        return .system(size: size, weight: fallbackWeight)
      }
      
      return .custom(fontName, size: size)
    }
    
    private func parseCountdownFont(_ fontName: String?, size: CGFloat, fallbackWeight: Font.Weight = .bold) -> Font {
      if let fontName = fontName, !fontName.isEmpty {
        return .custom(fontName, size: size)
      }
      
      // Default to Gunterz-Bold for countdown if available, otherwise use system font with fallback weight
      return .custom("Gunterz-Bold", size: size)
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
        
        return Color(red: 1.0, green: 0.843, blue: 0.0) // Default gold
    }
}

#endif
