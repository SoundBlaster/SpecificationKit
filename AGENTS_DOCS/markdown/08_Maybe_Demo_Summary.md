codex
Added a new Decisions screen to the DemoApp and wired it into a sidebar layout s
o you can switch between the main demo and the new Decides/Maybe/FirstMatchSpec
examples.

What I changed
- DemoApp/Sources/main.swift
  - Introduced `AppContentView` as the root with a `NavigationView` sidebar:
    - “Overview” → `MainDemoView` (formerly `ContentView`).
    - “Decisions” → `DecisionsDemoView`.
  - Renamed existing `ContentView` to `MainDemoView` and updated the app entry t
o use `AppContentView`.

- DemoApp/Sources/DecisionsDemoView.swift
  - New screen that demonstrates:
    - `@Maybe` optional result using pairs shorthand.
    - `@Decides` non-optional result with `or:` fallback, using pairs shorthand.
    - Explicit `FirstMatchSpec` evaluation alongside the wrappers.
  - UI lets you toggle `vip` and `promo` flags (bound to `DefaultContextProvider
.shared`) to see results update live.

Highlights
- Sidebar navigation: `NavigationView` with `SidebarListStyle` keeps things simp
le and compatible with iOS 15/macOS 12 targets.
- Wrappers demo:
  - `@Maybe([(vip, 50), (promo, 20)]) var discountOptional: Int?`
  - `@Decides([(vip, 50), (promo, 20)], or: 0) var discountRequired: Int`
  - Explicit `FirstMatchSpec` decide against the current context is also shown.
- State sync: Toggles reflect and modify `DefaultContextProvider.shared` flags s
o wrapper values recompute on render.

Build and run
- You can run the DemoApp in Xcode and navigate via the sidebar:
  - Overview: existing banner logic example.
  - Decisions: new Decides/Maybe/FirstMatchSpec showcase.
