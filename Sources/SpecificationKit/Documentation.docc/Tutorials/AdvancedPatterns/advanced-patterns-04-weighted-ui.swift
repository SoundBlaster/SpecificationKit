import Combine
import Foundation
import SpecificationKit
import SwiftUI

enum ExperimentVariant: String, CaseIterable, Identifiable {
    case control
    case onboardingRevamp
    case loyaltyUpsell

    var id: String { rawValue }
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

final class ExperimentViewModel: ObservableObject {
    private let configuration: ExperimentConfiguration
    private let selectionSpec: WeightedSpec<EvaluationContext, ExperimentVariant>
    private var context: EvaluationContext

    @Maybe(provider: staticContext(EvaluationContext()), decide: { _ in nil })
    private var activeVariant: ExperimentVariant?

    @Published private(set) var displayedVariant: ExperimentVariant?

    init(
        configuration: ExperimentConfiguration = ExperimentConfiguration(),
        context: EvaluationContext
    ) throws {
        self.configuration = configuration
        self.selectionSpec = try WeightedSpec(configuration.candidates)
        self.context = context

        let provider = staticContext(context)
        self._activeVariant = Maybe(provider: provider, using: selectionSpec)
        self.displayedVariant = activeVariant
    }

    func overrideFlag(key: String, value: Bool) {
        var flags = context.flags
        flags[key] = value

        context = EvaluationContext(
            currentDate: context.currentDate,
            launchDate: context.launchDate,
            userData: context.userData,
            counters: context.counters,
            events: context.events,
            flags: flags,
            segments: context.segments
        )

        refreshVariant()
    }

    func refreshVariant() {
        let provider = staticContext(context)
        _activeVariant = Maybe(provider: provider, using: selectionSpec)
        displayedVariant = activeVariant
    }

    func analytics(upliftByVariant: [ExperimentVariant: Double]) throws -> WeightedVariantAnalytics {
        let forecast = try VariantOutcomeForecast(
            configuration: configuration,
            upliftByVariant: upliftByVariant
        )
        return forecast.analytics()
    }
}

struct ExperimentBanner: View {
    @StateObject private var viewModel: ExperimentViewModel

    init(
        configuration: ExperimentConfiguration = ExperimentConfiguration(),
        context: EvaluationContext
    ) {
        let model = try? ExperimentViewModel(configuration: configuration, context: context)
        _viewModel = StateObject(wrappedValue: model ?? (try! ExperimentViewModel(configuration: configuration, context: context)))
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Experiment Variant")
                .font(.headline)

            if let variant = viewModel.displayedVariant {
                Text(variant.rawValue.capitalized)
                    .font(.title2)
            } else {
                Text("No eligible variant")
                    .foregroundColor(.secondary)
            }

            Button("Refresh decision") {
                viewModel.refreshVariant()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.blue.opacity(0.08))
        .cornerRadius(16)
    }
}

let initialContext = EvaluationContext(
    flags: [
        "experiment_onboarding_revamp": true,
        "experiment_loyalty_upsell": false,
        "experiment_control": true
    ]
)

let banner = ExperimentBanner(context: initialContext)
