# Feature Planning: DocC Documentation Migration to SpecificationCore

## Task Metadata
- **Created**: 2025-11-19
- **Priority**: P1
- **Estimated Scope**: Medium (2-3 days)
- **Prerequisites**: SpecificationCore separation completed ✅
- **Target Layers**: Documentation, SpecificationCore package

## Feature Overview

Migrate DocC documentation from SpecificationKit to SpecificationCore for all classes, protocols, macros, and other components that were previously migrated. Remove documentation from SpecificationKit for migrated items. Migrate articles and tutorials if they exclusively cover Core functionality.

## Objective

Create comprehensive DocC documentation for SpecificationCore to match the quality and completeness of SpecificationKit's documentation, ensuring developers have proper API references and learning materials for the core package.

## User Impact

- **Developers using SpecificationCore**: Will have complete API documentation, tutorials, and articles for the core package
- **Documentation consumers**: Will find relevant documentation in the correct package (Core vs Kit)
- **New users**: Will have clear learning paths specific to SpecificationCore basics
- **Maintainers**: Will have properly organized documentation reducing confusion

## Technical Scope

### Components to Document in SpecificationCore

Based on the completed SpecificationCore separation (from Summary_of_Work.md):

**Core Protocols** (Phase 1.2 - 6 files):
- `Specification` protocol with composition operators (.and(), .or(), .not())
- `DecisionSpec` protocol with adapters and type erasure
- `AsyncSpecification` protocol with bridging
- `ContextProviding` protocol with optional Combine support
- `AnySpecification` type erasure with helpers
- `AnyContextProvider` type erasure

**Context Infrastructure** (Phase 1.3 - 3 files):
- `EvaluationContext` immutable context struct
- `DefaultContextProvider` thread-safe singleton
- `MockContextProvider` for testing

**Basic Specifications** (Phase 1.4 - 7 files):
- `PredicateSpec`
- `FirstMatchSpec`
- `MaxCountSpec`
- `CooldownIntervalSpec`
- `TimeSinceEventSpec`
- `DateRangeSpec`
- `DateComparisonSpec`

**Property Wrappers** (Phase 1.5 - 4 files):
- `@Satisfies` (core version without SwiftUI)
- `@Decides`
- `@Maybe`
- `@AsyncSatisfies`

**Macros** (Phase 1.6):
- `@specs` macro
- `@AutoContext` macro

**Definitions** (Phase 1.7 - 2 files):
- `AutoContextSpecification`
- `CompositeSpec`

### Components to Keep in SpecificationKit

**Platform-Specific Providers**:
- AppleTVContextProvider
- MacOSSystemContextProvider
- NetworkContextProvider
- PersistentContextProvider
- CompositeContextProvider
- PlatformContextProviders

**Advanced Specs**:
- ComparativeSpec
- HistoricalSpec
- ThresholdSpec
- WeightedSpec

**SwiftUI Components**:
- ReactiveWrappers
- @ObservedSatisfies

**Utilities**:
- SpecificationTracer
- MockSpecificationBuilder

## Stages/Milestones

### Phase 1: Documentation Audit (Day 1, Morning)
1. Inventory all existing DocC documentation in SpecificationKit
2. Categorize documentation by Core vs Kit content
3. Identify tutorials and articles that are Core-only
4. Document what needs to be created, migrated, or updated

### Phase 2: SpecificationCore DocC Setup (Day 1, Afternoon)
1. Create `Sources/SpecificationCore/Documentation.docc/` structure
2. Create landing page `SpecificationCore.md`
3. Configure DocC catalog with proper metadata
4. Set up Resources/ directory for images/assets

### Phase 3: Core Documentation Migration (Day 2, Full Day)
1. Migrate/create documentation for Core protocols
2. Migrate/create documentation for Context infrastructure
3. Migrate/create documentation for Basic specifications
4. Migrate/create documentation for Property wrappers
5. Migrate/create documentation for Macros
6. Add code examples to all articles

### Phase 4: Tutorial Creation (Day 3, Morning)
1. Create "Getting Started with SpecificationCore" tutorial
2. Create "Composing Specifications" tutorial (Core-only)
3. Create "Working with Context Providers" tutorial
4. Ensure all tutorials build and compile

### Phase 5: Cleanup and Validation (Day 3, Afternoon)
1. Remove Core-related docs from SpecificationKit
2. Update SpecificationKit.md to reference SpecificationCore
3. Build DocC for both packages and verify
4. Fix any broken links or references
5. Update README files

## Implementation Plan

### Phase 1: Documentation Audit
- [ ] Read all .md files in SpecificationKit Documentation.docc
- [ ] Read all .tutorial files
- [ ] Create audit spreadsheet: File → Category (Core/Kit/Shared) → Migration Action
- [ ] Identify code examples that reference Core types
- [ ] List all Core protocols/types without documentation

### Phase 2: SpecificationCore DocC Setup
- [ ] Create directory: `SpecificationCore/Sources/SpecificationCore/Documentation.docc/`
- [ ] Create `SpecificationCore.md` landing page
- [ ] Create `Resources/` subdirectory for assets
- [ ] Add DocC catalog to Package.swift if needed
- [ ] Test: `swift package generate-documentation --target SpecificationCore`

