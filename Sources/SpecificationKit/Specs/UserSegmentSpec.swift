import Foundation

/// Checks membership of a user segment tag.
public struct UserSegmentSpec: Specification {
    public typealias T = EvaluationContext

    public enum UserSegment: String { case vip, beta, control, newUser = "new_user" }

    private let expected: UserSegment

    public init(_ expected: UserSegment) {
        self.expected = expected
    }

    public func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
        candidate.segments.contains(expected.rawValue)
    }
}

