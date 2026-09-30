# AnaPPTSkills

A collection of AI Agent **Skills** for building **business / consulting analysis reports**. An LLM acts as "Analysis Lead + Data Analyst" and collaborates with the user through a standardized SOP to deliver a complete analysis report—from requirement intake to written report and PPT delivery.

## What this project is

AnaPPTSkills is not an executable program. It is a set of **Skills** that can be loaded by AI Agents (e.g. Trae, Claude Code). Each Skill declares its trigger conditions, interaction principles, and execution steps via a `SKILL.md` file, accompanied by templates and reference docs. When the Agent recognizes the user's intent in conversation, it drives the work forward following the structured flow defined by the Skill.

## What problem it solves

Writing analysis reports typically suffers from four pain points:

1. **Starting before requirements are clear**—audience, decision scenario, and success criteria are not aligned, leading to heavy rework.
2. **Uncontrollable process**—no quality gates, modeling decisions are made by gut feel, and draft reviews become a formality.
3. **Hard to resume after interruption**—state is lost across multi-turn conversations; switching sessions means re-explaining the background from scratch.
4. **Untrustworthy charts**—truncated axes, 3D effects, and area-encoded numbers make the visuals look rich while a single chart can cast doubt on every conclusion.

This project addresses them with one SOP plus three Skills:

- **Grill questioning mechanism**: Stage 0-1 keeps asking sharp questions until `report.yml` is locked. You cannot proceed until you can answer four questions: *Who is it for? Why now? What conclusions are needed? When is the deadline?*
- **Four decision gates** (A audience tiering, B modeling assessment, C framework review, D draft review) act as quality brakes.
- **Resume from breakpoint**: every deliverable is written to `_报告进度.md`; a new session reads it and continues from where it left off.
- **Modeling is opt-in by default**: unless goal type + data condition + delivery constraint all pass, no model is built—avoiding loss of interpretability.
- **Trustworthy charts**: every visual must first clear the *faithfulness* bar (proportional encoding, comparisons that carry their own reference point, no design tricks standing in for data) before expressiveness and elegance are even considered.
- **Whole-report review**: after delivery, `review-report` audits the text + PPT across five layers with a fresh-eyes pass, grading issues into `_审校报告.md` to drive optimization.

## Skills included

### 1. `setup-anappt`—Project initialization

Triggers: "initialize report project", "create analysis project", "start a new analysis report", etc.

Creates the standard directory structure:

```
<target-dir>/
├── report.yml           ← Report settings file (filled and locked in Stage 0-1)
├── _报告进度.md           ← Breakpoint-resume state file
└── data/                ← User data file directory
```

### 2. `analysis-report-builder`—Main report-building flow

Triggers: "make an analysis report", "business analysis", "operational analysis", "topic analysis", "competitive analysis", "walk the report SOP", etc.

Advances through 7 stages + 4 decision gates:

```
Stage 0-1 Requirement intake (grill questioning) → report.yml
        ↓
[Gate A] Audience tiering and report form
        ↓
Stage 2 Analysis framework and data needs (consulting / operational / hybrid)
        ↓
[Gate B] Whether to model (default: no) → [Gate C] Framework review
        ↓
Stage 3 Data preparation and confirmation → Stage 4 External info + preliminary validation + outline (incl. chart planning)
        ↓
Stage 5 Written report v1.0 → [Gate D] Draft review
        ↓
Stage 6 PPT (charts redrawn) → Stage 7 Optimization, delivery + retrospective
```

Per-stage actions: state the goal → produce deliverable from template → self-check completion criteria → present to user for confirmation → update progress file.

### 3. `review-report`—Whole-report review

Trigger words: "review this report", "audit the report", "check report quality", "report health-check", "check the text and PPT together", etc.

Reviews the **text report + PPT** as a whole. What it audits is the **conclusion–evidence chain**, not typos. It first gauges the risk tier by purpose to decide review depth, then runs a five-layer checklist:

```
grade → load anchors → five-layer review → fresh-eyes re-review (independent subagent) → write _审校报告.md → optimization loop
```

- **Five layers**: hard flaws (traceability / recompute / caliber / charts) → logic & conclusions (conclusion–evidence / correlation vs. causation / opposing view / back to the original question) → completeness & consistency (selective reporting / cross-references / text↔PPT) → audience & risk (fit / sensitive-compliance) → form.
- **Fresh eyes**: a subagent that does not share the writing context cold-reads the draft, breaking the author's completion blind spot.
- **Output**: issues graded **must-fix / suggestion / optional** into `_审校报告.md`, with an optimization queue sorted by severity; revise in the matching builder stage and re-run until must-fix items hit zero.

Runs after the builder's delivery, or standalone on any existing report—deeper than decision gate D / the Stage-6 reconciliation.

## Installation

Three installation methods are available—pick either one. The first two are the recommended paths; the third is only for special situations.

### Method 1: `npx skills add` (recommended)

Run the following command in your terminal to register the three Skills with the current AI Agent (e.g. Trae, Claude Code):

```bash
# Install from a GitHub repository
npx skills add https://github.com/sidneylyzhang/AnaPPTSkills

# Or install from a local path (after cloning the repo)
npx skills add ./AnaPPTSkills
```

