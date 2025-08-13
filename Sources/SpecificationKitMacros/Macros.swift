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
