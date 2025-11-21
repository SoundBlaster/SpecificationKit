# DocC Documentation Migration PRD

## Document Metadata
- **PRD ID**: DocC_Migration
- **Created**: 2025-11-19
- **Status**: Draft
- **Related Planning**: `AGENTS_DOCS/INPROGRESS/DocC_Migration_Planning.md`
- **Priority**: P1

## Problem Statement

SpecificationCore was successfully separated from SpecificationKit with all core functionality migrated (protocols, specs, wrappers, macros). However, the DocC documentation remains in SpecificationKit, causing:

1. **Discoverability Issues**: Developers using only SpecificationCore cannot find documentation for Core types
2. **Maintenance Confusion**: Documentation for Core types exists in the wrong package
3. **Learning Path Problems**: Tutorials mix Core and Kit concepts, making it unclear what requires which package
4. **API Reference Gaps**: SpecificationCore has no generated API documentation or landing page

## Goals

### Primary Goals
1. **Complete Documentation Coverage**: All 26+ public Core types have comprehensive documentation
2. **Proper Organization**: Core documentation lives in SpecificationCore package
3. **Clear Learning Paths**: Tutorials exist specifically for Core fundamentals
4. **Accurate References**: Kit documentation correctly references Core without duplication

### Non-Goals
1. **Rewriting existing good documentation**: Adapt and migrate, don't start from scratch
2. **Platform-specific documentation**: That stays in SpecificationKit
3. **SwiftUI-specific tutorials**: Those belong in SpecificationKit
4. **Performance optimization docs**: Can be added later as enhancement

## Requirements

### Functional Requirements

**FR-1: SpecificationCore DocC Catalog**
- Must: Create `Sources/SpecificationCore/Documentation.docc/` with proper structure
- Must: Include landing page (`SpecificationCore.md`) with quick start examples
- Must: Build successfully with `swift package generate-documentation`

