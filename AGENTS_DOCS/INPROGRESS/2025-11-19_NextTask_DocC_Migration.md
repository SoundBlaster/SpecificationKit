# Next Task — DocC Documentation Migration to SpecificationCore

## Selection Metadata
- **Selection Date:** 2025-11-19
- **Chosen Task:** Migrate DocC documentation from SpecificationKit to SpecificationCore for all Core types
- **Source Backlog Entries:**
  - `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` lines 96–102 (Section 9: Documentation, P1 task)
- **Status:** Selected / Ready for implementation
- **Blocking Issues:** None

---

## Candidate Review

### Evaluated Options

**Option 1: DocC Migration to SpecificationCore (P1)** ✅ SELECTED
- **Source:** `00_SpecificationKit_TODO.md` lines 96-102
- **Priority:** P1 (explicitly marked)
- **Planning Status:** Complete (3 documents, 883 lines of planning)
- **Dependencies:** All satisfied
  - SpecificationCore package exists ✓
  - SpecificationCore builds successfully ✓
  - Planning artifacts complete ✓
  - SpecificationKit has 17 DocC files to reference ✓
- **Effort:** 2-3 days (30 hours estimated)
- **Value:** Critical for SpecificationCore adoption and discoverability

**Option 2: GitHub Actions workflow setup**
- **Source:** `00_SpecificationKit_TODO.md` line 108
- **Priority:** Unspecified (P2-P3 estimated)
- **Planning Status:** None
- **Dependencies:** Unknown
- **Effort:** Unknown
- **Value:** CI/CD infrastructure improvement
- **Reason not selected:** No planning, lower priority, would need scoping first

**Option 3: Optional DocC target setup**
- **Source:** `00_SpecificationKit_TODO.md` line 109
- **Priority:** Optional (P3)
- **Planning Status:** None
- **Dependencies:** Likely depends on Option 1
- **Effort:** Unknown
- **Value:** May be redundant with Option 1
- **Reason not selected:** Marked optional, lowest priority

**Blocked Option: macOS Benchmark Baselines**
- **Source:** `00_SpecificationKit_TODO.md` line 117, `blocked.md` lines 5-28
- **Status:** Blocked - requires macOS hardware access
- **Reason not selected:** Not currently executable

### Why this task now

**1. Highest Priority (P1)**
- Only P1 item in the backlog
- Explicitly prioritized over other documentation work

**2. Complete Planning**
- Comprehensive planning document with 5 phases
- PRD with requirements and user stories
- Summary report with scope analysis
- Total: 883 lines of planning artifacts

**3. Critical for Core Adoption**
- SpecificationCore (26+ types) has no documentation
- Developers cannot discover Core APIs
- Learning resources are in wrong package
- Clear Core vs Kit distinction needed

**4. All Dependencies Met**
- SpecificationCore package exists and builds
- SpecificationKit has reference documentation
- All prerequisites from SpecificationCore separation complete

**5. No Blockers**
- Not waiting on external dependencies
- Not waiting on hardware or infrastructure
- Not waiting on other task completions
- Can start immediately

**6. High ROI**
- Enables Core-only usage (reduces dependencies)
- Improves developer experience
- Clarifies package boundaries
- Documentation-only task (no code risk)

---

## Implementation Notes

### Entry Points / Files to Inspect

**SpecificationKit Documentation (Reference):**
- `Sources/SpecificationKit/Documentation.docc/` — Existing DocC catalog structure
- `Sources/SpecificationKit/Documentation.docc/SpecificationKit.md` — Landing page pattern
- `Sources/SpecificationKit/Documentation.docc/Tutorials/` — Tutorial structure (3 files)
- 14 existing article files — Reference for style and format

**SpecificationCore Package (Target):**
- `Sources/SpecificationCore/` — Core types needing documentation (26+ public types)
- Will create: `Sources/SpecificationCore/Documentation.docc/` — New DocC catalog
- Will create: 26+ article files + 3+ tutorials

**Planning Documents (Guidance):**
- `AGENTS_DOCS/INPROGRESS/DocC_Migration_Planning.md` — Detailed implementation plan
- `AGENTS_DOCS/SpecificationCore_PRD/DocC_Migration_PRD.md` — Requirements and user stories
- `AGENTS_DOCS/INPROGRESS/DocC_Migration_Summary.md` — Scope and findings
- `AGENTS_DOCS/INPROGRESS/Summary_of_Work.md` — What was migrated to Core

### Acceptance Thoughts

**Task is "done" when:**

1. **SpecificationCore Documentation Complete**
   - [ ] `Documentation.docc/` directory created with proper structure
   - [ ] Landing page (`SpecificationCore.md`) with quick start examples
   - [ ] 26+ article files for all Core types (protocols, specs, wrappers, macros)
   - [ ] Minimum 3 Core-focused tutorials
   - [ ] All code examples compile and run
   - [ ] `swift package generate-documentation --target SpecificationCore` succeeds

2. **SpecificationKit Documentation Updated**
   - [ ] Core-related documentation removed from SpecificationKit
   - [ ] `SpecificationKit.md` references SpecificationCore appropriately
   - [ ] Kit tutorials updated to remove Core-only content
   - [ ] `swift package generate-documentation --target SpecificationKit` succeeds

