//
//  AutoContextSpecification.swift
//  SpecificationKit
//
//  Created by AutoContext Macro Implementation.
//

import Foundation

/// Protocol for specifications that provide their own context provider automatically.
/// Used by @AutoContext macro to inject contextProvider and init().
public protocol AutoContextSpecification: Specification where T == EvaluationContext {
    /// The type of context provider this specification uses.
    associatedtype Provider: ContextProviding where Provider.Context == T

    /// The context provider for this specification.
    static var contextProvider: Provider { get }

    /// Default initializer.
    init()
}
