//
//  GenericContextProvider+Mock.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2025.
//

import Foundation

/// A generic mock context provider designed for unit testing with custom context types.
/// This provider allows you to set up specific test scenarios with any context type,
/// which is especially useful for testing DecisionSpec implementations.
public class GenericMockProvider<Context>: ContextProviding {

    // MARK: - Properties

    /// The closure that provides the mocked context
    private var contextProvider: () -> Context

    /// Track how many times `currentContext()` was called
    public private(set) var contextRequestCount = 0

    /// Closure that will be called each time `currentContext()` is invoked
    public var onContextRequested: (() -> Void)?

    // MARK: - Initialization

    /// Creates a mock context provider with a default context provider
    /// - Parameter defaultContext: The default context to provide
    public init(defaultContext: Context) {
        self.contextProvider = { defaultContext }
    }

    /// Creates a mock context provider with the specified context provider
    /// - Parameter provider: A closure that provides the context
    public init(provider: @escaping () -> Context) {
        self.contextProvider = provider
    }

    /// Default initializer that requires setting the context provider separately
    public init() {
        self.contextProvider = {
            fatalError("Context provider not set. Call provide() before using this mock.")
        }
    }

    // MARK: - ContextProviding

    public func currentContext() -> Context {
        contextRequestCount += 1
        onContextRequested?()
        return contextProvider()
    }

    // MARK: - Mock Control Methods

    /// Sets the context provider closure
    /// - Parameter provider: A closure that provides the context
    /// - Returns: Self for method chaining
    @discardableResult
    public func provide(_ provider: @escaping () -> Context) -> Self {
        self.contextProvider = provider
        return self
    }

    /// Sets a static context to be provided
    /// - Parameter context: The context to provide
    /// - Returns: Self for method chaining
    @discardableResult
    public func provideStatic(_ context: Context) -> Self {
        return provide { context }
    }

    /// Resets the context request count to zero
    /// - Returns: Self for method chaining
    @discardableResult
    public func resetRequestCount() -> Self {
        contextRequestCount = 0
        return self
    }

    /// Verifies that `currentContext()` was called the expected number of times
    /// - Parameter expectedCount: The expected number of calls
    /// - Returns: True if the count matches, false otherwise
    public func verifyContextRequestCount(_ expectedCount: Int) -> Bool {
        return contextRequestCount == expectedCount
    }
}
