import Foundation

// MARK: - Simplified Golden Hour Live Activity
// Single phase system triggered by push notifications

extension LiveActivityAttributes.ContentState {
    /// Check if this is a Golden Hour Live Activity
    /// Simplified: no complex phase calculations needed
    var isGoldenHour: Bool {
        return goldenHourEndTime != nil
    }
    
    /// Get the countdown timer range for Apple's native timer
    /// Returns range from now until goldenHourEndTime (1 hour + 5 min auto-dismiss)
    func getTimerRange() -> ClosedRange<Date>? {
        guard let endTime = goldenHourEndTime else { return nil }
        
        let now = Date()
        let target = Date(timeIntervalSince1970: endTime / 1000)
        
        // Ensure we don't create invalid ranges (target must be after now)
        guard target > now else { return nil }
        
        return now...target
    }
    
    /// Get icon for current state
    /// Simplified: always use Golden Hour icon or completion checkmark
    func getIcon() -> String {
        guard let endTime = goldenHourEndTime else { return "⏰" }
        
        let now = Date().timeIntervalSince1970 * 1000
        if now >= endTime {
            return "✓" // Completed
        } else {
            return "🔥" // Golden Hour active
        }
    }
    
    /// Get background color for current state
    func getBackgroundColor() -> String {
        // Use customizable background color from push notification, or default
        return backgroundColor ?? "#F4FFB0"
    }
    
    /// Get text color
    func getTextColor() -> String {
        // Use customizable text color from push notification, or default
        return textColor ?? "#000000"
    }
    
    /// Get display message with app-opened logic
    func getDisplayMessage() -> String {
        // If app was opened and we have a messageOpened value, use it
        if let appOpened = appOpened, appOpened == true,
           let messageOpened = messageOpened, !messageOpened.isEmpty {
            return messageOpened
        }
        
        // Otherwise use the standard message from push notification, or default
        return message ?? "🔥 Golden Hour is Live!"
    }
    
    /// Check if Golden Hour has ended
    var hasEnded: Bool {
        guard let endTime = goldenHourEndTime else { return false }
        return Date().timeIntervalSince1970 * 1000 >= endTime
    }
}
