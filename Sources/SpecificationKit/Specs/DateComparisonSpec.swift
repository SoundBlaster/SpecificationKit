import Foundation

/// Compares the date of a stored event to a reference date using before/after.
public struct DateComparisonSpec: Specification {
    public typealias T = EvaluationContext

    public enum Comparison { case before, after }

    private let eventKey: String
    private let comparison: Comparison
    private let date: Date

    public init(eventKey: String, comparison: Comparison, date: Date) {
        self.eventKey = eventKey
        self.comparison = comparison
        self.date = date
    }

    public func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
        guard let eventDate = candidate.event(for: eventKey) else { return false }
        switch comparison {
        case .before:
            return eventDate < date
        case .after:
            return eventDate > date
        }
    }
}

