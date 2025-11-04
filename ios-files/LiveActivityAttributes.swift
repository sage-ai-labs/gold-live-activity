import ActivityKit
import Foundation
import OneSignalLiveActivities

// MARK: - Golden Hour Live Activity Attributes (OneSignal Compatible)
struct GoldenHourLiveActivityAttributes: ActivityAttributes, OneSignalLiveActivityAttributes {
    public struct ContentState: OneSignalLiveActivityContentState {
        // Dynamic stateful properties about your activity go here!
        var phase: String                    // "golden_hour", "final_minutes", etc.
        var timeRemaining: TimeInterval      // Seconds remaining
        var currentBid: Double               // Current highest bid
        var dealTitle: String                // Title of the deal
        var message: String                  // Status message
        var backgroundColor: String?         // Hex color for background
        var progressValue: Double?           // Progress percentage (0.0 - 1.0)
        
        // OneSignal required property for ContentState
        var onesignal: OneSignalLiveActivityContentStateData?
    }

    // Fixed non-changing properties about your activity go here!
    var activityId: String                   // Unique identifier for this activity
    var dealId: String                       // Deal identifier
    var userId: String                       // User who triggered the activity
    
    // OneSignal required property for main attributes
    var onesignal: OneSignalLiveActivityAttributeData
}

// Keep the old typealias for backward compatibility during transition
typealias LiveActivityAttributes = GoldenHourLiveActivityAttributes
