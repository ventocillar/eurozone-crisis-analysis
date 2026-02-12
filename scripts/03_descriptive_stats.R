# ==============================================================================
# Eurozone Crisis Analysis: Descriptive Statistics Script
# ==============================================================================
# Purpose: Generate comprehensive summary statistics and descriptive tables
# Author: Generated for Eurozone Crisis Thesis Analysis
# Date: November 2025
# ==============================================================================

# Clear environment
rm(list = ls())

# Load required packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse,     # Data manipulation
  here,          # File paths
  knitr,         # Table formatting
  kableExtra,    # Enhanced tables
  psych,         # Descriptive statistics
  moments,       # Skewness and kurtosis
  stargazer      # LaTeX/HTML tables
)

# ==============================================================================
# Configuration
# ==============================================================================

processed_dir <- here("data/processed")
output_dir <- here("outputs/tables")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

cat(strrep("=", 78), "\n")
cat("EUROZONE CRISIS DESCRIPTIVE STATISTICS\n")
cat(strrep("=", 78), "\n\n")

# ==============================================================================
# 1. Load Data
# ==============================================================================

cat("1. Loading processed data...\n\n")
master_data <- readRDS(file.path(processed_dir, "eurozone_master.rds"))
panel_data <- readRDS(file.path(processed_dir, "panel_data.rds"))
spreads_wide <- readRDS(file.path(processed_dir, "spreads_wide.rds"))

cat(sprintf("  ✓ Master data loaded: %d observations\n", nrow(master_data)))
cat(sprintf("  ✓ Panel data loaded: %d observations\n", nrow(panel_data)))
cat(sprintf("  ✓ Spreads data loaded: %d time periods\n\n", nrow(spreads_wide)))

# ==============================================================================
# 2. Overall Summary Statistics
# ==============================================================================

cat("2. Computing overall summary statistics...\n\n")

# Select key variables for summary
vars_for_summary <- c(
  "debt_gdp", "deficit_gdp", "gdp_growth", "unemployment",
  "inflation", "bond_yield", "spread_bps", "ecb_rate"
)

# Overall summary
overall_summary <- master_data %>%
  select(all_of(vars_for_summary)) %>%
  describe() %>%
  as.data.frame() %>%
  select(n, mean, sd, median, min, max, skew, kurtosis) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

# Add variable labels
variable_labels <- c(
  "Debt-to-GDP (%)",
  "Deficit-to-GDP (%)",
  "GDP Growth (%)",
  "Unemployment (%)",
  "Inflation (%)",
  "Bond Yield (%)",
  "Sovereign Spread (bps)",
  "ECB Rate (%)"
)

overall_summary <- overall_summary %>%
  mutate(Variable = variable_labels) %>%
  select(Variable, everything())

# Save overall summary
write_csv(overall_summary, file.path(output_dir, "table1_overall_summary.csv"))
cat("  ✓ Table 1: Overall summary statistics saved\n")

# Print to console
cat("\nTable 1: Overall Summary Statistics (2008-2015)\n")
print(overall_summary, row.names = FALSE)
cat("\n")

# ==============================================================================
# 3. Summary by Country Group (GIIPS vs Core)
# ==============================================================================

cat("3. Computing summary by country group...\n\n")

