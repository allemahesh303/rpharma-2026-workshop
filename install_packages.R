# install_packages.R --------------------------------------------------------
#
# R/Pharma 2026 Workshop — install the R packages the skills need.
# Run from the repo root:
#
#   Rscript install_packages.R      # or  source("install_packages.R") in R
#
# What it does:
#   * picks a CRAN repository (pre-compiled binaries where available),
#   * makes sure there is a *writable* library to install into,
#   * installs only the packages that are missing or too old,
#   * tells you what is left to do (Python side) at the end.
#
# It does not touch packages that are already installed and new enough.
# Verify afterwards with:  Rscript check_setup.R
# --------------------------------------------------------------------------

# Base R only — nothing is assumed to be installed yet.

# -- what we need ----------------------------------------------------------

# name = minimum version ("" = any version)
required <- c(
  # admiral / ADaM thread (Section A)
  admiral          = "1.2.0",
  dplyr            = "",
  lubridate        = "",
  pharmaversesdtm  = "",
  pharmaverseadam  = "",
  metacore         = "",
  xportr           = "",
  # group sequential design thread (Section B)
  gsDesign         = "",
  gsDesign2        = "",
  lrstat           = "",
  graphicalMCP     = "",
  jsonlite         = ""
)

# -- 1. repository ---------------------------------------------------------

# Posit Public Package Manager serves pre-built Linux binaries for the common
# distributions, which avoids compiling lrstat / gsDesign2 / dplyr from source
# (minutes instead of tens of minutes). Everywhere else, CRAN already ships
# binaries for Windows and macOS.
ppm_linux_repo <- function() {
  if (Sys.info()[["sysname"]] != "Linux" || !file.exists("/etc/os-release")) {
    return(NULL)
  }
  os <- tryCatch(readLines("/etc/os-release", warn = FALSE), error = function(e) character())
  field <- function(key) {
    hit <- grep(paste0("^", key, "="), os, value = TRUE)
    if (length(hit) == 0) return(NA_character_)
    gsub('"', "", sub(paste0("^", key, "="), "", hit[1]))
  }
  id <- field("ID")
  codename <- field("VERSION_CODENAME")
  version <- field("VERSION_ID")

  slug <- NULL
  if (identical(id, "ubuntu") && codename %in% c("focal", "jammy", "noble")) {
    slug <- codename
  } else if (identical(id, "debian") && codename %in% c("bullseye", "bookworm")) {
    slug <- codename
  } else if (id %in% c("rhel", "centos", "rocky", "almalinux") && !is.na(version)) {
    major <- sub("\\..*$", "", version)
    if (major %in% c("8", "9")) slug <- paste0("rhel", major)
  } else if (identical(id, "opensuse-leap") && !is.na(version)) {
    slug <- paste0("opensuse", sub("\\..*$", "", version))
  }
  if (is.null(slug)) return(NULL)
  sprintf("https://packagemanager.posit.co/cran/__linux__/%s/latest", slug)
}

repo <- ppm_linux_repo()
if (is.null(repo)) {
  # getOption("repos") is often the unresolved "@CRAN@" placeholder, which makes
  # install.packages() stop and ask for a mirror. Name one explicitly.
  repo <- "https://cloud.r-project.org"
  message("Repository: ", repo, " (source install on Linux; binaries on Windows/macOS)")
} else {
  message("Repository: ", repo, " (pre-built Linux binaries)")
}
options(repos = c(CRAN = repo))

# -- 2. a writable library -------------------------------------------------

# The system library is usually root-owned. Fall back to the per-user library
# R already looks in (R_LIBS_USER), creating it if needed.
writable <- .libPaths()[file.access(.libPaths(), 2) == 0]
if (length(writable) == 0) {
  lib <- Sys.getenv("R_LIBS_USER")
  if (!nzchar(lib)) {
    stop("No writable library and R_LIBS_USER is unset. Set R_LIBS_USER and re-run.")
  }
  lib <- strsplit(lib, .Platform$path.sep, fixed = TRUE)[[1]][1]
  if (!dir.exists(lib)) {
    dir.create(lib, recursive = TRUE)
    message("Created personal library: ", lib)
  }
  .libPaths(c(lib, .libPaths()))
} else {
  lib <- writable[1]
}
message("Installing into: ", lib, "\n")

# -- 3. work out what is missing -------------------------------------------

needs_install <- function(pkg, min_version) {
  if (!requireNamespace(pkg, quietly = TRUE)) return(TRUE)
  if (!nzchar(min_version)) return(FALSE)
  ver <- tryCatch(as.character(utils::packageVersion(pkg)),
                  error = function(e) NA_character_)
  is.na(ver) || utils::compareVersion(ver, min_version) < 0
}

todo <- names(required)[vapply(names(required),
                               function(p) needs_install(p, required[[p]]),
                               logical(1))]

if (length(todo) == 0) {
  message("All required R packages are already installed and up to date.")
} else {
  message("To install (", length(todo), "): ", paste(todo, collapse = ", "), "\n")
  install.packages(todo, lib = lib, dependencies = TRUE)
}

# -- 4. report -------------------------------------------------------------

message("\n", strrep("-", 60))
failed <- character()
for (pkg in names(required)) {
  if (needs_install(pkg, required[[pkg]])) failed <- c(failed, pkg)
}
if (length(failed) == 0) {
  message("R packages: all present.")
} else {
  message("Still missing or out of date: ", paste(failed, collapse = ", "))
  message("Scroll up for the installation errors. Common causes are listed in INSTALL.md.")
}
message("\nStill needed for the group-sequential-design report step:")
message("  python3 -m pip install --user python-docx")
message("\nThen verify everything with:  Rscript check_setup.R")
message(strrep("-", 60))

invisible(failed)
