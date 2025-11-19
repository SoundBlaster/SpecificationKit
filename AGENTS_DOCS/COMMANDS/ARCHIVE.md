# Archive Completed Work

## 🧩 Purpose

Archive **completed** task implementations from [`AGENTS_DOCS/INPROGRESS`](../INPROGRESS) into a new, sequentially numbered folder inside [`AGENTS_DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE) while keeping forward-looking breadcrumbs and blocker logs accurate.

**IMPORTANT**: This command archives **only fully implemented and tested features**. Tasks that are only planned or partially implemented should remain in INPROGRESS until completion.

## 🎯 Goal

Safely relocate **completed** task artifacts into the archive, regenerate any `next_tasks.md` content that still applies, and ensure blocked work is either ready for recovery or clearly documented under a permanent blockers list.

---

## 🔗 Reference Materials

- [Program-wide TODO rollup (`AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md`)](../markdown/00_SpecificationKit_TODO.md)
- [v3 execution tracker (`AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md`)](../markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md)
- [Latest in-progress summary (`AGENTS_DOCS/INPROGRESS/Summary_of_Work.md`)](../INPROGRESS/Summary_of_Work.md)
- [Prior archive summaries (`AGENTS_DOCS/TASK_ARCHIVE/`)](../TASK_ARCHIVE)
- [Permanent blocker log (`AGENTS_DOCS/TASK_ARCHIVE/BLOCKED/` — create if missing)](../TASK_ARCHIVE/BLOCKED)

---

## 📁 Key Directories

```text
AGENTS_DOCS/
 ├── INPROGRESS/
 │    ├── active task notes, summaries, optional next_tasks.md, blocked.md
 │    └── ...
 └── TASK_ARCHIVE/
      ├── <N>_<Task_Name>/
      ├── (optional) ARCHIVE_SUMMARY.md
      └── BLOCKED/
```

---

## ⚙️ Execution Steps

### Step 0. Verify Task Completion (MANDATORY)

**CRITICAL**: Before archiving, verify that all tasks in INPROGRESS are **fully completed**:

- [ ] **`Summary_of_Work.md` exists** - This file is **required** and documents what was implemented
- [ ] **All code is implemented** - Feature/fix is fully coded and integrated into SpecificationKit
- [ ] **All tests pass** - Run `swift test` to verify (or `swift test --filter <TestName>` for specific tests)
- [ ] **Code builds cleanly** - Run `swift build` to ensure no compilation errors
- [ ] **Code is committed** - All changes are committed to git with descriptive messages
- [ ] **Documentation is updated** - README, API docs, inline comments, and CLAUDE.md reflect changes
- [ ] **Progress trackers updated** - Task marked complete in relevant TODO/Progress files
- [ ] **Demo app updated** (if applicable) - DemoApp examples reflect new features

**If any criterion is not met**: DO NOT ARCHIVE. Continue implementation using START.md workflow until all criteria are satisfied.

### Step 1. Review Current In-Progress Files

- Inspect [`AGENTS_DOCS/INPROGRESS`](../INPROGRESS) and list every Markdown document
- Verify that `Summary_of_Work.md` contains complete implementation notes with:
  - What was implemented (features, APIs, tests)
  - Key decisions made during implementation
  - Files modified or created
  - Test results and verification steps
- Capture key context from summaries, notes, or checklists so it is not lost during the move

### Step 2. Collect Future Work Notes

- Read [`AGENTS_DOCS/INPROGRESS/next_tasks.md`](../INPROGRESS/next_tasks.md) if it exists and extract actionable follow-ups
- Cross-check these notes against the backlog references above to confirm they remain relevant
- Note any new tasks discovered during implementation that should be added to the backlog

### Step 3. Classify Blocked Items

- Open [`AGENTS_DOCS/INPROGRESS/blocked.md`](../INPROGRESS/blocked.md) when present
- For each entry decide:
  - **Recoverable blockers:** keep them in `blocked.md` and update wording if context changed
  - **Permanently blocked work:**
    1. Create a Markdown file under [`AGENTS_DOCS/TASK_ARCHIVE/BLOCKED`](../TASK_ARCHIVE/BLOCKED) summarizing the blocker, prerequisites to resume, and links to historical context
    2. Remove the entry from `blocked.md` so the day-to-day list only contains recoverable items
- Update or create [`AGENTS_DOCS/TASK_ARCHIVE/BLOCKED/README.md`](../TASK_ARCHIVE/BLOCKED/README.md) if guidance needs refinement

### Step 4. Determine the Next Archive Folder Name

- Base path: [`AGENTS_DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
- Inspect existing directories: `ls AGENTS_DOCS/TASK_ARCHIVE` to find the highest numbered prefix
- Folder naming pattern: `{N}_{Task_Name}` using the next integer after the highest existing prefix (e.g., if highest is `1_FirstTask`, use `2_SecondTask`)
- Create the folder: `mkdir -p AGENTS_DOCS/TASK_ARCHIVE/{N}_{Task_Name}`

### Step 5. Move Artifacts Using Git

**Use `git mv` to preserve file history:**

- Move all files from INPROGRESS to the archive folder:
  ```bash
  git mv AGENTS_DOCS/INPROGRESS/Summary_of_Work.md AGENTS_DOCS/TASK_ARCHIVE/{N}_{Task_Name}/
  git mv AGENTS_DOCS/INPROGRESS/research.md AGENTS_DOCS/TASK_ARCHIVE/{N}_{Task_Name}/
  # ... repeat for all files
  ```
- For subdirectories, move them wholesale:
  ```bash
  git mv AGENTS_DOCS/INPROGRESS/subdir AGENTS_DOCS/TASK_ARCHIVE/{N}_{Task_Name}/
  ```
- Verify INPROGRESS is clear: `ls AGENTS_DOCS/INPROGRESS` should show no artifacts from archived task
- Verify archive is complete: `ls AGENTS_DOCS/TASK_ARCHIVE/{N}_{Task_Name}` should show all moved files

### Step 6. Create Archive Summary

Create `{Task_Name}_Summary.md` inside the archive directory using this template:

```markdown
# {Task Name} — Archive Summary

## Task Metadata
- **Task Name:** {Task Name}
- **Archive Index:** {N}
- **Archive Date:** {YYYY-MM-DD}
- **Status:** Completed and archived
- **Archive Path:** AGENTS_DOCS/TASK_ARCHIVE/{N}_{Task_Name}

## Objective
{One- or two-sentence description of the problem solved or feature implemented.}

## Key Outcomes
- {Major deliverable 1 - e.g., "Implemented AsyncSpecification protocol with full test coverage"}
- {Major deliverable 2 - e.g., "Added @AsyncSatisfies property wrapper for SwiftUI integration"}
- {Major deliverable 3 - e.g., "Updated DemoApp with async specification examples"}

## Implementation Details
- **Files Modified:** {List key source files changed}
- **Tests Added:** {List test files or test count}
- **API Changes:** {Note any public API additions or breaking changes}
- **Documentation Updates:** {Note README, CLAUDE.md, or other doc changes}

## Test Results
- **Swift Test Output:** {Summary of test results, e.g., "All 47 tests passed"}
- **Build Status:** {e.g., "Clean build with no warnings"}
- **Demo Verification:** {e.g., "Verified in DemoApp CLI and SwiftUI modes"}

## Follow-up Considerations
- {Risk, dependency, or recommended next step - e.g., "Consider async context provider optimization"}
- {Technical debt or future enhancement - e.g., "Future: Add async timeout configuration"}

## Archived Artifacts
- `AGENTS_DOCS/TASK_ARCHIVE/{N}_{Task_Name}/Summary_of_Work.md`
- `AGENTS_DOCS/TASK_ARCHIVE/{N}_{Task_Name}/...` {list all archived files}
```

If you maintain a global archive index (e.g., `ARCHIVE_SUMMARY.md`), append an entry referencing this new archive.

### Step 7. Rebuild `AGENTS_DOCS/INPROGRESS`

- Recreate [`AGENTS_DOCS/INPROGRESS/next_tasks.md`](../INPROGRESS/next_tasks.md) using the actionable items gathered in Step 2
  - Omit this file entirely if there are no follow-up tasks
  - Prioritize tasks and link to relevant backlog items
- Recreate [`AGENTS_DOCS/INPROGRESS/blocked.md`](../INPROGRESS/blocked.md) with the remaining recoverable blockers from Step 3
  - Omit this file if no blockers remain
  - For each blocker, note what's needed to unblock it
- Add any scaffolding files needed for upcoming work (e.g., fresh task shells, new research logs)

### Step 8. Update Planning Artifacts

- Reflect the archived state in:
  - `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` - Mark completed tasks, remove from active list
  - `AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md` - Update progress tracking
  - Any roadmap or checklist documents touched by the work
- Ensure tasks moved to the permanent blocked list are marked accordingly in those documents
- Update version-specific documentation if this work affects release notes

### Step 9. Git Commit and PR Preparation

**Commit your changes:**

```bash
# Review staged changes
git status

# Verify all moved files are tracked
git diff --cached --name-status

# Commit with descriptive message
git commit -m "Archive {Task_Name} task

- Archived completed work from INPROGRESS to TASK_ARCHIVE/{N}_{Task_Name}
- Updated progress trackers and TODO lists
- Created archive summary with implementation details
- Preserved file history using git mv"
```

**Prepare for PR (if using pull request workflow):**

- Ensure commit message follows repository conventions
- Verify all tests still pass: `swift test`
- Verify clean build: `swift build`
- Review the diff to ensure only archival changes are included
- Follow the repository's PR checklist (tests, summary, reviewers)

### Step 10. Report Results

**Document the archival:**

- Record the path of the new archive folder: `AGENTS_DOCS/TASK_ARCHIVE/{N}_{Task_Name}`
- Note whether fresh `next_tasks.md` or `blocked.md` files were generated
- List updates to archive index, backlog documents, and permanent blocker directory
- Summarize key outcomes in commit message and any status updates

---

## ✅ Expected Output

After completing this workflow, you should have:

- **A new sequential archive folder** containing all previously in-progress files with preserved git history
- **Refreshed `AGENTS_DOCS/INPROGRESS`** reflecting only actionable next tasks and recoverable blockers
- **Permanent blockers** (if any) captured under `AGENTS_DOCS/TASK_ARCHIVE/BLOCKED` with clear prerequisites
- **Archive summary** documenting task metadata, outcomes, implementation details, and test results
- **Updated planning artifacts** reflecting completed work in TODO lists and progress trackers
- **Clean git commit** with all archival changes staged and committed
- **Passing tests** confirming SpecificationKit integrity: `swift test` succeeds
- **Clean build** confirming no compilation issues: `swift build` succeeds

---

## 📋 Post-Archive Checklist

Before considering the archive complete, verify:

- [ ] All artifacts were moved with `git mv` and no longer exist in `AGENTS_DOCS/INPROGRESS`
- [ ] `{Task_Name}_Summary.md` documents metadata, outcomes, implementation details, and archived artifact paths
- [ ] Archive index sequencing is correct and no directories were overwritten
- [ ] `git status` shows only the intended archive changes before committing
- [ ] `swift test` passes with all tests succeeding
- [ ] `swift build` completes with no errors or warnings
- [ ] INPROGRESS directory is either empty or contains only next tasks/blockers
- [ ] Progress trackers and TODO lists accurately reflect the archived state
- [ ] Commit message clearly describes what was archived

---

## 🧠 Tips for SpecificationKit

- **Archive only completed work** - Planning-only or partially implemented tasks stay in INPROGRESS
- **Summary_of_Work.md is mandatory** - Never archive without this completion record
- **Test coverage matters** - Ensure archived features have comprehensive test coverage
- **Keep numbering contiguous** - Never reuse an existing archive prefix
- **Preserve git history** - Always use `git mv` instead of `mv` to maintain file history tracking
- **Swift-specific validation** - Always run `swift test` and `swift build` before committing
- **DemoApp updates** - If the feature affects user-facing functionality, verify DemoApp examples work
- **Double-check next_tasks.md** - Cross-reference against canonical backlog to avoid resurrecting outdated plans
- **Use permanent blockers sparingly** - Only when recovery truly depends on unavailable capabilities (e.g., Swift language features, OS APIs)
- **When in doubt** - Use START.md to complete the task first, then ARCHIVE.md to archive it

---

## 🔍 SpecificationKit-Specific Considerations

When archiving work for SpecificationKit:

1. **Core Layer Changes** - If changes affect `Sources/SpecificationKit/Core/`, note API stability implications
2. **Macro Changes** - If `Sources/SpecificationKitMacros/` was modified, verify macro expansion tests pass
3. **Property Wrapper Changes** - If wrappers were added/modified, ensure SwiftUI integration tests pass
4. **Breaking Changes** - Flag any breaking API changes in the archive summary and progress docs
5. **Performance** - Note any performance implications for specification evaluation
6. **Thread Safety** - Document thread-safety guarantees for any new concurrent specifications
7. **Async Support** - If async features were added, verify AsyncSpecification integration

---

## End of Command

Maintain consistent Markdown formatting manually; the legacy helper script `scripts/fix_markdown.py` remains retired.