**FR-2: Core Type Documentation**
- Must: All core protocols have dedicated articles (Specification, DecisionSpec, AsyncSpecification, ContextProviding)
- Must: All basic specs have usage examples (MaxCountSpec, PredicateSpec, FirstMatchSpec, etc.)
- Must: All property wrappers have usage examples (@Satisfies, @Decides, @Maybe, @AsyncSatisfies)
- Must: All macros have expansion examples (@specs, @AutoContext)
- Should: Include inline doc comments (///) for all public APIs

**FR-3: Tutorial Content**
- Must: Minimum 3 tutorials focused on Core concepts
  1. Getting Started with SpecificationCore
  2. Composing Specifications
  3. Working with Context Providers
- Must: All tutorials build and compile successfully
- Must: Tutorials focus exclusively on Core features (no SwiftUI, no platform providers)

**FR-4: Migration and Cleanup**
- Must: Remove Core-related documentation from SpecificationKit
- Must: Update SpecificationKit.md to reference SpecificationCore
- Must: Update SpecificationKit tutorials to remove Core-only content
- Must: All cross-package links work correctly

### Non-Functional Requirements

**NFR-1: Documentation Quality**
- Comprehensive: Cover all public APIs
- Clear: Use simple language and concrete examples
- Consistent: Follow same style/format throughout
- Accurate: All code examples compile and run

**NFR-2: Build Performance**
- Documentation build time < 30 seconds for SpecificationCore
- No warnings or errors in DocC output

**NFR-3: Maintainability**
- Documentation structure mirrors code structure
- Clear separation between Core and Kit docs
- Easy to update when APIs change

**NFR-4: Accessibility**
- Works with DocC rendering in Xcode
- Works with static site generation for web hosting
- Proper heading hierarchy for screen readers

## Success Metrics

### Quantitative Metrics
- **Coverage**: 100% of public Core types have documentation
- **Tutorial Count**: ≥ 3 Core-focused tutorials
- **Build Success**: 100% clean builds (no warnings/errors)
- **Link Integrity**: 0 broken cross-package links
- **Example Coverage**: ≥ 80% of articles have runnable code examples

### Qualitative Metrics
- Documentation is discoverable from package landing page
- Learning progression is clear and logical
- Examples are practical and realistic
- Distinction between Core and Kit is obvious

## API Design

### DocC Catalog Structure
```
SpecificationCore/
└── Sources/SpecificationCore/Documentation.docc/
    ├── SpecificationCore.md (landing page)
    ├── Specification.md
    ├── DecisionSpec.md
    ├── AsyncSpecification.md
    ├── ContextProviding.md
    ├── AnySpecification.md
    ├── SpecificationOperators.md
    ├── EvaluationContext.md
    ├── DefaultContextProvider.md
    ├── MockContextProvider.md
    ├── PredicateSpec.md
    ├── FirstMatchSpec.md
    ├── MaxCountSpec.md
    ├── CooldownIntervalSpec.md
    ├── TimeSinceEventSpec.md
    ├── DateRangeSpec.md
    ├── DateComparisonSpec.md
    ├── Satisfies.md
    ├── Decides.md
    ├── Maybe.md
    ├── AsyncSatisfies.md
    ├── SpecsMacro.md
    ├── AutoContextMacro.md
    ├── Tutorials/
    │   ├── Tutorials.tutorial (index)
    │   ├── GettingStartedCore.tutorial
    │   ├── ComposingSpecifications.tutorial
    │   └── WorkingWithContext.tutorial
    └── Resources/ (images, assets)
```

### Landing Page Structure
```markdown
# ``SpecificationCore``

Platform-independent core for building specification-based business logic in Swift.

## Overview
[High-level description of Core vs Kit]

## Quick Start
[Basic example with Specification protocol]

## Topics

### Core Protocols
- ``Specification``
- ``DecisionSpec``
- ``AsyncSpecification``
- ``ContextProviding``

### Basic Specifications
- ``PredicateSpec``
- ``MaxCountSpec``
- [etc...]

### Property Wrappers
- ``@Satisfies``
- ``@Decides``
- [etc...]

### Macros
- ``@specs``
- ``@AutoContext``
```

## User Stories

### US-1: Core-Only Developer
**As a** developer building a backend service with SpecificationCore,
**I want** complete documentation for all Core APIs,
**So that** I can implement business logic without needing SpecificationKit or platform knowledge.

**Acceptance Criteria**:
- Can find SpecificationCore docs from package README
- Can navigate from landing page to any Core type
- Can follow tutorials without SwiftUI or platform dependencies
- All examples run in CLI/server context

### US-2: Migrating Developer
**As a** developer currently using SpecificationKit,
**I want** clear documentation about what's in Core vs Kit,
**So that** I can decide if I only need Core and reduce dependencies.

**Acceptance Criteria**:
- SpecificationKit docs clearly state "Built on SpecificationCore"
- Landing pages explain Core (platform-independent) vs Kit (platform-specific + SwiftUI)
- Migration path is documented

### US-3: API Explorer
**As a** developer exploring the Specification Pattern,
**I want** comprehensive API reference with examples,
**So that** I can understand how to use each type without reading source code.

**Acceptance Criteria**:
- All public types have doc articles
- All articles have code examples
- Examples are copy-pasteable and compile
- Related types are cross-linked

### US-4: Tutorial Learner
**As a** new user learning SpecificationCore,
**I want** step-by-step tutorials,
**So that** I can build working specifications incrementally.

**Acceptance Criteria**:
- Tutorial 1 covers basics (protocol, testing)
- Tutorial 2 covers composition (.and, .or, .not)
- Tutorial 3 covers context (providers, counters, events)
- Each tutorial builds on previous concepts

## Technical Constraints

### DocC Version
- Swift 5.10+ DocC support required
- Must work with Xcode 15+ built-in DocC

### Cross-Package Linking
- DocC symbol links: ``` ``SpecificationCore/TypeName`` ```
- May need package name qualification
- Verify cross-package links work in generated docs

### Asset Management
- Images must be in Resources/ directory
- Asset naming: lowercase-with-hyphens.png
- Supported formats: PNG, SVG

### Tutorial Limitations
- No interactive playgrounds (DocC limitation)
- Code snippets must be in separate files or inline
- Tutorial steps are linear (no branching)

## Open Questions

1. **Q: Should Core docs include migration guide from Kit?**
   - A: Yes, create `MigrationGuide.md` article

2. **Q: How to handle types that exist in both Core and Kit (e.g., @Satisfies)?**
   - A: Document Core version in Core, note Kit enhancements in Kit docs

3. **Q: Should we include architecture diagrams?**
   - A: Yes, create simple diagrams for:
     - Specification composition
     - Context provider flow
     - Macro expansion

4. **Q: What code style for examples?**
   - A: Follow Swift API Design Guidelines
   - Use realistic but simple examples
   - Prefer structs over classes where appropriate

## Dependencies

- SpecificationCore package (completed)
- Swift-DocC-Plugin (should be in Package.swift)
- Xcode 15+ or Swift 5.10+ CLI

## Timeline

- **Phase 1**: Documentation audit (4 hours)
- **Phase 2**: DocC setup (2 hours)
- **Phase 3**: Article migration/creation (12 hours)
- **Phase 4**: Tutorial creation (8 hours)
- **Phase 5**: Cleanup and validation (4 hours)

**Total Estimated Effort**: 2-3 days

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Cross-package linking doesn't work | Low | Medium | Test early, use alternative link syntax |
| Tutorial code doesn't compile | Low | High | Test all examples before committing |
| Asset migration complexity | Low | Low | Can use text-only initially |
| Time overrun on article writing | Medium | Low | Focus on critical types first, iterate |

## Approval

- **Stakeholder**: SpecificationKit maintainers
- **Status**: Ready for implementation
- **Related Planning Document**: `AGENTS_DOCS/INPROGRESS/DocC_Migration_Planning.md`
