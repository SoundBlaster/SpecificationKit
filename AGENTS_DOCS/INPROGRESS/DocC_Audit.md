# DocC Documentation Audit

## Audit Date
2025-11-19

## Purpose
Categorize existing SpecificationKit DocC documentation to determine what should be migrated to SpecificationCore vs what should remain in SpecificationKit.

---

## Existing Files in SpecificationKit Documentation.docc

### Articles (14 files)

| File | Category | Action | Rationale |
|------|----------|--------|-----------|
| `SpecificationKit.md` | Mixed | Update | Landing page - needs Core reference section |
| `AppleTVContextProvider.md` | Kit | Keep | Platform-specific provider |
| `ComparativeSpec.md` | Kit | Keep | Advanced spec (Kit-only) |
| `CompositeContextProvider.md` | Kit | Keep | Platform-specific provider |
| `HistoricalSpec.md` | Kit | Keep | Advanced spec (Kit-only) |
| `MacOSSystemContextProvider.md` | Kit | Keep | Platform-specific provider |
| `MockSpecificationBuilder.md` | Kit | Keep | Utility (Kit-only) |
| `NetworkContextProvider.md` | Kit | Keep | Platform-specific provider |
| `PersistentContextProvider.md` | Kit | Keep | Platform-specific provider |
| `PlatformContextProviders.md` | Kit | Keep | Overview of platform providers |
| `ReactiveWrappers.md` | Kit | Keep | SwiftUI-specific wrappers |
| `SpecificationTracer.md` | Kit | Keep | Utility (Kit-only) |
| `ThresholdSpec.md` | Kit | Keep | Advanced spec (Kit-only) |
| `WeightedSpec.md` | Kit | Keep | Advanced spec (Kit-only) |

### Tutorials (3 files)

| File | Category | Action | Rationale |
|------|----------|--------|-----------|
| `Tutorials.tutorial` | Mixed | Update | Index - needs Core vs Kit distinction |
| `GettingStarted.tutorial` | Mixed | Extract Core concepts | Has Core fundamentals mixed with SwiftUI |
| `AdvancedPatterns.tutorial` | Kit | Keep | Advanced specs (WeightedSpec, HistoricalSpec, etc.) |

---

## Core Types Needing Documentation (26+ types)

### Core Protocols (6 types)
- [ ] `Specification` - Base protocol with composition
- [ ] `DecisionSpec` - Decision-based specifications
- [ ] `AsyncSpecification` - Async evaluation
- [ ] `ContextProviding` - Context provider protocol
- [ ] `AnySpecification` - Type erasure
- [ ] `AnyContextProvider` - Type-erased provider

### Context Infrastructure (3 types)
- [ ] `EvaluationContext` - Context structure
- [ ] `DefaultContextProvider` - Thread-safe provider
- [ ] `MockContextProvider` - Testing utilities

### Basic Specifications (7 types)
- [ ] `PredicateSpec` - Custom predicate specs
- [ ] `FirstMatchSpec` - Priority-based decisions
- [ ] `MaxCountSpec` - Counter-based limits
- [ ] `CooldownIntervalSpec` - Cooldown periods
- [ ] `TimeSinceEventSpec` - Time-based conditions
- [ ] `DateRangeSpec` - Date range validation
- [ ] `DateComparisonSpec` - Date comparisons

### Property Wrappers (4 types)
- [ ] `@Satisfies` - Boolean evaluation wrapper
- [ ] `@Decides` - Decision wrapper with fallback
- [ ] `@Maybe` - Optional decision wrapper
- [ ] `@AsyncSatisfies` - Async evaluation wrapper

### Macros (2 types)
- [ ] `@specs` - Composite specification generation
- [ ] `@AutoContext` - Context provider injection

### Definitions (2+ types)
- [ ] `AutoContextSpecification` - Base for auto-context specs
- [ ] `CompositeSpec` - Composite specification base

### Operators
- [ ] `SpecificationOperators` - DSL operators (.and, .or, .not, build)

---

## Tutorial Content Analysis

### GettingStarted.tutorial

Needs review to extract Core concepts:
- Section 1: "Create Your First Specification" → CORE CONTENT
  - Basic Specification protocol usage
  - No SwiftUI dependencies
