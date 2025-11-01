# Next Tasks — Post-Archive Focus

## 🔬 Capture macOS Benchmark Baselines
- **Objective:** Run `SpecificationKitBenchmarks` on macOS hardware (release configuration) and record timing/memory metrics for spec evaluation, macro compilation, and wrapper overhead.
- **How:** Trigger the `.github/workflows/ci.yml` macOS job or schedule a manual run on available hardware. Export the results into `AGENTS_DOCS/TASK_ARCHIVE/4_Benchmarking_Infrastructure/` and surface highlights in `AGENTS_DOCS/markdown/00_SpecificationKit_TODO.md` §11.
- **References:** Archived task log (`AGENTS_DOCS/TASK_ARCHIVE/5_Capture_Benchmark_Baselines/2025-10-31_NextTask_Benchmark_Baselines.md`), benchmarking summary in the same folder, and the roadmap checklist (`AGENTS_DOCS/markdown/3.0.0/tasks/03_performance_tasks.md` §P2.1).

## 🚀 Outline P2.2 AnySpecification Optimization Plan
- **Objective:** Translate fresh baseline data into an optimization roadmap for AnySpecification scenarios per §P2.2.
- **How:** Review `AGENTS_DOCS/markdown/3.0.0/tasks/03_performance_tasks.md` and capture hypotheses plus experiment staging in a new dated research log within `AGENTS_DOCS/INPROGRESS/`.
- **Dependencies:** Completion of the baseline run above to anchor performance targets.

## ⚙️ Improve Linux Benchmark Coverage
- **Objective:** Identify approaches that let benchmark coverage run in Linux-based CI despite CoreData restrictions.
- **How:** Investigate conditional compilation, alternative fixtures, or skip lists and summarize findings in a dedicated log. Coordinate with infrastructure stakeholders if additional tooling is required.
- **References:** Historical context in `AGENTS_DOCS/TASK_ARCHIVE/4_Benchmarking_Infrastructure/Summary_of_Work.md` and the archived blocker notes under `AGENTS_DOCS/TASK_ARCHIVE/5_Capture_Benchmark_Baselines/blocked.md`.
