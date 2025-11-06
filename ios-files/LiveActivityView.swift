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
          // Title from OneSignal state with emoji support
          HStack(spacing: 4) {
            if let titleEmoji = context.state.data["titleEmoji"]?.asDict()?["en"]?.asString() {
              Text(titleEmoji)
                .font(.headline)
            }
            Text(context.state.data["title"]?.asDict()?["en"]?.asString() ?? "Golden Hour")
              .font(.headline)
              .multilineTextAlignment(.center)
              .foregroundColor(Color.black.opacity(0.85))
          }

          // Golden Hour countdown timer (no spacing from title)
          if let countdownSeconds = context.state.data["countdownSeconds"]?.asDouble() {
            let endDate = Date().addingTimeInterval(countdownSeconds)
            Text(timerInterval: Date()...endDate, countsDown: true)
              .font(.custom("Manrope-Bold", size: 48))
              .monospacedDigit()
              .foregroundColor(Color.black.opacity(0.9))
              .multilineTextAlignment(.center)
          } else if let countdownSecondsInt = context.state.data["countdownSeconds"]?.asInt() {
            // Try parsing as Int in case it's sent as integer
            let endDate = Date().addingTimeInterval(Double(countdownSecondsInt))
            Text(timerInterval: Date()...endDate, countsDown: true)
              .font(.custom("Manrope-Bold", size: 48))
              .monospacedDigit()
              .foregroundColor(Color.black.opacity(0.9))
              .multilineTextAlignment(.center)
          } else if let countdownSecondsString = context.state.data["countdownSeconds"]?.asString() {
            // Try parsing as String in case OneSignal sends it as string in push updates
            if let countdownValue = Double(countdownSecondsString) {
              let endDate = Date().addingTimeInterval(countdownValue)
              Text(timerInterval: Date()...endDate, countsDown: true)
                .font(.custom("Manrope-Bold", size: 48))
                .monospacedDigit()
                .foregroundColor(Color.black.opacity(0.9))
                .multilineTextAlignment(.center)
            } else {
              // Fallback with debug info
              Text("1:00:00 (String: \(countdownSecondsString))")
                .font(.custom("Manrope-Bold", size: 48))
                .monospacedDigit()
                .foregroundColor(Color.black.opacity(0.9))
                .multilineTextAlignment(.center)
            }
          } else {
            // Default 1-hour countdown if no countdownSeconds provided - show debug info
            let defaultEndTime = Date().addingTimeInterval(3600) // 1 hour from now
            Text(timerInterval: Date()...defaultEndTime, countsDown: true)
              .font(.custom("Manrope-Bold", size: 48))
              .monospacedDigit()
              .foregroundColor(Color.black.opacity(0.9))
              .multilineTextAlignment(.center)
          }

          // Progress bar (comes before subtitle)
          let progressValue: Double = {
            if let progress = context.state.data["progressValue"]?.asDouble() {
              return progress
            } else if let countdownSeconds = context.state.data["countdownSeconds"]?.asDouble() {
              // Calculate progress based on countdown (assuming 3600 seconds total)
              return max(0.0, min(1.0, (3600.0 - countdownSeconds) / 3600.0))
            } else if let countdownSecondsInt = context.state.data["countdownSeconds"]?.asInt() {
              // Calculate progress based on countdown as Int
              let countdown = Double(countdownSecondsInt)
              return max(0.0, min(1.0, (3600.0 - countdown) / 3600.0))
            } else if let countdownSecondsString = context.state.data["countdownSeconds"]?.asString(),
                      let countdownValue = Double(countdownSecondsString) {
              // Calculate progress based on countdown as String
              return max(0.0, min(1.0, (3600.0 - countdownValue) / 3600.0))
            } else {
              // No countdownSeconds provided, using 1-hour default, so start at 100% (full time remaining)
              return 1.0
            }
          }()
          
          ProgressView(value: progressValue)
            .progressViewStyle(LinearProgressViewStyle(tint: Color.orange))
            .scaleEffect(x: 1, y: 2, anchor: .center)

          // Subtitle from OneSignal state with emoji support (comes after progress)
          HStack(spacing: 4) {
            if let subtitleEmoji = context.state.data["subtitleEmoji"]?.asDict()?["en"]?.asString() {
              Text(subtitleEmoji)
                .font(.subheadline)
            }
            if let subtitle = context.state.data["subtitle"]?.asDict()?["en"]?.asString() {
              Text(subtitle)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.black.opacity(0.7))
            }
          }
          .padding(.top, 8)
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
