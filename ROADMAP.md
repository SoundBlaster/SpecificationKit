# SpecificationKit Roadmap

This document outlines the planned development path for SpecificationKit.

## Current Version: 3.0.0

**Status:** ✅ Released (2025-11-16)

All P1 features for v3.0.0 are complete. The library is production-ready with comprehensive documentation, extensive test coverage, and full Swift 6 compatibility.

---

## 🚀 Upcoming Features

### Short-term (Next 6 months)

#### @AutoContext Enhancements
**Status:** 🔄 Infrastructure Complete, Awaiting Swift Toolchain Evolution

The macro infrastructure is fully implemented and ready. These features will be activated when Swift's macro capabilities evolve:

- **`@AutoContext(environment)` - SwiftUI Environment Integration**
  - **Current Status:** Parsing infrastructure ready, emits informative warning
  - **Implementation:** Complete argument parsing, diagnostic system in place
  - **Blocker:** Requires enhanced Swift macro capabilities for SwiftUI Environment access
  - **Expected:** When Swift Evolution proposals for macro-Environment integration are adopted
  - **Migration:** Existing code using this syntax will automatically work when implemented

- **`@AutoContext(infer)` - Automatic Provider Inference**
  - **Current Status:** Parsing infrastructure ready, emits informative warning
  - **Implementation:** Complete argument parsing, diagnostic system in place
  - **Blocker:** Requires type inference and dependency analysis capabilities in macros
  - **Expected:** When Swift macros gain advanced type analysis features
  - **Use Case:** Automatically infer provider type from specification's generic context

- **`@AutoContext(CustomProvider.self)` - Custom Provider Types**
  - **Current Status:** Parsing infrastructure ready, emits informative warning
  - **Implementation:** Complete argument parsing, diagnostic system in place
  - **Blocker:** Requires generic type support in macro expansion
  - **Expected:** When Swift macros support generic provider injection
  - **Use Case:** Override default provider with custom implementations

**Technical Details:**
- File: `Sources/SpecificationKitMacros/AutoContextMacro.swift`
- Test Coverage: 5 comprehensive test cases in `AutoContextMacroComprehensiveTests.swift`
- Documentation: `AGENTS_DOCS/markdown/05_AutoContext.md`

#### Performance Optimizations

- **Benchmark Baseline Capture**
  - **Status:** ⏳ Awaiting macOS Hardware Access
  - **Blocker:** Requires macOS runner for CoreData-dependent test cases
  - **Tracked In:** `AGENTS_DOCS/INPROGRESS/blocked.md`
  - **Next Steps:** Schedule macOS CI workflow run for release benchmarks

- **Performance Benchmarking Suite Expansion**
  - Expand existing `SpecificationKitBenchmarks` target
  - Add baseline validators for regression detection
  - Memory usage profiling tools

### Mid-term (6-12 months)

#### Advanced Macro Features

- **Inline Attribute Syntax Transformations**
  - Transform complex attribute chains into optimized code
  - Compile-time validation improvements
  - Enhanced diagnostic messages with fix-it suggestions

- **Macro Composition Improvements**
  - Better interaction between `@AutoContext` and `@specs(...)`
  - Optimized macro expansion for nested specifications
  - Reduced compilation overhead

#### Platform Enhancements

- **Extended Platform-Specific Context Providers**
  - watchOS complications integration
  - tvOS focus engine integration
  - visionOS spatial context providers (when platform matures)
  - Additional iOS-specific providers (HealthKit, HomeKit, etc.)

#### Developer Experience

- **Enhanced Documentation**
  - README examples showcasing parameterized spec patterns
  - Advanced tutorial content for complex use cases
  - Video tutorials and example projects
  - Migration guides from common patterns

### Long-term (12+ months)

#### Architecture Improvements (v4.0.0)

