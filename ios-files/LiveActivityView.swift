import SwiftUI
import WidgetKit
import OneSignalLiveActivities

#if canImport(ActivityKit)

@available(iOS 16.1, *)
struct LiveActivityView: View {
    let context: ActivityViewContext<DefaultLiveActivityAttributes>

    var body: some View {
      VStack(spacing: 16) {
        // Title from OneSignal attributes
        Text(context.attributes.data["title"]?.asString() ?? "Golden Hour")
          .font(.headline)
          .multilineTextAlignment(.center)
          .foregroundColor(Color.black.opacity(0.85))

        // Countdown timer from OneSignal state
        if let timerEndDate = context.state.data["timerEndDate"]?.asDouble() {
          Text(timerInterval: Date(timeIntervalSince1970: timerEndDate / 1000)...Date(timeIntervalSince1970: timerEndDate / 1000), countsDown: true)
            .font(.custom("Gunterz-Bold", size: 48))
            .monospacedDigit()
            .foregroundColor(Color.black.opacity(0.9))
            .multilineTextAlignment(.center)
        }

        // Message from OneSignal state
        Text(context.state.data["message"]?.asDict()?["en"]?.asString() ?? "Golden Hour is active!")
          .font(.subheadline)
          .multilineTextAlignment(.center)
          .foregroundColor(Color.black.opacity(0.7))

        // Progress view
        if let progress = context.state.data["progressValue"]?.asDouble() {
          ProgressView(value: progress)
            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
            .scaleEffect(y: 2)
        } else if let timerEndDate = context.state.data["timerEndDate"]?.asDouble() {
          ProgressView(timerInterval: Date(timeIntervalSince1970: timerEndDate / 1000)...Date(timeIntervalSince1970: timerEndDate / 1000))
            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
            .scaleEffect(y: 2)
        }
      }
      .padding()
      .frame(maxWidth: .infinity)
      .background(
        Color.fromHex(context.attributes.data["backgroundColor"]?.asString())
      )
      .cornerRadius(16)
    }
  }

#endif
