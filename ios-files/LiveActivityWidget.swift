import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Golden Hour Phase Extensions

extension LiveActivityAttributes.ContentState {
  var phaseIcon: String {
    switch phase {
    case "before_start":
      return "⏰"
    case "active_coming":
      return "🔥"
    case "active_last_5min":
      return "⚡"
    case "active_last_min":
      return "🚨"
    case "ended":
      return "✓"
    default:
      return ""
    }
  }
  
  var phaseColor: Color {
    switch phase {
    case "before_start":
      return .yellow
    case "active_coming":
      return .orange
    case "active_last_5min":
      return .yellow
    case "active_last_min":
      return .red
    case "ended":
      return .gray
    default:
      return .blue
    }
  }
  
  var compactMessage: String {
    switch phase {
    case "before_start":
      return "Coming Soon"
    case "active_coming":
      return "Active Now"
    case "active_last_5min":
      return "Last 5 Min"
    case "active_last_min":
      return "FINAL MIN"
    case "ended":
      return "Ended"
    default:
      return ""
    }
  }
  
  var isGoldenHour: Bool {
    return phase != nil && dealEndTime != nil
  }
}

struct LiveActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    // Default expo-live-activity attributes
    var title: String
    var subtitle: String?
    var timerEndDateInMilliseconds: Double?
    var progress: Double?
    var imageName: String?
    var dynamicIslandImageName: String?
    
    // Golden Hour custom attributes
    var phase: String?  // "before_start", "active_coming", "active_last_5min", "active_last_min", "ended"
    var dealEndTime: Double?  // Timestamp in milliseconds for 7PM PT deadline
  }

  var name: String
  var backgroundColor: String?
  var titleColor: String?
  var subtitleColor: String?
  var progressViewTint: String?
  var progressViewLabelColor: String?
  var deepLinkUrl: String?
  var timerType: DynamicIslandTimerType?
  var padding: Int?
  var paddingDetails: PaddingDetails?
  var imagePosition: String?
  var imageSize: Int?
  var imageAlign: String?

  enum DynamicIslandTimerType: String, Codable {
    case circular
    case digital
  }

  struct PaddingDetails: Codable, Hashable {
    var top: Int?
    var bottom: Int?
    var left: Int?
    var right: Int?
    var vertical: Int?
    var horizontal: Int?
  }
}

struct LiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivityAttributes.self) { context in
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
          if context.state.isGoldenHour, let dealEndTime = context.state.dealEndTime {
            goldenHourExpandedBottom(dealEndTime: dealEndTime)
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
          // Golden Hour: Show phase icon
          Text(context.state.phaseIcon)
            .font(.system(size: 18))
            .applyWidgetURL(from: context.attributes.deepLinkUrl)
        } else if let dynamicIslandImageName = context.state.dynamicIslandImageName {
          resizableImage(imageName: dynamicIslandImageName)
            .frame(maxWidth: 23, maxHeight: 23)
            .applyWidgetURL(from: context.attributes.deepLinkUrl)
        }
      } compactTrailing: {
        if context.state.isGoldenHour, let dealEndTime = context.state.dealEndTime {
          // Golden Hour: Show digital countdown
          Text(timerInterval: Date.toTimerInterval(miliseconds: dealEndTime))
            .font(.system(size: 14))
            .fontWeight(.semibold)
            .foregroundColor(context.state.phaseColor)
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
          // Golden Hour: Show phase icon in minimal state
          Text(context.state.phaseIcon)
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
  
  // MARK: - Golden Hour Expanded Views
  
  private func goldenHourExpandedLeading(state: LiveActivityAttributes.ContentState) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Spacer()
      HStack(spacing: 6) {
        Text(state.phaseIcon)
          .font(.title2)
        Text(state.compactMessage)
          .font(.title3)
          .fontWeight(.bold)
          .foregroundStyle(state.phaseColor)
      }
      Text("Golden Hour")
        .font(.caption)
        .foregroundStyle(.white.opacity(0.7))
      Spacer()
    }
  }
  
  private func goldenHourExpandedTrailing(state: LiveActivityAttributes.ContentState) -> some View {
    VStack(spacing: 4) {
      Spacer()
      Text(state.phaseIcon)
        .font(.system(size: 40))
      Text("Ends at 7PM PT")
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.6))
      Spacer()
    }
  }
  
  private func goldenHourExpandedBottom(dealEndTime: Double) -> some View {
    VStack(spacing: 8) {
      Text("Time Remaining")
        .font(.caption)
        .foregroundStyle(.white.opacity(0.7))
      
      // Mini FlipClock for expanded view
      CompactCountdownView(dealEndTimeInMilliseconds: dealEndTime)
        .frame(height: 40)
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
}

// MARK: - Compact Countdown for Dynamic Island

struct CompactCountdownView: View {
  let dealEndTimeInMilliseconds: Double
  @StateObject private var viewModel: CountdownViewModel
  
  init(dealEndTimeInMilliseconds: Double) {
    self.dealEndTimeInMilliseconds = dealEndTimeInMilliseconds
    _viewModel = StateObject(wrappedValue: CountdownViewModel(dealEndTimeInMilliseconds: dealEndTimeInMilliseconds))
  }
  
  var body: some View {
    HStack(spacing: 6) {
      TimeUnitView(value: viewModel.hours, label: "H")
      Text(":")
        .font(.system(size: 20, weight: .bold))
        .foregroundColor(.white)
      TimeUnitView(value: viewModel.minutes, label: "M")
      Text(":")
        .font(.system(size: 20, weight: .bold))
        .foregroundColor(.white)
      TimeUnitView(value: viewModel.seconds, label: "S")
    }
  }
}

struct TimeUnitView: View {
  let value: String
  let label: String
  
  var body: some View {
    VStack(spacing: 2) {
      Text(value)
        .font(.system(size: 18, weight: .bold, design: .rounded))
        .foregroundColor(.white)
        .frame(width: 32)
      Text(label)
        .font(.system(size: 8, weight: .semibold))
        .foregroundColor(.white.opacity(0.6))
    }
  }
}
