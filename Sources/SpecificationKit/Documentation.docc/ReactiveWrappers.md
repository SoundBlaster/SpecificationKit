# Reactive Wrappers

The library includes SwiftUI-friendly wrappers that automatically re-evaluate when a context provider publishes changes via ``ContextUpdatesProviding``.

## ObservedSatisfies

`@ObservedSatisfies` evaluates a boolean ``Specification`` and updates the view whenever the provider signals a change.

```swift
import SwiftUI
import SpecificationKit

struct QuotaView: View {
    @ObservedSatisfies(provider: DefaultContextProvider.shared,
                       using: MaxCountSpec(counterKey: "attempts", limit: 3))
    private var underLimit: Bool

    var body: some View {
        VStack {
            Text(underLimit ? "Below limit" : "Limit reached")
            Button("+1") { _ = DefaultContextProvider.shared.incrementCounter("attempts") }
            Button("Reset") { DefaultContextProvider.shared.setCounter("attempts", to: 0) }
        }
    }
}
```

## ObservedMaybe

`@ObservedMaybe` is the optional decision counterpart. It evaluates a ``DecisionSpec`` (or pairs/closure) and exposes an optional result that refreshes on provider updates.

```swift
import SwiftUI
import SpecificationKit

struct MaybeView: View {
    @ObservedMaybe(provider: DefaultContextProvider.shared,
                   firstMatch: [(FeatureFlagSpec(flagKey: "feature_x"), "Flag enabled")])
    private var flagMessage: String?

    @ObservedMaybe(provider: DefaultContextProvider.shared,
                   decide: { ctx in ctx.counter(for: "tap_count") > 0 ? "Count > 0" : nil })
    private var countMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            Text(flagMessage ?? "Flag disabled")
            Text(countMessage ?? "No taps yet")
        }
    }
}
```

### Provider Requirements

To enable reactive updates, your provider should conform to ``ContextUpdatesProviding`` and emit change signals. ``DefaultContextProvider`` and ``EnvironmentContextProvider`` already implement this.

