import Foundation

// MARK: - Golden Hour Phase Calculator
// This allows Live Activities to self-update without JavaScript running

enum GoldenHourPhase: String {
    case beforeStart = "before_start"
    case active = "active"
    case activeSecondary = "active_secondary"
    case activeLastMin = "active_last_min"
    case ended = "ended"
    case dismiss = "dismiss"
}

extension LiveActivityAttributes.ContentState {
    /// Calculate the current phase based on timestamps and current time
    /// This allows the Live Activity to self-update without React Native running
    func getCurrentPhase() -> GoldenHourPhase {
        guard let beforeStart = beforeStartTime,
              let active = activeTime,
              let activeSecondary = activeSecondaryTime,
              let activeLastMin = activeLastMinTime,
              let ended = endedTime else {
            // Fallback to phase from React Native if timestamps aren't available
            return GoldenHourPhase(rawValue: phase ?? "before_start") ?? .beforeStart
        }
        
        let now = Date().timeIntervalSince1970 * 1000 // Convert to milliseconds
        
        // Check dismiss time if available
        // If we're past ended + 5 minutes, consider it dismissed
        let dismissTime = ended + (5 * 60 * 1000) // 5 minutes after ended
        
        if now >= dismissTime {
            return .dismiss
        } else if now >= ended {
            return .ended
        } else if now >= activeLastMin {
            return .activeLastMin
        } else if now >= activeSecondary {
            return .activeSecondary
        } else if now >= active {
            return .active
        } else {
            return .beforeStart
        }
    }
    
    /// Get phase-specific icon
    func getPhaseIcon() -> String {
        let currentPhase = getCurrentPhase()
        switch currentPhase {
        case .beforeStart:
            return beforeStartIcon ?? "⏰"
        case .active:
            return activeIcon ?? "🔥"
        case .activeSecondary:
            return activeSecondaryIcon ?? "⚡"
        case .activeLastMin:
            return activeLastMinIcon ?? "🚨"
        case .ended, .dismiss:
            return endedIcon ?? "✓"
        }
    }
    
    /// Get phase-specific color
    func getPhaseColorHex() -> String {
        let currentPhase = getCurrentPhase()
        switch currentPhase {
        case .beforeStart:
            return beforeStartColor ?? "#F4FFB0" // Light yellow
        case .active:
            return activeColor ?? "#E7F86C" // Yellow
        case .activeSecondary:
            return activeSecondaryColor ?? "#FFD700" // Gold
        case .activeLastMin:
            return activeLastMinColor ?? "#FF6B6B" // Red
        case .ended, .dismiss:
            return endedColor ?? "#9E9E9E" // Gray
        }
    }
    
    /// Get phase-specific message
    func getPhaseMessage() -> String {
        let currentPhase = getCurrentPhase()
        switch currentPhase {
        case .beforeStart:
            return beforeStartMessage ?? "⏰ Golden Hour Coming Soon"
        case .active:
            return activeMessage ?? "🔥 Golden Hour Active - Shop Now!"
        case .activeSecondary:
            return activeSecondaryMessage ?? "⚡ Last 2 Minutes - Hurry!"
        case .activeLastMin:
            return activeLastMinMessage ?? "🚨 FINAL MINUTE - SHOP NOW!"
        case .ended, .dismiss:
            return endedMessage ?? "✓ Golden Hour Ended"
        }
    }
    
    /// Get compact phase message for Dynamic Island
    func getCompactMessage() -> String {
        let currentPhase = getCurrentPhase()
        switch currentPhase {
        case .beforeStart:
            return beforeStartCompactMessage ?? "Coming Soon"
        case .active:
            return activeCompactMessage ?? "Shop Now!"
        case .activeSecondary:
            return activeSecondaryCompactMessage ?? "Last 2 Min!"
        case .activeLastMin:
            return activeLastMinCompactMessage ?? "FINAL MIN!"
        case .ended, .dismiss:
            return endedCompactMessage ?? "Ended"
        }
    }
    
    /// Get countdown target for current phase
    /// NOTE: During Golden Hour (active/activeSecondary/activeLastMin), 
    /// the countdown is CONTINUOUS to the end time, not phase-specific.
    /// Only before_start has a different target (counts to Golden Hour start).
    func getCountdownTarget() -> Double? {
        let currentPhase = getCurrentPhase()
        
        switch currentPhase {
        case .beforeStart:
            // Count down to when Golden Hour starts
            return activeTime
        case .active, .activeSecondary, .activeLastMin:
            // ALL Golden Hour phases count to the SAME end time
            // This creates one continuous countdown throughout Golden Hour
            return endedTime
        case .ended, .dismiss:
            return nil // No countdown when ended
        }
    }
}
