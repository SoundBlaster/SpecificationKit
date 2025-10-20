import Foundation
import SpecificationKit

// Define experiment variants for A/B testing
enum ExperimentVariant: String {
    case control
    case variantA
    case variantB
}

// Setup feature flags for each variant
let experimentContext = EvaluationContext(
    flags: [
        "variant_control": true,
        "variant_a": true,
        "variant_b": true
    ]
)
