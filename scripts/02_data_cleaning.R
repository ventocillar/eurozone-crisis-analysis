# ==============================================================================
# Eurozone Crisis Analysis: Data Cleaning and Preparation Script
# ==============================================================================
# Purpose: Clean, merge, and prepare analysis-ready datasets
# Author: Generated for Eurozone Crisis Thesis Analysis
# Date: November 2025
# ==============================================================================

# Clear environment
rm(list = ls())

# Load required packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse,     # Data manipulation
  lubridate,     # Date handling
  zoo,           # Time series functions (na.approx for interpolation)
  countrycode,   # Country code conversion
  here           # File path management
)

# ==============================================================================
# Configuration
# ==============================================================================

# Data directories
raw_dir <- here("data/raw")
processed_dir <- here("data/processed")
if (!dir.exists(processed_dir)) dir.create(processed_dir, recursive = TRUE)

# Country mapping
country_mapping <- tibble(
  iso2 = c("EL", "IE", "IT", "PT", "ES", "DE", "FR", "NL", "AT"),
  iso3 = c("GRC", "IRL", "ITA", "PRT", "ESP", "DEU", "FRA", "NLD", "AUT"),
  country_name = c("Greece", "Ireland", "Italy", "Portugal", "Spain",
                   "Germany", "France", "Netherlands", "Austria"),
  country_group = c("GIIPS", "GIIPS", "GIIPS", "GIIPS", "GIIPS",
                    "Core", "Core", "Core", "Core")
)

cat(strrep("=", 78), "\n")
cat("EUROZONE CRISIS DATA CLEANING AND PREPARATION\n")
cat(strrep("=", 78), "\n\n")

# ==============================================================================
# 1. Load Raw Data
# ==============================================================================

cat("1. Loading raw data files...\n\n")

## 1.1 Eurostat data
cat("  Loading Eurostat data...\n")
debt_data <- read_csv(file.path(raw_dir, "eurostat_debt.csv"), show_col_types = FALSE)
gdp_data <- read_csv(file.path(raw_dir, "eurostat_gdp.csv"), show_col_types = FALSE)
unemp_data <- read_csv(file.path(raw_dir, "eurostat_unemployment.csv"), show_col_types = FALSE)
infl_data <- read_csv(file.path(raw_dir, "eurostat_inflation.csv"), show_col_types = FALSE)
deficit_data <- read_csv(file.path(raw_dir, "eurostat_deficit.csv"), show_col_types = FALSE)
cat("    ✓ Eurostat data loaded\n")

## 1.2 ECB data
cat("  Loading ECB data...\n")
bond_yields <- read_csv(file.path(raw_dir, "ecb_bond_yields.csv"), show_col_types = FALSE)
ecb_rates <- read_csv(file.path(raw_dir, "ecb_policy_rates.csv"), show_col_types = FALSE)
cat("    ✓ ECB data loaded\n")

## 1.3 OECD data (if available)
cat("  Loading OECD data...\n")
if (file.exists(file.path(raw_dir, "oecd_current_account.csv"))) {
  current_account <- read_csv(file.path(raw_dir, "oecd_current_account.csv"), show_col_types = FALSE)
  cat("    ✓ OECD current account data loaded\n")
} else {
  current_account <- NULL
  cat("    ! OECD current account data not found\n")
}

if (file.exists(file.path(raw_dir, "oecd_unit_labor_costs.csv"))) {
  ulc_data <- read_csv(file.path(raw_dir, "oecd_unit_labor_costs.csv"), show_col_types = FALSE)
  cat("    ✓ OECD unit labor costs loaded\n")
} else {
  ulc_data <- NULL
  cat("    ! OECD unit labor costs not found\n")
}

## 1.4 Manual data
cat("  Loading manual data...\n")
bailout_programs <- read_csv(file.path(raw_dir, "bailout_programs.csv"), show_col_types = FALSE)
crisis_events <- read_csv(file.path(raw_dir, "crisis_events.csv"), show_col_types = FALSE)
cat("    ✓ Manual data loaded\n\n")

# ==============================================================================
# 2. Standardize Country Codes and Dates
# ==============================================================================

