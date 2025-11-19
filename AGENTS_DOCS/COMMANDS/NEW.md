# Starting New Feature Work

## 🧩 Purpose

Process an incoming feature request or task idea by integrating it into the SpecificationKit documentation ecosystem, creating proper planning artifacts, and preparing it for implementation.

**IMPORTANT**: This command is for **planning and documenting** new work. After completing this command, use `SELECT_NEXT.md` to prioritize the task, then `START.md` to implement it.

## 🎯 Goal

Transform an incoming feature description (from a sentence to a detailed plan) into a fully contextualized set of planning artifacts:

- Structured analysis of the feature request
- Cross-referenced insights from prior tasks and architecture
- Updated backlog and TODO entries
- Planning documents in `AGENTS_DOCS/INPROGRESS/` or backlog
- Integration with existing SpecificationKit architecture

---

## 🔗 Reference Materials

- [Program-wide TODO (`AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md`)](../../AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md)
- [v3 execution tracker (`AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md`)](../../AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md)
- [Executive summary with TDD mandate (`AGENTS_DOCS/markdown/3.0.0/tasks/00_executive_summary.md`)](../../AGENTS_DOCS/markdown/3.0.0/tasks/00_executive_summary.md)
- [Agent coordination guide (`AGENTS_DOCS/markdown/3.0.0/tasks/summary_for_agents.md`)](../../AGENTS_DOCS/markdown/3.0.0/tasks/summary_for_agents.md)
- [Prior archive summaries (`AGENTS_DOCS/TASK_ARCHIVE/`)](../../AGENTS_DOCS/TASK_ARCHIVE)
- [SpecificationCore PRD (`AGENTS_DOCS/SpecificationCore_PRD/`)](../../AGENTS_DOCS/SpecificationCore_PRD)
- [Architecture docs (`AGENTS_DOCS/markdown/`)](../../AGENTS_DOCS/markdown)

---

## 📁 Key Directories

```text
AGENTS_DOCS/
 ├── INPROGRESS/           # Active or queued tasks
 ├── TASK_ARCHIVE/         # Completed task history
 ├── markdown/
 │   ├── 00_SpecificationKit_TODO.md  # Global backlog
 │   ├── 3.0.0/
 │   │   └── tasks/
 │   │       ├── SpecificationKit_v3.0.0_Progress.md
 │   │       ├── 00_executive_summary.md
 │   │       └── ...       # Domain-specific task docs
 │   └── ...
 └── SpecificationCore_PRD/  # Product requirements
```

---

## ⚙️ Execution Steps

### Step 1. Understand the Incoming Feature

**Parse and decompose the request:**

- Read the provided feature request, regardless of size (sentence, paragraph, or detailed spec)
- Break it down into:
  - **Main objective**: What problem does this solve?
  - **User impact**: Who benefits and how?
  - **Technical scope**: What layers are affected? (Core, Specs, Wrappers, Macros, Providers, Demo)
  - **Stages/milestones**: What are the implementation phases?
  - **Atomic subtasks**: Break into testable units
- Capture:
  - **Open questions**: What needs clarification?
  - **Dependencies**: What must exist first?
  - **Assumptions**: What are we assuming about the system?
  - **Success criteria**: How do we know it's done?

**Example decomposition:**
```markdown
# Feature: Async Timeout Support

## Objective
Add timeout configuration to AsyncSpecification evaluation to prevent indefinite hangs.

## User Impact
- Developers can set max evaluation time for async specs
- Better error messages when timeouts occur
- Prevents production hangs from slow async operations

## Technical Scope
- Core Layer: Extend AsyncSpecification protocol
- Specs Layer: Add TimeoutSpec wrapper
- Wrappers: Update @AsyncSatisfies with timeout parameter
- Tests: Add timeout test coverage
- Demo: Show timeout examples in DemoApp

## Stages
1. Design timeout API (duration, error handling)
2. Implement core timeout mechanism
3. Add property wrapper support
4. Create comprehensive tests
5. Update documentation and demos

## Dependencies
- Existing AsyncSpecification infrastructure
- Swift Concurrency (Task.sleep, Task.withTimeout)
```

### Step 2. Research Existing Knowledge

**Search for related work:**

