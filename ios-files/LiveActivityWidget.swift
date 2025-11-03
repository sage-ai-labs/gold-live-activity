import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Simplified Golden Hour Live Activity Widget
// Single phase system triggered by push notifications

struct LiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityAttributes.self) { context in
            // Main Live Activity view
            LiveActivityView(contentState: context.state, attributes: context.attributes)
                .activityBackgroundTint(
                    context.attributes.backgroundColor.map { Color(hex: $0) }
                )
                .activitySystemActionForegroundColor(Color.black)
                .applyWidgetURL(from: context.attributes.deepLinkUrl)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Regions
                
                DynamicIslandExpandedRegion(.leading, priority: 1) {
                    if context.state.isGoldenHour {
                        goldenHourExpandedLeading(state: context.state)
                            .dynamicIsland(verticalPlacement: .belowIfTooWide)
                            .padding(.leading, 5)
                            .applyWidgetURL(from: context.attributes.deepLinkUrl)
                    } else {
                        dynamicIslandExpandedLeading(title: context.state.title, subtitle: context.state.subtitle)
                            .dynamicIsland(verticalPlacement: .belowIfTooWide)
                            .padding(.leading, 5)
                            .applyWidgetURL(from: context.attributes.deepLinkUrl)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isGoldenHour {
                        goldenHourExpandedTrailing(state: context.state)
                            .padding(.trailing, 5)
                            .applyWidgetURL(from: context.attributes.deepLinkUrl)
                    } else if let imageName = context.state.imageName {
                        dynamicIslandExpandedTrailing(imageName: imageName)
                            .padding(.trailing, 5)
                            .applyWidgetURL(from: context.attributes.deepLinkUrl)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isGoldenHour {
                        goldenHourExpandedBottom(state: context.state)
                            .padding(.horizontal, 5)
                            .applyWidgetURL(from: context.attributes.deepLinkUrl)
                    } else if let date = context.state.timerEndDateInMilliseconds {
                        dynamicIslandExpandedBottom(
                            endDate: date, progressViewTint: context.attributes.progressViewTint
                        )
                        .padding(.horizontal, 5)
                        .applyWidgetURL(from: context.attributes.deepLinkUrl)
                    }
                }
            } compactLeading: {
                if context.state.isGoldenHour {
                    Text(context.state.getIcon())
                        .font(.system(size: 18))
                        .applyWidgetURL(from: context.attributes.deepLinkUrl)
                } else if let dynamicIslandImageName = context.state.dynamicIslandImageName {
                    resizableImage(imageName: dynamicIslandImageName)
                        .frame(maxWidth: 23, maxHeight: 23)
                        .applyWidgetURL(from: context.attributes.deepLinkUrl)
                }
            } compactTrailing: {
                if context.state.isGoldenHour, let timerRange = context.state.getTimerRange() {
                    Text(timerInterval: timerRange, countsDown: true)
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: context.state.getTextColor()))
                        .applyWidgetURL(from: context.attributes.deepLinkUrl)
                } else if let date = context.state.timerEndDateInMilliseconds {
                    compactTimer(
                        endDate: date,
                        timerType: context.attributes.timerType ?? .circular,
                        progressViewTint: context.attributes.progressViewTint
                    ).applyWidgetURL(from: context.attributes.deepLinkUrl)
                }
            } minimal: {
                if context.state.isGoldenHour {
                    Text(context.state.getIcon())
                        .font(.system(size: 16))
                        .applyWidgetURL(from: context.attributes.deepLinkUrl)
                } else if let date = context.state.timerEndDateInMilliseconds {
                    compactTimer(
                        endDate: date,
                        timerType: context.attributes.timerType ?? .circular,
                        progressViewTint: context.attributes.progressViewTint
                    ).applyWidgetURL(from: context.attributes.deepLinkUrl)
                }
            }
        }
    }
    
    // MARK: - Simplified Golden Hour Expanded Views
    
    private func goldenHourExpandedLeading(state: LiveActivityAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            HStack(spacing: 6) {
                Text(state.getIcon())
                    .font(.title2)
                Text("Golden Hour")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: state.getTextColor()))
            }
            Text(state.getDisplayMessage())
                .font(.caption)
                .foregroundStyle(Color(hex: state.getTextColor()).opacity(0.8))
            Spacer()
        }
    }
    
    private func goldenHourExpandedTrailing(state: LiveActivityAttributes.ContentState) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Spacer()
            if let timerRange = state.getTimerRange() {
                Text(timerInterval: timerRange, countsDown: true)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: state.getTextColor()))
                Text("remaining")
                    .font(.caption2)
                    .foregroundColor(Color(hex: state.getTextColor()).opacity(0.7))
            } else {
                Text("Ended")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
    
    private func goldenHourExpandedBottom(state: LiveActivityAttributes.ContentState) -> some View {
        VStack(spacing: 8) {
            if let timerRange = state.getTimerRange() {
                ProgressView(timerInterval: timerRange)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: state.getBackgroundColor())))
                    .scaleEffect(y: 2)
            }
            
            Text("Tap to open app")
                .font(.caption)
                .foregroundColor(Color(hex: state.getTextColor()).opacity(0.6))
        }
    }
    
    // MARK: - Default Views (Original expo-live-activity functionality)
    
    private func dynamicIslandExpandedLeading(title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private func dynamicIslandExpandedTrailing(imageName: String) -> some View {
        resizableImage(imageName: imageName)
            .frame(maxWidth: 40, maxHeight: 40)
    }
    
    private func dynamicIslandExpandedBottom(endDate: Double, progressViewTint: String?) -> some View {
        ProgressView(timerInterval: Date.toTimerInterval(miliseconds: endDate))
            .tint(progressViewTint.map { Color(hex: $0) })
    }
    
    private func compactTimer(endDate: Double, timerType: TimerType, progressViewTint: String?) -> some View {
        switch timerType {
        case .circular:
            return ProgressView(timerInterval: Date.toTimerInterval(miliseconds: endDate))
                .progressViewStyle(CircularProgressViewStyle())
                .tint(progressViewTint.map { Color(hex: $0) })
                .frame(width: 20, height: 20)
        case .linear:
            return ProgressView(timerInterval: Date.toTimerInterval(miliseconds: endDate))
                .progressViewStyle(LinearProgressViewStyle())
                .tint(progressViewTint.map { Color(hex: $0) })
                .frame(height: 6)
        case .timer:
            return Text(timerInterval: Date.toTimerInterval(miliseconds: endDate), countsDown: true)
                .font(.system(size: 14))
                .frame(width: 20, height: 20)
        }
    }
    
    private func resizableImage(imageName: String) -> some View {
        if let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Text("?")
                        .font(.caption)
                        .foregroundColor(.gray)
                )
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Widget URL Modifier

extension View {
    func applyWidgetURL(from deepLinkUrl: String?) -> some View {
        if let urlString = deepLinkUrl, let url = URL(string: urlString) {
            return AnyView(self.widgetURL(url))
        } else {
            return AnyView(self)
        }
    }
}
        .font(.caption)
        .foregroundStyle(.white.opacity(0.7))
      Spacer()
    }
  }
  
  private func goldenHourExpandedTrailing(state: LiveActivityAttributes.ContentState) -> some View {
    VStack(spacing: 4) {
      Spacer()
      // Live phase icon that changes based on current time
      Text(state.phaseIcon(at: Date()))
        .font(.system(size: 40))
      Text("Ends at 7PM PT")
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.6))
      Spacer()
    }
  }
  
  private func goldenHourExpandedBottom(state: LiveActivityAttributes.ContentState) -> some View {
    VStack(spacing: 8) {
      Text("Time Remaining")
        .font(.caption)
        .foregroundStyle(.white.opacity(0.7))
      
      // Native iOS countdown timer with PHASE-SPECIFIC target
      // Uses Apple's Food Truck pattern: Text(timerInterval: timerRange, countsDown: true)
      // Timer target automatically updates based on current phase
      if let timerRange = state.getTimerRange(at: Date()) {
        Text(timerInterval: timerRange, countsDown: true)
          .font(.custom("Manrope-Bold", size: 32))
          .monospacedDigit()
          .foregroundColor(.white)
          .frame(height: 40)
      } else {
        Text("Complete")
          .font(.custom("Manrope-Bold", size: 32))
          .foregroundColor(.gray)
          .frame(height: 40)
      }
    }
    .padding(.top, 8)
  }
  
  // MARK: - Default Views (Original expo-live-activity)

  @ViewBuilder
  private func compactTimer(
    endDate: Double,
    timerType: LiveActivityAttributes.DynamicIslandTimerType,
    progressViewTint: String?
  ) -> some View {
    if timerType == .digital {
      Text(timerInterval: Date.toTimerInterval(miliseconds: endDate))
        .font(.system(size: 15))
        .minimumScaleFactor(0.8)
        .fontWeight(.semibold)
        .frame(maxWidth: 60)
        .multilineTextAlignment(.trailing)
    } else {
      circularTimer(endDate: endDate)
        .tint(progressViewTint.map { Color(hex: $0) })
    }
  }

  private func dynamicIslandExpandedLeading(title: String, subtitle: String?) -> some View {
    VStack(alignment: .leading) {
      Spacer()
      Text(title)
        .font(.title2)
        .foregroundStyle(.white)
        .fontWeight(.semibold)
      if let subtitle {
        Text(subtitle)
          .font(.title3)
          .minimumScaleFactor(0.8)
          .foregroundStyle(.white.opacity(0.75))
      }
      Spacer()
    }
  }

  private func dynamicIslandExpandedTrailing(imageName: String) -> some View {
    VStack {
      Spacer()
      resizableImage(imageName: imageName)
        .frame(maxHeight: 64)
      Spacer()
    }
  }

  private func dynamicIslandExpandedBottom(endDate: Double, progressViewTint: String?) -> some View {
    ProgressView(timerInterval: Date.toTimerInterval(miliseconds: endDate))
      .foregroundStyle(.white)
      .tint(progressViewTint.map { Color(hex: $0) })
      .padding(.top, 5)
  }

  private func circularTimer(endDate: Double) -> some View {
    ProgressView(
      timerInterval: Date.toTimerInterval(miliseconds: endDate),
      countsDown: false,
      label: { EmptyView() },
      currentValueLabel: {
        EmptyView()
      }
    )
    .progressViewStyle(.circular)
  }
  
  // MARK: - Helper Functions
  
  @ViewBuilder
  private func resizableImage(imageName: String) -> some View {
    if let uiImage = UIImage(named: imageName) {
      Image(uiImage: uiImage)
        .resizable()
        .aspectRatio(contentMode: .fit)
    } else {
      Rectangle()
        .fill(Color.gray.opacity(0.3))
        .overlay(
          Text("No Image")
            .font(.caption2)
            .foregroundColor(.gray)
        )
    }
  }
}