3. **Quality Criteria Met**
   - [ ] No broken links between packages
   - [ ] All cross-package references work correctly
   - [ ] Documentation style consistent throughout
   - [ ] Clear distinction between Core and Kit features
   - [ ] README files in both packages updated

4. **Validation Complete**
   - [ ] Both packages build documentation without warnings/errors
   - [ ] Manual review of generated documentation
   - [ ] All 26+ Core types have documentation coverage
   - [ ] Tutorial code examples tested and verified

5. **Deliverables Committed**
   - [ ] All new DocC files committed to git
   - [ ] Modified files committed
   - [ ] Summary_of_Work.md created documenting completion
   - [ ] Progress trackers updated

### Open Questions / Risks

**Questions to Address During Implementation:**

1. **Cross-Package Linking Syntax**
   - Q: What's the correct syntax for linking from Kit to Core docs?
   - Plan: Test ``` ``SpecificationCore/TypeName`` ``` early in Phase 2
   - Fallback: Use web URLs if symbol links don't work

2. **Asset Migration**
   - Q: Do existing diagrams/images apply to Core concepts?
   - Plan: Audit Resources/ in Phase 1, create new assets if needed
   - Fallback: Start text-only, add visuals as enhancement

3. **Tutorial Code Location**
   - Q: Should tutorial code be inline or in separate files?
   - Plan: Follow SpecificationKit pattern (reference external files)
   - Decision: Inline for short snippets, files for complete examples

4. **Inline Doc Comments**
   - Q: Should we add /// comments to all Core types?
   - Plan: Add comprehensive doc comments for public APIs
   - Benefit: Auto-generates symbol documentation

**Risks Identified:**

1. **Risk:** Cross-package linking may not work as expected
   - **Probability:** Low
   - **Impact:** Medium
   - **Mitigation:** Test linking syntax early, have fallback strategies

2. **Risk:** Tutorial code doesn't compile in Core context
   - **Probability:** Low
   - **Impact:** High
   - **Mitigation:** Test all examples incrementally, create minimal reproducible examples

3. **Risk:** Time overrun on article writing
   - **Probability:** Medium
   - **Impact:** Low
   - **Mitigation:** Focus on critical types first (protocols, basic specs), iterate on polish

4. **Risk:** Asset organization becomes complex
   - **Probability:** Low
   - **Impact:** Low
   - **Mitigation:** Start without images, add as enhancement phase

---

## Immediate Next Actions

1. **Begin Phase 1: Documentation Audit** (4 hours)
   - Read all 14 .md files in SpecificationKit Documentation.docc
   - Read all 3 .tutorial files
   - Create audit matrix: File → Category (Core/Kit/Shared) → Action (Migrate/Keep/Delete)
   - Identify code examples that reference Core types
   - List all Core types without documentation

2. **Phase 2: SpecificationCore DocC Setup** (2 hours)
   - Create `SpecificationCore/Sources/SpecificationCore/Documentation.docc/` directory
   - Create landing page `SpecificationCore.md` with quick start
   - Create `Resources/` subdirectory for future assets
   - Test: `swift package generate-documentation --target SpecificationCore`

3. **Phase 3: Core Documentation Migration** (12 hours)
   - Create 6 Core Protocols articles
   - Create 3 Context Infrastructure articles
   - Create 7 Basic Specifications articles
   - Create 4 Property Wrappers articles
   - Create 2 Macros articles
   - Add code examples to all articles

4. **Phase 4: Tutorial Creation** (8 hours)
   - Create "Getting Started with SpecificationCore" tutorial
   - Create "Composing Specifications" tutorial
   - Create "Working with Context Providers" tutorial
   - Ensure all tutorial code compiles

5. **Phase 5: Cleanup and Validation** (4 hours)
   - Remove Core-related docs from SpecificationKit
   - Update SpecificationKit.md cross-references
   - Build documentation for both packages
   - Fix any broken links or warnings
   - Create Summary_of_Work.md

---

## Task Tracking

**Related Planning Documents:**
- Implementation Plan: `AGENTS_DOCS/INPROGRESS/DocC_Migration_Planning.md`
- Requirements: `AGENTS_DOCS/SpecificationCore_PRD/DocC_Migration_PRD.md`
- Summary: `AGENTS_DOCS/INPROGRESS/DocC_Migration_Summary.md`

**Progress Tracking:**
- TODO: `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` (line 96)
- Will create: `AGENTS_DOCS/INPROGRESS/Summary_of_Work.md` (on completion)

**Success Metrics:**
- Coverage: 100% of 26+ Core types documented
- Tutorials: ≥ 3 Core-focused tutorials
- Build: 100% clean (no warnings/errors)
- Links: 0 broken cross-package links
- Examples: ≥ 80% of articles have runnable code

---

## Ready for START.md

This task is now selected and ready for implementation via `START.md` command.

**Estimated Duration:** 2-3 days (30 hours)
**Priority:** P1
**Risk Level:** Low (documentation-only, no code changes)