- Section 2: "Compose Specifications" → CORE CONTENT
  - Logical operators (.and, .or, .not)
  - Composition patterns
- Section 3: "SwiftUI Integration" → KIT CONTENT (if exists)
  - @ObservedSatisfies usage
  - Platform-specific features

**Action**: Create new "Getting Started with SpecificationCore" tutorial with Core concepts only

### AdvancedPatterns.tutorial

Review sections:
- WeightedSpec, HistoricalSpec, ComparativeSpec, ThresholdSpec → All Kit-only
- No Core content identified

**Action**: Keep in SpecificationKit unchanged

---

## Migration Matrix

### Documents to Create in SpecificationCore (23+ files)

**Landing Page:**
1. `SpecificationCore.md` - NEW

**Core Protocol Articles:**
2. `Specification.md` - NEW
3. `DecisionSpec.md` - NEW
4. `AsyncSpecification.md` - NEW
5. `ContextProviding.md` - NEW
6. `AnySpecification.md` - NEW
7. `SpecificationOperators.md` - NEW

**Context Infrastructure Articles:**
8. `EvaluationContext.md` - NEW
9. `DefaultContextProvider.md` - NEW
10. `MockContextProvider.md` - NEW

**Basic Specification Articles:**
11. `PredicateSpec.md` - NEW
12. `FirstMatchSpec.md` - NEW
13. `MaxCountSpec.md` - NEW
14. `CooldownIntervalSpec.md` - NEW
15. `TimeSinceEventSpec.md` - NEW
16. `DateRangeSpec.md` - NEW
17. `DateComparisonSpec.md` - NEW

**Property Wrapper Articles:**
18. `Satisfies.md` - NEW
19. `Decides.md` - NEW
20. `Maybe.md` - NEW
21. `AsyncSatisfies.md` - NEW

**Macro Articles:**
22. `SpecsMacro.md` - NEW
23. `AutoContextMacro.md` - NEW

**Tutorials:**
24. `Tutorials/Tutorials.tutorial` - NEW (index)
25. `Tutorials/GettingStartedCore.tutorial` - NEW (Core fundamentals)
26. `Tutorials/ComposingSpecifications.tutorial` - NEW (Composition patterns)
27. `Tutorials/WorkingWithContext.tutorial` - NEW (Context providers)

### Documents to Modify in SpecificationKit (2 files)

1. `SpecificationKit.md` - UPDATE (add Core reference section)
2. `Tutorials/GettingStarted.tutorial` - UPDATE (remove Core-only content, focus on SwiftUI/Kit features)

### Documents to Keep Unchanged (12 files)

All platform providers, advanced specs, utilities, and AdvancedPatterns tutorial.

---

## Code Example Sources

Need to examine existing tutorial code for reusable examples:
- [ ] Review `GettingStarted.tutorial` code examples
- [ ] Identify Core-only examples (no SwiftUI, no platform dependencies)
- [ ] Extract reusable patterns for Core tutorials

---

## Assets and Resources

- [ ] Check if `Resources/` directory exists in SpecificationKit
- [ ] Identify images/diagrams that apply to Core concepts
- [ ] Plan new diagrams needed for Core tutorials

---

## Validation Checklist

Before proceeding to Phase 2:
- [x] All existing files categorized (Core vs Kit)
- [x] All Core types identified (26+ types)
- [x] Migration matrix complete (27 new files planned)
- [x] Tutorial content analyzed
- [ ] Code examples identified (need to review tutorial files)
- [ ] Asset requirements determined (need to check Resources/)

---

## Summary

**Findings:**
- SpecificationKit has 14 articles + 3 tutorials (17 files total)
- ALL 14 articles are Kit-specific (platform providers, advanced specs, utilities)
- NO existing Core-specific articles found
- Tutorials contain MIXED content (Core fundamentals + Kit features)
- Need to create 27 new files in SpecificationCore
- Need to update 2 files in SpecificationKit
- Keep 12 files unchanged in SpecificationKit

**Conclusion:**
- This is primarily a creation task (not migration)
- Most content will be NEW documentation for Core types
- Some tutorial content can be extracted and adapted from GettingStarted.tutorial
- Clear separation exists between Core and Kit features

**Next Action:**
Proceed to Phase 2: Create SpecificationCore DocC structure
