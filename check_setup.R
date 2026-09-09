# check_setup.R --------------------------------------------------------------
#
# R/Pharma 2026 Workshop — environment check.
# Run from the repo root:  source("check_setup.R")
#
# Verifies R version, the two package sets (admiral / group sequential design),
# and Python + python-docx for the GSD Word-report step. Prints a pass/fail
# summary. If every line is [ OK ] you are ready to start.
#
# This only checks; it installs nothing. See README.md for install commands.
# --------------------------------------------------------------------------

# Base R only — no dependency on any package being installed yet.

.results <- new.env()
.results$rows <- list()

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a)) b else a

record <- function(status, label, detail = "") {
  # status: "OK", "FAIL", or "WARN"
  .results$rows[[length(.results$rows) + 1]] <- list(
    status = status, label = label, detail = detail
  )
  tag <- switch(status,
    OK   = "[ OK ]",
    FAIL = "[FAIL]",
    WARN = "[WARN]"
  )
  line <- sprintf("%s  %-34s %s", tag, label, detail)
  message(trimws(line, which = "right"))
  invisible(NULL)
}

check_pkg <- function(pkg, min_version = NULL, group = "") {
  label <- if (nzchar(group)) sprintf("%s (%s)", pkg, group) else pkg
  ok <- requireNamespace(pkg, quietly = TRUE)
  if (!ok) {
    record("FAIL", label, "not installed")
    return(invisible(FALSE))
  }
  ver <- tryCatch(as.character(utils::packageVersion(pkg)), error = function(e) NA_character_)
  if (!is.null(min_version) && !is.na(ver) &&
      utils::compareVersion(ver, min_version) < 0) {
    record("WARN", label, sprintf("%s installed; >= %s expected", ver, min_version))
    return(invisible(FALSE))
  }
  record("OK", label, ver %||% "installed")
  invisible(TRUE)
}

# -- R version -------------------------------------------------------------

message("\n== R ==")
r_ver <- paste(R.version$major, R.version$minor, sep = ".")
if (utils::compareVersion(r_ver, "4.2.0") < 0) {
  record("FAIL", "R version", sprintf("%s installed; >= 4.2 required", r_ver))
} else {
  record("OK", "R version", r_ver)
}

# -- admiral thread (Section A) -----------------------------------------------

message("\n== admiral / ADaM packages (Section A) ==")
check_pkg("admiral", min_version = "1.2.0", group = "core")
check_pkg("dplyr",             group = "core")
check_pkg("lubridate",         group = "core")
check_pkg("pharmaversesdtm",   group = "test data")
check_pkg("pharmaverseadam",   group = "test data")
check_pkg("metacore",          group = "submission output")
check_pkg("xportr",            group = "submission output")

# -- group sequential design thread (Section B) -----------------------------

message("\n== Group sequential design packages (Section B) ==")
check_pkg("gsDesign",     group = "boundaries")
check_pkg("gsDesign2",    group = "boundaries")
check_pkg("lrstat",       group = "verification")
check_pkg("graphicalMCP", group = "multiplicity")
check_pkg("jsonlite",     group = "results I/O")

# -- Python + python-docx (Section B report) --------------------------------

message("\n== Python (GSD Word report) ==")

# Probe a candidate interpreter. Returns NULL if it is not a real, working
# Python >= 3.8. This deliberately weeds out the Windows "App execution alias"
# stub at ...\WindowsApps\python3.exe, which exits non-zero and prints a
# "install from the Microsoft Store" message instead of a version.
try_python <- function(cmd) {
  if (length(cmd) == 1 && !nzchar(Sys.which(cmd[1]))) return(NULL)
  out <- tryCatch(
    suppressWarnings(system2(cmd[1], c(cmd[-1], "--version"),
                             stdout = TRUE, stderr = TRUE)),
    error = function(e) NULL
  )
  status <- attr(out, "status") %||% 0
  txt <- paste(out %||% "", collapse = " ")
  if (!is.null(status) && status != 0) return(NULL)
  if (grepl("Microsoft Store|was not found", txt, ignore.case = TRUE)) return(NULL)
  m <- regmatches(txt, regexpr("3\\.[0-9]+(\\.[0-9]+)?", txt))
  if (length(m) == 0) return(NULL)
  minor <- as.integer(sub("^3\\.([0-9]+).*", "\\1", m))
  list(cmd = cmd, version = m, ok_version = !is.na(minor) && minor >= 8)
}

py_candidates <- list("python3", "python", c("py", "-3"), "py")
py <- NULL
for (cand in py_candidates) {
  hit <- try_python(cand)
  if (!is.null(hit)) { py <- hit; break }
}

if (is.null(py)) {
  record("FAIL", "python", "no working Python >= 3.8 found on PATH")
  record("FAIL", "python-docx", "skipped — Python not available")
} else {
  cmd_str <- paste(py$cmd, collapse = " ")
  if (isTRUE(py$ok_version)) {
    record("OK", "python", sprintf("%s (%s)", py$version, cmd_str))
  } else {
    record("WARN", "python", sprintf("%s found; >= 3.8 expected (%s)", py$version, cmd_str))
  }
  docx_ok <- tryCatch(
    suppressWarnings(system2(py$cmd[1], c(py$cmd[-1], "-c", shQuote("import docx")),
                             stdout = FALSE, stderr = FALSE)) == 0,
    error = function(e) FALSE
  )
  if (isTRUE(docx_ok)) {
    record("OK", "python-docx", "import docx OK")
  } else {
    record("FAIL", "python-docx", "cannot 'import docx' — pip install python-docx")
  }
}

# -- Summary ---------------------------------------------------------------

statuses <- vapply(.results$rows, function(r) r$status, character(1))
n_fail <- sum(statuses == "FAIL")
n_warn <- sum(statuses == "WARN")
n_ok   <- sum(statuses == "OK")

message("\n", strrep("-", 60))
message(sprintf("Summary:  %d OK   %d WARN   %d FAIL", n_ok, n_warn, n_fail))

if (n_fail == 0 && n_warn == 0) {
  message("All checks passed — you are ready to start.")
} else if (n_fail == 0) {
  message("No blockers, but review the WARN lines above.")
} else {
  message("Some checks FAILED. Fix these before the workshop:")
  for (r in .results$rows) {
    if (r$status == "FAIL") message("  - ", r$label, ": ", r$detail)
  }
  message("\nInstall commands are in README.md.")
}
message(strrep("-", 60))

# Non-zero exit when run via `Rscript check_setup.R` and something failed.
if (!interactive() && n_fail > 0) quit(status = 1, save = "no")

invisible(list(ok = n_ok, warn = n_warn, fail = n_fail))
