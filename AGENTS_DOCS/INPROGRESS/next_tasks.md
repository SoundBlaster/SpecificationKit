# Next Tasks

## 🎯 Remaining P1 Items for v3.0.0

### 1. AutoContext Future Hooks
- Leave hooks for future flags (environment/infer) per AutoContext design
- Ensure the `@AutoContext` macro infrastructure can support future enhancement flags
- Document placeholder/reserved parameters for future Swift macro capabilities
- **Status**: Ready to implement
- **Reference**: AGENTS_DOCS/markdown/3.0.0/00_3.0.0_TODO_SpecificationKit.md

### 2. Swift Package Index Preparation
- Prepare package metadata for Swift Package Index
- Confirm license information is correct and complete
- Create semantic version tag `3.0.0`
- Verify README and documentation are ready for publication
- **Status**: Ready to implement
- **Reference**: AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md (Phase 5)

## 📦 Future Enhancements (Post-3.0.0)
- Macro transformation for inline attribute syntax (requires Swift macro evolution)
- README updates showcasing parameterized spec patterns
- Additional platform-specific context provider examples

## ✅ Recently Completed
- **Parameterized @Satisfies Support** (2025-11-16) - Archived to `AGENTS_DOCS/TASK_ARCHIVE/7_Parameterized_Satisfies_Implementation/`
  - Validated existing `init(using:)` overload works with parameterized specs
  - Added 7 comprehensive tests demonstrating usage patterns
  - Documented property wrapper syntax limitations