### Phase 3: Core Documentation Migration
- [ ] **Core Protocols Articles** (6 articles):
  - `Specification.md` - Base protocol and composition
  - `DecisionSpec.md` - Decision-based specifications
  - `AsyncSpecification.md` - Async evaluation patterns
  - `ContextProviding.md` - Context provider protocol
  - `AnySpecification.md` - Type erasure and helpers
  - `SpecificationOperators.md` - DSL operators

- [ ] **Context Infrastructure Articles** (3 articles):
  - `EvaluationContext.md` - Context structure and usage
  - `DefaultContextProvider.md` - Thread-safe provider
  - `MockContextProvider.md` - Testing utilities

- [ ] **Basic Specifications Articles** (7 articles):
  - `PredicateSpec.md` - Custom predicate specs
  - `FirstMatchSpec.md` - Priority-based decisions
  - `MaxCountSpec.md` - Counter-based limits
  - `CooldownIntervalSpec.md` - Cooldown periods
  - `TimeSinceEventSpec.md` - Time-based conditions
  - `DateRangeSpec.md` - Date range validation
  - `DateComparisonSpec.md` - Date comparisons

- [ ] **Property Wrappers Articles** (4 articles):
  - `Satisfies.md` - Boolean evaluation wrapper
  - `Decides.md` - Decision wrapper with fallback
  - `Maybe.md` - Optional decision wrapper
  - `AsyncSatisfies.md` - Async evaluation wrapper

- [ ] **Macros Articles** (2 articles):
  - `SpecsMacro.md` - @specs composite generation
  - `AutoContextMacro.md` - @AutoContext injection

### Phase 4: Tutorial Creation
- [ ] **Tutorial 1**: `GettingStartedCore.tutorial`
  - Sections: Import, Create First Spec, Test Spec, Compose Specs
  - Focus: Specification protocol, basic composition, testing
  - No SwiftUI, no platform-specific features

- [ ] **Tutorial 2**: `ComposingSpecifications.tutorial`
  - Sections: Logical operators, Complex rules, Reusable specs
  - Focus: .and()/.or()/.not(), @specs macro, AnySpecification

- [ ] **Tutorial 3**: `WorkingWithContext.tutorial`
  - Sections: EvaluationContext, DefaultContextProvider, Counters/Events/Flags
  - Focus: Context-aware specs, testing with MockContextProvider

### Phase 5: Cleanup and Validation
- [ ] Remove Core documentation from SpecificationKit:
  - Delete articles that were migrated
  - Keep only Kit-specific documentation
- [ ] Update SpecificationKit.md:
  - Add "Built on SpecificationCore" section
  - Link to SpecificationCore documentation
  - Clarify Kit vs Core distinction
- [ ] Update GettingStarted.tutorial in Kit:
  - Remove Core-only content
  - Focus on SwiftUI integration and advanced specs
- [ ] Build documentation for both packages:
  - `cd SpecificationCore && swift package generate-documentation`
  - `cd SpecificationKit && swift package generate-documentation`
- [ ] Verify all links resolve correctly
- [ ] Check for broken references

## Files to Create

**SpecificationCore Documentation**:
- `Sources/SpecificationCore/Documentation.docc/SpecificationCore.md` (landing page)
- `Sources/SpecificationCore/Documentation.docc/Specification.md`
- `Sources/SpecificationCore/Documentation.docc/DecisionSpec.md`
- `Sources/SpecificationCore/Documentation.docc/AsyncSpecification.md`
- `Sources/SpecificationCore/Documentation.docc/ContextProviding.md`
- `Sources/SpecificationCore/Documentation.docc/AnySpecification.md`
- `Sources/SpecificationCore/Documentation.docc/SpecificationOperators.md`
- `Sources/SpecificationCore/Documentation.docc/EvaluationContext.md`
- `Sources/SpecificationCore/Documentation.docc/DefaultContextProvider.md`
- `Sources/SpecificationCore/Documentation.docc/MockContextProvider.md`
- `Sources/SpecificationCore/Documentation.docc/PredicateSpec.md`
- `Sources/SpecificationCore/Documentation.docc/FirstMatchSpec.md`
- `Sources/SpecificationCore/Documentation.docc/MaxCountSpec.md`
- `Sources/SpecificationCore/Documentation.docc/CooldownIntervalSpec.md`
- `Sources/SpecificationCore/Documentation.docc/TimeSinceEventSpec.md`
- `Sources/SpecificationCore/Documentation.docc/DateRangeSpec.md`
- `Sources/SpecificationCore/Documentation.docc/DateComparisonSpec.md`
- `Sources/SpecificationCore/Documentation.docc/Satisfies.md`
- `Sources/SpecificationCore/Documentation.docc/Decides.md`
- `Sources/SpecificationCore/Documentation.docc/Maybe.md`
- `Sources/SpecificationCore/Documentation.docc/AsyncSatisfies.md`
- `Sources/SpecificationCore/Documentation.docc/SpecsMacro.md`
- `Sources/SpecificationCore/Documentation.docc/AutoContextMacro.md`
- `Sources/SpecificationCore/Documentation.docc/Tutorials/GettingStartedCore.tutorial`
- `Sources/SpecificationCore/Documentation.docc/Tutorials/ComposingSpecifications.tutorial`
- `Sources/SpecificationCore/Documentation.docc/Tutorials/WorkingWithContext.tutorial`
- `Sources/SpecificationCore/Documentation.docc/Tutorials/Tutorials.tutorial` (index)
- `Sources/SpecificationCore/Documentation.docc/Resources/` (directory for assets)

