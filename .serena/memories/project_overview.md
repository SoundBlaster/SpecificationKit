# SpecificationKit Project Overview

## Purpose
SpecificationKit is a powerful Swift library implementing the **Specification Pattern** with support for context providers, property wrappers, and composable business rules. It's designed for feature flags, conditional logic, banner display rules, and complex business requirements.

## Tech Stack
- **Language**: Swift 5.9+
- **Platforms**: iOS 13.0+, macOS 10.15+, tvOS 13.0+, watchOS 6.0+
- **Package Manager**: Swift Package Manager
- **Dependencies**:
  - Swift Syntax (for macro support)
  - swift-macro-testing (for macro testing)
  - swift-docc-plugin (for documentation generation)

## Current Version
- Version 2.0.0 (working toward v3.0.0)
- Swift 6 compatibility target
- Macro-based enhancements

## Key Features
- Specification Pattern implementation
- Decision-oriented specifications with typed results
- Context providers for runtime data
- Property wrappers (@Satisfies, @Decides, @Maybe, etc.)
- Reactive SwiftUI support (@ObservedSatisfies, @ObservedDecides, @ObservedMaybe)
- Advanced specifications (WeightedSpec, HistoricalSpec, ComparativeSpec, ThresholdSpec)
- Platform-specific context providers
- Performance profiling and tracing tools
- Comprehensive macro system