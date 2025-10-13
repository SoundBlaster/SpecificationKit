# Selecting the Next SpecificationKit Task

This command reference explains how to pull the highest-value item from the SpecificationKit backlog
and record it as the next task for implementation.

## Purpose
- Keep the in-progress queue focused on the most impactful, unblocked work.
- Provide transparent rationale (source references, dependencies, and acceptance hints).
- Ensure every selection leaves behind a paper trail for future agents.

## Required Inputs
- `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` (global backlog with priority bands).
- Any roadmap-specific TODOs inside `AGENTS_DOCS/markdown/3.0.0/` when planning macro or v3 work.
- Recent archive summaries in `AGENTS_DOCS/TASK_ARCHIVE/` (avoid duplicating completed tasks).
- Optional: open GitHub issues, CHANGELOG entries, or PR feedback if they signal urgent work.

## Step-by-Step Procedure
1. **Inventory Backlog Candidates**
   - Scan the base TODO list and roadmap documents for unchecked items.
   - Copy the most relevant bullets (include their source paths/line ranges) into your working notes.
2. **Filter & Prioritize**
   - Drop items explicitly marked as blocked.
   - Rank the remaining candidates using the repo's priority shorthands (`P0` > `P1` > `P2` > `P3`).
   - Prefer work that unblocks other backlog entries (e.g., missing infrastructure or tests).
3. **Confirm Dependencies**
   - Read the source files or documentation referenced by the candidate to ensure prerequisites exist.
   - Note any follow-up tasks or risks you uncover while inspecting the codebase.
4. **Author the Selection Record**
   - Create the directory `AGENTS_DOCS/INPROGRESS/` if it does not exist.
   - Add a markdown file named `YYYY-MM-DD_NextTask_<Slug>.md` describing the chosen task.
   - Fill in the template below, citing the relevant backlog lines and code entry points.
5. **Review & Commit**
   - Re-read the selection file to ensure context, rationale, and next actions are clear.
   - Stage the new/updated files and follow the repository's commit + PR process.

## Selection Record Template
```
# Next Task — <Task Title>

## Selection Metadata
- **Selection Date:** <YYYY-MM-DD>
- **Chosen Task:** <Short description>
- **Source Backlog Entries:**
  - `<File Path>` lines `X–Y`
- **Status:** Selected / Ready to plan implementation
- **Blocking Issues:** <"None" or short list>

## Candidate Review
- **Evaluated Options:**
  - <Option 1 summary with references>
  - <Option 2 summary with references>
- **Why this task now:** <Explain priority, dependencies, or ROI.>

## Implementation Notes
- **Entry Points / Files to Inspect:**
  - `<File.swift>` — <reason>
- **Acceptance Thoughts:**
  - <Bullets describing what "done" should look like>
- **Open Questions / Risks:**
  - <Any uncertainties to resolve>

## Immediate Next Actions
1. <First follow-up step>
2. <Second follow-up step>
```

Agents may expand sections as needed (e.g., linking to diagrams or external documents), but the
selection record must stand on its own without external context.