## Files to Modify

**SpecificationKit Documentation**:
- `Sources/SpecificationKit/Documentation.docc/SpecificationKit.md` - Add SpecificationCore reference
- `Sources/SpecificationKit/Documentation.docc/Tutorials/GettingStarted.tutorial` - Remove Core-only content
- `Sources/SpecificationKit/Documentation.docc/Tutorials/AdvancedPatterns.tutorial` - Update to clarify Kit-specific

## Files to Delete

**From SpecificationKit** (if any Core-only documentation exists - TBD after audit):
- Any articles that exclusively document Core protocols
- Any code examples that only use Core types

## Test Strategy

### Documentation Build Tests
- Build SpecificationCore documentation: `swift package generate-documentation --target SpecificationCore`
- Build SpecificationKit documentation: `swift package generate-documentation --target SpecificationKit`
- Verify no warnings or errors in DocC output
- Check all links resolve correctly

### Content Validation Tests
- All Core protocols have documentation articles
- All Property wrappers have usage examples
- All Macros have expansion examples
- All tutorials compile successfully
- Code examples in documentation compile and run

### Cross-Package Reference Tests
- SpecificationKit.md correctly links to SpecificationCore docs
- No broken cross-package links
- Clear distinction between Core and Kit features

### Completeness Tests
- All public types in SpecificationCore have doc comments
- All public methods have parameter documentation
- All tutorials have intro and sections
- Landing pages have quick start examples

## Success Criteria

- [ ] SpecificationCore has complete DocC catalog with landing page
- [ ] All 26+ Core public types have dedicated documentation articles or sections
- [ ] At least 3 Core-focused tutorials exist and build successfully
- [ ] `swift package generate-documentation` succeeds for SpecificationCore
- [ ] `swift package generate-documentation` succeeds for SpecificationKit
- [ ] No broken links between packages
- [ ] SpecificationKit.md references SpecificationCore appropriately
- [ ] Core-related documentation removed from SpecificationKit
- [ ] All code examples compile and run
- [ ] README files updated to reflect new documentation structure

## Open Questions

1. **Asset Migration**: Do existing images/diagrams in SpecificationKit apply to Core concepts?
   - Need to audit Resources/ folder
   - May need to create new diagrams for Core tutorials

2. **API Documentation**: Should we add extensive inline doc comments to Core types?
   - Yes - comprehensive /// comments for all public APIs
   - Generate symbol documentation automatically

3. **Tutorial Complexity**: How deep should Core tutorials go?
   - Keep focused on fundamentals (protocols, composition, context)
   - Advanced patterns (macros, async) can be intermediate level
   - Link to Kit tutorials for SwiftUI/platform features

4. **Versioning**: What version should SpecificationCore documentation target?
   - Match current SpecificationCore version (0.1.0)
   - Note in documentation what version features were added

5. **Cross-Linking**: How to link between Core and Kit documentation?
   - Use proper DocC symbol links: ``SpecificationCore/Specification``
   - Add "See Also" sections with cross-package links

## Related Work

- **Completed**: SpecificationCore separation (Task: SpecificationCore_Separation)
- **Reference**: Summary_of_Work.md documents all migrated components
- **Architecture**: SpecificationCore_PRD/PRD.md defines Core scope
- **Similar Patterns**: Standard library documentation structure (Foundation, Combine)

## Dependencies

- [x] SpecificationCore package exists with all Core types
- [x] SpecificationCore builds successfully
- [x] SpecificationCore has test coverage
- [ ] Swift-DocC-Plugin available (should be in Package.swift)
- [ ] Access to both package repositories

## Assumptions

- DocC supports cross-package linking (verify with Swift 5.10+)
- Existing SpecificationKit documentation is accurate and can be adapted
- Code examples in current documentation compile
- Tutorial format from SpecificationKit is appropriate for Core

## Risk Assessment

**Low Risk**:
- Documentation is additive, doesn't affect code
- Can iterate on content quality after initial migration
- Easy to roll back by keeping copies

**Medium Risk**:
- Cross-package linking may have complexity
- Tutorial code examples must compile correctly
- Asset organization needs careful planning

**Mitigation**:
- Test documentation builds frequently
- Keep original SpecificationKit docs until migration validated
- Create simple tutorials first, add complexity incrementally

## Notes

- This is a documentation-only task - no code changes to SpecificationCore or SpecificationKit
- Focus on clarity and completeness over perfection
- Documentation can be improved iteratively after initial release
- Consider creating a migration guide for users moving from Kit to Core
