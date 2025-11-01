import Foundation

struct BenchmarkTimer {
    mutating func measureAverageTime(iterations: Int, _ operation: () -> Void) -> TimeInterval {
        measureAverageTime(iterations: iterations) { _ in operation() }
    }

    mutating func measureAverageTime(iterations: Int, operation: (Int) -> Void) -> TimeInterval {
        precondition(iterations > 0, "Iterations must be greater than zero")

        var totalDuration: TimeInterval = 0
        for index in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            operation(index)
            totalDuration += CFAbsoluteTimeGetCurrent() - start
        }

        return totalDuration / Double(iterations)
    }
}