- **SpecificationCore: Platform-Independent Foundation**
  - **Status:** 🔨 Planning & PRD Complete (2025-11-16)
  - **Timeline:** 6 weeks implementation planned
  - **Primary Goal:** Extract platform-independent core logic into separate Swift Package
  - **Key Objectives:**
    - Create minimal, platform-independent Swift Package (`SpecificationCore`)
    - Zero dependencies on platform-specific frameworks (SwiftUI, UIKit, AppKit, etc.)
    - Support all Swift platforms (iOS, macOS, tvOS, watchOS, Linux, Windows)
    - Maintain 100% backward compatibility for SpecificationKit
    - Reduce core package size to < 5,000 LOC (vs ~14,415 in monolithic)
  - **What Moves to SpecificationCore:**
    - Core protocols: `Specification`, `DecisionSpec`, `AsyncSpecification`
    - Property wrappers: `@Satisfies`, `@Decides`, `@Maybe` (non-SwiftUI)
    - Macros: `@AutoContext`, `@specs`
    - Context providers: `DefaultContextProvider`, `MockContextProvider`
    - Base specifications: `MaxCountSpec`, `TimeSinceEventSpec`, `PredicateSpec`
  - **What Stays in SpecificationKit:**
    - SwiftUI property wrappers: `@ObservedSatisfies`, `@ObservedDecides`
    - Platform-specific providers (iOS, macOS, watchOS, tvOS)
    - Advanced domain specs: `FeatureFlagSpec`, `SubscriptionStatusSpec`
    - Profiling tools: `SpecificationTracer`, `PerformanceProfiler`
    - Network/storage integration: `NetworkContextProvider`, `PersistentContextProvider`
  - **Benefits:**
    - **Compile Time:** 20%+ improvement for core-only users
    - **Binary Size:** Reduced footprint for minimal feature sets
    - **Platform Support:** True cross-platform capability including Linux/Windows
    - **Testing:** Better isolation and faster test execution
    - **Flexibility:** Use SpecificationCore standalone or with full SpecificationKit
  - **Implementation Phases:**
    - Phase 1 (Weeks 1-2): SpecificationCore package creation
    - Phase 2 (Weeks 3-4): SpecificationKit refactoring to depend on Core
    - Phase 3 (Week 5): Validation, documentation, migration guides
    - Phase 4 (Week 6+): Release and monitoring
  - **Success Metrics:**
    - SpecificationCore compiles on all Swift platforms
    - Zero platform-specific imports in core module
    - 90%+ test coverage maintained
    - All existing SpecificationKit tests pass
    - Build time improvement ≥20% for core-only projects
  - **Documentation:**
    - Full PRD: `AGENTS_DOCS/SpecificationCore_PRD/PRD.md`
    - Workplan: `AGENTS_DOCS/SpecificationCore_PRD/Workplan.md`
    - TODO List: `AGENTS_DOCS/SpecificationCore_PRD/TODO.md`
  - **Reference:** `AGENTS_DOCS/SpecificationCore_PRD/` (complete planning docs)

#### Experimental Features

- **Result Builder DSL for Specifications**
  - Declarative syntax for complex specification composition
  - Type-safe specification builders
  - Integration with SwiftUI-style declarative patterns

- **Visual Specification Debugger**
  - Real-time specification evaluation visualization
  - Context state inspection tools
  - Decision tree visualization for complex specs

- **Code Generation Tools**
  - Specification scaffolding generators
  - Test case generators from specifications
  - Documentation generators

#### Community & Ecosystem

- **Community-Contributed Specifications**
  - Curated repository of common specification patterns
  - Industry-specific specification libraries (e-commerce, fintech, etc.)
  - Best practices and design patterns documentation

---

## 📝 Post-3.0.0 Enhancements

These are refinements and nice-to-haves for future minor releases:

### Documentation & Examples
- [ ] README examples showcasing parameterized spec patterns
- [ ] Advanced tutorial content for SwiftUI integration
- [ ] Performance comparison benchmarks vs manual implementations
- [ ] Migration guide from Objective-C patterns
- [ ] Common pitfalls and troubleshooting guide

### Testing & Quality
- [ ] Additional integration tests for complex scenarios
- [ ] Stress testing under high-concurrency scenarios
- [ ] Memory leak detection in CI pipeline
- [ ] Performance regression tests

### Developer Tooling
- [ ] Xcode templates for common specification patterns
- [ ] Swift Package Plugin for specification validation
- [ ] Lint rules for specification best practices

---

## 🚫 Out of Scope

Features we've decided **not** to pursue:

- ❌ **Swift versions < 5.9 support**
  - Rationale: Macro system requires Swift 5.9+
  - Alternative: Use SpecificationKit 2.x for older Swift versions

- ❌ **Objective-C bridging**
  - Rationale: Swift-only library leveraging modern Swift features
  - Alternative: Wrapper layer can be created in consuming projects if needed

- ❌ **Runtime code generation**
  - Rationale: Compile-time safety and performance are core principles
  - Alternative: All specifications are compile-time validated