cat("2. Standardizing country codes and dates...\n\n")

# Function to standardize country codes
standardize_country_codes <- function(data, code_col = "country") {
  data %>%
    mutate(
      country_clean = case_when(
        .data[[code_col]] == "EL" ~ "Greece",
        .data[[code_col]] == "GR" ~ "Greece",
        .data[[code_col]] == "GRC" ~ "Greece",
        .data[[code_col]] == "IE" ~ "Ireland",
        .data[[code_col]] == "IRL" ~ "Ireland",
        .data[[code_col]] == "IT" ~ "Italy",
        .data[[code_col]] == "ITA" ~ "Italy",
        .data[[code_col]] == "PT" ~ "Portugal",
        .data[[code_col]] == "PRT" ~ "Portugal",
        .data[[code_col]] == "ES" ~ "Spain",
        .data[[code_col]] == "ESP" ~ "Spain",
        .data[[code_col]] == "DE" ~ "Germany",
        .data[[code_col]] == "DEU" ~ "Germany",
        .data[[code_col]] == "FR" ~ "France",
        .data[[code_col]] == "FRA" ~ "France",
        .data[[code_col]] == "NL" ~ "Netherlands",
        .data[[code_col]] == "NLD" ~ "Netherlands",
        .data[[code_col]] == "AT" ~ "Austria",
        .data[[code_col]] == "AUT" ~ "Austria",
        TRUE ~ as.character(.data[[code_col]])
      )
    ) %>%
    select(-all_of(code_col)) %>%
    rename(country = country_clean)
}

# Apply standardization
debt_clean <- standardize_country_codes(debt_data)
gdp_clean <- standardize_country_codes(gdp_data)
unemp_clean <- standardize_country_codes(unemp_data)
infl_clean <- standardize_country_codes(infl_data)
deficit_clean <- standardize_country_codes(deficit_data)

if (!is.null(current_account)) {
  current_account_clean <- standardize_country_codes(current_account)
} else {
  current_account_clean <- NULL
}

if (!is.null(ulc_data)) {
  ulc_clean <- standardize_country_codes(ulc_data)
} else {
  ulc_clean <- NULL
}

cat("  ✓ Country codes standardized\n\n")

# ==============================================================================
# 3. Convert Monthly Bond Yields to Quarterly
# ==============================================================================

cat("3. Converting bond yields to quarterly frequency...\n\n")

# Standardize bond yield country codes (ECB uses 2-letter codes)
bond_yields <- standardize_country_codes(bond_yields)

bond_yields_quarterly <- bond_yields %>%
  mutate(
    year = year(date),
    quarter = quarter(date),
    year_quarter = paste0(year, "Q", quarter)
  ) %>%
  group_by(country, year, quarter) %>%
  summarise(
    bond_yield = mean(bond_yield, na.rm = TRUE),
    date = floor_date(first(date), "quarter"),
    .groups = "drop"
  ) %>%
  select(country, date, bond_yield)

cat("  ✓ Bond yields converted to quarterly\n\n")

# ==============================================================================
# 4. Calculate Sovereign Spreads (vs German Bunds)
# ==============================================================================

cat("4. Calculating sovereign spreads over German Bunds...\n\n")

# Extract German bond yields
german_yields <- bond_yields_quarterly %>%
  filter(country == "Germany") %>%
  select(date, german_yield = bond_yield)

# Calculate spreads for all countries
spreads_data <- bond_yields_quarterly %>%
  left_join(german_yields, by = "date") %>%
  mutate(
    spread_bps = (bond_yield - german_yield) * 100,  # Convert to basis points
    spread_bps = ifelse(country == "Germany", 0, spread_bps)  # Germany spread = 0
  ) %>%
  select(country, date, bond_yield, spread_bps)

cat("  ✓ Sovereign spreads calculated\n")
cat(sprintf("  ✓ Average spreads calculated for %d country-quarters\n\n",
            nrow(spreads_data)))

# ==============================================================================
# 5. Merge All Macroeconomic Data
# ==============================================================================

cat("5. Merging all macroeconomic datasets...\n\n")

