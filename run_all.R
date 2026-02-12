# ==============================================================================
# Eurozone Crisis Analysis: Master Runner Script
# ==============================================================================
# Purpose: Run the full analysis pipeline with validation checks
# Usage: Rscript run_all.R
# ==============================================================================

cat("\n")
cat(strrep("=", 78), "\n")
cat("EUROZONE CRISIS ANALYSIS — FULL PIPELINE\n")
cat(strrep("=", 78), "\n")
cat("Started:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# ==============================================================================
# 0. Check Required Packages
# ==============================================================================

cat("Step 0: Checking required packages...\n")

if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman", repos = "https://cran.r-project.org")
}

required_packages <- c(
  "tidyverse", "lubridate", "zoo", "countrycode", "here",
  "knitr", "kableExtra", "psych", "moments", "stargazer",
  "scales", "gridExtra", "patchwork", "ggrepel", "gghighlight",
  "RColorBrewer", "viridis",
  "plm", "lmtest", "sandwich", "car", "tseries",
  "strucchange", "vars", "urca", "broom", "estimatr",
  "ggridges", "factoextra", "cluster"
)

pacman::p_load(char = required_packages)
cat("  All packages available.\n\n")

# ==============================================================================
# Helper: Validate outputs exist
# ==============================================================================

validate_files <- function(dir, expected_patterns, step_name) {
  missing <- character()
  for (pat in expected_patterns) {
    matches <- list.files(dir, pattern = pat)
    if (length(matches) == 0) missing <- c(missing, pat)
  }
  if (length(missing) > 0) {
    cat(sprintf("  WARNING: Missing after %s: %s\n", step_name,
                paste(missing, collapse = ", ")))
    return(FALSE)
  }
  return(TRUE)
}

results <- list()

# ==============================================================================
# 1. Data Collection (skip if raw data exists)
# ==============================================================================

cat(strrep("-", 78), "\n")
cat("Step 1: Checking raw data...\n")

raw_dir <- here::here("data/raw")
required_raw <- c(
  "eurostat_debt.csv", "eurostat_gdp.csv", "eurostat_unemployment.csv",
  "eurostat_inflation.csv", "eurostat_deficit.csv",
  "ecb_bond_yields.csv", "ecb_policy_rates.csv",
  "bailout_programs.csv", "crisis_events.csv"
)

missing_raw <- required_raw[!file.exists(file.path(raw_dir, required_raw))]
if (length(missing_raw) > 0) {
  cat("  Missing raw files:", paste(missing_raw, collapse = ", "), "\n")
  cat("  Running data collection script...\n")
  source("scripts/01_data_collection.R")
} else {
  cat("  All 9 raw data files present. Skipping data collection.\n")
}
results[["raw_data"]] <- length(missing_raw) == 0
cat("\n")

# ==============================================================================
# 2. Data Cleaning
# ==============================================================================

cat(strrep("-", 78), "\n")
cat("Step 2: Running data cleaning...\n\n")
source("scripts/02_data_cleaning.R")

processed_dir <- here::here("data/processed")
results[["cleaning"]] <- validate_files(
  processed_dir,
  c("eurozone_master\\.rds", "panel_data\\.rds", "spreads_wide\\.rds",
    "country_summary\\.csv"),
  "data cleaning"
)
if (results[["cleaning"]]) cat("  Validation passed: all processed data files created.\n")
cat("\n")

# ==============================================================================
# 3. Descriptive Statistics
# ==============================================================================

cat(strrep("-", 78), "\n")
cat("Step 3: Running descriptive statistics...\n\n")
source("scripts/03_descriptive_stats.R")

tables_dir <- here::here("outputs/tables")
results[["descriptive"]] <- validate_files(
  tables_dir,
  c("table1_overall_summary\\.csv", "table5_correlation_matrix\\.csv"),
  "descriptive stats"
)
if (results[["descriptive"]]) cat("  Validation passed: tables generated.\n")
cat("\n")

# ==============================================================================
# 4. Visualization
# ==============================================================================

cat(strrep("-", 78), "\n")
cat("Step 4: Running visualization...\n\n")
source("scripts/04_visualization.R")

figures_dir <- here::here("outputs/figures")
results[["visualization"]] <- validate_files(
  figures_dir,
  c("fig1_bond_yields\\.png", "fig2_sovereign_spreads\\.png",
    "fig13_fiscal_deficits\\.png"),
  "visualization"
)
n_figs <- length(list.files(figures_dir, pattern = "\\.png$"))
if (results[["visualization"]]) cat(sprintf("  Validation passed: %d figures generated.\n", n_figs))
cat("\n")

# ==============================================================================
# 5. Econometric Analysis
# ==============================================================================

cat(strrep("-", 78), "\n")
cat("Step 5: Running econometric analysis...\n\n")
source("scripts/05_econometric_analysis.R")

results[["econometrics"]] <- validate_files(
  tables_dir,
  c("regression_table_spreads\\.tex", "event_study_omt\\.csv",
    "pca_loadings\\.csv"),
  "econometric analysis"
)
if (results[["econometrics"]]) cat("  Validation passed: regression outputs generated.\n")
cat("\n")

# ==============================================================================
# Summary
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("PIPELINE SUMMARY\n")
cat(strrep("=", 78), "\n\n")

for (step_name in names(results)) {
  status <- if (results[[step_name]]) "PASS" else "FAIL"
  cat(sprintf("  %-20s [%s]\n", step_name, status))
}

n_tables <- length(list.files(tables_dir, pattern = "\\.(csv|tex|txt)$"))
n_figures <- length(list.files(figures_dir, pattern = "\\.png$"))
n_processed <- length(list.files(processed_dir))

cat(sprintf("\nOutputs: %d processed files, %d figures, %d tables\n",
            n_processed, n_figures, n_tables))

all_passed <- all(unlist(results))
if (all_passed) {
  cat("\nAll steps completed successfully.\n")
} else {
  cat("\nSome steps had issues. Review the output above.\n")
}

cat("\nFinished:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat(strrep("=", 78), "\n")
