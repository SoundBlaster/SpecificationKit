# Archive Current Work-in-Progress

## 🧩 Purpose

Archive the current contents of [`AGENTS_DOCS/INPROGRESS`](../../AGENTS_DOCS/INPROGRESS) into a new, sequentially numbered folder inside [`AGENTS_DOCS/TASK_ARCHIVE`](../../AGENTS_DOCS/TASK_ARCHIVE) while keeping forward-looking breadcrumbs and blocker logs accurate.

## 🎯 Goal

Safely relocate every active task artifact into the archive, regenerate any `next_tasks.md` content that still applies, and ensure blocked work is either ready for recovery or clearly documented under a permanent blockers list.

---

## 🔗 Reference Materials

- [Program-wide TODO rollup (`AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md`)](../../AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md)
- [v3 execution tracker (`AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md`)](../../AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md)
- [Latest in-progress summary (`AGENTS_DOCS/INPROGRESS/Summary_of_Work.md`)](../../AGENTS_DOCS/INPROGRESS/Summary_of_Work.md)
- [Prior archive summaries (`AGENTS_DOCS/TASK_ARCHIVE/`)](../../AGENTS_DOCS/TASK_ARCHIVE)
- [Permanent blocker log (`AGENTS_DOCS/TASK_ARCHIVE/BLOCKED/` — create if missing)](../../AGENTS_DOCS/TASK_ARCHIVE/BLOCKED)

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

### Step 1. Review Current In-Progress Files

- Inspect [`AGENTS_DOCS/INPROGRESS`](../../AGENTS_DOCS/INPROGRESS) and list every Markdown document.
- Capture key context from summaries, notes, or checklists so it is not lost during the move.

### Step 2. Collect Future Work Notes

- Read [`AGENTS_DOCS/INPROGRESS/next_tasks.md`](../../AGENTS_DOCS/INPROGRESS/next_tasks.md) if it exists and extract actionable follow-ups.
- Cross-check these notes against the backlog references above to confirm they remain relevant.

### Step 3. Classify Blocked Items

- Open [`AGENTS_DOCS/INPROGRESS/blocked.md`](../../AGENTS_DOCS/INPROGRESS/blocked.md) when present.
- For each entry decide:
  - **Recoverable blockers:** keep them in `blocked.md` and update wording if context changed.
  - **Permanently blocked work:**
    1. Create a Markdown file under [`AGENTS_DOCS/TASK_ARCHIVE/BLOCKED`](../../AGENTS_DOCS/TASK_ARCHIVE/BLOCKED) summarizing the blocker, prerequisites to resume, and links to historical context.
    2. Remove the entry from `blocked.md` so the day-to-day list only contains recoverable items.
- Update or create [`AGENTS_DOCS/TASK_ARCHIVE/BLOCKED/README.md`](../../AGENTS_DOCS/TASK_ARCHIVE/BLOCKED/README.md) if guidance needs refinement.

### Step 4. Determine the Next Archive Folder Name

- Base path: [`AGENTS_DOCS/TASK_ARCHIVE`](../../AGENTS_DOCS/TASK_ARCHIVE).
- Folder naming pattern: `{N}_{Task_Name}` using the next integer after the highest existing prefix (e.g., `2_New_Work_Item`).
- Create the folder if it does not exist.

### Step 5. Move Current Work Into the Archive

- Move every file and subfolder from [`AGENTS_DOCS/INPROGRESS`](../../AGENTS_DOCS/INPROGRESS) into the new archive folder, preserving structure.
- Update or create `{Task_Name}_Summary.md` inside the archive directory with highlights and links to artifacts.
- If you maintain an archive index (e.g., `ARCHIVE_SUMMARY.md`), append an entry referencing the new folder.

### Step 6. Rebuild `AGENTS_DOCS/INPROGRESS`

- Recreate [`AGENTS_DOCS/INPROGRESS/next_tasks.md`](../../AGENTS_DOCS/INPROGRESS/next_tasks.md) using the actionable items gathered in Step 2 (omit the file when there are no follow-ups).
- Recreate [`AGENTS_DOCS/INPROGRESS/blocked.md`](../../AGENTS_DOCS/INPROGRESS/blocked.md) with the remaining recoverable blockers from Step 3.
- Add any scaffolding files needed for upcoming work (e.g., fresh task shells, new research logs).

### Step 7. Update Planning Artifacts

- Reflect the archived state in `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md`, `AGENTS_DOCS/markdown/3.0.0/tasks/SpecificationKit_v3.0.0_Progress.md`, and any roadmap or checklist documents touched by the work.
- Ensure tasks moved to the permanent blocked list are marked accordingly in those documents.

### Step 8. Report Results

- Record the path of the new archive folder and whether fresh `next_tasks.md` or `blocked.md` files were generated.
- Note updates to the archive index, backlog documents, and the permanent blocker directory.

---

## ✅ Expected Output

- A new sequential archive folder containing all previously in-progress files.
- Refreshed `AGENTS_DOCS/INPROGRESS` scaffolding that reflects only actionable next tasks and recoverable blockers.
- Permanent blockers, if any, captured under `AGENTS_DOCS/TASK_ARCHIVE/BLOCKED` with clear prerequisites for resuming work.
- A short summary highlighting the changes for future agents.

---

## 🧠 Tips

- Keep numbering contiguous; never reuse an existing archive prefix.
- Always double-check `next_tasks.md` against the canonical backlog to avoid resurrecting outdated plans.
- Use the permanent blocker directory sparingly—only when recovery truly depends on unavailable capabilities.

---

## End of Command

Maintain consistent Markdown formatting manually; the legacy helper script `scripts/fix_markdown.py` remains retired.
