# R/Pharma 2026 Workshop — AI Skills for Clinical Trial Design & ADaM Derivation

A hands-on workshop, to be delivered at **R/Pharma 2026**, on using Claude Code
*skills* to accelerate two common clinical-programming tasks:

1. **Deriving ADaM analysis datasets** (ADSL, ADAE, ADVS/ADLB) from SDTM with the
   [{admiral}](https://pharmaverse.github.io/admiral/) R package.
2. **Designing group sequential trials** for survival endpoints — boundaries,
   sample size, multiplicity, and simulation-based verification.

**Slides:** <https://jeffreyad.github.io/rpharma-2026-workshop/>

## What you'll learn

- What an agent *skill* is (a `SKILL.md` workflow plus supporting references and
  scripts) and how Claude Code picks one up.
- How the admiral skills encode function-selection logic and CDISC conventions so
  the agent writes QC-ready, submission-traceable R — with `# REVIEW:` markers at
  every protocol-specific decision.
- How to go from a trial scenario to a fully specified group sequential design
  and a Word report, with the design verified by `lrstat` simulation.
- How to run these skills yourself: install once, then drive them by describing
  the task in natural language.

You will clone this repo and run the skills live during the session.

## Included skills

| Skill | One-line description |
|---|---|
| [`skills/admiral`](skills/admiral/) | Parent skill — shared admiral conventions: library setup, native-pipe / `exprs()` style, date-imputation rules, `"Y"`/`NA` flag convention, `# REVIEW:` annotation and `stopifnot()` QC patterns. |
| [`skills/admiral/admiral-adsl`](skills/admiral/admiral-adsl/) | Derive the ADaM Subject-Level Analysis Dataset (ADSL) from SDTM DM/EX/DS — treatment dates, disposition, demographics, and population flags. |
| [`skills/admiral/admiral-adae`](skills/admiral/admiral-adae/) | Derive the ADaM Adverse Events dataset (ADAE) from SDTM AE + ADSL — treatment-emergent flag, severity, seriousness, causality, and study-day variables. |
| [`skills/admiral/admiral-bds`](skills/admiral/admiral-bds/) | Derive ADaM BDS findings datasets (ADVS, ADLB) — parameter assignment, baseline flagging, change from baseline, visit windowing, and ADLB normal-range derivations. |
| [`skills/group-sequential-design`](skills/group-sequential-design/) | Design group sequential trials for survival endpoints (OS, PFS, DFS): spending-function boundaries, N-first sample sizing, graphical multiplicity, NPH sensitivity, `lrstat` verification, and a template-driven Word report. |

## Setup

### 1. Clone

```bash
git clone https://github.com/jeffreyad/rpharma-2026-workshop.git
cd rpharma-2026-workshop
```

### 2. Install the dependencies

Use **R >= 4.2** (the skills were exercised on R 4.4.1) and, for the
group-sequential-design report step, **Python >= 3.8**.

```bash
Rscript install_packages.R                  # the 12 R packages
python3 -m pip install --user python-docx   # Word-report dependency
```

### 3. Verify

```bash
Rscript check_setup.R
```

Every line should read `[ OK ]`. If anything fails — a read-only R library, a CRAN
mirror prompt, a compile error, a Python that pip and R disagree about — see
[`INSTALL.md`](INSTALL.md) for the manual commands and per-platform fixes.

### 4. Point Claude Code at the skills

**Option A — use this repo as your project.** Open this folder in Claude Code.
The root [`CLAUDE.md`](CLAUDE.md) tells the agent where each skill lives and asks
you to set your local **Rscript path** (needed by the GSD skill, which executes
R). Then just describe a task:

> Derive ADSL from the SDTM DM, EX, and DS domains for this study.

> Design a Phase 3 trial for first-line metastatic NSCLC with co-primary PFS and
> OS, 1:1 randomization, target HR 0.70 for OS.

**Option B — install into another project.** Copy (or symlink) a skill folder
into that project's agent skills directory, e.g. for Claude Code:

```bash
cp -r skills/group-sequential-design ~/.claude/skills/
cp -r skills/admiral                 ~/.claude/skills/
# or symlink to keep them updated with `git pull`
ln -s "$(pwd)/skills/admiral" ~/.claude/skills/admiral
```

**Option C — install from the upstream project with the `skills` CLI:**

```bash
npx skills add RConsortium/pharma-skills --skill admiral-adsl --skill group-sequential-design
```

## Credits

Every skill here is copied — without changes to its derivation logic — from the
R Consortium **[`pharma-skills`](https://github.com/RConsortium/pharma-skills)**
project, part of the R Consortium Submissions Working Group **Pilot 7** (a joint
effort with the [BBSW AI committee](https://www.bbsw.org/ai-committee)).

| Skill | Author | Copyright |
|---|---|---|
| `admiral`, `admiral-adsl`, `admiral-adae`, `admiral-bds` | **Jeff Dickinson** (Navitas Data Sciences; admiral Core Team) | © 2026 Jeff Dickinson, Navitas Data Sciences |
| `group-sequential-design` | **Eric Zhang** | © 2026 Eric Zhang |

Each skill directory retains its original `LICENSE` file. See [`LICENSE`](LICENSE)
for the repository license (MIT).

## Go deeper after the workshop

- **Source project:** https://github.com/RConsortium/pharma-skills — full catalog
  (also `sdtm-oak`, `clinical-trial-simulation`, `statistical-reviewer`,
  `rounding`, and more), the skill development
  [lifecycle](https://github.com/RConsortium/pharma-skills/blob/main/LIFECYCLE.md),
  and community benchmarking.
- **admiral:** https://pharmaverse.github.io/admiral/ · [CDISC ADaMIG v1.3](https://www.cdisc.org/standards/foundational/adam)
- **gsDesign:** https://cran.r-project.org/package=gsDesign · **gsDesign2:** https://cran.r-project.org/package=gsDesign2 · **lrstat:** https://cran.r-project.org/package=lrstat
- **Submissions Working Group:** https://rconsortium.github.io/submissions-wg/

## Disclaimer

These skills produce **drafting aids, not validated deliverables**. LLM output
can be wrong or vary between runs — always independently verify generated code
and results against your own QC process before they inform any regulatory,
clinical, safety, or GxP-regulated activity, and comply with your organization's
policies. The skills bundle scripts that execute in your environment; review a
skill's contents before running it and only supply data you are permitted to use.
Provided as-is under the MIT License, with no warranty or endorsement from the
R Consortium, the BBSW AI committee, or any contributor's employer.