Once complete, `setup-anappt`, `analysis-report-builder`, and `review-report` will be automatically registered in the Agent's Skills list.

### Method 2: Let the Agent self-install

Tell the Agent directly in conversation:

> "Please install the AnaPPTSkills skill set https://github.com/sidneylyzhang/AnaPPTSkills for me."

The Agent will recognize the intent and invoke `npx skills add` on its own to complete the installation and registration.

### Method 3: Local script install (special situations only)

> ⚠️ **Use this method only when one of the following special situations applies.** For normal scenarios, use Method 1 or 2.
>
> - `npx skills add` fails (network/npm registry issues, missing `skills` CLI, etc.)
> - The target machine cannot reach GitHub or npm
> - You need the Skills installed into the Trae CN global directory (`%USERPROFILE%\.trae-cn\skills\`) with live-edit support (source-code changes reflected immediately during development)
> - You need the Skills registered in Trae CN's `skill-config.json` (Method 1/2 does not maintain this file)

The repository ships a Windows batch installer in `scripts/`—double-click to run:

```bat
:: Default install: English output, source from ..\skills relative to script, target %USERPROFILE%\.trae-cn\skills\
install.bat

:: Chinese output
install.bat -cn

:: Dry run (print actions without performing them)
install.bat -whatif

:: Custom source/target paths
install.bat -Source "D:\my-fork\AnaPPTSkills\skills" -Target "C:\Users\me\.trae-cn\skills"
```

Script behavior:

- **Git-repo aware**: auto-detects whether the project is inside a git working tree. Yes → creates a symbolic link via `mklink /D` (cross-volume supported, source changes reflected immediately). No → copies files directly.
- **Auto UAC elevation**: creating a symbolic link requires admin or Developer Mode; the script requests UAC elevation only when the initial `mklink /D` fails.
- **Backup strategy**: if the target Skill directory already exists as a real directory, it is renamed to `<name>.bak.<timestamp>` before install; if it is a link, it is removed and recreated. Backup paths are printed at the end.
- **Auto-registers in `skill-config.json`**: writes all three Skills into `%USERPROFILE%\.trae-cn\skill-config.json` under `managedSkills` (value `user_upload`); existing entries are preserved. Writes use a temp file + Move-Item atomic replacement to avoid corruption.
- **PS 5.1 compatible**: `install.ps1` is pure ASCII (no BOM, no Chinese characters); Chinese strings live in `scripts/messages.zh.json` and are loaded only with `-cn`. This sidesteps the known PowerShell 5.1 parser failure on Chinese scripts.

See `scripts/install.bat -help`, or [ADR 0001](./docs/adr/0001-symlink-with-auto-elevation.md) for the symlink decision rationale.

## How to use

1. **Load the Skills**: follow any method in the [Installation](#installation) section above to complete registration.
2. **Initialize a project**: trigger `setup-anappt` in conversation to generate `report.yml`, `_报告进度.md`, and `data/` in the working directory.
3. **Build the report**: trigger `analysis-report-builder` to start Stage 0-1 grill questioning. Each stage auto-advances after user confirmation.
4. **Whole-report review**: after delivery, trigger `review-report` to audit the text + PPT across five layers with a fresh-eyes pass; issues are graded into `_审校报告.md`, then revise in the matching stage.
5. **Interrupt and resume**: say "stop", "change requirements", or "go back to stage X" at any time. To resume in a new session, simply trigger the main Skill again—it reads the progress file and continues from the breakpoint.

## Key features

- **Conclusion first**: both the written report and the PPT follow the pyramid principle; the title states the conclusion.
- **Trustworthy charts**: visuals follow the *faithfulness · expressiveness · elegance* doctrine, backed by one chart spec that runs through the whole flow—chart type chosen in Stage 2, chart planning set in Stage 4, charts drawn and read in Stage 5, redrawn and re-checked in Stage 6, with a per-chart checklist before delivery.
- **Audience adaptation**: three specs for management / business staff / external readers—same conclusion, tailored presentation in length, language, and evidence strength.
- **Actionable recommendations**: every recommendation specifies "who, does what, when, expected effect".
- **Traceable data**: every number traces back to the Stage 3 data snapshot; every external input is tagged with source and timeliness.
- **Retrospective**: Stage 7 outputs reusable templates, metrics definitions, and lessons learned, and asks whether to archive them.

## Language

Simplified Chinese by default. The report body follows the "conclusion + impact + recommendation" order and minimizes jargon; the management version annotates terms and gives every number a reference point.

## Acknowledgements

This project recommends pairing with the [dashi-ppt-skill](https://github.com/chuspeeism/dashi-ppt-skill) skill during **Stage 6 PPT generation**. Developed by **chuspeeism**, the skill quickly generates offline-viewable, browser-editable HTML presentations based on preset visual themes, with PPTX / PDF export support—fitting perfectly with this project's PPT delivery stage.

Special thanks to **chuspeeism** for open-sourcing this high-quality skill, which lets this project's PPT delivery focus on content and conclusion presentation while leaving layout and visual polish to a dedicated tool.

## License

This project is open-sourced under the [MIT License](./LICENSE), copyright © 2026 sidneylyzhang. You are free to use, modify, and distribute it, provided the original copyright notice is retained.
