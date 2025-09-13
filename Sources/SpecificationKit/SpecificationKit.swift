//
//  SpecificationKit.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
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
