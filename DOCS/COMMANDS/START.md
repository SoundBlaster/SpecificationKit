# Starting an Active SpecificationKit Task

This command reference describes how to implement tasks from `AGENTS_DOCS/INPROGRESS` following TDD and XP practices.

## Purpose
- Implement tasks queued in `AGENTS_DOCS/INPROGRESS` with full code, tests, and documentation
- Ensure every build iteration follows the engineering discipline captured in the v3.0.0 task docs
- Keep traceability intact so subsequent agents can audit what was built and why
- **Complete tasks fully** so they are ready for archival via ARCHIVE.md

**Workflow**: START.md (implement) → Summary_of_Work.md (document) → ARCHIVE.md (archive)

## Goal
Execute one or more items currently stored under `AGENTS_DOCS/INPROGRESS/`, strictly following the
methodology and quality bars documented in:
- `AGENTS_DOCS/markdown/3.0.0/tasks/00_executive_summary.md` (TDD mandate, Swift 6 standards,
  coverage requirements).
- `AGENTS_DOCS/markdown/3.0.0/tasks/summary_for_agents.md` (role expectations, dependency checks,
  progress tracking rules).
- `AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md` (canonical status board).

## Execution Steps

### Step 1. Identify Active Tasks
- Review every Markdown file in `AGENTS_DOCS/INPROGRESS/`; each file represents a queued puzzle.
- Confirm priorities and dependencies using the `SpecificationKit_v3.0.0_Progress.md` tracker and the
  backlog rollup in `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md`.
- Select the highest-impact task that is unblocked. If multiple tasks remain, process them
  sequentially.

### Step 2. Load Methodology Rules
- Skim the directive bundle inside `AGENTS_DOCS/markdown/3.0.0/tasks/` to refresh the playbook.
  Focus on:
  - `00_executive_summary.md` for mandatory TDD + XP practices (failing tests first, small commits,
    continuous refactoring).
  - `summary_for_agents.md` for coordination etiquette, pairing expectations, and dependency checks.
  - Any domain-specific file tied to your task (e.g., `03_performance_tasks.md` for benchmarking,
    `06_context_providers_tasks.md` for provider work).
- Keep these rules visible throughout implementation.

### Step 3. Gather Supporting References
- Pull context from adjacent specs in `AGENTS_DOCS/markdown/` (architecture briefs, macro notes,
  platform checklists).
- Sync with runtime expectations by reading relevant source files under `Sources/SpecificationKit/`
  and mirrored tests under `Tests/SpecificationKitTests/`.
- When benchmarks or demos apply, consult `DemoApp/` and existing performance notes in
  `AGENTS_DOCS/markdown/3.0.0/agent_logs/`.

### Step 4. Implement with TDD + XP Discipline
- Follow the red/green/refactor loop:
  1. Author failing tests that describe the target behavior.
  2. Implement the minimal Swift code to make them pass.
  3. Refactor for clarity, safety, and performance while retaining green tests.
- Keep iterations small, pair changes with doc updates, and maintain high coverage.
- Treat each in-progress Markdown file as a self-contained puzzle; complete one puzzle per commit
  whenever possible.

### Step 5. Track Progress in Documentation
- Update task status inside `AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md` as
  milestones are hit.
- Reflect new insights or TODO closures in the originating task file within `AGENTS_DOCS/INPROGRESS/`.
- Mirror task completion in `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` or any specialized
  checklist that referenced the work.

### Step 6. Summarize Completed Work (REQUIRED)

**CRITICAL**: You **must** create `AGENTS_DOCS/INPROGRESS/Summary_of_Work.md` when work is complete. This file is **mandatory for archival**.

Create `Summary_of_Work.md` capturing:
- Completed task names and their commit identifiers
- Key implementation notes, test suites executed, and benchmark highlights
- Follow-up items or deferred risks
- Confirmation that all acceptance criteria are met

**Completion Checklist** (verify before archival):
- [ ] All code implemented and committed
- [ ] All tests pass (`swift test`)
- [ ] Documentation updated
- [ ] Progress trackers updated
- [ ] `Summary_of_Work.md` created

Once complete, the task is ready for archival using `AGENTS_DOCS/COMMANDS/ARCHIVE.md`.

### Step 7. Finalize
- Run `swift build` and `swift test` from the repository root to verify the package.
- Ensure documentation, trackers, and TODO files reflect the final state.
- Conclude with a status message summarizing completed tasks and pointing to the
  `Summary_of_Work.md` record.

## Expected Output
- Selected `AGENTS_DOCS/INPROGRESS` tasks are **fully implemented, tested, and validated**
- Progress trackers (`SpecificationKit_v3.0.0_Progress.md`, `00_SpecificationKit_TODO.md`) are in sync with the codebase
- `AGENTS_DOCS/INPROGRESS/Summary_of_Work.md` exists with concise documentation of the work
- All changes are committed, tests pass, and the workspace has no leftover modifications
- **Task is ready for archival** via ARCHIVE.md command

## Notes
- Do not skip the rules and progress trackers—they prevent conflicting automation runs.
- Maintain atomic commits and keep doc updates in lockstep with code.
- Retired helper scripts (e.g., `scripts/fix_markdown.py`) should remain unused; rely on manual
  Markdown curation.
