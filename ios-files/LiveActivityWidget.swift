import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Golden Hour Phase Extensions
// Note: These extensions are kept for backward compatibility
// The actual phase calculation happens in GoldenHourPhaseCalculator.swift

extension LiveActivityAttributes.ContentState {
  var phaseColor: Color {
    return Color(hex: getPhaseColorHex())
  }
  
  var phaseIcon: String {
    return getPhaseIcon()
  }
  
  var phaseColorHex: String {
    return getPhaseColorHex()
  }
  
  var phaseMessage: String {
    return getPhaseMessage()
  }
  
  var compactMessage: String {
    return getCompactMessage()
  }
  
  var isGoldenHour: Bool {
    return beforeStartTime != nil && endedTime != nil
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
          // Golden Hour: Show phase icon with periodic refresh
          TimelineView(.periodic(from: Date.now, by: 1.0)) { _ in
            Text(context.state.phaseIcon)
              .font(.system(size: 18))
              .id(context.state.getCurrentPhase().rawValue)
              .applyWidgetURL(from: context.attributes.deepLinkUrl)
          }
        } else if let dynamicIslandImageName = context.state.dynamicIslandImageName {
          resizableImage(imageName: dynamicIslandImageName)
            .frame(maxWidth: 23, maxHeight: 23)
            .applyWidgetURL(from: context.attributes.deepLinkUrl)
        }
      } compactTrailing: {
        if context.state.isGoldenHour {
          // Golden Hour: Show digital countdown with periodic refresh
          TimelineView(.periodic(from: Date.now, by: 1.0)) { _ in
            if let countdownTarget = context.state.getCountdownTarget() {
              Text(timerInterval: Date.toTimerInterval(miliseconds: countdownTarget))
                .font(.system(size: 14))
                .fontWeight(.semibold)
                .foregroundColor(context.state.phaseColor)
                .id(context.state.getCurrentPhase().rawValue)
                .applyWidgetURL(from: context.attributes.deepLinkUrl)
            } else {
              Text("--:--")
                .font(.system(size: 14))
                .fontWeight(.semibold)
                .foregroundColor(context.state.phaseColor)
                .applyWidgetURL(from: context.attributes.deepLinkUrl)
            }
          }
        } else if let date = context.state.timerEndDateInMilliseconds {
          compactTimer(
            endDate: date,
            timerType: context.attributes.timerType ?? .circular,
            progressViewTint: context.attributes.progressViewTint
          ).applyWidgetURL(from: context.attributes.deepLinkUrl)
        }
      } minimal: {
        if context.state.isGoldenHour {
          // Golden Hour: Show phase icon in minimal state with periodic refresh
          TimelineView(.periodic(from: Date.now, by: 1.0)) { _ in
            Text(context.state.phaseIcon)
              .font(.system(size: 16))
              .id(context.state.getCurrentPhase().rawValue)
              .applyWidgetURL(from: context.attributes.deepLinkUrl)
          }
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
  
  // Note: contentStaleDate is not available in the current ActivityKit version
  // Manual dismissal will be handled by React Native after 5 minutes of ended phase
  
  // MARK: - Golden Hour Expanded Views
  
  private func goldenHourExpandedLeading(state: LiveActivityAttributes.ContentState) -> some View {
    // Use periodic refresh to update phase-dependent content
    TimelineView(.periodic(from: Date.now, by: 1.0)) { _ in
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
      .id(state.getCurrentPhase().rawValue)
    }
  }
  
  private func goldenHourExpandedTrailing(state: LiveActivityAttributes.ContentState) -> some View {
    TimelineView(.periodic(from: Date.now, by: 1.0)) { _ in
      VStack(spacing: 4) {
        Spacer()
        Text(state.phaseIcon)
          .font(.system(size: 40))
        Text("Ends at 7PM PT")
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.6))
        Spacer()
      }
      .id(state.getCurrentPhase().rawValue)
    }
  }
  
  private func goldenHourExpandedBottom(state: LiveActivityAttributes.ContentState) -> some View {
    TimelineView(.periodic(from: Date.now, by: 1.0)) { _ in
      VStack(spacing: 8) {
        Text("Time Remaining")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.7))
        
        // Native iOS countdown timer
        if let countdownTarget = state.getCountdownTarget() {
          Text(timerInterval: Date.toTimerInterval(miliseconds: countdownTarget), countsDown: true)
            .font(.custom("Manrope-Bold", size: 32))
            .monospacedDigit()
            .foregroundColor(.white)
            .frame(height: 40)
        }
      }
      .padding(.top, 8)
      .id(state.getCurrentPhase().rawValue)
    }
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
