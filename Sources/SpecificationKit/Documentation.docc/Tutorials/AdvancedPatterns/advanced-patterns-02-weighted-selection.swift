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

struct ExperimentDecider {
    private let configuration: ExperimentConfiguration
    private let weightedSpec: WeightedSpec<EvaluationContext, ExperimentVariant>

    init(configuration: ExperimentConfiguration = ExperimentConfiguration()) throws {
        self.configuration = configuration
        self.weightedSpec = try WeightedSpec(configuration.candidates)
    }

    func chooseVariant(for context: EvaluationContext) -> ExperimentVariant? {
        weightedSpec.decide(context)
    }

    func probabilityByVariant() -> [ExperimentVariant: Double] {
        let probabilities = weightedSpec.probabilityDistribution
        return Dictionary(uniqueKeysWithValues: zip(configuration.candidates.map(\.2), probabilities))
    }
}

let sampleContext = EvaluationContext(
    flags: [
        "experiment_onboarding_revamp": true,
        "experiment_loyalty_upsell": true,
        "experiment_control": true
    ]
)

let decider = try? ExperimentDecider()
let selectedVariant = decider?.chooseVariant(for: sampleContext)
let probabilities = decider?.probabilityByVariant()
