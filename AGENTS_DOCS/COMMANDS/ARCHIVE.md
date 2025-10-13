# Archiving Completed Tasks

This guide describes the standardized workflow for moving a completed AI Agent task from `AGENTS_DOCS/INPROGRESS` into the long-term archive.

## Preconditions
- The task's deliverables (e.g., PRDs, notes, supporting docs) reside in `AGENTS_DOCS/INPROGRESS`.
- The task has been reviewed and marked as complete by the owning agent or project lead.

## Workflow Overview
1. **Identify Task Metadata**
   - Determine the canonical **task name** (e.g., `AutoContext_NegativeTests`).
   - Assign the next sequential **archive index `N`**. Use zero-padded numbers only if existing archives do so; otherwise start at `1` and increment by `1` per task.
2. **Create Archive Folder**
   - Path format: `AGENTS_DOCS/TASK_ARCHIVE/{N}_{TASK_NAME}`.
   - Ensure the `TASK_ARCHIVE` directory exists before creating the task-specific folder.
3. **Move Task Artifacts**
   - Transfer every file belonging to the completed task from `AGENTS_DOCS/INPROGRESS` into the new archive folder, preserving filenames and relative structure.
   - Confirm `AGENTS_DOCS/INPROGRESS` no longer contains stray files for the archived task.
4. **Author the Summary**
   - Inside the archive folder, create `{TASK_NAME}_Summary.md`.
   - Include the following sections:
     - **Task Metadata:** name, archive index, completion status, archive date, and a list of primary artifacts.
     - **Objective:** brief statement of the problem solved or goal achieved.
     - **Key Outcomes:** bullet list of major deliverables or decisions captured in the archived documents.
     - **Follow-up Considerations:** remaining risks, dependencies, or recommended next steps.
5. **Validate Archive**
   - Double-check file contents for accuracy and formatting.
   - Run `git status` to verify only the intended files changed.
6. **Commit & PR**
   - Commit the archive changes with a concise message (e.g., `Archive AutoContext negative tests task`).
   - Follow the repository's PR process, summarizing the archive action and linking relevant context if needed.

## Post-Conditions
- The completed task's artifacts live exclusively under `AGENTS_DOCS/TASK_ARCHIVE/{N}_{TASK_NAME}`.
- `AGENTS_DOCS/INPROGRESS` contains only active tasks.
- A structured summary file exists to provide quick historical context without opening the full PRD.
