//
//  SpecificationKit.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

/// SpecificationKit — a Swift-first Specification pattern library.
/// See the documentation catalog for overview and guides: <doc:SpecificationKit>.
public enum SpecificationKit {

    /// The current version of SpecificationKit
    public static let version = "2.0.0"

}

// MARK: - Macros

/// Automatically synthesizes a composite specification by combining the
/// provided specifications with logical AND. See <doc:SpecificationKit>
/// for examples, generated members, and validation details.
///
/// - Parameters:
///   - specifications: Variable number of specification instances to combine with AND logic
@attached(
    member, names: named(init), named(isSatisfiedBy), named(isSatisfiedByAsync), named(isSatisfied),
    named(composite))
public macro specs(
    _ specifications: Any...
) = #externalMacro(module: "SpecificationKitMacros", type: "SpecsMacro")

/// Augments a `Specification` type to become an `AutoContextSpecification` with
/// automatic context injection. See <doc:SpecificationKit> for examples,
/// SwiftUI integration, benefits, and requirements.
@attached(member, names: named(Provider), named(contextProvider), named(init))
public macro AutoContext() =
    #externalMacro(
        module: "SpecificationKitMacros",
        type: "AutoContextMacro"
    )

/// Creates a Satisfies property wrapper with automatic spec instantiation from parameters.
/// Enables declarative syntax: `#SatisfiesSpec(using: CooldownIntervalSpec.self, eventKey: "action", cooldownInterval: 10)`
/// instead of manual construction: `Satisfies(using: CooldownIntervalSpec(eventKey: "action", cooldownInterval: 10))`
///
/// - Parameters:
///   - using: The specification type to instantiate (e.g., `CooldownIntervalSpec.self`)
///   - Additional parameters are passed to the specification's initializer
///
/// Example usage:
/// ```swift
/// @#SatisfiesSpec(using: CooldownIntervalSpec.self, eventKey: "action", cooldownInterval: 10)
/// var canPerformAction: Bool
/// ```
@freestanding(expression)
public macro SatisfiesSpec(
    using: Any.Type,
    _ parameters: Any...
) = #externalMacro(module: "SpecificationKitMacros", type: "SatisfiesMacro")

/// Conditionally enables a specification based on a runtime condition.
/// Generates members that wrap the specification's `isSatisfiedBy` method to check
/// the condition first before evaluating the specification.
///
/// **Note:** For most use cases, prefer using `ConditionalSpecification` wrapper directly
/// or the `.when()` / `.unless()` convenience methods on `Specification`.
///
/// - Parameters:
///   - condition: A closure `(T) -> Bool` that determines if the spec should be evaluated
///
/// Example usage:
/// ```swift
/// @specsIf(condition: { ctx in ctx.flag(for: "premium") })
/// struct PremiumFeatureSpec: Specification {
///     typealias T = EvaluationContext
///     // specification implementation
/// }
/// ```
///
/// Equivalent using wrapper (recommended):
/// ```swift
/// let premiumSpec = ConditionalSpecification(
///     condition: { ctx in ctx.flag(for: "premium") },
///     wrapping: PremiumFeatureSpec()
/// )
///
/// // Or using convenience method:
/// let premiumSpec = PremiumFeatureSpec().when { ctx in ctx.flag(for: "premium") }
/// ```
@attached(member, names: named(condition), named(isSatisfiedBy), named(_originalIsSatisfiedBy))
public macro specsIf(
    condition: Any
) = #externalMacro(module: "SpecificationKitMacros", type: "SpecsIfMacro")
