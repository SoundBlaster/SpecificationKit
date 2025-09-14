//
//  ConditionalSatisfies.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

#if canImport(SwiftUI)
    import SwiftUI
#endif

/// A property wrapper that selects specifications based on runtime conditions.
///
/// `@ConditionalSatisfies` allows for dynamic specification selection based on
/// runtime predicates. This is particularly useful for adaptive behavior where
/// the specification to use depends on device characteristics, user preferences,
/// or environmental conditions.
///
/// ## Usage
///
/// ```swift
/// @ConditionalSatisfies(
///     conditions: [
///         ({ UIDevice.current.userInterfaceIdiom == .pad }, TabletModeSpec()),
///         ({ UIAccessibility.isVoiceOverRunning }, AccessibilityModeSpec())
///     ],
///     fallback: StandardModeSpec()
/// )
/// var shouldShowFeature: Bool
/// ```
///
/// ## Thread Safety
///
/// The implementation is thread-safe. Condition predicates are evaluated
/// on each access, allowing for dynamic behavior changes.
@propertyWrapper
public struct ConditionalSatisfies<Context> {

    // MARK: - Types

    /// A condition that pairs a predicate with a specification
    public typealias Condition = (predicate: () -> Bool, specification: AnySpecification<Context>)

    // MARK: - Properties

    private let contextFactory: () -> Context
    private let asyncContextFactory: (() async throws -> Context)?
    private let conditions: [Condition]
    private let fallbackSpecification: AnySpecification<Context>

    // MARK: - Property Wrapper Interface

    /// The wrapped value representing whether the selected specification is satisfied.
    /// The first condition whose predicate returns true will have its specification evaluated.
    public var wrappedValue: Bool {
        let context = contextFactory()
        let activeSpec = selectActiveSpecification()
        return activeSpec.isSatisfiedBy(context)
    }

    // MARK: - Initializers

    /// Creates a ConditionalSatisfies property wrapper with runtime condition selection.
    /// - Parameters:
    ///   - provider: The context provider to use for evaluation
    ///   - conditions: Array of condition predicates and their associated specifications
    ///   - fallback: The fallback specification to use if no conditions match
    public init<Provider: ContextProviding, S: Specification>(
        provider: Provider,
        conditions: [(predicate: () -> Bool, specification: S)],
        fallback: S
    ) where Provider.Context == Context, S.T == Context {
        precondition(!conditions.isEmpty, "ConditionalSatisfies requires at least one condition")

        self.contextFactory = provider.currentContext
        self.asyncContextFactory = provider.currentContextAsync
        self.conditions = conditions.map {
            (predicate: $0.predicate, specification: AnySpecification($0.specification))
        }
        self.fallbackSpecification = AnySpecification(fallback)
    }

    /// Internal initializer for builder pattern with AnySpecification
    internal init<Provider: ContextProviding>(
        provider: Provider,
        anyConditions: [(predicate: () -> Bool, specification: AnySpecification<Context>)],
        fallback: AnySpecification<Context>
    ) where Provider.Context == Context {
        precondition(!anyConditions.isEmpty, "ConditionalSatisfies requires at least one condition")

        self.contextFactory = provider.currentContext
        self.asyncContextFactory = provider.currentContextAsync
        self.conditions = anyConditions
        self.fallbackSpecification = fallback
    }

    /// Creates a ConditionalSatisfies property wrapper with predicate functions as specifications.
    /// - Parameters:
    ///   - provider: The context provider to use for evaluation
    ///   - conditions: Array of condition predicates and their associated predicate functions
    ///   - fallback: The fallback predicate function
    public init<Provider: ContextProviding>(
        provider: Provider,
        conditions: [(predicate: () -> Bool, specification: (Context) -> Bool)],
        fallback: @escaping (Context) -> Bool
    ) where Provider.Context == Context {
        precondition(!conditions.isEmpty, "ConditionalSatisfies requires at least one condition")

        self.contextFactory = provider.currentContext
        self.asyncContextFactory = provider.currentContextAsync
        self.conditions = conditions.map {
            (predicate: $0.predicate, specification: AnySpecification($0.specification))
        }
        self.fallbackSpecification = AnySpecification(fallback)
    }

    // MARK: - Projected Value & Advanced Features

    /// Projected value providing access to runtime selection information and async evaluation
    public var projectedValue: ConditionalSatisfiesProjection<Context> {
        ConditionalSatisfiesProjection(
            contextFactory: contextFactory,
            asyncContextFactory: asyncContextFactory,
            conditions: conditions,
            fallbackSpecification: fallbackSpecification
        )
    }

    // MARK: - Internal Logic

