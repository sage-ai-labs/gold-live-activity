import ActivityKit
import Foundation

struct LiveActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var title: String
    var subtitle: String?
    var timerEndDateInMilliseconds: Double?
    var progress: Double?
    var imageName: String?
    var dynamicIslandImageName: String?
    
    // Golden Hour custom attributes
    var phase: String?
    var backgroundColor: String?
    
    // Phase timestamps (milliseconds since epoch)
    var beforeStartTime: Double?
    var activeTime: Double?
    var activeSecondaryTime: Double?
    var activeLastMinTime: Double?
    var endedTime: Double?
    
    // Phase-specific visual assets (for push notification control)
    var beforeStartIcon: String?
    var beforeStartColor: String?
    var beforeStartMessage: String?
    var beforeStartCompactMessage: String?
    
    var activeIcon: String?
    var activeColor: String?
    var activeMessage: String?
    var activeCompactMessage: String?
    
    var activeSecondaryIcon: String?
    var activeSecondaryColor: String?
    var activeSecondaryMessage: String?
    var activeSecondaryCompactMessage: String?
    
    var activeLastMinIcon: String?
    var activeLastMinColor: String?
    var activeLastMinMessage: String?
    var activeLastMinCompactMessage: String?
    
    var endedIcon: String?
    var endedColor: String?
    var endedMessage: String?
    var endedCompactMessage: String?
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
  var imageWidth: Int?
  var imageHeight: Int?
  var imageWidthPercent: Double?
  var imageHeightPercent: Double?
  var imageAlign: String?
  var contentFit: String?

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
