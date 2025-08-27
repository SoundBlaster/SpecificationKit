import SwiftUI
import SpecificationKit

struct AsyncDemoView: View {
    @State private var isEvaluating = false
    @State private var resultText: String = "Tap Evaluate"
    @State private var simulateError = false
    @State private var addDelay = true
    @State private var featureOn = false

    private let provider = DefaultContextProvider.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Async Specs Demo")
                .font(.title)
                .fontWeight(.semibold)

            Toggle("Feature flag", isOn: .init(
                get: { featureOn },
                set: { newValue in
                    featureOn = newValue
                    provider.setFlag("feature_async", to: newValue)
                }
            ))

            Toggle("Simulate error", isOn: $simulateError)
            Toggle("Add 100ms delay", isOn: $addDelay)

            HStack(spacing: 12) {
                Button(action: evaluate) {
                    HStack {
                        if isEvaluating { ProgressView().controlSize(.small) }
                        Text("Evaluate Async Spec")
                    }
                }
                .disabled(isEvaluating)

                Text(resultText)
                    .font(.headline)
            }

            Divider()

            Text("Using AnyAsyncSpecification<EvaluationContext>")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .onAppear {
            provider.setFlag("feature_async", to: featureOn)
        }
        .navigationTitle("Async Specs")
    }

    private func evaluate() {
        isEvaluating = true
        resultText = "Evaluating…"

        Task {
            enum EvalError: Error { case simulated }

            let spec = AnyAsyncSpecification<EvaluationContext> { ctx in
                if addDelay {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                }
                if simulateError { throw EvalError.simulated }
                return ctx.flag(for: "feature_async")
            }

            do {
                let ctx = provider.currentContext() // sync context is fine here
                let ok = try await spec.isSatisfiedBy(ctx)
                resultText = ok ? "Result: TRUE" : "Result: FALSE"
            } catch {
                resultText = "Error: \(error)"
            }
            isEvaluating = false
        }
    }
}

#Preview {
    AsyncDemoView()
}

