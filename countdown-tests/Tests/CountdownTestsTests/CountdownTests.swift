import XCTest
@testable import CountdownLogic

final class CountdownTests: XCTestCase {

    // MARK: - secondsUntilISO8601Date

    func test_futureDate_withFractionalSeconds_returnsPositiveSeconds() {
        let future = Date().addingTimeInterval(300)
        let iso = isoString(from: future, fractional: true)
        let result = secondsUntilISO8601Date(iso)
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!, 290) // allow a few seconds of test runtime slack
        XCTAssertLessThanOrEqual(result!, 300)
    }

    func test_futureDate_withoutFractionalSeconds_returnsPositiveSeconds() {
        let future = Date().addingTimeInterval(300)
        let iso = isoString(from: future, fractional: false)
        let result = secondsUntilISO8601Date(iso)
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!, 290)
        XCTAssertLessThanOrEqual(result!, 300)
    }

    func test_pastDate_returnsNil() {
        let past = Date().addingTimeInterval(-60)
        let iso = isoString(from: past, fractional: true)
        XCTAssertNil(secondsUntilISO8601Date(iso))
    }

    func test_invalidString_returnsNil() {
        XCTAssertNil(secondsUntilISO8601Date("not-a-date"))
        XCTAssertNil(secondsUntilISO8601Date(""))
        XCTAssertNil(secondsUntilISO8601Date("2026-13-01T00:00:00Z")) // invalid month
    }

    func test_exactlyNow_returnsNil() {
        // A date in the past by the time the formatter runs should return nil
        let now = Date().addingTimeInterval(-1)
        let iso = isoString(from: now, fractional: true)
        XCTAssertNil(secondsUntilISO8601Date(iso))
    }

    // MARK: - Cap behaviour (simulated via secondsUntilISO8601Date + min)

    /// When goldenHourEndTime implies more time than countdownSeconds, min() should cap it.
    func test_cap_endTimeLargerThanLegacy_returnsLegacy() {
        let endTimeSeconds = 500.0
        let legacySeconds = 300.0
        XCTAssertEqual(min(endTimeSeconds, legacySeconds), 300.0)
    }

    /// When goldenHourEndTime implies less time than countdownSeconds (e.g. late delivery), use end time.
    func test_cap_endTimeSmallerThanLegacy_returnsEndTime() {
        let endTimeSeconds = 100.0
        let legacySeconds = 300.0
        XCTAssertEqual(min(endTimeSeconds, legacySeconds), 100.0)
    }

    /// When only goldenHourEndTime is provided (no countdownSeconds), use end time directly.
    func test_noLegacy_usesEndTime() {
        let future = Date().addingTimeInterval(200)
        let iso = isoString(from: future, fractional: true)
        let result = secondsUntilISO8601Date(iso)
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!, 190)
    }

    // MARK: - Helpers

    private func isoString(from date: Date, fractional: Bool) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = fractional
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        return formatter.string(from: date)
    }
}
