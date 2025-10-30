import SwiftUI
import WidgetKit

#if canImport(ActivityKit)

  // MARK: - Golden Hour Phase Helpers
  
  extension LiveActivityAttributes.ContentState {
    var showGoldenHourView: Bool {
      return self.phase != nil && self.phase != "ended" && self.endedTime != nil
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
        let width = attributes.imageWidth.map { CGFloat($0) }
        let height = attributes.imageHeight.map { CGFloat($0) }
        
        if let width = width, let height = height {
          resizableImage(imageName: imageName, height: height, width: width)
        } else if let width = width {
          resizableImage(imageName: imageName)
            .frame(width: width)
        } else if let height = height {
          resizableImage(imageName: imageName)
            .frame(height: height)
        } else {
          resizableImage(imageName: imageName)
        }
      }
      .frame(maxHeight: .infinity, alignment: imageAlignment)
    }
    
  // MARK: - Golden Hour Countdown View
  
  // Get the appropriate countdown target based on current phase
  private func getCountdownTarget() -> Double? {
    guard let phase = contentState.phase else { return nil }
    
    switch phase {
    case "before_start":
      // Count down to when Golden Hour starts (active phase)
      return contentState.activeTime
    case "active":
      // Count down to when secondary phase starts
      return contentState.activeSecondaryTime
    case "active_secondary":
      // Count down to when last minute starts
      return contentState.activeLastMinTime
    case "active_last_min":
      // Count down to when Golden Hour ends
      return contentState.endedTime
    default:
      return nil
    }
  }
  
  @ViewBuilder
  private func goldenHourContent() -> some View {
    VStack(spacing: 16) {
      // Title from React Native (phase-appropriate message)
      Text(contentState.title)
        .font(.headline)
        .multilineTextAlignment(.center)
        .foregroundColor(Color.black.opacity(0.85))

      // Native iOS countdown timer with PHASE-SPECIFIC target
      // Each phase counts down to its own end time, not the final ended time
      // This automatically updates without requiring pushes
      // Uses Manrope-Bold to match the app's ClockCountdown style
      if let countdownTarget = getCountdownTarget() {
        Text(timerInterval: Date.toTimerInterval(miliseconds: countdownTarget), countsDown: true)
          .font(.custom("Manrope-Bold", size: 48))
          .monospacedDigit()
          .foregroundColor(Color.black.opacity(0.9))
          .multilineTextAlignment(.center)
      }

      // Subtitle from React Native
      if let subtitle = contentState.subtitle {
        Text(subtitle)
          .font(.subheadline)
          .multilineTextAlignment(.center)
          .foregroundColor(Color.black.opacity(0.7))
      }
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(
      // Use backgroundColor from React Native, fallback to default
      contentState.backgroundColor.flatMap { Color(hex: $0) } ?? Color(hex: "#F4FFB0")
    )
    .cornerRadius(16)
  }  
  var body: some View {
    // If Golden Hour phase is active, show custom countdown view
    if contentState.showGoldenHourView {
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

#endif
