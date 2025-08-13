//
//  AutoContextSpecification.swift
//  SpecificationKit
//
//  Created by AutoContext Macro Implementation.
//

import Foundation

/// A protocol for specifications that can provide their own context.
///
/// When a `Specification` conforms to this protocol, it can be used with the `@Satisfies`
/// property wrapper without explicitly providing a context provider. The wrapper will
/// use the `contextProvider` defined by the specification type itself.
public protocol AutoContextSpecification: Specification {
    /// The type of context provider this specification uses. The provider's `Context`
    /// must match the specification's associated type `T`.
    associatedtype Provider: ContextProviding where Provider.Context == T

    /// The static context provider that supplies the context for evaluation.
    static var contextProvider: Provider { get }

    /// Creates a new instance of this specification.
    init()
}
