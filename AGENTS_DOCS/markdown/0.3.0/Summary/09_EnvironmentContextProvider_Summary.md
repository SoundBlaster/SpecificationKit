codex
I scanned the new TODO and picked the P1 item “Implement EnvironmentContextProvi
der reading SwiftUI @Environment/@AppStorage into EvaluationContext,” then imple
mented it with a demo and tests.

What I changed
- Providers: Added EnvironmentContextProvider to build an EvaluationContext snap
shot from environment-like values and simple persisted settings.
  - File: Sources/SpecificationKit/Providers/EnvironmentContextProvider.swift
  - Injects environment info into `userData` keys:
    - `environment.calendar.identifier`: `Calendar.Identifier`
    - `environment.timeZone.identifier`: `String`
    - `environment.locale.identifier`: `String`
    - `environment.interfaceStyle`: `String` (“light”/“dark” suggested)
- DemoApp: Added a SwiftUI screen demonstrating the provider bridged from @Envir
onment and @AppStorage.
  - New: DemoApp/Sources/EnvironmentDemoView.swift
  - Updated navigation: DemoApp/Sources/main.swift (added “Environment Context”
link)
- Tests: Added unit tests validating the provider → EvaluationContext mapping.
  - File: Tests/SpecificationKitTests/EnvironmentContextProviderTests.swift
- Docs: Updated README with a new “EnvironmentContextProvider” section and menti
oned the new demo screen in the Demo section.

How to try it
- Build and test: `swift test` (requires normal developer environment)
- Run demo:
  - `cd DemoApp && swift run SpecificationKitDemo`
  - Open “Environment Context” in the sidebar.
  - Toggle “Promo Enabled” and adjust “Launch Count”; locale and color scheme re
flect from the environment.
  - The screen evaluates:
    - FeatureFlagSpec on `promo_enabled`
    - PredicateSpec counter on `launch_count >= 3`

Notes
- The provider is UI-agnostic; SwiftUI views set its properties from `@Environme
nt` and `@AppStorage`.
- Keys used in `userData` are stable and tested; specs can reference them if nee
ded.