# Group comparison
group_summary <- master_data %>%
  group_by(country_group) %>%
  summarise(
    n_obs = n(),
    debt_gdp_mean = mean(debt_gdp, na.rm = TRUE),
    debt_gdp_sd = sd(debt_gdp, na.rm = TRUE),
    deficit_gdp_mean = mean(deficit_gdp, na.rm = TRUE),
    deficit_gdp_sd = sd(deficit_gdp, na.rm = TRUE),
    gdp_growth_mean = mean(gdp_growth, na.rm = TRUE),
    gdp_growth_sd = sd(gdp_growth, na.rm = TRUE),
    unemployment_mean = mean(unemployment, na.rm = TRUE),
    unemployment_sd = sd(unemployment, na.rm = TRUE),
    spread_mean = mean(spread_bps, na.rm = TRUE),
    spread_sd = sd(spread_bps, na.rm = TRUE),
    spread_max = max(spread_bps, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

# Statistical tests for group differences
t_test_results <- tibble(
  Variable = c("Debt-to-GDP", "Deficit-to-GDP", "GDP Growth",
               "Unemployment", "Sovereign Spread"),
  t_statistic = numeric(5),
  p_value = numeric(5)
)

# Perform t-tests
vars_to_test <- c("debt_gdp", "deficit_gdp", "gdp_growth",
                  "unemployment", "spread_bps")

for (i in seq_along(vars_to_test)) {
  var <- vars_to_test[i]
  giips_vals <- master_data %>% filter(country_group == "GIIPS") %>% pull(!!sym(var))
  core_vals <- master_data %>% filter(country_group == "Core") %>% pull(!!sym(var))

  test <- t.test(giips_vals, core_vals, na.rm = TRUE)
  t_test_results$t_statistic[i] <- round(test$statistic, 3)
  t_test_results$p_value[i] <- round(test$p.value, 4)
}

# Save group comparison
write_csv(group_summary, file.path(output_dir, "table2_group_comparison.csv"))
write_csv(t_test_results, file.path(output_dir, "table2b_group_tests.csv"))
cat("  ✓ Table 2: Group comparison statistics saved\n")
cat("  ✓ Table 2b: Statistical tests saved\n")

# Print to console
cat("\nTable 2: Summary Statistics by Country Group\n")
print(group_summary, row.names = FALSE)
cat("\nTable 2b: t-tests for Group Differences\n")
print(t_test_results, row.names = FALSE)
cat("\n")

# ==============================================================================
# 4. Summary by Time Period
# ==============================================================================

cat("4. Computing summary by time period...\n\n")

period_summary <- master_data %>%
  group_by(period, country_group) %>%
  summarise(
    n_obs = n(),
    debt_gdp = mean(debt_gdp, na.rm = TRUE),
    deficit_gdp = mean(deficit_gdp, na.rm = TRUE),
    gdp_growth = mean(gdp_growth, na.rm = TRUE),
    unemployment = mean(unemployment, na.rm = TRUE),
    spread_bps = mean(spread_bps, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(across(where(is.numeric), ~round(., 2))) %>%
  arrange(country_group, period)

write_csv(period_summary, file.path(output_dir, "table3_period_summary.csv"))
cat("  ✓ Table 3: Period summary statistics saved\n")

# Print to console
cat("\nTable 3: Summary by Time Period and Country Group\n")
print(period_summary, row.names = FALSE)
cat("\n")

# ==============================================================================
# 5. Summary by Individual Country
# ==============================================================================

cat("5. Computing summary by individual country...\n\n")

country_summary <- master_data %>%
  group_by(country, country_group) %>%
  summarise(
    n_quarters = n(),
    debt_mean = mean(debt_gdp, na.rm = TRUE),
    debt_max = max(debt_gdp, na.rm = TRUE),
    deficit_mean = mean(deficit_gdp, na.rm = TRUE),
    gdp_growth_mean = mean(gdp_growth, na.rm = TRUE),
    gdp_cumulative = sum(gdp_growth, na.rm = TRUE) / 4,  # Approximate
    unemployment_mean = mean(unemployment, na.rm = TRUE),
    unemployment_max = max(unemployment, na.rm = TRUE),
    spread_mean = mean(spread_bps, na.rm = TRUE),
    spread_max = max(spread_bps, na.rm = TRUE),
    bond_yield_mean = mean(bond_yield, na.rm = TRUE),
    bond_yield_max = max(bond_yield, na.rm = TRUE),
    had_bailout = max(bailout, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(across(where(is.numeric), ~round(., 2))) %>%
  arrange(country_group, country)

write_csv(country_summary, file.path(output_dir, "table4_country_summary.csv"))
cat("  ✓ Table 4: Country summary statistics saved\n")

# Print to console
cat("\nTable 4: Summary Statistics by Country\n")
print(country_summary, row.names = FALSE)
cat("\n")

# ==============================================================================
# 6. Correlation Matrix
# ==============================================================================

cat("6. Computing correlation matrices...\n\n")

# Overall correlation
cor_data <- panel_data %>%
  select(debt_gdp, deficit_gdp, gdp_growth, unemployment,
         inflation, bond_yield, spread_bps)

cor_matrix <- cor(cor_data, use = "pairwise.complete.obs")
cor_matrix_rounded <- round(cor_matrix, 3)

# Save correlation matrix
write_csv(as.data.frame(cor_matrix_rounded) %>% rownames_to_column("Variable"),
          file.path(output_dir, "table5_correlation_matrix.csv"))
cat("  ✓ Table 5: Correlation matrix saved\n")

# Print to console
cat("\nTable 5: Correlation Matrix of Key Variables\n")
print(cor_matrix_rounded)
cat("\n")

# Correlation of spreads across countries
spreads_cor <- spreads_wide %>%
  select(-date) %>%
  cor(use = "pairwise.complete.obs") %>%
  round(3)

write_csv(as.data.frame(spreads_cor) %>% rownames_to_column("Country"),
          file.path(output_dir, "table6_spreads_correlation.csv"))
cat("  ✓ Table 6: Spreads correlation matrix saved\n")

# Print spreads correlation
cat("\nTable 6: Correlation Matrix of Sovereign Spreads\n")
print(spreads_cor)
cat("\n")

# ==============================================================================
# 7. Crisis vs Non-Crisis Comparison
# ==============================================================================

cat("7. Comparing crisis vs non-crisis periods...\n\n")

crisis_comparison <- master_data %>%
  mutate(crisis_label = ifelse(crisis_period == 1, "Crisis (2009-2012)",
                                "Non-Crisis")) %>%
  group_by(crisis_label, country_group) %>%
  summarise(
    n_obs = n(),
    debt_gdp = mean(debt_gdp, na.rm = TRUE),
    deficit_gdp = mean(deficit_gdp, na.rm = TRUE),
    gdp_growth = mean(gdp_growth, na.rm = TRUE),
    unemployment = mean(unemployment, na.rm = TRUE),
    spread_bps = mean(spread_bps, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

write_csv(crisis_comparison, file.path(output_dir, "table7_crisis_comparison.csv"))
cat("  ✓ Table 7: Crisis vs non-crisis comparison saved\n")

# Print to console
cat("\nTable 7: Crisis vs Non-Crisis Period Comparison\n")
print(crisis_comparison, row.names = FALSE)
cat("\n")

# ==============================================================================
# 8. Divergence Metrics
# ==============================================================================

cat("8. Computing divergence metrics over time...\n\n")

# Calculate coefficient of variation by time period
divergence_metrics <- master_data %>%
  group_by(date) %>%
  summarise(
    # Coefficient of variation (CV)
    cv_debt = sd(debt_gdp, na.rm = TRUE) / mean(debt_gdp, na.rm = TRUE),
    cv_gdp_growth = sd(gdp_growth, na.rm = TRUE) / abs(mean(gdp_growth, na.rm = TRUE)),
    cv_unemployment = sd(unemployment, na.rm = TRUE) / mean(unemployment, na.rm = TRUE),
    cv_spread = sd(spread_bps, na.rm = TRUE) / mean(spread_bps, na.rm = TRUE),

    # Standard deviation (σ-divergence)
    sd_debt = sd(debt_gdp, na.rm = TRUE),
    sd_gdp_growth = sd(gdp_growth, na.rm = TRUE),
    sd_unemployment = sd(unemployment, na.rm = TRUE),
    sd_spread = sd(spread_bps, na.rm = TRUE),

    # Range (max - min)
    range_debt = max(debt_gdp, na.rm = TRUE) - min(debt_gdp, na.rm = TRUE),
    range_unemployment = max(unemployment, na.rm = TRUE) - min(unemployment, na.rm = TRUE),
    range_spread = max(spread_bps, na.rm = TRUE) - min(spread_bps, na.rm = TRUE),

    .groups = "drop"
  ) %>%
  mutate(
    year = year(date),
    quarter = quarter(date)
  )

# Summary of divergence by period
divergence_summary <- divergence_metrics %>%
  mutate(period = case_when(
    year == 2008 ~ "Pre-Crisis",
    year >= 2009 & year <= 2012 ~ "Crisis",
    year >= 2013 ~ "Recovery"
  )) %>%
  group_by(period) %>%
  summarise(
    cv_debt_mean = mean(cv_debt, na.rm = TRUE),
    cv_unemployment_mean = mean(cv_unemployment, na.rm = TRUE),
    cv_spread_mean = mean(cv_spread, na.rm = TRUE),
    sd_debt_mean = mean(sd_debt, na.rm = TRUE),
    sd_unemployment_mean = mean(sd_unemployment, na.rm = TRUE),
    sd_spread_mean = mean(sd_spread, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(across(where(is.numeric), ~round(., 3)))

write_csv(divergence_metrics, file.path(output_dir, "table8_divergence_timeseries.csv"))
write_csv(divergence_summary, file.path(output_dir, "table8b_divergence_summary.csv"))
cat("  ✓ Table 8: Divergence metrics saved\n")

# Print to console
cat("\nTable 8: Divergence Summary by Period\n")
print(divergence_summary, row.names = FALSE)
cat("\n")

# ==============================================================================
# 9. Bailout Programs Summary
# ==============================================================================

cat("9. Summarizing bailout programs...\n\n")

bailout_summary <- master_data %>%
  filter(bailout == 1) %>%
  group_by(country) %>%
  summarise(
    n_quarters_in_program = n(),
    total_amount_billion = max(bailout_amount, na.rm = TRUE),
    avg_spread_in_program = mean(spread_bps, na.rm = TRUE),
    max_spread_in_program = max(spread_bps, na.rm = TRUE),
    avg_debt_in_program = mean(debt_gdp, na.rm = TRUE),
    avg_unemployment = mean(unemployment, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

if (nrow(bailout_summary) > 0) {
  write_csv(bailout_summary, file.path(output_dir, "table9_bailout_summary.csv"))
  cat("  ✓ Table 9: Bailout programs summary saved\n")

  cat("\nTable 9: Bailout Programs Summary\n")
  print(bailout_summary, row.names = FALSE)
  cat("\n")
} else {
  cat("  ! No bailout data available\n\n")
}

# ==============================================================================
# 10. Germany vs Greece Comparison (Case Study)
# ==============================================================================

cat("10. Germany vs Greece detailed comparison...\n\n")

de_gr_comparison <- master_data %>%
  filter(country %in% c("Germany", "Greece")) %>%
  group_by(country) %>%
  summarise(
    across(
      c(debt_gdp, deficit_gdp, gdp_growth, unemployment,
        inflation, bond_yield, spread_bps),
      list(
        mean = ~mean(., na.rm = TRUE),
        min = ~min(., na.rm = TRUE),
        max = ~max(., na.rm = TRUE),
        sd = ~sd(., na.rm = TRUE)
      ),
      .names = "{.col}_{.fn}"
    ),
    .groups = "drop"
  ) %>%
  mutate(across(where(is.numeric), ~round(., 2))) %>%
  pivot_longer(-country, names_to = "statistic", values_to = "value") %>%
  pivot_wider(names_from = country, values_from = value) %>%
  mutate(difference = Greece - Germany)

write_csv(de_gr_comparison, file.path(output_dir, "table10_germany_greece_comparison.csv"))
cat("  ✓ Table 10: Germany vs Greece comparison saved\n")

cat("\nTable 10: Germany vs Greece Comparison (Sample)\n")
print(head(de_gr_comparison, 20), row.names = FALSE)
cat("\n")

# ==============================================================================
# 11. Peak Crisis Statistics
# ==============================================================================

cat("11. Identifying peak crisis statistics...\n\n")

# Find maximum spreads for each country
peak_spreads <- master_data %>%
  group_by(country) %>%
  arrange(desc(spread_bps)) %>%
  slice(1) %>%
  select(country, country_group, date, spread_bps, bond_yield,
         debt_gdp, deficit_gdp, unemployment) %>%
  mutate(across(where(is.numeric), ~round(., 2))) %>%
  arrange(desc(spread_bps))

write_csv(peak_spreads, file.path(output_dir, "table11_peak_spreads.csv"))
cat("  ✓ Table 11: Peak spreads by country saved\n")

cat("\nTable 11: Peak Sovereign Spreads by Country\n")
print(peak_spreads, row.names = FALSE)
cat("\n")

# ==============================================================================
# 12. Generate LaTeX Tables for Thesis
# ==============================================================================

cat("12. Generating LaTeX formatted tables...\n\n")

# Table 1: Overall summary (LaTeX)
latex_table1 <- stargazer(
  as.data.frame(cor_data),
  type = "latex",
  title = "Summary Statistics of Key Variables (2008-2015)",
  summary.stat = c("n", "mean", "sd", "min", "median", "max"),
  digits = 2,
  out = file.path(output_dir, "table1_overall_summary.tex")
)
cat("  ✓ LaTeX table 1 saved\n")

# Table for group comparison (LaTeX)
latex_group <- group_summary %>%
  select(country_group, debt_gdp_mean, unemployment_mean, spread_mean) %>%
  as.data.frame()

stargazer(
  latex_group,
  type = "latex",
  summary = FALSE,
  title = "GIIPS vs Core Country Comparison",
  digits = 2,
  out = file.path(output_dir, "table2_group_comparison.tex")
)
cat("  ✓ LaTeX table 2 saved\n")

cat("\n")

# ==============================================================================
# 13. Summary Report
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("DESCRIPTIVE STATISTICS SUMMARY\n")
cat(strrep("=", 78), "\n\n")

cat("Tables generated:\n")
cat("  1. Overall summary statistics\n")
cat("  2. Group comparison (GIIPS vs Core)\n")
cat("  3. Summary by time period\n")
cat("  4. Summary by individual country\n")
cat("  5. Correlation matrix of key variables\n")
cat("  6. Correlation matrix of sovereign spreads\n")
cat("  7. Crisis vs non-crisis comparison\n")
cat("  8. Divergence metrics over time\n")
cat("  9. Bailout programs summary\n")
cat("  10. Germany vs Greece detailed comparison\n")
cat("  11. Peak crisis statistics\n")
cat("  + LaTeX formatted tables for thesis\n\n")

cat("All tables saved to:", output_dir, "\n")
cat(strrep("=", 78), "\n\n")

cat("Descriptive statistics script completed successfully!\n")
cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("\nNext steps:\n")
cat("  1. Review tables in outputs/tables/\n")
cat("  2. Run scripts/04_visualization.R to create charts\n")
cat("  3. Run scripts/05_econometric_analysis.R for regressions\n")