1. **Check for duplicates or overlap:**
   ```bash
   # Search for similar features in backlog
   grep -r "timeout" AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md

   # Search completed work
   grep -r "async" AGENTS_DOCS/TASK_ARCHIVE/*/Summary*.md

   # Search current in-progress work
   ls -la AGENTS_DOCS/INPROGRESS/
   ```

2. **Review architecture and prior decisions:**
   - Read `AGENTS_DOCS/markdown/` for relevant architecture docs
   - Check `AGENTS_DOCS/SpecificationCore_PRD/` for related requirements
   - Review `CLAUDE.md` for architectural patterns and conventions
   - Examine `Sources/SpecificationKit/` for existing similar implementations

3. **Summarize findings:**
   ```markdown
   ## Related Work Analysis

   ### Existing Features
   - AsyncSpecification protocol (Sources/SpecificationKit/Core/AsyncSpecification.swift)
   - @AsyncSatisfies property wrapper (Sources/SpecificationKit/Wrappers/AsyncSatisfies.swift)
   - Task 7 in TASK_ARCHIVE: Parameterized @Satisfies implementation (similar pattern)

   ### Architecture Patterns
   - Property wrappers use configuration structs for options
   - Error handling follows Swift Result<Success, Failure> pattern
   - Thread safety required for all context providers

   ### Lessons Learned
   - From Task 7: Parameter APIs should be optional with sensible defaults
   - From Task 3: Property wrapper edge cases need comprehensive test coverage
   - From exec summary: TDD is mandatory - tests first, then implementation

   ### Potential Conflicts
   - None identified

   ### Gaps to Address
   - No existing timeout mechanism in async specs
   - No error types defined for timeout scenarios
   ```

### Step 3. Evaluate Novelty and Relevance

**Determine the feature's status:**

1. **Check for duplicates:**
   - Is this feature already implemented? → Document and close the request
   - Is it partially implemented? → Document what's missing and plan completion
   - Is it already planned? → Consolidate with existing plans or adjust priority

2. **Assess relevance to project goals:**
   - Does it align with SpecificationKit's mission (specification pattern for Swift)?
   - Does it support v3.0.0 goals (from progress tracker)?
   - Is it appropriate for the current release cycle?

3. **Evaluate scope and effort:**
   - **Small** (< 1 day): Single spec, small enhancement, documentation update
   - **Medium** (1-3 days): New property wrapper, multiple specs, macro enhancement
   - **Large** (> 3 days): Major architectural change, new layer, breaking API change

4. **Make a decision:**
   ```markdown
   ## Feature Assessment

   - **Status**: Novel feature, not yet implemented
   - **Relevance**: High - improves async spec reliability and error handling
   - **Alignment**: Aligns with v3.0.0 stability and robustness goals
   - **Scope**: Medium - requires core protocol, wrapper updates, and tests
   - **Priority**: P1 - Important for production async spec usage
   - **Recommendation**: Add to backlog with P1 priority, plan for next sprint
   ```

### Step 4. Update Documentation Ecosystem

**Integrate the new feature into planning docs:**

1. **Update the global backlog:**
   - Add entry to `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md`
   - Assign priority (P0 = critical, P1 = high, P2 = medium, P3 = low)
   - Link to any related tasks or dependencies
   - Example:
     ```markdown
     ### Async Specifications
     - [ ] **P1** Add timeout support to AsyncSpecification with configurable duration
     - [ ] **P2** Add cancellation token support for async specs
     ```

2. **Update version-specific trackers:**
   - If targeting v3.0.0, update `AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md`
   - Add to appropriate category (Core, Property Wrappers, Macros, etc.)

3. **Handle related tasks:**
   - Link to prerequisites (tasks that must complete first)
   - Link to follow-ups (tasks this will unblock)
   - Update or deprecate conflicting tasks
   - Cross-reference similar completed work in archives

4. **Create planning document (for immediate work):**
   - If the feature is high priority and ready to start, create planning doc in `AGENTS_DOCS/INPROGRESS/`
   - Use format: `<Feature_Name>_Planning.md`
   - Include all analysis from Steps 1-3
   - Otherwise, leave in backlog for later selection via SELECT_NEXT.md

### Step 5. Create or Update PRD Documentation

**Maintain product requirements coverage:**

1. **Locate relevant PRD:**
   - Check `AGENTS_DOCS/SpecificationCore_PRD/` for applicable documents
   - Determine if feature fits existing PRD or needs new document

