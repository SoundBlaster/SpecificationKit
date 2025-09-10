//
//  DecisionsDemoView.swift
//  SpecificationKitDemo
//

import SwiftUI
import SpecificationKit

struct DecisionsDemoView: View {
    // AutoContext demo spec: uses DefaultContextProvider.shared via @AutoContext
    @AutoContext
    struct PromoEnabledSpec: Specification {
        typealias T = EvaluationContext
        func isSatisfiedBy(_ context: EvaluationContext) -> Bool {
            context.flag(for: "promo")
        }
    }

    // Demo specs
    private let vip = PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }
    private let promo = PredicateSpec<EvaluationContext> { $0.flag(for: "promo") }

    // Optional decision wrapper (no implicit default)
    @Maybe([
        (PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }, 50),
        (PredicateSpec<EvaluationContext> { $0.flag(for: "promo") }, 20)
    ]) var discountOptional: Int?

    // Non-optional with explicit fallback
    @Decides([
        (PredicateSpec<EvaluationContext> { $0.flag(for: "vip") }, 50),
        (PredicateSpec<EvaluationContext> { $0.flag(for: "promo") }, 20)
    ], or: 0) var discountRequired: Int

    // Local UI state with synchronous provider updates
    @State private var isVip = false
    @State private var isInPromo = false

    private let provider = DefaultContextProvider.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Decisions Demo")
                .font(.title)
                .fontWeight(.semibold)

            HStack(spacing: 24) {
                Toggle("VIP", isOn: .init(
                    get: { isVip },
                    set: { newValue in
                        isVip = newValue
                        provider.setFlag("vip", to: newValue)
                    }
                ))

                Toggle("Promo", isOn: .init(
                    get: { isInPromo },
                    set: { newValue in
                        isInPromo = newValue
                        provider.setFlag("promo", to: newValue)
                    }
                ))
            }

            Group {
                Text("@Maybe result: \(discountOptional?.description ?? "nil")")
                Text("@Decides result: \(discountRequired)")
                // AutoContext demo: use macro-injected contextProvider
                AutoContextRow()
            }
            .font(.headline)

            Divider()

            // Explicit FirstMatchSpec usage
            let explicit = FirstMatchSpec<EvaluationContext, Int>([
                (vip, 50),
                (promo, 20)
            ])
            let explicitValue = explicit.decide(provider.currentContext()) ?? 0
            Text("FirstMatchSpec.decide(_:): \(explicitValue)")

            Spacer()
        }
        .padding()
        .onAppear {
            // Initialize from provider once at appear
            isVip = provider.getFlag("vip")
            isInPromo = provider.getFlag("promo")
        }
        .navigationTitle("Decisions")
    }
}

#Preview {
    DecisionsDemoView()
}

// MARK: - Subviews

private struct AutoContextRow: View {
    // Using provider injected by @AutoContext macro
    @Satisfies(provider: DecisionsDemoView.PromoEnabledSpec.contextProvider,
               using: DecisionsDemoView.PromoEnabledSpec())
    private var isPromoOn: Bool

    var body: some View {
        Text("@AutoContext PromoEnabledSpec: \(isPromoOn ? "ON" : "OFF")")
    }
}
