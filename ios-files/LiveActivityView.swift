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
        resizableImage(imageName: imageName)
          .applyImageSize(attributes.imageSize)
      }
      .frame(maxHeight: .infinity, alignment: imageAlignment)
    }
    
  // MARK: - Golden Hour Countdown View
  
  @ViewBuilder
  private func goldenHourContent() -> some View {
    // Determine if we should show countdown
    let shouldShowCountdown = contentState.phase != nil && 
                              contentState.phase != "ended" && 
                              contentState.endedTime != nil

    VStack(spacing: 16) {
      // Title from React Native (phase-appropriate message)
      Text(contentState.title)
        .font(.headline)
        .multilineTextAlignment(.center)
        .foregroundColor(Color.black.opacity(0.85))

      // Native iOS countdown timer using endedTime
      // This automatically updates without requiring pushes
      if shouldShowCountdown, let endedTime = contentState.endedTime {
        Text(timerInterval: Date.toTimerInterval(miliseconds: endedTime), countsDown: true)
          .font(.system(size: 48, weight: .bold, design: .rounded))
          .monospacedDigit()
          .foregroundColor(Color.black.opacity(0.9))
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
