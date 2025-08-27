//
//  SpecificationKit.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

/// The main SpecificationKit module providing specification pattern implementation
/// for Swift applications with support for context providers, property wrappers,
/// and composable business rules.
public enum SpecificationKit {

    /// The current version of SpecificationKit
    public static let version = "1.0.0"

}

// MARK: - Macros

/// A macro that automatically synthesizes a composite specification by combining
/// the provided specifications with a logical AND.
///
/// For example:
/// ```
/// @specs(
///   DelaySinceLaunchSpec(seconds: 10),
///   MaxDisplayCountSpec(limit: 3)
/// )
/// struct PromoBannerSpec: Specification<PromoContext> {}
/// ```
/// This will generate the necessary implementation to combine the two specifications.
@attached(member, names: named(init), named(isSatisfiedBy), named(composite))
public macro specs(
    _ specifications: Any...
) = #externalMacro(module: "SpecificationKitMacros", type: "SpecsMacro")

/// A macro that augments a `Specification` type to become an `AutoContextSpecification`.
///
/// It injects:
/// - `public typealias Provider = DefaultContextProvider`
/// - `public static var contextProvider: DefaultContextProvider { .shared }`
/// - `public init()` if not present
@attached(member, names: named(Provider), named(contextProvider), named(init))
public macro AutoContext() = #externalMacro(
    module: "SpecificationKitMacros",
    type: "AutoContextMacro"
)
