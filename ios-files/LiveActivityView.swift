import SwiftUI
import WidgetKit

#if canImport(ActivityKit)

// MARK: - Simplified Golden Hour Live Activity View
// Single phase system without complex timeline updates

struct LiveActivityView: View {
    let contentState: LiveActivityAttributes.ContentState
    let attributes: LiveActivityAttributes

    var body: some View {
        // Check if this is a Golden Hour Live Activity (simplified)
        if contentState.isGoldenHour {
            goldenHourView()
        } else {
            defaultView()
        }
    }
    
    // MARK: - Simplified Golden Hour View
    @ViewBuilder
    private func goldenHourView() -> some View {
        VStack(spacing: 12) {
            // Header with icon and title
            HStack {
                Text(contentState.getIcon())
                    .font(.title2)
                
                Text(contentState.title ?? "Golden Hour")
                    .font(.headline)
                    .foregroundColor(Color(hex: contentState.getTextColor()))
                
                Spacer()
            }
            
            // Main message
            Text(contentState.getDisplayMessage())
                .font(.body)
                .foregroundColor(Color(hex: contentState.getTextColor()))
                .multilineTextAlignment(.leading)
            
            // Countdown timer (only if Golden Hour is active)
            if let timerRange = contentState.getTimerRange() {
                HStack {
                    Text("Time remaining:")
                        .font(.caption)
                        .foregroundColor(Color(hex: contentState.getTextColor()).opacity(0.8))
                    
                    Spacer()
                    
                    Text(timerInterval: timerRange, countsDown: true)
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(Color(hex: contentState.getTextColor()))
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(16)
        .background(Color(hex: contentState.getBackgroundColor()))
        .cornerRadius(12)
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

                if hasImage, !isLeftImage {
                    Spacer()
                    if let imageName = contentState.imageName {
                        alignedImage(imageName: imageName)
                    }
                }
            }

            if !effectiveStretch {
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
    
    // MARK: - Helper Views and Modifiers
    
    var progressViewTint: Color? {
        attributes.progressViewTint.map { Color(hex: $0) }
    }

    private var imageAlignment: Alignment {
        switch attributes.imageAlign {
        case "center": return .center
        case "bottom": return .bottom
        default: return .top
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
                resizableImage(imageName: imageName).frame(width: width)
            } else if let height = height {
                resizableImage(imageName: imageName).frame(height: height)
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
}

// MARK: - Helper Modifiers and Extensions

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

#endif
