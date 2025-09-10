import Foundation

/// A specification that checks whether a feature flag matches an expected boolean value.
///
/// `FeatureFlagSpec` is useful for implementing feature toggles, A/B tests, and gradual rollouts.
/// It looks up a boolean flag in the evaluation context and compares it to an expected value.
/// Missing flags are treated as `false`, ensuring that features are opt-in by default.
///
/// ## Usage Examples
///
/// ### Basic Feature Toggle
/// ```swift
/// let newUISpec = FeatureFlagSpec(flagKey: "new_ui_enabled")
///
/// @Satisfies(using: newUISpec)
/// var shouldShowNewUI: Bool
///
/// if shouldShowNewUI {
///     showNewUserInterface()
/// }
/// ```
///
/// ### Disabled Feature Check
/// ```swift
/// let maintenanceSpec = FeatureFlagSpec(flagKey: "maintenance_mode", expected: false)
///
/// @Satisfies(using: maintenanceSpec)
/// var isAppAvailable: Bool
/// ```
///
/// ### A/B Testing
/// ```swift
/// @specs(
///     FeatureFlagSpec(flagKey: "experiment_variant_a"),
///     UserSegmentSpec(expectedSegment: .beta)
/// )
/// @AutoContext
/// struct ExperimentVariantASpec: Specification {
///     typealias T = EvaluationContext
/// }
/// ```
///
/// ### Integration with Context Provider
/// ```swift
/// // Configure the flag
/// DefaultContextProvider.shared.setFlag("premium_features", value: true)
///
/// let premiumSpec = FeatureFlagSpec(flagKey: "premium_features")
/// let isPremiumEnabled = premiumSpec.isSatisfiedBy(context)
/// ```
public struct FeatureFlagSpec: Specification {
    public typealias T = EvaluationContext

    /// The key identifying the feature flag in the evaluation context
    public let flagKey: String

    /// The expected boolean value for the flag
    public let expectedValue: Bool

    /// Creates a new feature flag specification.
    /// - Parameters:
    ///   - flagKey: The key identifying the feature flag in the evaluation context
    ///   - expected: The expected boolean value for the flag (defaults to `true`)
    public init(flagKey: String, expected: Bool = true) {
        self.flagKey = flagKey
        self.expectedValue = expected
    }

    public func isSatisfiedBy(_ candidate: EvaluationContext) -> Bool {
        // Treat missing flags as non-satisfying (do not conflate missing with false)
        guard let value = candidate.flags[flagKey] else { return false }
        return value == expectedValue
    }
}

// MARK: - Convenience Extensions

extension FeatureFlagSpec {

    /// Creates a specification that checks if a feature flag is enabled (true).
    /// - Parameter flagKey: The feature flag key to check
    /// - Returns: A FeatureFlagSpec that expects the flag to be `true`
    public static func enabled(_ flagKey: String) -> FeatureFlagSpec {
        FeatureFlagSpec(flagKey: flagKey, expected: true)
    }

    /// Creates a specification that checks if a feature flag is disabled (false).
    /// - Parameter flagKey: The feature flag key to check
    /// - Returns: A FeatureFlagSpec that expects the flag to be `false`
    public static func disabled(_ flagKey: String) -> FeatureFlagSpec {
        FeatureFlagSpec(flagKey: flagKey, expected: false)
    }

    /// Creates a specification for experimental features that should only be shown to beta users.
    /// - Parameter flagKey: The experimental feature flag key
    /// - Returns: A FeatureFlagSpec for experimental features
    public static func experimental(_ flagKey: String) -> FeatureFlagSpec {
        FeatureFlagSpec(flagKey: "experimental_\(flagKey)", expected: true)
    }

    /// Creates a specification for debug-only features.
    /// - Parameter flagKey: The debug feature flag key
    /// - Returns: A FeatureFlagSpec for debug features
    public static func debug(_ flagKey: String) -> FeatureFlagSpec {
        FeatureFlagSpec(flagKey: "debug_\(flagKey)", expected: true)
    }
}
