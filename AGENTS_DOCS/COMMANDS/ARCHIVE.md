# Archiving Completed Tasks

This command reference documents the repeatable workflow for relocating a completed AI Agent task from `AGENTS_DOCS/INPROGRESS`
into `AGENTS_DOCS/TASK_ARCHIVE`.

## Purpose
- Preserve historical context for completed tasks without polluting the in-progress queue.
- Keep numbering, naming, and documentation consistent across archived tasks.
- Capture high-level outcomes in a concise summary file for fast recall.

## Prerequisites
- All deliverables tied to the task (PRDs, research notes, decision logs, etc.) live under `AGENTS_DOCS/INPROGRESS`.
- The task has been reviewed, approved, and explicitly marked complete by its owner or project lead.
- You know the canonical task name (e.g., `AutoContext_NegativeTests`).

## Step-by-Step Procedure
1. **Collect Metadata**
   - Determine the next sequential archive index `N`. Inspect existing directories under `AGENTS_DOCS/TASK_ARCHIVE` and increment the
     highest number by one.
   - Confirm the final task slug (`{TASK_NAME}`) to use in directory and file names.
   - Make note of the primary artifacts that will move (e.g., PRDs, diagrams, research notes).
2. **Create the Archive Directory**
   - Directory format: `AGENTS_DOCS/TASK_ARCHIVE/{N}_{TASK_NAME}`.
   - Create the directory with `mkdir -p AGENTS_DOCS/TASK_ARCHIVE/{N}_{TASK_NAME}`.
3. **Move All Artifacts**
   - Use `git mv` to relocate each file from `AGENTS_DOCS/INPROGRESS` to the archive directory so history is preserved
     (e.g., `git mv AGENTS_DOCS/INPROGRESS/foo.md AGENTS_DOCS/TASK_ARCHIVE/{N}_{TASK_NAME}/`).
   - If the task contains subdirectories, move them wholesale with `git mv AGENTS_DOCS/INPROGRESS/subdir AGENTS_DOCS/TASK_ARCHIVE/{N}_{TASK_NAME}/`.
   - After moving, confirm `AGENTS_DOCS/INPROGRESS` no longer contains artifacts from the archived task.
4. **Author the Archive Summary**
   - Create `{TASK_NAME}_Summary.md` inside the archive directory using the template below.
   - Document the archive date using the ISO format `YYYY-MM-DD` and list every artifact that was moved.
5. **Verify the Archive**
   - Run `ls AGENTS_DOCS/TASK_ARCHIVE/{N}_{TASK_NAME}` to ensure the expected files are present.
   - Open the summary and critical artifacts to confirm formatting.
   - Execute `git status` to review the staged changes.
6. **Commit and Prepare a PR**
   - Commit with a descriptive subject (e.g., `Archive {TASK_NAME} task`).
   - Follow the repository's PR checklist (tests, summary, reviewers) before publishing.

## Archive Summary Template

```
# {Task Name} — Archive Summary

## Task Metadata
- **Task Name:** {Task Name}
- **Archive Index:** {N}
- **Archive Date:** {YYYY-MM-DD}
- **Status:** Completed and archived
- **Archive Path:** AGENTS_DOCS/TASK_ARCHIVE/{N}_{TASK_NAME}
- **Primary Artifacts:**
  - `AGENTS_DOCS/TASK_ARCHIVE/{N}_{TASK_NAME}/…`

## Objective
{One- or two-sentence description of the problem solved.}

## Key Outcomes
- {Major deliverable or decision 1}
- {Major deliverable or decision 2}

## Follow-up Considerations
- {Risk, dependency, or recommended next step}

## Archived Artifacts
- `AGENTS_DOCS/TASK_ARCHIVE/{N}_{TASK_NAME}/...`
```

## Post-Archive Checklist
- [ ] All artifacts were moved with `git mv` and no longer exist in `AGENTS_DOCS/INPROGRESS`.
- [ ] `{TASK_NAME}_Summary.md` documents metadata, outcomes, follow-ups, and archived artifact paths.
- [ ] Archive index sequencing is correct and no directories were overwritten.
- [ ] `git status` shows only the intended archive changes before committing.
