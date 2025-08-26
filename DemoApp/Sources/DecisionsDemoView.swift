//
//  DecisionsDemoView.swift
//  SpecificationKitDemo
//

import SwiftUI
import SpecificationKit

struct DecisionsDemoView: View {
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

    // Local UI state mirroring DefaultContextProvider flags
    @State private var isVip = false
    @State private var isInPromo = false

    private let provider = DefaultContextProvider.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Decisions Demo")
                .font(.title)
                .fontWeight(.semibold)

            HStack(spacing: 24) {
                Toggle("VIP", isOn: $isVip)
                    .onChange(of: isVip) { newValue in
                        provider.setFlag("vip", to: newValue)
                    }

                Toggle("Promo", isOn: $isInPromo)
                    .onChange(of: isInPromo) { newValue in
                        provider.setFlag("promo", to: newValue)
                    }
            }

            Group {
                Text("@Maybe result: \(discountOptional?.description ?? "nil")")
                Text("@Decides result: \(discountRequired)")
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
            // Sync toggles with provider flags
            isVip = provider.getFlag("vip")
            isInPromo = provider.getFlag("promo")
        }
        .navigationTitle("Decisions")
    }
}

#Preview {
    DecisionsDemoView()
}