# Start with debt data as base
master_data <- debt_clean %>%
  # Join GDP
  left_join(gdp_clean, by = c("country", "date")) %>%
  # Join unemployment
  left_join(unemp_clean, by = c("country", "date")) %>%
  # Join inflation
  left_join(infl_clean, by = c("country", "date")) %>%
  # Join deficit
  left_join(deficit_clean, by = c("country", "date")) %>%
  # Join spreads and bond yields
  left_join(spreads_data, by = c("country", "date"))

# Join OECD data if available
if (!is.null(current_account_clean)) {
  master_data <- master_data %>%
    left_join(current_account_clean, by = c("country", "date"))
}

if (!is.null(ulc_clean)) {
  master_data <- master_data %>%
    left_join(ulc_clean, by = c("country", "date"))
}

# Add country group classification
master_data <- master_data %>%
  left_join(
    country_mapping %>% select(country_name, country_group),
    by = c("country" = "country_name")
  )

cat("  ✓ All datasets merged\n")
cat(sprintf("  ✓ Master dataset: %d observations, %d variables\n\n",
            nrow(master_data), ncol(master_data)))

# ==============================================================================
# 6. Handle Missing Values
# ==============================================================================

cat("6. Handling missing values...\n\n")

# Check missing values before interpolation
missing_summary <- master_data %>%
  summarise(across(where(is.numeric), ~sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "missing_count") %>%
  filter(missing_count > 0) %>%
  arrange(desc(missing_count))

if (nrow(missing_summary) > 0) {
  cat("  Missing values detected:\n")
  print(missing_summary, n = Inf)
  cat("\n")
}

# Interpolate missing values for time series (within country)
master_data <- master_data %>%
  arrange(country, date) %>%
  group_by(country) %>%
  mutate(
    across(
      c(debt_gdp, gdp_growth, unemployment, inflation, deficit_gdp,
        bond_yield, spread_bps),
      ~zoo::na.approx(., na.rm = FALSE, maxgap = 2)
    )
  ) %>%
  ungroup()

# Check remaining missing values
missing_after <- master_data %>%
  summarise(across(where(is.numeric), ~sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "missing_count") %>%
  filter(missing_count > 0)

if (nrow(missing_after) > 0) {
  cat("  Remaining missing values after interpolation:\n")
  print(missing_after, n = Inf)
  cat("\n")
} else {
  cat("  ✓ All missing values handled\n\n")
}

# ==============================================================================
# 7. Add Time Period Variables
# ==============================================================================

cat("7. Creating time period variables...\n\n")

master_data <- master_data %>%
  mutate(
    year = year(date),
    quarter = quarter(date),
    year_quarter = paste0(year, "Q", quarter),

    # Period classification
    period = case_when(
      year == 2008 ~ "Pre-Crisis",
      year >= 2009 & year <= 2012 ~ "Crisis",
      year >= 2013 & year <= 2015 ~ "Recovery",
      TRUE ~ "Other"
    ),

    # Crisis dummy
    crisis_period = ifelse(year >= 2009 & year <= 2012, 1, 0),

    # Post-OMT dummy (after July 2012)
    post_omt = ifelse(date >= as.Date("2012-07-01"), 1, 0),

    # GIIPS dummy
    giips = ifelse(country_group == "GIIPS", 1, 0)
  )

cat("  ✓ Time period variables created\n\n")

# ==============================================================================
# 8. Add ECB Policy Rate
# ==============================================================================

cat("8. Adding ECB policy rates to master dataset...\n\n")

# Convert ECB rates to quarterly (take last value of quarter)
ecb_rates_quarterly <- ecb_rates %>%
  mutate(
    year = year(date),
    quarter = quarter(date),
    quarter_date = floor_date(date, "quarter")
  ) %>%
  group_by(quarter_date) %>%
  summarise(ecb_rate = last(ecb_rate), .groups = "drop") %>%
  rename(date = quarter_date)

# Merge with master data
master_data <- master_data %>%
  left_join(ecb_rates_quarterly, by = "date")

cat("  ✓ ECB policy rates added\n\n")

# ==============================================================================
# 9. Create Derived Variables
# ==============================================================================

cat("9. Creating derived variables and transformations...\n\n")

master_data <- master_data %>%
  group_by(country) %>%
  arrange(date) %>%
  mutate(
    # Lagged variables (for regression analysis)
    debt_gdp_lag1 = lag(debt_gdp, 1),
    deficit_gdp_lag1 = lag(deficit_gdp, 1),
    gdp_growth_lag1 = lag(gdp_growth, 1),

    # Changes
    debt_change = debt_gdp - lag(debt_gdp, 1),
    spread_change = spread_bps - lag(spread_bps, 1),

    # Rolling averages (4-quarter)
    debt_gdp_ma4 = zoo::rollmean(debt_gdp, k = 4, fill = NA, align = "right"),
    gdp_growth_ma4 = zoo::rollmean(gdp_growth, k = 4, fill = NA, align = "right"),

    # Interaction terms for regression
    debt_crisis = debt_gdp * crisis_period,
    deficit_crisis = deficit_gdp * crisis_period
  ) %>%
  ungroup()

cat("  ✓ Derived variables created\n\n")

# ==============================================================================
# 10. Create Bailout Indicators
# ==============================================================================

cat("10. Adding bailout program indicators...\n\n")

# Create quarterly bailout indicators
bailout_quarterly <- bailout_programs %>%
  mutate(
    start_q = floor_date(start_date, "quarter"),
    end_q = floor_date(end_date, "quarter")
  ) %>%
  # Expand to all quarters in program period
  rowwise() %>%
  mutate(quarters = list(seq(start_q, end_q, by = "quarter"))) %>%
  unnest(quarters) %>%
  group_by(country, quarters) %>%
  summarise(
    bailout = 1,
    bailout_amount = sum(amount_billion_eur, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rename(date = quarters)

# Merge with master data
master_data <- master_data %>%
  left_join(bailout_quarterly, by = c("country", "date")) %>%
  mutate(
    bailout = replace_na(bailout, 0),
    bailout_amount = replace_na(bailout_amount, 0)
  )

cat("  ✓ Bailout indicators added\n\n")

# ==============================================================================
# 11. Data Quality Checks
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("DATA QUALITY CHECKS\n")
cat(strrep("=", 78), "\n\n")

# Check date range
cat("Date range:\n")
cat(sprintf("  First date: %s\n", min(master_data$date)))
cat(sprintf("  Last date: %s\n", max(master_data$date)))
cat(sprintf("  Total quarters: %d\n\n", n_distinct(master_data$date)))

# Check countries
cat("Countries included:\n")
countries_summary <- master_data %>%
  group_by(country, country_group) %>%
  summarise(n_obs = n(), .groups = "drop") %>%
  arrange(country_group, country)
print(countries_summary, n = Inf)
cat("\n")

# Check key variables summary
cat("Key variables summary:\n")
summary_stats <- master_data %>%
  select(debt_gdp, gdp_growth, unemployment, inflation,
         deficit_gdp, bond_yield, spread_bps) %>%
  summary()
print(summary_stats)
cat("\n")

# Check for outliers (spreads > 2000 bps)
extreme_spreads <- master_data %>%
  filter(spread_bps > 2000) %>%
  select(country, date, spread_bps, bond_yield)

if (nrow(extreme_spreads) > 0) {
  cat("Extreme spreads detected (>2000 bps):\n")
  print(extreme_spreads, n = Inf)
  cat("\n")
}

# ==============================================================================
# 12. Save Processed Data
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("SAVING PROCESSED DATA\n")
cat(strrep("=", 78), "\n\n")

# Save master dataset in multiple formats
cat("Saving master dataset...\n")

# RDS format (preserves R data types, most efficient)
saveRDS(master_data, file.path(processed_dir, "eurozone_master.rds"))
cat("  ✓ Saved as RDS: eurozone_master.rds\n")

# CSV format (for compatibility)
write_csv(master_data, file.path(processed_dir, "eurozone_master.csv"))
cat("  ✓ Saved as CSV: eurozone_master.csv\n")

# Save separate datasets for specific analyses
cat("\nSaving analysis-specific datasets...\n")

# Panel data (only complete cases for regression)
panel_data <- master_data %>%
  filter(!is.na(debt_gdp) & !is.na(spread_bps) &
         !is.na(gdp_growth) & !is.na(unemployment)) %>%
  select(country, country_group, date, year, quarter, period,
         debt_gdp, deficit_gdp, gdp_growth, unemployment, inflation,
         spread_bps, bond_yield, ecb_rate, crisis_period, post_omt,
         giips, bailout, debt_crisis, deficit_crisis)

saveRDS(panel_data, file.path(processed_dir, "panel_data.rds"))
write_csv(panel_data, file.path(processed_dir, "panel_data.csv"))
cat("  ✓ Panel data for regression analysis saved\n")

# Spreads data (for contagion analysis)
spreads_wide <- master_data %>%
  select(date, country, spread_bps) %>%
  pivot_wider(names_from = country, values_from = spread_bps)

saveRDS(spreads_wide, file.path(processed_dir, "spreads_wide.rds"))
write_csv(spreads_wide, file.path(processed_dir, "spreads_wide.csv"))
cat("  ✓ Spreads data (wide format) for contagion analysis saved\n")

# Country group summaries
country_summary <- master_data %>%
  group_by(country, country_group) %>%
  summarise(
    n_quarters = n(),
    avg_debt = mean(debt_gdp, na.rm = TRUE),
    avg_deficit = mean(deficit_gdp, na.rm = TRUE),
    avg_gdp_growth = mean(gdp_growth, na.rm = TRUE),
    avg_unemployment = mean(unemployment, na.rm = TRUE),
    avg_spread = mean(spread_bps, na.rm = TRUE),
    max_spread = max(spread_bps, na.rm = TRUE),
    had_bailout = max(bailout),
    .groups = "drop"
  )

write_csv(country_summary, file.path(processed_dir, "country_summary.csv"))
cat("  ✓ Country summary statistics saved\n")

# Crisis events
write_csv(crisis_events, file.path(processed_dir, "crisis_events.csv"))
cat("  ✓ Crisis events saved\n")

# ==============================================================================
# 13. Summary Report
# ==============================================================================

cat("\n", strrep("=", 78), "\n")
cat("DATA CLEANING SUMMARY REPORT\n")
cat(strrep("=", 78), "\n\n")

cat("Master Dataset Dimensions:\n")
cat(sprintf("  Observations: %d\n", nrow(master_data)))
cat(sprintf("  Variables: %d\n", ncol(master_data)))
cat(sprintf("  Countries: %d\n", n_distinct(master_data$country)))
cat(sprintf("  Time periods: %d quarters (%s to %s)\n",
            n_distinct(master_data$date),
            min(master_data$date),
            max(master_data$date)))

cat("\nCountry Groups:\n")
cat(sprintf("  GIIPS countries: %d\n",
            sum(country_mapping$country_group == "GIIPS")))
cat(sprintf("  Core countries: %d\n",
            sum(country_mapping$country_group == "Core")))

cat("\nData Completeness:\n")
completeness <- master_data %>%
  summarise(across(where(is.numeric), ~mean(!is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "completeness") %>%
  mutate(completeness = scales::percent(completeness, accuracy = 0.1)) %>%
  arrange(completeness)
print(completeness, n = 20)

cat("\n", strrep("=", 78), "\n")
cat("Files saved to:", processed_dir, "\n")
cat("  - eurozone_master.rds (main dataset)\n")
cat("  - panel_data.rds (for regression analysis)\n")
cat("  - spreads_wide.rds (for contagion analysis)\n")
cat("  - country_summary.csv (summary statistics)\n")
cat(strrep("=", 78), "\n\n")

cat("Data cleaning and preparation completed successfully!\n")
cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("\nNext steps:\n")
cat("  1. Run scripts/03_descriptive_stats.R for summary statistics\n")
cat("  2. Run scripts/04_visualization.R to create charts\n")
cat("  3. Run scripts/05_econometric_analysis.R for regressions\n")
