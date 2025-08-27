import Foundation

/// Checks a boolean flag in the EvaluationContext.
public struct FeatureFlagSpec: Specification {
    public typealias T = EvaluationContext

    private let flagKey: String
    private let expected: Bool

    public init(flagKey: String, expected: Bool = true) {
        self.flagKey = flagKey
        self.expected = expected
    }

    public func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
        candidate.flag(for: flagKey) == expected
    }
}