2. **Document feature requirements:**
   ```markdown
   # AsyncSpecification Timeout Support

   ## Problem Statement
   AsyncSpecification evaluations can hang indefinitely if async operations
   don't complete, causing production issues and poor developer experience.

   ## Goals
   - Provide configurable timeout for async specification evaluation
   - Generate clear error messages when timeouts occur
   - Maintain backward compatibility with existing async specs

   ## Non-Goals
   - Cancellation tokens (future enhancement)
   - Retry logic (out of scope)

   ## Requirements

   ### Functional
   1. AsyncSpecification protocol supports optional timeout parameter
   2. @AsyncSatisfies property wrapper exposes timeout configuration
   3. Timeout errors include context (spec name, duration, stack trace)
   4. Default timeout is configurable globally via context provider

   ### Non-Functional
   1. Zero performance overhead when timeout is not set
   2. Thread-safe timeout handling
   3. Compatible with Swift Concurrency best practices

   ## API Design
   \`\`\`swift
   // Protocol extension
   extension AsyncSpecification {
       func isSatisfiedBy(_ candidate: Candidate,
                         timeout: Duration = .none) async throws -> Bool
   }

   // Property wrapper usage
   @AsyncSatisfies(using: mySpec, timeout: .seconds(5))
   var isValid: Bool
   \`\`\`

   ## Success Metrics
   - All async spec tests include timeout coverage
   - Zero production timeout incidents reported
   - Developer feedback: improved async debugging experience
   ```

3. **Update or create PRD file:**
   - For new features, create `AGENTS_DOCS/SpecificationCore_PRD/AsyncTimeout_PRD.md`
   - For enhancements, update existing PRD sections
   - Ensure consistency with technical analysis from earlier steps

### Step 6. Create Planning Artifacts

**Prepare detailed implementation guidance:**

1. **Create task planning document** (if immediate work):
   - Location: `AGENTS_DOCS/INPROGRESS/<Feature_Name>_Planning.md`
   - Template:
     ```markdown
     # Feature Planning: <Feature Name>

     ## Task Metadata
     - **Created**: YYYY-MM-DD
     - **Priority**: P1
     - **Estimated Scope**: Medium (1-3 days)
     - **Prerequisites**: <List any blockers>
     - **Target Layers**: Core, Wrappers, Tests

     ## Feature Overview
     <One-paragraph summary>

     ## Implementation Plan

     ### Phase 1: Core Protocol Extension
     - [ ] Design timeout parameter API
     - [ ] Add Duration type support
     - [ ] Implement timeout wrapper in AsyncSpecification
     - [ ] Write unit tests for timeout behavior

     ### Phase 2: Property Wrapper Integration
     - [ ] Update @AsyncSatisfies with timeout parameter
     - [ ] Add timeout configuration to wrapper
     - [ ] Test wrapper timeout behavior

     ### Phase 3: Error Handling
     - [ ] Define TimeoutError type
     - [ ] Add context to timeout errors
     - [ ] Test error propagation

     ### Phase 4: Documentation & Demo
     - [ ] Update API documentation
     - [ ] Add DemoApp examples
     - [ ] Update CLAUDE.md if needed
     - [ ] Update README if needed

     ## Files to Modify
     - `Sources/SpecificationKit/Core/AsyncSpecification.swift`
     - `Sources/SpecificationKit/Wrappers/AsyncSatisfies.swift`
     - `Tests/SpecificationKitTests/AsyncSpecificationTests.swift`
     - `DemoApp/Sources/Examples/AsyncExamples.swift`

     ## Test Strategy
     - Unit tests for timeout mechanism (fast timeout, slow operation)
     - Integration tests with @AsyncSatisfies wrapper
     - Error handling tests (timeout triggers correct error)
     - Edge cases: zero timeout, negative timeout, very large timeout

     ## Success Criteria
     - [ ] All tests pass (`swift test`)
     - [ ] Clean build (`swift build`)
     - [ ] Code coverage maintained or improved
     - [ ] DemoApp demonstrates timeout behavior
     - [ ] Documentation updated

     ## Open Questions
     - Should timeout be Duration or TimeInterval?
     - Should we support per-context timeout defaults?
     - How to handle nested async spec timeouts?

     ## Related Work
     - Task 7: Parameterized @Satisfies (similar pattern)
     - Core AsyncSpecification implementation
     - Swift Concurrency timeout patterns
     ```

