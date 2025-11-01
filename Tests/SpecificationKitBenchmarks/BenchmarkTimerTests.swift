import XCTest

final class BenchmarkTimerTests: XCTestCase {
    func testMeasureAverageTimeRunsBodyExpectedNumberOfTimes() {
        var callCount = 0
        var timer = BenchmarkTimer()

        _ = timer.measureAverageTime(iterations: 5) {
            callCount += 1
        }

        XCTAssertEqual(callCount, 5, "Timer should invoke the body for each iteration")
    }

    func testMeasureAverageTimeReflectsWorkDuration() {
        var timer = BenchmarkTimer()

        let averageDuration = timer.measureAverageTime(iterations: 3) {
            usleep(3_000) // ~3ms of work per iteration
        }

        XCTAssertGreaterThanOrEqual(averageDuration, 0.001, "Average duration should reflect the work performed")
    }
}
