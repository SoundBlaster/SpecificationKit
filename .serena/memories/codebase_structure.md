# SpecificationKit Codebase Structure

## Main Directory Structure
```
Sources/
├── SpecificationKit/          # Main library
│   ├── Core/                  # Core protocols and types
│   │   ├── Specification.swift
│   │   ├── DecisionSpec.swift
│   │   ├── AnySpecification.swift
│   │   ├── AsyncSpecification.swift
│   │   └── ContextProviding.swift
│   ├── Specs/                 # Built-in specifications
│   │   ├── WeightedSpec.swift
│   │   ├── HistoricalSpec.swift
│   │   ├── ComparativeSpec.swift
│   │   ├── ThresholdSpec.swift
│   │   └── FirstMatchSpec.swift
│   ├── Wrappers/              # Property wrappers
│   │   ├── @Satisfies.swift
│   │   ├── @Decides.swift
│   │   ├── @Maybe.swift
│   │   ├── @ObservedSatisfies.swift
│   │   ├── @ObservedDecides.swift
│   │   ├── @ObservedMaybe.swift
│   │   ├── @CachedSatisfies.swift
│   │   └── @ConditionalSatisfies.swift
│   ├── Providers/             # Context providers
│   │   ├── DefaultContextProvider.swift
│   │   ├── NetworkContextProvider.swift
│   │   ├── PersistentContextProvider.swift
│   │   ├── CompositeContextProvider.swift
│   │   └── Platform-specific providers
│   ├── Utils/                 # Utilities
│   │   ├── SpecificationTracer.swift
│   │   └── PerformanceProfiler.swift
│   └── Documentation.docc/    # DocC documentation
└── SpecificationKitMacros/    # Macro implementations

Tests/SpecificationKitTests/   # Comprehensive test suite
DemoApp/                       # SwiftUI demo application
AGENTS_DOCS/                   # Agent documentation and tasks
```