- ❌ **Dynamic specification loading from external sources**
  - Rationale: Security and type-safety concerns
  - Alternative: Code generation tools for external specification formats

---

## 🎯 Version Planning

### v3.1.0 (Planned: Q2 2025)
- Complete benchmark baseline capture
- Enhanced platform-specific providers
- Additional documentation and examples
- Performance optimizations based on benchmarks

### v3.2.0 (Planned: Q3 2025)
- Depends on Swift Evolution proposals for macros
- Potential activation of @AutoContext enhancements if toolchain supports
- Advanced macro composition features

### v4.0.0 (Planned: 2026)
- **SpecificationCore Package** - Platform-independent foundation (6-week implementation)
  - Extract core protocols, property wrappers, and macros to separate package
  - Zero platform-specific dependencies (supports Linux, Windows, all Apple platforms)
  - 20%+ compile time improvement for core-only usage
  - < 5,000 LOC focused package (down from ~14,415)
  - Full PRD and workplan in `AGENTS_DOCS/SpecificationCore_PRD/`
- **SpecificationKit Refactoring** - Depends on SpecificationCore
  - Becomes platform-specific extension package
  - SwiftUI integrations, platform providers, profiling tools
  - 100% backward compatibility maintained
  - Comprehensive migration guide
- Result Builder DSL (if mature)
- Breaking API changes (if needed for significant improvements)
- Minimum Swift version bump to latest stable

---

## 🤝 Contributing to Roadmap

Have ideas for SpecificationKit's future? We'd love to hear from you!

### How to Propose Features

1. **Check Existing Issues & Discussions**
   - Review [open issues](https://github.com/SoundBlaster/SpecificationKit/issues)
   - Search [discussions](https://github.com/SoundBlaster/SpecificationKit/discussions)

2. **Start a Discussion**
   - Open a [discussion](https://github.com/SoundBlaster/SpecificationKit/discussions/new) to gauge interest
   - Describe the use case and benefits
   - Gather feedback from the community

3. **Create Detailed Proposal**
   - Once there's community interest, create a detailed [issue](https://github.com/SoundBlaster/SpecificationKit/issues/new)
   - Include:
     - Clear use cases
     - Proposed API design
     - Backward compatibility considerations
     - Implementation complexity estimate

4. **Submit Implementation**
   - For approved features, submit a PR with:
     - Full implementation with tests (>90% coverage)
     - Documentation updates
     - Migration guide (if breaking changes)
     - Performance benchmarks (if applicable)

### Community Priorities

We prioritize features based on:
- **Community demand** - Features requested by multiple users
- **Alignment with vision** - Fits SpecificationKit's design principles
- **Implementation feasibility** - Can be implemented with current Swift capabilities
- **Maintenance burden** - Sustainable long-term maintenance

---

## 📊 Progress Tracking

### Internal Documentation

For detailed implementation progress, see:
- **Overall Progress:** `AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md`
- **Active Work:** `AGENTS_DOCS/INPROGRESS/`
- **Completed Tasks:** `AGENTS_DOCS/TASK_ARCHIVE/`
- **Blocked Items:** `AGENTS_DOCS/INPROGRESS/blocked.md`

### Public Tracking

- **Milestones:** [GitHub Milestones](https://github.com/SoundBlaster/SpecificationKit/milestones)
- **Project Board:** [GitHub Projects](https://github.com/SoundBlaster/SpecificationKit/projects)
- **Release Notes:** [CHANGELOG.md](CHANGELOG.md)

---

## 🔔 Stay Updated

- **Watch this repository** to get notifications about roadmap updates
- **Follow releases** to stay informed about new versions
- **Join discussions** to participate in feature planning

---

## 📅 Roadmap Updates

This roadmap is a living document and will be updated regularly.

- **Last Updated:** 2025-11-16
- **Next Review:** 2026-02-16 (Quarterly review cycle)
- **Maintained By:** SpecificationKit Core Team

---

## 📜 Roadmap History

### Major Milestones Achieved

- **v3.0.0 (2025-11-16)** - Complete rewrite with Swift 6 support, macro system, comprehensive property wrappers
- **v2.0.0 (2024)** - Introduction of property wrappers and context providers
- **v1.0.0 (2023)** - Initial release with core Specification pattern implementation

---

**Questions about the roadmap?** Open a [discussion](https://github.com/SoundBlaster/SpecificationKit/discussions)!
