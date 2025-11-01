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
// MARK: - Timer Range Support for Apple's Live Activity Pattern

/// Returns the timer range for native iOS countdown display
/// This follows Apple's pattern: `Text(timerInterval: timerRange, countsDown: true)`
func getTimerRange(at date: Date) -> ClosedRange<Date>? {
    guard let countdownTarget = getCountdownTarget(at: date) else { return nil }
    
    let now = date
    let target = Date(timeIntervalSince1970: countdownTarget / 1000)
    
    // Ensure we don't create invalid ranges (target must be after now)
    guard target > now else { return nil }
    
    return now...target
}

// MARK: - Updated Functions for Timeline Context Synchronization

func getCurrentPhase(at date: Date) -> GoldenHourPhase {
    let now = date.timeIntervalSince1970 * 1000
    
    // Safely unwrap optional timestamp values
    guard let beforeStart = beforeStartTime,
          let active = activeTime,
          let activeSecondary = activeSecondaryTime,
          let activeLastMin = activeLastMinTime,
          let ended = endedTime else {
        // If timestamps are missing, default to ended state
        return .ended
    }

    if now < beforeStart {
        return .beforeStart
    } else if now >= beforeStart && now < active {
        return .active
    } else if now >= active && now < activeSecondary {
        return .activeSecondary
    } else if now >= activeSecondary && now < activeLastMin {
        return .activeLastMin
    } else if now >= activeLastMin && now < ended {
        return .activeLastMin // Continue last minute until ended
    } else {
        return .ended
    }
}

func getCountdownTarget(at date: Date) -> Double? {
    let currentPhase = getCurrentPhase(at: date)
    
    switch currentPhase {
    case .beforeStart:
        return activeTime
    case .active:
        return activeSecondaryTime
    case .activeSecondary:
        return activeLastMinTime
    case .activeLastMin:
        return endedTime
    case .ended, .dismiss:
        return nil
    }
}    /// Get phase-specific icon
    func phaseIcon(at currentTime: Date = Date()) -> String {
        let currentPhase = getCurrentPhase(at: currentTime)
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
    func phaseColorHex(at currentTime: Date = Date()) -> String {
        let currentPhase = getCurrentPhase(at: currentTime)
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
    func phaseMessage(at currentTime: Date = Date()) -> String {
        let currentPhase = getCurrentPhase(at: currentTime)
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
    func compactMessage(at currentTime: Date = Date()) -> String {
        let currentPhase = getCurrentPhase(at: currentTime)
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
    
    /// Get countdown target for current phase (duplicate function removed)
}