    /// Selects the active specification based on current conditions
    private func selectActiveSpecification() -> AnySpecification<Context> {
        for condition in conditions {
            if condition.predicate() {
                return condition.specification
            }
        }
        return fallbackSpecification
    }
}

// MARK: - Projected Value Implementation

/// Projected value for ConditionalSatisfies providing advanced selection analysis
public struct ConditionalSatisfiesProjection<Context> {
    private let contextFactory: () -> Context
    private let asyncContextFactory: (() async throws -> Context)?
    private let conditions: [ConditionalSatisfies<Context>.Condition]
    private let fallbackSpecification: AnySpecification<Context>

    internal init(
        contextFactory: @escaping () -> Context,
        asyncContextFactory: (() async throws -> Context)?,
        conditions: [ConditionalSatisfies<Context>.Condition],
        fallbackSpecification: AnySpecification<Context>
    ) {
        self.contextFactory = contextFactory
        self.asyncContextFactory = asyncContextFactory
        self.conditions = conditions
        self.fallbackSpecification = fallbackSpecification
    }

    /// Async evaluation of the currently selected specification
    public func evaluateAsync() async throws -> Bool {
        let activeSpec = selectActiveSpecification()

        let context: Context
        if let asyncFactory = asyncContextFactory {
            context = try await asyncFactory()
        } else {
            context = contextFactory()
        }

        return activeSpec.isSatisfiedBy(context)
    }

    /// Returns the index of the currently active condition, or nil if using fallback
    public func getActiveConditionIndex() -> Int? {
        for (index, condition) in conditions.enumerated() {
            if condition.predicate() {
                return index
            }
        }
        return nil  // Using fallback
    }

    /// Returns whether the fallback specification is currently active
    public func isUsingFallback() -> Bool {
        return getActiveConditionIndex() == nil
    }

    /// Evaluates all condition predicates and returns their current states
    public func getAllConditionStates() -> [Bool] {
        return conditions.map { $0.predicate() }
    }

    /// Force evaluation of all specifications with current context for debugging
    public func evaluateAllSpecifications() -> [(conditionIndex: Int?, result: Bool)] {
        let context = contextFactory()
        var results: [(conditionIndex: Int?, result: Bool)] = []

        for (index, condition) in conditions.enumerated() {
            let result = condition.specification.isSatisfiedBy(context)
            results.append((conditionIndex: index, result: result))
        }

        // Add fallback result
        let fallbackResult = fallbackSpecification.isSatisfiedBy(context)
        results.append((conditionIndex: nil, result: fallbackResult))

        return results
    }

    private func selectActiveSpecification() -> AnySpecification<Context> {
        for condition in conditions {
            if condition.predicate() {
                return condition.specification
            }
        }
        return fallbackSpecification
    }
}

// MARK: - EvaluationContext Convenience

extension ConditionalSatisfies where Context == EvaluationContext {

    /// Creates a ConditionalSatisfies property wrapper using the shared default context provider.
    /// - Parameters:
    ///   - conditions: Array of condition predicates and their associated specifications
    ///   - fallback: The fallback specification
    public init<S: Specification>(
        conditions: [(predicate: () -> Bool, specification: S)],
        fallback: S
    ) where S.T == EvaluationContext {
        self.init(
            provider: DefaultContextProvider.shared,
            conditions: conditions,
            fallback: fallback
        )
    }

    /// Creates a ConditionalSatisfies property wrapper with predicate functions using the shared default context provider.
    /// - Parameters:
    ///   - conditions: Array of condition predicates and their associated predicate functions
    ///   - fallback: The fallback predicate function
    public init(
        conditions: [(predicate: () -> Bool, specification: (EvaluationContext) -> Bool)],
        fallback: @escaping (EvaluationContext) -> Bool
    ) {
        self.init(
            provider: DefaultContextProvider.shared,
            conditions: conditions,
            fallback: fallback
        )
    }
}

// MARK: - Builder Pattern Support

extension ConditionalSatisfies {

    /// Creates a builder for constructing conditional specifications
    /// - Parameter provider: The context provider to use
    /// - Returns: A ConditionalSatisfiesBuilder for fluent composition
    public static func builder<Provider: ContextProviding>(
        provider: Provider
    ) -> ConditionalSatisfiesBuilder<Context> where Provider.Context == Context {
        ConditionalSatisfiesBuilder(provider: provider)
    }
}

/// A builder for creating ConditionalSatisfies property wrappers using a fluent interface
public struct ConditionalSatisfiesBuilder<Context> {
    private let contextFactory: () -> Context
    private let asyncContextFactory: (() async throws -> Context)?
    private var conditions: [(predicate: () -> Bool, specification: AnySpecification<Context>)] = []

    internal init<Provider: ContextProviding>(provider: Provider)
    where Provider.Context == Context {
        self.contextFactory = provider.currentContext
        self.asyncContextFactory = provider.currentContextAsync
    }

