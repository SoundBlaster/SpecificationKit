import SwiftUI
import SpecificationKit

struct AsyncDemoView: View {
    @State private var isEvaluating = false
    @State private var resultText: String = "Tap Evaluate"
    @State private var simulateError = false
    @State private var addDelay = true
    @State private var featureOn = false
    @State private var asyncCount: Int = 0
    @State private var macroAsyncResult: String = "—"
    @State private var autoCtxAsyncResult: String = "—"

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
                .font(.title)

            // MARK: - @specs async demos
            Group {
                Text("Local spec types for this demo:")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("- @specs(MaxCountSpec(counterKey: \"async_count\", limit: 3)) → MacroAsyncCountSpec")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("- @AutoContext + @specs(MaxCountSpec(...)) → AutoCtxAsyncCountSpec (async computed isSatisfied)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Text("Counter (async_count): \(asyncCount)")
                    Button("+1") { incrementCount() }
                    Button("Reset") { resetCount() }
                }

                HStack(spacing: 12) {
                    Button(action: evaluateMacroAsync) {
                        Text("Evaluate @specs.isSatisfiedByAsync(ctx)")
                    }
                    Text("Result: \(macroAsyncResult)")
                }

                HStack(spacing: 12) {
                    Button(action: evaluateAutoCtxAsync) {
                        Text("Evaluate @AutoContext @specs .isSatisfied")
                    }
                    Text("Result: \(autoCtxAsyncResult)")
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            provider.setFlag("feature_async", to: featureOn)
            asyncCount = provider.getCounter("async_count")
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

    // MARK: - @specs async helpers

    @specs(MaxCountSpec(counterKey: "async_count", limit: 3))
    struct MacroAsyncCountSpec: Specification { typealias T = EvaluationContext }

    @AutoContext
    @specs(MaxCountSpec(counterKey: "async_count", limit: 3))
    struct AutoCtxAsyncCountSpec: Specification { typealias T = EvaluationContext }

    private func incrementCount() {
        _ = provider.incrementCounter("async_count")
        asyncCount = provider.getCounter("async_count")
    }

    private func resetCount() {
        provider.setCounter("async_count", to: 0)
        asyncCount = 0
    }

    private func evaluateMacroAsync() {
        macroAsyncResult = "…"
        let spec = MacroAsyncCountSpec()
        let ctx = provider.currentContext()
        Task {
            let ok = try await spec.isSatisfiedByAsync(ctx)
            macroAsyncResult = ok ? "TRUE" : "FALSE"
        }
    }

    private func evaluateAutoCtxAsync() {
        autoCtxAsyncResult = "…"
        Task {
            let ok = try await AutoCtxAsyncCountSpec().isSatisfied
            autoCtxAsyncResult = ok ? "TRUE" : "FALSE"
        }
    }
}

#Preview {
    AsyncDemoView()
}
