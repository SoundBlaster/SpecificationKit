# Obserder Wrapped Properties

Short answer: you can’t re-implement SwiftUI’s private @State, but you can build your own property wrapper that participates in SwiftUI’s update cycle by conforming to DynamicProperty and backing itself with public primitives like @State, @ObservedObject, or the new Observation framework. That’s the supported path.

Below are two patterns you can copy-paste.

⸻

1) Build a @ClampedState (a custom, validating state)

This wrapper persists across renders (because it’s backed by @State), exposes a Binding, and enforces constraints whenever the value changes.

import SwiftUI

@propertyWrapper
struct ClampedState<Value: Comparable>: DynamicProperty {
    @State private var storage: Value
    private let range: ClosedRange<Value>

    var wrappedValue: Value {
        get { storage }
        nonmutating set { storage = min(max(newValue, range.lowerBound), range.upperBound) }
    }

    var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self._storage = State(initialValue: min(max(wrappedValue, range.lowerBound), range.upperBound))
        self.range = range
    }

    // Optional: hook for per-update side effects
    mutating func update() {
        // Called every render before body; keep cheap!
    }
}

Use it in a View:

struct VolumeView: View {
    @ClampedState(0...100) var volume: Int = 30

    var body: some View {
        VStack {
            Text("Volume: \($volume.wrappedValue)")
            Slider(value: Binding(
                get: { Double(volume) },
                set: { volume = Int($0.rounded()) }
            ), in: 0...100)
        }
        .padding()
    }
}

Why this works:
	•	DynamicProperty tells SwiftUI your wrapper needs lifecycle calls (update()).
	•	Backing with @State gives you identity + persistence across re-renders.
	•	Setting wrappedValue triggers @State’s invalidation → the view re-renders.

⸻

2) Build a model-backed wrapper using the new Observation (@Observable)

Use Swift’s Observation to auto-refresh when fields mutate, not just when you assign a new value.

import SwiftUI
import Observation

@Observable
final class CounterModel {
    var count: Int = 0
}

// A wrapper that wires a model into SwiftUI and exposes a Binding to one of its fields.
@propertyWrapper
struct ModelField<State>: DynamicProperty {
    @State private var model: CounterModel
    private let keyPath: ReferenceWritableKeyPath<CounterModel, State>

    var wrappedValue: State {
        get { model[keyPath: keyPath] }
        nonmutating set { model[keyPath: keyPath] = newValue }
    }

    var projectedValue: Binding<State> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    init(_ keyPath: ReferenceWritableKeyPath<CounterModel, State>, initial: CounterModel = .init()) {
        self._model = State(initialValue: initial)
        self.keyPath = keyPath
    }
}

struct CounterView: View {
    @ModelField(\.count) var count

    var body: some View {
        VStack {
            Text("Count: \(count)")
            HStack {
                Button("-") { count -= 1 }
                Button("+") { count += 1 }
            }
        }
    }
}

Why this works:
	•	@Observable makes property mutations emit change notifications.
	•	The wrapper stores the model using @State (so it’s stable across renders).
	•	Mutating a field (count) triggers Observation → SwiftUI re-renders.

⸻

Tips & gotchas (important!)
	•	Always conform to DynamicProperty for SwiftUI lifecycle integration. A plain property wrapper won’t persist across renders.
	•	Back with a SwiftUI primitive (@State, @StateObject, @ObservedObject, @Environment, or Observation). Don’t try to mimic SwiftUI’s private storage.
	•	Keep update() cheap. It’s called every render.
	•	Identity matters. If you need reference semantics (e.g., async tasks, caches), store a reference type via @StateObject inside your wrapper rather than @State.
	•	Bindings: expose projectedValue as a Binding for interop with controls.
	•	Initialization: use init(wrappedValue:) so your wrapper can be used like the native ones.

⸻

Variants you might want to build
	•	@DebouncedState: writes to wrappedValue immediately for UI, but debounces an external callback.
	•	@PersistedState: syncs to UserDefaults/AppStorage with custom encoding.
	•	@DerivedState: wraps a value derived from other state and invalidates when inputs change.
	•	@ResettableState: provides a .reset() API you can call from the view.

If you tell me your exact behavioral twist (clamping, persistence, debouncing, dependency-keyed reset, etc.), I’ll tailor a wrapper to that scenario.
