import SwiftUI
import WidgetKit

#if canImport(ActivityKit)

  // MARK: - Golden Hour Phase Helpers
  
  extension LiveActivityAttributes.ContentState {
    var showGoldenHourView: Bool {
      let result = self.phase != nil && self.endedTime != nil
      print("[LiveActivity] showGoldenHourView: \(result)")
      print("[LiveActivity] phase: \(phase ?? "nil")")
      print("[LiveActivity] endedTime: \(endedTime ?? 0)")
      print("[LiveActivity] beforeStartTime: \(beforeStartTime ?? 0)")
      print("[LiveActivity] activeTime: \(activeTime ?? 0)")
      return result
    }
    
    // Helper method to check if we have all required timestamps for Apple's timer pattern
    func hasValidTimestamps() -> Bool {
      return beforeStartTime != nil && activeTime != nil && 
             activeSecondaryTime != nil && activeLastMinTime != nil && 
             endedTime != nil
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
    
    @ViewBuilder
    private func resizableImage(imageName: String, height: CGFloat? = nil, width: CGFloat? = nil) -> some View {
      if let uiImage = UIImage(named: imageName) {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: width, height: height)
      } else {
        Rectangle()
          .fill(Color.gray.opacity(0.3))
          .frame(width: width ?? 50, height: height ?? 50)
          .overlay(
            Text("No Image")
              .font(.caption)
              .foregroundColor(.gray)
          )
      }
    }
    
  // MARK: - Golden Hour Countdown View (Updated to Apple's Pattern)
  
  @ViewBuilder
  private func goldenHourContent() -> some View {
    VStack(spacing: 16) {
      // Top Row: Current phase with live updates
      HStack {
        // Phase icon and name - auto-calculated
        VStack(alignment: .leading, spacing: 4) {
          Text(contentState.phaseIcon())
            .font(.title)
          Text(contentState.getCurrentPhase(at: Date()).rawValue.capitalized)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(Color(hex: contentState.phaseColorHex()))
        }
        
        Spacer()
        
        // Native iOS countdown timer - Apple's pattern!
        VStack(alignment: .trailing, spacing: 4) {
          if let timerRange = contentState.getTimerRange(at: Date()) {
            Text(timerInterval: timerRange, countsDown: true)
              .font(.custom("Manrope-Bold", size: 24))
              .monospacedDigit()
              .foregroundColor(.white)
          } else {
            Text("Complete")
              .font(.custom("Manrope-Bold", size: 24))
              .foregroundColor(.gray)
          }
          Text("Remaining")
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
        }
      }
      
      // Progress Bar using Apple's pattern
      if let timerRange = contentState.getTimerRange(at: Date()) {
        ProgressView(timerInterval: timerRange)
          .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: contentState.phaseColorHex())))
          .scaleEffect(y: 2)
      }
      
      // Bottom Row: Phase details
      HStack {
        Text("Golden Hour Phase")
          .font(.caption)
          .foregroundColor(.white.opacity(0.7))
        
        Spacer()
        
        Text(contentState.phaseMessage())
          .font(.caption)
          .foregroundColor(.white.opacity(0.7))
      }
      
      // DEBUG INFO (Remove this section when working)
      VStack(alignment: .leading, spacing: 2) {
        Text("🔍 DEBUG INFO - APPLE TIMER PATTERN")
          .font(.caption2)
          .foregroundColor(.yellow)
        Text("CURRENT: \(Int(Date().timeIntervalSince1970 * 1000))")
          .font(.caption2)
          .foregroundColor(.yellow)
        if let target = contentState.getCountdownTarget(at: Date()) {
          Text("TARGET: \(Int(target))")
            .font(.caption2)
            .foregroundColor(.yellow)
          Text("DIFF: \(Int(target - Date().timeIntervalSince1970 * 1000))")
            .font(.caption2)
            .foregroundColor(.yellow)
        }
        Text("PHASE: \(contentState.getCurrentPhase(at: Date()).rawValue)")
          .font(.caption2)
          .foregroundColor(.yellow)
      }
    }
    .padding(16)
    .background(
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: contentState.phaseColorHex()).opacity(0.3),
          Color.black.opacity(0.8)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
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
