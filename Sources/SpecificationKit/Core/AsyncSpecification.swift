import Foundation

/// An asynchronous specification protocol.
public protocol AsyncSpecification {
    associatedtype T
    func isSatisfiedBy(_ candidate: T) async throws -> Bool
}

/// Type-erased asynchronous specification.
public struct AnyAsyncSpecification<T>: AsyncSpecification {
    private let _isSatisfied: (T) async throws -> Bool

    public init<S: AsyncSpecification>(_ spec: S) where S.T == T {
        self._isSatisfied = spec.isSatisfiedBy
    }

    public init(_ predicate: @escaping (T) async throws -> Bool) {
        self._isSatisfied = predicate
    }

    public func isSatisfiedBy(_ candidate: T) async throws -> Bool {
        try await _isSatisfied(candidate)
    }
}

// MARK: - Bridging

extension AnyAsyncSpecification {
    /// Bridge a synchronous specification to async form.
    public init<S: Specification>(_ spec: S) where S.T == T {
        self._isSatisfied = { candidate in spec.isSatisfiedBy(candidate) }
    }
}

