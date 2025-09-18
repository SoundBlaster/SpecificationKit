import Foundation
import SpecificationKit

enum ExperimentVariant: String, CaseIterable {
    case control
    case onboardingRevamp
    case loyaltyUpsell
}

struct ExperimentConfiguration {
    let candidates: [(FeatureFlagSpec, Double, ExperimentVariant)]

    init() {
        candidates = [
            (FeatureFlagSpec.enabled("experiment_onboarding_revamp"), 0.45, .onboardingRevamp),
            (FeatureFlagSpec.enabled("experiment_loyalty_upsell"), 0.35, .loyaltyUpsell),
            (FeatureFlagSpec.enabled("experiment_control"), 0.20, .control)
        ]
    }
}

extension ExperimentConfiguration {
    func availableFlagKeys() -> [String] {
        candidates.map(\.0.flagKey)
    }
}

let previewContext = EvaluationContext(
    flags: [
        "experiment_onboarding_revamp": true,
        "experiment_loyalty_upsell": true,
        "experiment_control": true
    ]
)
