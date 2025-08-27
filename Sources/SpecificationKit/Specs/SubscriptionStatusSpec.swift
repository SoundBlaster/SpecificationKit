import Foundation

/// Matches the subscription status encoded in userData.
public struct SubscriptionStatusSpec: Specification {
    public typealias T = EvaluationContext

    public enum SubscriptionStatus: String { case trial, premium, expired, canceled }

    private let expected: SubscriptionStatus
    private let key = "subscription_status"

    public init(_ expected: SubscriptionStatus) {
        self.expected = expected
    }

    public func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
        guard let value: String = candidate.userData(for: key) else { return false }
        return value == expected.rawValue
    }
}