2. **Add task breakdown** (optional, for complex features):
   - Create `AGENTS_DOCS/INPROGRESS/<Feature_Name>_Tasks.md` with detailed subtasks
   - Each subtask should be independently testable
   - Follow TDD mandate: test file listed before implementation file

### Step 7. Validate and Consolidate

**Ensure all documentation is consistent:**

1. **Verify references:**
   ```bash
   # Check that all file paths in your planning docs exist
   ls Sources/SpecificationKit/Core/AsyncSpecification.swift
   ls Tests/SpecificationKitTests/AsyncSpecificationTests.swift
   ```

2. **Cross-check for consistency:**
   - Priority in TODO matches priority in planning doc
   - PRD requirements align with implementation plan
   - Test strategy covers all requirements
   - Success criteria are measurable

3. **Validate against project standards:**
   - Follows TDD mandate (tests first)
   - Aligns with Swift API Design Guidelines
   - Respects SpecificationKit architecture (layering, protocols)
   - Compatible with existing specs and wrappers

4. **Run basic validation:**
   ```bash
   # Ensure project still builds
   swift build

   # Ensure tests still pass
   swift test
   ```

### Step 8. Commit Documentation Changes

**Save your planning work:**

```bash
# Stage all documentation changes
git add AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md
git add AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md
git add AGENTS_DOCS/INPROGRESS/<Feature_Name>_Planning.md
git add AGENTS_DOCS/SpecificationCore_PRD/<Feature_Name>_PRD.md

# Review changes
git status
git diff --cached

# Commit with descriptive message
git commit -m "Plan new feature: <Feature Name>

- Added planning document to INPROGRESS
- Updated global TODO with P1 task
- Created PRD for feature requirements
- Identified dependencies and success criteria

Ready for selection and implementation via START.md"
```

### Step 9. Report Results

**Summarize your planning work:**

Create a brief summary of what was done:

```markdown
## Planning Summary: <Feature Name>

### Actions Completed
- ✅ Feature analyzed and decomposed into subtasks
- ✅ Existing codebase researched for related work
- ✅ Feature assessed as novel P1 work
- ✅ Global TODO updated with new entry
- ✅ Progress tracker updated (if applicable)
- ✅ Planning document created in INPROGRESS
- ✅ PRD documentation created/updated
- ✅ All changes committed to git

### Key Findings
- **Related Work**: <List any relevant prior tasks or similar features>
- **Dependencies**: <List prerequisites>
- **Scope**: Medium (1-3 days estimated)
- **Priority**: P1 (high value, aligns with v3.0.0 goals)

### Next Steps
1. Use SELECT_NEXT.md to prioritize this task against other backlog items
2. When ready to implement, use START.md to begin TDD implementation
3. After completion, use ARCHIVE.md to archive the work

### Planning Artifacts Created
- `AGENTS_DOCS/INPROGRESS/<Feature_Name>_Planning.md` - Implementation plan
- `AGENTS_DOCS/SpecificationCore_PRD/<Feature_Name>_PRD.md` - Requirements
- Updated: `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` - Backlog entry

### Unresolved Questions
- <List any questions that need answers before implementation>
- <These should be addressed during implementation or via team discussion>
```

---

## ✅ Expected Output

After completing this workflow, you should have:

- **Feature analysis** with objective, scope, stages, dependencies, and success criteria
- **Related work summary** documenting similar features, patterns, and lessons learned
- **Novelty assessment** confirming this is new work worth doing
- **Updated backlog** with new entry in `00_SpecificationKit_TODO.md` at appropriate priority
- **Progress tracker updates** (if version-specific)
- **Planning document** in `AGENTS_DOCS/INPROGRESS/` with detailed implementation plan
- **PRD documentation** capturing requirements and API design
- **Git commit** with all planning artifacts
- **Clear next steps** for selecting and implementing the work

---

## 📋 Planning Checklist

Before considering planning complete, verify:

- [ ] Feature request is fully analyzed and decomposed
- [ ] Codebase researched for related work, no duplicates found
- [ ] Feature novelty and relevance confirmed
- [ ] Priority assigned based on impact and effort
- [ ] Global TODO (`00_SpecificationKit_TODO.md`) updated
- [ ] Progress tracker updated (if version-specific work)
- [ ] Planning document created in INPROGRESS (for immediate work) or backlog updated
- [ ] PRD documentation created or updated
- [ ] All file paths in planning docs verified to exist or noted as new files
- [ ] Planning follows TDD principles (tests listed before implementations)
- [ ] Success criteria are clear and measurable
- [ ] Dependencies and prerequisites identified
- [ ] Open questions documented
- [ ] All changes committed to git with descriptive message
- [ ] Project still builds: `swift build` succeeds
- [ ] Tests still pass: `swift test` succeeds

