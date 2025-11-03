import ActivityKit
import Foundation

struct LiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        // Standard expo-live-activity fields
        var title: String
        var subtitle: String?
        var timerEndDateInMilliseconds: Double?
        var progress: Double?
        var imageName: String?
        var dynamicIslandImageName: String?
        
        // Simplified Golden Hour fields (matching backend LiveActivityData interface)
        var message: String?
        var backgroundColor: String?
        var textColor: String?
        var messageOpened: String?
        
        // Golden Hour timing (simplified to single phase)
        var goldenHourEndTime: Double? // End time in milliseconds (1 hour + 5 min auto-dismiss)
        
        // App state tracking for message switching
        var appOpened: Bool?
    }

    var name: String
    var backgroundColor: String?
    var titleColor: String?
    var subtitleColor: String?
    var progressViewTint: String?
    var progressViewLabelColor: String?
    var deepLinkUrl: String?
    var timerType: TimerType?
    var padding: Int?
    var paddingDetails: PaddingDetails?
    var imagePosition: String?
    var imageWidth: Int?
    var imageHeight: Int?
    var imageWidthPercent: Double?
    var imageHeightPercent: Double?
    var imageAlign: String?
    var contentFit: String?

    enum TimerType: String, Codable {
        case circular
        case linear
        case timer
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
