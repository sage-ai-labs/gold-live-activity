import SwiftUI
import WidgetKit

#if canImport(ActivityKit)

  // MARK: - Golden Hour Phase Helpers
  
  extension LiveActivityAttributes.ContentState {
    var showGoldenHourView: Bool {
      return self.phase != nil && self.endedTime != nil
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
  
  @ViewBuilder
  private func goldenHourContent() -> some View {
    // Create explicit timeline entries for phase transitions
    let timeline = createPhaseTimeline()
    
    TimelineView(timeline) { context in
      VStack(spacing: 16) {
        // Title recalculated at each timeline entry (phase transitions)
        Text(contentState.phaseMessage)
          .font(.headline)
          .multilineTextAlignment(.center)
          .foregroundColor(Color.black.opacity(0.85))

        // Native iOS countdown timer
        if let countdownTarget = contentState.getCountdownTarget() {
          Text(timerInterval: Date.toTimerInterval(miliseconds: countdownTarget), countsDown: true)
            .font(.custom("Gunterz-Bold", size: 48))
            .monospacedDigit()
            .foregroundColor(Color.black.opacity(0.9))
            .multilineTextAlignment(.center)
        }

        // Subtitle from React Native (optional)
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
        // Background color recalculated at each timeline entry
        Color(hex: contentState.phaseColorHex)
      )
    }
  }
  
  // Create timeline with entries at each phase transition
  private func createPhaseTimeline() -> Timeline<Date> {
    var entries: [Date] = [Date.now]
    
    // Add entries for each phase transition time
    if let active = contentState.activeTime {
      let activeDate = Date(timeIntervalSince1970: active / 1000)
      if activeDate > Date.now {
        entries.append(activeDate)
      }
    }
    
    if let activeSecondary = contentState.activeSecondaryTime {
      let activeSecondaryDate = Date(timeIntervalSince1970: activeSecondary / 1000)
      if activeSecondaryDate > Date.now {
        entries.append(activeSecondaryDate)
      }
    }
    
    if let activeLastMin = contentState.activeLastMinTime {
      let activeLastMinDate = Date(timeIntervalSince1970: activeLastMin / 1000)
      if activeLastMinDate > Date.now {
        entries.append(activeLastMinDate)
      }
    }
    
    if let ended = contentState.endedTime {
      let endedDate = Date(timeIntervalSince1970: ended / 1000)
      if endedDate > Date.now {
        entries.append(endedDate)
      }
    }
    
    // Sort entries chronologically
    entries.sort()
    
    print("[LiveActivity] 📅 Created timeline with \(entries.count) entries:")
    for (index, date) in entries.enumerated() {
      print("  Entry \(index): \(date)")
    }
    
    // Policy: .atEnd means "reload when we reach the last entry"
    return Timeline(entries: entries, policy: .atEnd)
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
