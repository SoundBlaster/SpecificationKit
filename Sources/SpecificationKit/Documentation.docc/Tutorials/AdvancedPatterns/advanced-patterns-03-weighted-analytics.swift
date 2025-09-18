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

struct WeightedVariantAnalytics {
    let expectedConversionLift: Double
    let variance: Double
    let standardDeviation: Double
    let probabilities: [ExperimentVariant: Double]
}

struct VariantOutcomeForecast {
    private let configuration: ExperimentConfiguration
    private let selectionSpec: WeightedSpec<EvaluationContext, ExperimentVariant>
    private let upliftSpec: WeightedSpec<EvaluationContext, Double>

    init(
        configuration: ExperimentConfiguration = ExperimentConfiguration(),
        upliftByVariant: [ExperimentVariant: Double]
    ) throws {
        self.configuration = configuration
        self.selectionSpec = try WeightedSpec(configuration.candidates)

        let upliftCandidates = configuration.candidates.map { candidate in
            let uplift = upliftByVariant[candidate.2] ?? 0.0
            return (candidate.0, candidate.1, uplift)
        }

        self.upliftSpec = try WeightedSpec(upliftCandidates)
    }

    func chooseVariant(for context: EvaluationContext) -> ExperimentVariant? {
        selectionSpec.decide(context)
    }

    func analytics() -> WeightedVariantAnalytics {
        let probabilities = Dictionary(
            uniqueKeysWithValues: zip(configuration.candidates.map(\.2), selectionSpec.probabilityDistribution)
        )

        return WeightedVariantAnalytics(
            expectedConversionLift: upliftSpec.expectedValue(),
            variance: upliftSpec.variance(),
            standardDeviation: upliftSpec.standardDeviation(),
            probabilities: probabilities
        )
    }
}

let upliftSignals: [ExperimentVariant: Double] = [
    .onboardingRevamp: 0.08,
    .loyaltyUpsell: 0.05,
    .control: 0.0
]

let forecast = try? VariantOutcomeForecast(upliftByVariant: upliftSignals)
let analytics = forecast?.analytics()