---

## 🧠 Tips for SpecificationKit

- **Start small**: Break large features into smaller, independently deliverable pieces
- **Respect the layers**: Core → Specs → Wrappers → Macros → Providers. Build bottom-up.
- **TDD always**: Every plan should list test files before implementation files
- **Check archives first**: Many patterns have been used before in completed tasks
- **Link dependencies**: Explicitly note what must exist before this feature can work
- **Be specific**: "Update AsyncSpecification" is vague; "Add timeout parameter to isSatisfiedBy" is clear
- **Consider all touchpoints**: New features often need Core + Wrapper + Test + Demo + Docs updates
- **Validate early**: Check that referenced files exist or clearly mark as new files
- **Don't skip PRDs**: Requirements documentation prevents scope creep and miscommunication
- **Atomic commits**: Commit planning docs separately from implementation

---

## 🔍 SpecificationKit-Specific Considerations

When planning new features for SpecificationKit:

1. **Architecture Layers** - Identify which layers are affected:
   - Core: Protocols, base types, operators
   - Specs: Built-in specification implementations
   - Wrappers: Property wrappers (@Satisfies, @Decides, etc.)
   - Macros: Compile-time code generation (@specs, @AutoContext)
   - Providers: Context providers and evaluation context
   - Definitions: Composite specs and auto-context specs

2. **API Design** - Follow Swift API Design Guidelines:
   - Clear, self-documenting names
   - Appropriate use of default parameters
   - Protocol extensions for common functionality
   - Value types (structs) unless reference semantics needed

3. **Property Wrappers** - If adding/modifying wrappers:
   - Consider projectedValue for additional functionality
   - Ensure @Observable/@ObservableObject compatibility
   - Test with SwiftUI environment integration
   - Document initialization patterns clearly

4. **Macros** - If modifying macro system:
   - Comprehensive diagnostics with clear error messages
   - Macro expansion tests using swift-macro-testing
   - Consider impact on compile times
   - Document macro usage patterns and limitations

5. **Async Support** - For async features:
   - Use Swift Concurrency properly (async/await, Task, actors)
   - Consider cancellation and timeout scenarios
   - Test with various async contexts (MainActor, background)
   - Document thread safety guarantees

6. **Thread Safety** - For concurrent features:
   - Document thread-safety guarantees explicitly
   - Use appropriate synchronization (actors, locks, @Sendable)
   - Test concurrent access patterns
   - Avoid data races (Swift 6 concurrency checking)

7. **Performance** - Consider performance implications:
   - Will this affect hot paths (specification evaluation)?
   - Should this be benchmarked?
   - Are there optimizations worth documenting?
   - Does this affect compilation time?

8. **Breaking Changes** - If API changes are needed:
   - Document breaking changes clearly
   - Consider deprecation path for existing APIs
   - Update version expectations (semver)
   - Plan migration guide for users

9. **Demo Integration** - Plan demo updates:
   - CLI examples in DemoApp for command-line scenarios
   - SwiftUI examples for reactive/UI scenarios
   - Real-world use cases, not toy examples
   - Cover both happy path and error cases

---

## 🔄 Workflow Integration

**NEW.md fits into the broader workflow:**

1. **NEW.md** ← You are here
   - Analyze and plan new feature requests
   - Create planning artifacts and update backlog
   - Output: Planning docs and updated TODO

2. **SELECT_NEXT.md**
   - Prioritize tasks from backlog
   - Choose highest-value unblocked work
   - Output: Selection record in INPROGRESS

3. **START.md**
   - Implement selected task using TDD
   - Follow implementation plan from NEW.md
   - Output: Working code, tests, and Summary_of_Work.md

4. **ARCHIVE.md**
   - Archive completed work from INPROGRESS
   - Preserve history and update trackers
   - Output: Sequential archive folder with summary

---

## End of Command

Maintain consistent Markdown formatting manually; the legacy helper script `scripts/fix_markdown.py` remains retired.
