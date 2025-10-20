import Foundation
import SpecificationKit

// Define experiment variants
enum ExperimentVariant: String {
    case control
    case variantA
    case variantB
}

// Setup experiment context with feature flags
let context = EvaluationContext(
    flags: [
        "variant_control": true,
        "variant_a": true,
        "variant_b": true
    ]
)

// Create weighted specification for A/B testing
// Format: (specification, weight, result)
let weightedSpec = try WeightedSpec<EvaluationContext, ExperimentVariant>([
    (FeatureFlagSpec.enabled("variant_control"), 0.5, .control),  // 50% control
    (FeatureFlagSpec.enabled("variant_a"), 0.3, .variantA),       // 30% variant A
    (FeatureFlagSpec.enabled("variant_b"), 0.2, .variantB)        // 20% variant B
])

// Choose a variant based on weights
let selectedVariant = weightedSpec.decide(context)
print("Selected variant: \(selectedVariant?.rawValue ?? "none")")

// View probability distribution
let probabilities = weightedSpec.probabilityDistribution
print("Probabilities: \(probabilities)")
