import SwiftUI
import WidgetKit

#if canImport(ActivityKit)

  // MARK: - Golden Hour Phase Helpers
  
  extension LiveActivityAttributes.ContentState {
    var phaseBackgroundColor: Color {
      switch phase {
      case "before_start":
        return Color(hex: "#F4FFB0") ?? Color.yellow.opacity(0.3)
      case "active_coming":
        return Color(hex: "#E7F86C") ?? Color.yellow.opacity(0.5)
      case "active_last_5min":
        return Color(hex: "#FFD700") ?? Color.yellow
      case "active_last_min":
        return Color(hex: "#FF6B6B") ?? Color.red.opacity(0.7)
      case "ended":
        return Color(hex: "#9E9E9E") ?? Color.gray
      default:
        return Color.clear
      }
    }
    
    var phaseMessage: String {
      switch phase {
      case "before_start":
        return "⏰ Golden Hour Coming Soon"
      case "active_coming":
        return "🔥 Golden Hour Active - Time to Bid!"
      case "active_last_5min":
        return "⚡ Last 5 Minutes - Hurry!"
      case "active_last_min":
        return "🚨 FINAL MINUTE - BID NOW!"
      case "ended":
        return "✓ Golden Hour Ended"
      default:
        return ""
      }
    }
    
    var showFlipClock: Bool {
      return phase != nil && dealEndTime != nil && phase != "ended"
    }
  }

  struct ConditionalForegroundViewModifier: ViewModifier {
    let color: String?

    func body(content: Content) -> some View {
      if let color = color {
        content.foregroundStyle(Color(hex: color))
      } else {
        content
      }
    }
  }

  struct LiveActivityView: View {
    let contentState: LiveActivityAttributes.ContentState
    let attributes: LiveActivityAttributes

    var progressViewTint: Color? {
      attributes.progressViewTint.map { Color(hex: $0) }
    }

    private var imageAlignment: Alignment {
      switch attributes.imageAlign {
      case "center":
        return .center
      case "bottom":
        return .bottom
      default:
        return .top
      }
    }

    @ViewBuilder
    private func alignedImage(imageName: String) -> some View {
      VStack {
        resizableImage(imageName: imageName)
          .applyImageSize(attributes.imageSize)
      }
      .frame(maxHeight: .infinity, alignment: imageAlignment)
    }
    
    // MARK: - Golden Hour FlipClock View
    
    @ViewBuilder
    private func goldenHourContent() -> some View {
      VStack(spacing: 16) {
        // Phase message
        Text(contentState.phaseMessage)
          .font(.headline)
          .fontWeight(.bold)
          .foregroundColor(.black)
          .multilineTextAlignment(.center)
        
        // FlipClock countdown
        if let dealEndTime = contentState.dealEndTime {
          CountdownClockView(dealEndTimeInMilliseconds: dealEndTime)
            .frame(height: 80)
        }
        
        // Optional subtitle
        if let subtitle = contentState.subtitle {
          Text(subtitle)
            .font(.subheadline)
            .foregroundColor(.black.opacity(0.7))
            .multilineTextAlignment(.center)
        }
      }
      .padding(24)
      .frame(maxWidth: .infinity)
      .background(contentState.phaseBackgroundColor)
      .cornerRadius(16)
    }

    var body: some View {
      // If Golden Hour phase is active, show custom view
      if contentState.showFlipClock {
        goldenHourContent()
      } else {
        // Default expo-live-activity view
        defaultView()
      }
    }
    
    // MARK: - Default View (Original expo-live-activity)
    
    @ViewBuilder
    private func defaultView() -> some View {
      let defaultPadding = 24

      let top = CGFloat(
        attributes.paddingDetails?.top
          ?? attributes.paddingDetails?.vertical
          ?? attributes.padding
          ?? defaultPadding
      )

      let bottom = CGFloat(
        attributes.paddingDetails?.bottom
          ?? attributes.paddingDetails?.vertical
          ?? attributes.padding
          ?? defaultPadding
      )

      let leading = CGFloat(
        attributes.paddingDetails?.left
          ?? attributes.paddingDetails?.horizontal
          ?? attributes.padding
          ?? defaultPadding
      )

      let trailing = CGFloat(
        attributes.paddingDetails?.right
          ?? attributes.paddingDetails?.horizontal
          ?? attributes.padding
          ?? defaultPadding
      )

      VStack(alignment: .leading) {
        let position = attributes.imagePosition ?? "right"
        let isStretch = position.contains("Stretch")
        let isLeftImage = position.hasPrefix("left")
        let hasImage = contentState.imageName != nil
        let effectiveStretch = isStretch && hasImage
        HStack(alignment: .center) {
          if hasImage, isLeftImage {
            if let imageName = contentState.imageName {
              alignedImage(imageName: imageName)
            }
          }

          VStack(alignment: .leading, spacing: 2) {
            Text(contentState.title)
              .font(.title2)
              .fontWeight(.semibold)
              .modifier(ConditionalForegroundViewModifier(color: attributes.titleColor))

            if let subtitle = contentState.subtitle {
              Text(subtitle)
                .font(.title3)
                .modifier(ConditionalForegroundViewModifier(color: attributes.subtitleColor))
            }

            if effectiveStretch {
              if let date = contentState.timerEndDateInMilliseconds {
                ProgressView(timerInterval: Date.toTimerInterval(miliseconds: date))
                  .tint(progressViewTint)
                  .modifier(ConditionalForegroundViewModifier(color: attributes.progressViewLabelColor))
              } else if let progress = contentState.progress {
                ProgressView(value: progress)
                  .tint(progressViewTint)
                  .modifier(ConditionalForegroundViewModifier(color: attributes.progressViewLabelColor))
              }
            }
          }

          if hasImage, !isLeftImage { // right side (default)
            Spacer()
            if let imageName = contentState.imageName {
              alignedImage(imageName: imageName)
            }
          }
        }

        if !effectiveStretch {
          // Bottom progress (hidden when using Stretch variants where progress is inline)
          if let date = contentState.timerEndDateInMilliseconds {
            ProgressView(timerInterval: Date.toTimerInterval(miliseconds: date))
              .tint(progressViewTint)
              .modifier(ConditionalForegroundViewModifier(color: attributes.progressViewLabelColor))
          } else if let progress = contentState.progress {
            ProgressView(value: progress)
              .tint(progressViewTint)
              .modifier(ConditionalForegroundViewModifier(color: attributes.progressViewLabelColor))
          }
        }
      }
      .padding(EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing))
    }
  }
  
  // MARK: - Countdown Clock Wrapper
  
  struct CountdownClockView: View {
    let dealEndTimeInMilliseconds: Double
    @StateObject private var viewModel: CountdownViewModel
    
    init(dealEndTimeInMilliseconds: Double) {
      self.dealEndTimeInMilliseconds = dealEndTimeInMilliseconds
      _viewModel = StateObject(wrappedValue: CountdownViewModel(dealEndTimeInMilliseconds: dealEndTimeInMilliseconds))
    }
    
    var body: some View {
      ClockView(
        hours: viewModel.hours,
        minutes: viewModel.minutes,
        seconds: viewModel.seconds
      )
    }
  }

#endif
