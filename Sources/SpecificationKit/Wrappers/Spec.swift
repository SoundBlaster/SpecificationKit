//
//  Spec.swift (deprecated aliases)
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

import Foundation

@available(*, deprecated, message: "Use @Decides instead")
public typealias Spec<Context, Result> = Decides<Context, Result>

@available(*, deprecated, message: "Use DecidesBuilder instead")
public typealias SpecBuilder<Context, Result> = DecidesBuilder<Context, Result>