    /// Adds a condition with a specification to the builder
    /// - Parameters:
    ///   - predicate: The condition predicate
    ///   - specification: The specification to use when the condition is true
    /// - Returns: Self for method chaining
    public func when<S: Specification>(_ predicate: @escaping () -> Bool, use specification: S)
        -> ConditionalSatisfiesBuilder<Context> where S.T == Context
    {
        var builder = self
        builder.conditions.append(
            (predicate: predicate, specification: AnySpecification(specification)))
        return builder
    }

    /// Adds a condition with a predicate function to the builder
    /// - Parameters:
    ///   - predicate: The condition predicate
    ///   - specification: The predicate function to use when the condition is true
    /// - Returns: Self for method chaining
    public func when(
        _ predicate: @escaping () -> Bool, use specification: @escaping (Context) -> Bool
    ) -> ConditionalSatisfiesBuilder<Context> {
        var builder = self
        builder.conditions.append(
            (predicate: predicate, specification: AnySpecification(specification)))
        return builder
    }

    /// Builds a ConditionalSatisfies property wrapper with a fallback specification
    /// - Parameter fallback: The fallback specification
    /// - Returns: A ConditionalSatisfies property wrapper
    public func otherwise<S: Specification>(_ fallback: S) -> ConditionalSatisfies<Context>
    where S.T == Context {
        ConditionalSatisfies(
            provider: GenericContextProvider(contextFactory),
            anyConditions: conditions,
            fallback: AnySpecification(fallback)
        )
    }

    /// Builds a ConditionalSatisfies property wrapper with a fallback predicate function
    /// - Parameter fallback: The fallback predicate function
    /// - Returns: A ConditionalSatisfies property wrapper
    public func otherwise(_ fallback: @escaping (Context) -> Bool) -> ConditionalSatisfies<Context>
    {
        ConditionalSatisfies(
            provider: GenericContextProvider(contextFactory),
            anyConditions: conditions,
            fallback: AnySpecification(fallback)
        )
    }
}

// MARK: - Platform-Specific Convenience Extensions

#if os(iOS) || os(tvOS)
    extension ConditionalSatisfies where Context == EvaluationContext {

        /// Creates a device-adaptive ConditionalSatisfies that selects specifications based on device type
        /// - Parameters:
        ///   - ipadSpec: Specification to use on iPad
        ///   - iphoneSpec: Specification to use on iPhone
        ///   - fallback: Fallback specification for other devices
        /// - Returns: A ConditionalSatisfies wrapper for device adaptation
        public static func deviceAdaptive<S: Specification>(
            ipad ipadSpec: S,
            iphone iphoneSpec: S,
            fallback: S
        ) -> ConditionalSatisfies<EvaluationContext> where S.T == EvaluationContext {
            ConditionalSatisfies(
                conditions: [
                    (
                        predicate: { UIDevice.current.userInterfaceIdiom == .pad },
                        specification: ipadSpec
                    ),
                    (
                        predicate: { UIDevice.current.userInterfaceIdiom == .phone },
                        specification: iphoneSpec
                    ),
                ],
                fallback: fallback
            )
        }

        /// Creates an accessibility-adaptive ConditionalSatisfies that selects specifications based on accessibility settings
        /// - Parameters:
        ///   - voiceOverSpec: Specification to use when VoiceOver is running
        ///   - reducedMotionSpec: Specification to use when reduced motion is enabled
        ///   - fallback: Fallback specification for standard accessibility settings
        /// - Returns: A ConditionalSatisfies wrapper for accessibility adaptation
        public static func accessibilityAdaptive<S: Specification>(
            voiceOver voiceOverSpec: S,
            reducedMotion reducedMotionSpec: S,
            fallback: S
        ) -> ConditionalSatisfies<EvaluationContext> where S.T == EvaluationContext {
            ConditionalSatisfies(
                conditions: [
                    (
                        predicate: { UIAccessibility.isVoiceOverRunning },
                        specification: voiceOverSpec
                    ),
                    (
                        predicate: { UIAccessibility.isReduceMotionEnabled },
                        specification: reducedMotionSpec
                    ),
                ],
                fallback: fallback
            )
        }
    }
#endif

#if canImport(SwiftUI)
    // MARK: - SwiftUI Integration

    extension ConditionalSatisfies: DynamicProperty where Context == EvaluationContext {

        /// SwiftUI integration that updates when conditions change
        /// Note: This wrapper evaluates conditions on each access,
        /// so SwiftUI views will automatically update when conditions change
        public mutating func update() {
            // SwiftUI will call this when the view needs updating
            // The conditional logic handles the rest
        }
    }
#endif
