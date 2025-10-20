//
//  MockSpecificationBuilder.swift
//  SpecificationKit
//
//  Lightweight mocking utilities for SpecificationKit specifications.
//

import Foundation

/// Builder for creating configurable mock specifications used in unit tests.
///
/// `MockSpecificationBuilder` provides a fluent API for defining deterministic
/// behaviours that emulate real `Specification` types without relying on
/// production implementations. The builder supports fixed responses, sequences,
/// randomized outcomes, and context-aware predicates while also allowing tests
/// to simulate latency and error conditions.
public final class MockSpecificationBuilder<Context> {

    /// Behavioural presets for a mock specification.
    public enum BehaviorType {
        /// Always returns `true`.
        case alwaysTrue
        /// Always returns `false`.
        case alwaysFalse
        /// Evaluates a custom predicate for each context.
        case conditional((Context) -> Bool)
        /// Waits for the specified delay before returning the provided result.
        case delayed(TimeInterval, result: Bool)
        /// Returns `true` with the supplied probability.
        case random(probability: Double)
        /// Returns values from a fixed sequence in order, wrapping when necessary.
        case sequence([Bool])
        /// Returns the boolean value located at the given key path.
        case contextDependent(KeyPath<Context, Bool>)
    }

    private var behavior: BehaviorType = .alwaysTrue
    private var simulatedError: Error?
    private var executionTime: TimeInterval = 0

    /// Creates a fresh builder with default behaviour (`alwaysTrue`).
    public init() {}

    /// Configures the mock to always return the specified result.
    /// - Parameter result: The boolean response to return.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func alwaysReturns(_ result: Bool) -> Self {
        behavior = result ? .alwaysTrue : .alwaysFalse
        return self
    }

    /// Configures the mock to evaluate the provided predicate for each call.
    /// - Parameter predicate: Closure producing the evaluation outcome.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func returns(_ predicate: @escaping (Context) -> Bool) -> Self {
        behavior = .conditional(predicate)
        return self
    }

    /// Configures the mock to introduce latency before returning the given value.
    /// - Parameters:
    ///   - delay: Duration to wait before producing the result.
    ///   - result: The value returned after the delay.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func withDelay(_ delay: TimeInterval, returning result: Bool) -> Self {
        behavior = .delayed(delay, result: result)
        return self
    }

    /// Configures the mock to succeed with the provided probability.
    /// - Parameter probability: Success likelihood in the range `0...1`.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func withRandomResult(probability: Double) -> Self {
        behavior = .random(probability: max(0, min(1, probability)))
        return self
    }

    /// Configures the mock to return values from a repeating sequence.
    /// - Parameter results: Ordered sequence of boolean values. Must be non-empty.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func withSequence(_ results: [Bool]) -> Self {
        precondition(!results.isEmpty, "Result sequence must not be empty")
        behavior = .sequence(results)
        return self
    }

    /// Configures the mock to read a boolean from the provided key path on the context.
    /// - Parameter keyPath: Key path specifying the boolean value within the context.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func withContextBoolean(_ keyPath: KeyPath<Context, Bool>) -> Self {
        behavior = .contextDependent(keyPath)
        return self
    }

    /// Configures the mock to simulate a thrown error on evaluation.
    /// - Parameter error: Error value to raise when `isSatisfiedBy(_:)` is invoked.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func willThrow(_ error: Error) -> Self {
        simulatedError = error
        return self
    }

    /// Configures additional execution time applied to every evaluation.
    /// - Parameter time: Duration (seconds) to block before returning a result.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func withExecutionTime(_ time: TimeInterval) -> Self {
        executionTime = max(0, time)
        return self
    }

    /// Builds the configured mock specification instance.
    /// - Returns: A ready-to-use mock specification.
    public func build() -> MockSpecification<Context> {
        MockSpecification(
            behavior: behavior,
            simulatedError: simulatedError,
            executionTime: executionTime
        )
    }
}

/// A mock specification that records evaluation details for assertions.
public final class MockSpecification<Context>: Specification {

