import Foundation

/// Succeeds when `currentDate` is within the inclusive range [start, end].
public struct DateRangeSpec: Specification {
    public typealias T = EvaluationContext

    private let start: Date
    private let end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    public func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
        (start ... end).contains(candidate.currentDate)
    }
}

