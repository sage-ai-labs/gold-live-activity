import Foundation

/// Pure function: parse an ISO 8601 string and return seconds until that date, or nil if past/invalid.
/// This is a copy of `secondsUntilISO8601Date` from LiveActivity.swift — keep in sync.
public func secondsUntilISO8601Date(_ isoString: String) -> Double? {
    let formatter = ISO8601DateFormatter()

    // Try with fractional seconds first (e.g. "2026-01-16T02:45:00.000Z")
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let endDate = formatter.date(from: isoString) {
        let seconds = endDate.timeIntervalSinceNow
        return seconds > 0 ? seconds : nil
    }

    // Fallback: without fractional seconds (e.g. "2026-01-16T02:45:00Z")
    formatter.formatOptions = [.withInternetDateTime]
    if let endDate = formatter.date(from: isoString) {
        let seconds = endDate.timeIntervalSinceNow
        return seconds > 0 ? seconds : nil
    }

    return nil
}