    /// Captures details about each evaluation.
    public struct CallRecord {
        /// Context passed to `isSatisfiedBy(_:)`.
        public let context: Context
        /// Timestamp for the recorded invocation.
        public let timestamp: Date
        /// Result returned for the invocation.
        public let result: Bool
    }

    private let behavior: MockSpecificationBuilder<Context>.BehaviorType
    private let simulatedError: Error?
    private let executionTime: TimeInterval
    private let stateQueue = DispatchQueue(
        label: "com.specificationkit.mockSpecification.state",
        attributes: .concurrent
    )

    private var sequenceIndex: Int = 0
    private var callRecords: [CallRecord] = []

    internal init(
        behavior: MockSpecificationBuilder<Context>.BehaviorType,
        simulatedError: Error?,
        executionTime: TimeInterval
    ) {
        self.behavior = behavior
        self.simulatedError = simulatedError
        self.executionTime = max(0, executionTime)
    }

    /// Evaluates the specification according to the configured behaviour.
    /// - Parameter candidate: Context value under evaluation.
    /// - Returns: Boolean response defined by the mock configuration.
    public func isSatisfiedBy(_ candidate: Context) -> Bool {
        if executionTime > 0 {
            Thread.sleep(forTimeInterval: executionTime)
        }

        if let error = simulatedError {
            fatalError("Mock specification configured to throw error: \(error)")
        }

        let result: Bool

        switch behavior {
        case .alwaysTrue:
            result = true
        case .alwaysFalse:
            result = false
        case .conditional(let predicate):
            result = predicate(candidate)
        case .delayed(let delay, let delayedResult):
            if delay > 0 {
                Thread.sleep(forTimeInterval: delay)
            }
            result = delayedResult
        case .random(let probability):
            result = Double.random(in: 0..<1) < probability
        case .sequence(let results):
            result = stateQueue.sync(flags: .barrier) {
                let value = results[sequenceIndex % results.count]
                sequenceIndex += 1
                return value
            }
        case .contextDependent(let keyPath):
            result = candidate[keyPath: keyPath]
        }

        let record = CallRecord(context: candidate, timestamp: Date(), result: result)
        stateQueue.sync(flags: .barrier) {
            callRecords.append(record)
        }

        return result
    }

    /// Total number of times the mock specification has been evaluated.
    public var callCount: Int {
        stateQueue.sync { callRecords.count }
    }

    /// Returns the most recently evaluated context, if any.
    public var lastContext: Context? {
        stateQueue.sync { callRecords.last?.context }
    }

    /// Returns the list of recorded results in evaluation order.
    public var allResults: [Bool] {
        stateQueue.sync { callRecords.map(\.result) }
    }

    /// Returns all recorded call details in chronological order.
    public var recordedCalls: [CallRecord] {
        stateQueue.sync { callRecords }
    }

    /// Clears recorded state so the mock can be reused.
    public func reset() {
        stateQueue.sync(flags: .barrier) {
            callRecords.removeAll()
            sequenceIndex = 0
        }
    }
}

// MARK: - Convenience Helpers

extension MockSpecificationBuilder {

    /// Convenience factory for a mock that always returns `true`.
    public static func alwaysTrue() -> MockSpecification<Context> {
        MockSpecificationBuilder<Context>()
            .alwaysReturns(true)
            .build()
    }

    /// Convenience factory for a mock that always returns `false`.
    public static func alwaysFalse() -> MockSpecification<Context> {
        MockSpecificationBuilder<Context>()
            .alwaysReturns(false)
            .build()
    }

    /// Convenience factory for a mock that succeeds with the given probability.
    /// - Parameter successRate: Probability of a `true` result (default `0.8`).
    public static func flaky(successRate: Double = 0.8) -> MockSpecification<Context> {
        MockSpecificationBuilder<Context>()
            .withRandomResult(probability: successRate)
            .build()
    }

    /// Convenience factory for a mock that introduces artificial delay.
    /// - Parameter delay: Duration to wait before returning `true`.
    public static func slow(delay: TimeInterval) -> MockSpecification<Context> {
        MockSpecificationBuilder<Context>()
            .withDelay(delay, returning: true)
            .build()
    }
}
