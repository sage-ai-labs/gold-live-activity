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
        
        // Check dismiss time if available (for showing ended phase before dismissing)
        // For now, we show ended indefinitely until React Native stops it
        
        if now >= ended {
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
    var phaseIcon: String {
        let currentPhase = getCurrentPhase()
        switch currentPhase {
        case .beforeStart:
            return "⏰"
        case .active:
            return "🔥"
        case .activeSecondary:
            return "⚡"
        case .activeLastMin:
            return "🚨"
        case .ended, .dismiss:
            return "✓"
        }
    }
    
    /// Get phase-specific color
    var phaseColorHex: String {
        let currentPhase = getCurrentPhase()
        switch currentPhase {
        case .beforeStart:
            return "#F4FFB0" // Light yellow
        case .active:
            return "#E7F86C" // Yellow
        case .activeSecondary:
            return "#FFD700" // Gold
        case .activeLastMin:
            return "#FF6B6B" // Red
        case .ended, .dismiss:
            return "#9E9E9E" // Gray
        }
    }
    
    /// Get phase-specific message
    var phaseMessage: String {
        let currentPhase = getCurrentPhase()
        switch currentPhase {
        case .beforeStart:
            return "⏰ Golden Hour Coming Soon"
        case .active:
            return "🔥 Golden Hour Active - Shop Now!"
        case .activeSecondary:
            return "⚡ Last 5 Minutes - Hurry!"
        case .activeLastMin:
            return "🚨 FINAL MINUTE - SHOP NOW!"
        case .ended, .dismiss:
            return "✓ Golden Hour Ended"
        }
    }
    
    /// Get compact phase message for Dynamic Island
    var compactMessage: String {
        let currentPhase = getCurrentPhase()
        switch currentPhase {
        case .beforeStart:
            return "Coming Soon"
        case .active:
            return "Active Now"
        case .activeSecondary:
            return "Last 5 Min"
        case .activeLastMin:
            return "FINAL MIN"
        case .ended, .dismiss:
            return "Ended"
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
