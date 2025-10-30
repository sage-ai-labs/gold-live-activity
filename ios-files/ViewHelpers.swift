import SwiftUI

func resizableImage(imageName: String) -> some View {
  Image.dynamic(assetNameOrPath: imageName)
    .resizable()
    .scaledToFit()
}

func resizableImage(imageName: String, height: CGFloat?, width: CGFloat?) -> some View {
  resizableImage(imageName: imageName)
    .frame(width: width, height: height)
}

private struct ContainerSizeKey: PreferenceKey {
  static var defaultValue: CGSize?
  static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
    value = nextValue() ?? value
  }
}

extension View {
  func captureContainerSize() -> some View {
    background(
      GeometryReader { proxy in
        Color.clear.preference(key: ContainerSizeKey.self, value: proxy.size)
      }
    )
  }

  func onContainerSize(_ perform: @escaping (CGSize?) -> Void) -> some View {
    onPreferenceChange(ContainerSizeKey.self, perform: perform)
  }
  
  func applyImageSize(_ size: Int?) -> some View {
    if let size = size {
      let cgSize = CGFloat(size)
      return AnyView(self.frame(width: cgSize, height: cgSize))
    } else {
      return AnyView(self)
    }
  }
}

// MARK: - Countdown Clock View for Live Activities

struct CountdownClockView: View {
  let dealEndTimeInMilliseconds: Double
  
  private var dealEndTime: Date {
    Date(timeIntervalSince1970: dealEndTimeInMilliseconds / 1000.0)
  }
  
  private var timerInterval: ClosedRange<Date> {
    Date.now ... max(Date.now, dealEndTime)
  }
  
  var body: some View {
    // Use iOS's native auto-updating Text timer
    // This is what Uber and other apps use - it updates automatically
    Text(timerInterval: timerInterval, countsDown: true)
      .font(.system(size: 48, weight: .bold, design: .rounded))
      .monospacedDigit()
      .foregroundColor(.black)
      .frame(height: 80)
  }
}

