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
            print("[LiveActivity] ⚠️ Missing timestamps, falling back to phase: \(phase ?? "none")")
            return GoldenHourPhase(rawValue: phase ?? "before_start") ?? .beforeStart
        }
        
        let now = Date().timeIntervalSince1970 * 1000 // Convert to milliseconds
        
        // Debug logging - ALWAYS show this to diagnose issues
        let nowDate = Date(timeIntervalSince1970: now / 1000)
        let beforeStartDate = Date(timeIntervalSince1970: beforeStart / 1000)
        let activeDate = Date(timeIntervalSince1970: active / 1000)
        let endedDate = Date(timeIntervalSince1970: ended / 1000)
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("[LiveActivity] PHASE CHECK")
        print("  Now:         \(nowDate) (\(now))")
        print("  BeforeStart: \(beforeStartDate) (\(beforeStart))")
        print("  Active:      \(activeDate) (\(active))")
        print("  Ended:       \(endedDate) (\(ended))")
        print("  Seconds until active: \((active - now) / 1000)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Check dismiss time if available
        // If we're past ended + 5 minutes, consider it dismissed
        let dismissTime = ended + (5 * 60 * 1000) // 5 minutes after ended
        
        let detectedPhase: GoldenHourPhase
        if now >= dismissTime {
            detectedPhase = .dismiss
        } else if now >= ended {
            detectedPhase = .ended
        } else if now >= activeLastMin {
            detectedPhase = .activeLastMin
        } else if now >= activeSecondary {
            detectedPhase = .activeSecondary
        } else if now >= active {
            detectedPhase = .active
        } else {
            detectedPhase = .beforeStart
        }
        
        print("[LiveActivity] 🎯 Detected Phase: \(detectedPhase.rawValue)")
        return detectedPhase
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
        let now = Date().timeIntervalSince1970 * 1000 // Convert to milliseconds
        
        print("[LiveActivity] 🎯 Getting countdown target for phase: \(currentPhase.rawValue)")
        
        switch currentPhase {
        case .beforeStart:
            // Count down to when Golden Hour starts
            // Safety check: if activeTime is in the past or equal to now, return nil
            guard let active = activeTime, active > now else {
                print("[LiveActivity] ⚠️ beforeStart: activeTime is in past or nil, returning nil")
                return nil
            }
            let secondsRemaining = (active - now) / 1000
            print("[LiveActivity] ✅ beforeStart: Counting to active in \(secondsRemaining)s (target: \(active))")
            return active
        case .active, .activeSecondary, .activeLastMin:
            // ALL Golden Hour phases count to the SAME end time
            // This creates one continuous countdown throughout Golden Hour
            // Safety check: if endedTime is in the past or equal to now, return nil
            guard let ended = endedTime, ended > now else {
                print("[LiveActivity] ⚠️ \(currentPhase.rawValue): endedTime is in past or nil, returning nil")
                return nil
            }
            let secondsRemaining = (ended - now) / 1000
            print("[LiveActivity] ✅ \(currentPhase.rawValue): Counting to ended in \(secondsRemaining)s (target: \(ended))")
            return ended
        case .ended, .dismiss:
            print("[LiveActivity] ⚠️ \(currentPhase.rawValue): No countdown needed")
            return nil // No countdown when ended
        }
    }
}
