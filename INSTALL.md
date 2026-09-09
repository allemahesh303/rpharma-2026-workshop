# Installation

Everything the workshop needs: **R >= 4.2**, 12 R packages, and **Python >= 3.8**
with `python-docx`. Budget 10–30 minutes, mostly download time.

Check where you stand at any point:

```bash
Rscript check_setup.R
```

Every line should read `[ OK ]` before the workshop starts.

---

## Quick start

From the repo root:

```bash
Rscript install_packages.R              # the 12 R packages
python3 -m pip install --user python-docx   # the Word-report dependency
Rscript check_setup.R                   # verify
```

[`install_packages.R`](install_packages.R) picks a package repository (pre-built
Linux binaries via Posit Public Package Manager where available), creates a
personal library if the system one is read-only, and installs only what is
missing. It is safe to re-run.

If that works, you are done — the rest of this file is the manual route and
troubleshooting.

---

## Manual installation

### 1. R packages

```r
# admiral / ADaM thread (Section A)
install.packages(c(
  "admiral", "dplyr", "lubridate",
  "pharmaversesdtm", "pharmaverseadam",
  "metacore", "xportr"
))

# Group sequential design thread (Section B)
install.packages(c(
  "gsDesign", "gsDesign2", "lrstat", "graphicalMCP", "jsonlite"
))
```

All 12 are on CRAN. `admiral >= 1.2.0` is required (current CRAN release is
1.5.0). `pharmaversesdtm` / `pharmaverseadam` supply the public
CDISC-conformant test data the admiral examples run against.

**On Linux, install the binaries instead of compiling.** `lrstat`, `gsDesign2`,
and `dplyr` all contain C/C++ that takes a long while to build from source.
Point R at Posit Public Package Manager first — substitute your distribution's
codename for `jammy` (`focal`, `jammy`, `noble`, `bookworm`, `rhel9`, …):

```r
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/latest"))
install.packages(c(
  "admiral", "dplyr", "lubridate", "pharmaversesdtm", "pharmaverseadam",
  "metacore", "xportr", "gsDesign", "gsDesign2", "lrstat",
  "graphicalMCP", "jsonlite"
))
```

Find your codename with `. /etc/os-release && echo $VERSION_CODENAME`. To make
the setting stick, add that `options(repos = ...)` line to `~/.Rprofile`.

On **Windows** and **macOS**, CRAN already serves binaries — plain
`install.packages()` is fine.

### 2. Python and `python-docx`

The group-sequential-design skill generates its Word report through Python.

```bash
# Linux / macOS
python3 -m pip install --user python-docx

# Windows
py -3 -m pip install python-docx
```

Verify — note that the import name is `docx`, not `python_docx`:

```bash
python3 -c "import docx; print(docx.__version__)"
```

Install `python-docx`, **not** the abandoned `docx` package on PyPI; they
collide on the same import name.

If you would rather keep it out of your user site-packages, a virtual
environment works, but `check_setup.R` and the skill both invoke whatever
`python3` is first on `PATH` — so activate the environment in the same shell you
launch R from.

---

## Troubleshooting

### `install.packages()` asks me to choose a CRAN mirror, or errors in `Rscript`

Your `repos` option is still the unresolved `@CRAN@` placeholder, which cannot
work non-interactively. Name a repository explicitly:

```r
options(repos = c(CRAN = "https://cloud.r-project.org"))
```

Check with `getOption("repos")`.

### `'lib' is not writable` / `unable to create ...`

The system library is root-owned — normal for R installed under `/opt` or
`/usr/lib`. Install into your personal library instead of using `sudo`:

```r
lib <- Sys.getenv("R_LIBS_USER")
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
install.packages("admiral", lib = lib)
```

`R_LIBS_USER` defaults to `~/R/<platform>-library/<R-version>` and R already
searches it, so nothing else needs configuring. Confirm with `.libPaths()`.

### Compilation fails on Linux

Either switch to the Posit Package Manager binaries (above) or install the
toolchain and headers:

```bash
# Debian / Ubuntu
sudo apt-get install -y build-essential libcurl4-openssl-dev libssl-dev \
                        libxml2-dev libfontconfig1-dev libfreetype6-dev

# RHEL / Fedora / Rocky
sudo dnf install -y gcc gcc-c++ make libcurl-devel openssl-devel libxml2-devel
```

### `check_setup.R` says "no working Python >= 3.8 found on PATH" on Windows

`python3.exe` in `WindowsApps` is Microsoft's App Execution Alias stub, not a
real interpreter. Install Python from [python.org](https://www.python.org/downloads/)
(tick **Add python.exe to PATH**) or from the Microsoft Store, then reopen your
terminal so the new `PATH` is picked up. `check_setup.R` also tries `py -3`,
which the python.org installer provides.

### `cannot 'import docx'` even though pip reported success

pip installed into a different interpreter than the one `check_setup.R` found.
Install through the *same* interpreter rather than the bare `pip` command:

```bash
python3 -m pip install --user python-docx    # same python3 that R will call
python3 -m pip show python-docx              # confirm Location
```

If you use conda, activate the environment before launching R.

### A package installs but `library()` warns about a version conflict

Restart R. Loading a package while an older copy of a dependency is already
attached in the session produces spurious errors.

---

## Also useful

- **Rscript path** — the group-sequential-design skill writes and executes R, so
  set the *Rscript path* line in [`CLAUDE.md`](CLAUDE.md) to your local
  interpreter. Find it with `which Rscript` (Linux/macOS) or
  `where Rscript` (Windows).
- **Offline or restricted network?** Bring a machine with the packages already
  installed, or mirror them ahead of time — the skills themselves need no
  network access at run time, only the packages.
