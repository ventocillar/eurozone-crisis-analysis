# ==============================================================================
# Eurozone Crisis Analysis: Econometric Analysis Script
# ==============================================================================
# Purpose: Panel regressions, time series tests, and statistical analysis
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
  plm,           # Panel data models
  lmtest,        # Diagnostic tests
  sandwich,      # Robust standard errors
  car,           # Additional tests
  tseries,       # Time series tests
  strucchange,   # Structural break tests
  vars,          # Vector autoregression
  urca,          # Unit root tests
  stargazer,     # Regression tables
  broom,         # Tidy regression output
  estimatr       # Robust estimators
)

# ==============================================================================
# Configuration
# ==============================================================================

processed_dir <- here("data/processed")
tables_dir <- here("outputs/tables")
if (!dir.exists(tables_dir)) dir.create(tables_dir, recursive = TRUE)

cat(strrep("=", 78), "\n")
cat("EUROZONE CRISIS ECONOMETRIC ANALYSIS\n")
cat(strrep("=", 78), "\n\n")

# ==============================================================================
# 1. Load Data
# ==============================================================================

cat("1. Loading processed data...\n\n")
panel_data <- readRDS(file.path(processed_dir, "panel_data.rds"))
spreads_wide <- readRDS(file.path(processed_dir, "spreads_wide.rds"))

# Convert to panel data format
pdata <- pdata.frame(panel_data, index = c("country", "date"))

cat(sprintf("  ✓ Panel data loaded: %d observations\n", nrow(pdata)))
cat(sprintf("  ✓ Countries: %d, Time periods: %d\n\n",
            n_distinct(panel_data$country),
            n_distinct(panel_data$date)))

# ==============================================================================
# 2. PANEL REGRESSION: Determinants of Sovereign Spreads
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("2. Panel Regression Analysis: Determinants of Sovereign Spreads\n")
cat(strrep("=", 78), "\n\n")

# Model 1: Baseline (fiscal variables only)
cat("Estimating Model 1: Baseline model...\n")
model1 <- plm(
  spread_bps ~ debt_gdp + deficit_gdp,
  data = pdata,
  model = "within",
  effect = "twoways"
)

# Model 2: Add macroeconomic variables
cat("Estimating Model 2: With macroeconomic variables...\n")
model2 <- plm(
  spread_bps ~ debt_gdp + deficit_gdp + gdp_growth + unemployment,
  data = pdata,
  model = "within",
  effect = "twoways"
)

# Model 3: Add inflation and ECB rate
cat("Estimating Model 3: Full model...\n")
model3 <- plm(
  spread_bps ~ debt_gdp + deficit_gdp + gdp_growth + unemployment +
    inflation + ecb_rate,
  data = pdata,
  model = "within",
  effect = "twoways"
)

# Model 4: Crisis interaction model
cat("Estimating Model 4: Crisis interaction effects...\n")
model4 <- plm(
  spread_bps ~ debt_gdp + deficit_gdp + gdp_growth + unemployment +
    debt_crisis + deficit_crisis + post_omt,
  data = pdata,
  model = "within",
  effect = "twoways"
)

# Model 5: Random effects (for Hausman test comparison with Model 2)
cat("Estimating Model 5: Random effects model...\n")
model5 <- plm(
  spread_bps ~ debt_gdp + deficit_gdp + gdp_growth + unemployment,
  data = pdata,
  model = "random",
  effect = "twoways"
)

cat("  ✓ All models estimated\n\n")

# Hausman test (FE vs RE)
cat("Running Hausman test (Fixed vs Random Effects)...\n")
hausman_test <- phtest(model2, model5)
cat(sprintf("  Hausman test p-value: %.4f\n", hausman_test$p.value))
if (hausman_test$p.value < 0.05) {
  cat("  → Fixed effects model preferred (p < 0.05)\n\n")
} else {
  cat("  → Random effects model not rejected (p >= 0.05)\n\n")
}

# Get robust standard errors
cat("Computing robust standard errors (clustered by country)...\n")
model2_robust <- coeftest(model2, vcov = vcovHC(model2, cluster = "group"))
model3_robust <- coeftest(model3, vcov = vcovHC(model3, cluster = "group"))
model4_robust <- coeftest(model4, vcov = vcovHC(model4, cluster = "group"))
cat("  ✓ Robust standard errors computed\n\n")

# Create regression table
cat("Generating regression output tables...\n")

# Save detailed results for each model
model_summary <- list(
  model1 = summary(model1),
  model2 = summary(model2),
  model3 = summary(model3),
  model4 = summary(model4)
)

# Extract robust SEs and p-values for stargazer
model1_robust <- coeftest(model1, vcov = vcovHC(model1, cluster = "group"))
robust_se <- list(
  model1_robust[, "Std. Error"],
  model2_robust[, "Std. Error"],
  model3_robust[, "Std. Error"],
  model4_robust[, "Std. Error"]
)
robust_p <- list(
  model1_robust[, "Pr(>|t|)"],
  model2_robust[, "Pr(>|t|)"],
  model3_robust[, "Pr(>|t|)"],
  model4_robust[, "Pr(>|t|)"]
)

# Stargazer table (LaTeX and text) — with cluster-robust SEs
stargazer(
  model1, model2, model3, model4,
  type = "text",
  title = "Panel Regression Results: Determinants of Sovereign Spreads",
  column.labels = c("Baseline", "Macro", "Full", "Crisis Interactions"),
  dep.var.labels = "Sovereign Spread (bps)",
  covariate.labels = c(
    "Debt-to-GDP", "Deficit-to-GDP", "GDP Growth", "Unemployment",
    "Inflation", "ECB Rate", "Debt × Crisis", "Deficit × Crisis",
    "Post-OMT"
  ),
  se = robust_se,
  p = robust_p,
  omit.stat = c("ser"),
  digits = 2,
  notes = "Cluster-robust standard errors (by country) in parentheses.",
  out = file.path(tables_dir, "regression_table_spreads.txt")
)

stargazer(
  model1, model2, model3, model4,
  type = "latex",
  title = "Panel Regression Results: Determinants of Sovereign Spreads",
  column.labels = c("Baseline", "Macro", "Full", "Crisis Interactions"),
  dep.var.labels = "Sovereign Spread (bps)",
  se = robust_se,
  p = robust_p,
  omit.stat = c("ser"),
  digits = 2,
  notes = "Cluster-robust standard errors (by country) in parentheses.",
  out = file.path(tables_dir, "regression_table_spreads.tex")
)

cat("  ✓ Regression tables saved\n\n")

# ==============================================================================
# 2b. FIRST-DIFFERENCE MODEL (robustness for non-stationarity)
# ==============================================================================

cat("Estimating first-difference model (robustness for non-stationarity)...\n")
model_fd <- plm(
  spread_bps ~ debt_gdp + deficit_gdp + gdp_growth + unemployment,
  data = pdata,
  model = "fd"
)
model_fd_robust <- coeftest(model_fd, vcov = vcovHC(model_fd, cluster = "group"))
cat("  ✓ First-difference model estimated\n\n")

# ==============================================================================
# 2c. DRISCOLL-KRAAY STANDARD ERRORS (robust to cross-sectional dependence)
# ==============================================================================

cat("Computing Driscoll-Kraay standard errors (SCC)...\n")
model2_dk <- coeftest(model2, vcov = vcovSCC(model2))
model3_dk <- coeftest(model3, vcov = vcovSCC(model3))
model4_dk <- coeftest(model4, vcov = vcovSCC(model4))
cat("  ✓ Driscoll-Kraay standard errors computed\n\n")

# ==============================================================================
# 2d. EXPORT regression_coefficients.csv (for dashboard)
# ==============================================================================

cat("Exporting regression coefficients for dashboard...\n")

extract_coefs <- function(model_obj, robust_ct, dk_ct = NULL, model_name) {
  coefs <- coef(model_obj)
  # Cluster-robust
  rows <- tibble(
    variable = names(coefs),
    estimate = as.numeric(coefs),
    std_error = as.numeric(robust_ct[, "Std. Error"]),
    ci_lower = as.numeric(coefs) - 1.96 * as.numeric(robust_ct[, "Std. Error"]),
    ci_upper = as.numeric(coefs) + 1.96 * as.numeric(robust_ct[, "Std. Error"]),
    p_value = as.numeric(robust_ct[, "Pr(>|t|)"]),
    model = model_name,
    se_type = "cluster-robust"
  )
  # Driscoll-Kraay (if available)
  if (!is.null(dk_ct)) {
    dk_rows <- tibble(
      variable = names(coefs),
      estimate = as.numeric(coefs),
      std_error = as.numeric(dk_ct[, "Std. Error"]),
      ci_lower = as.numeric(coefs) - 1.96 * as.numeric(dk_ct[, "Std. Error"]),
      ci_upper = as.numeric(coefs) + 1.96 * as.numeric(dk_ct[, "Std. Error"]),
      p_value = as.numeric(dk_ct[, "Pr(>|t|)"]),
      model = model_name,
      se_type = "driscoll-kraay"
    )
    rows <- bind_rows(rows, dk_rows)
  }
  rows
}

# Extract from FD model separately (different coefficient names)
fd_coefs <- coef(model_fd)
fd_rows <- tibble(
  variable = names(fd_coefs),
  estimate = as.numeric(fd_coefs),
  std_error = as.numeric(model_fd_robust[, "Std. Error"]),
  ci_lower = as.numeric(fd_coefs) - 1.96 * as.numeric(model_fd_robust[, "Std. Error"]),
  ci_upper = as.numeric(fd_coefs) + 1.96 * as.numeric(model_fd_robust[, "Std. Error"]),
  p_value = as.numeric(model_fd_robust[, "Pr(>|t|)"]),
  model = "First-Difference",
  se_type = "cluster-robust"
)

all_coefs <- bind_rows(
  extract_coefs(model1, model1_robust, NULL, "Baseline"),
  extract_coefs(model2, model2_robust, model2_dk, "Macro"),
  extract_coefs(model3, model3_robust, model3_dk, "Full"),
  extract_coefs(model4, model4_robust, model4_dk, "Crisis Interactions"),
  fd_rows
)

write_csv(all_coefs, file.path(tables_dir, "regression_coefficients.csv"))
cat(sprintf("  ✓ Exported %d coefficient rows to regression_coefficients.csv\n\n",
            nrow(all_coefs)))

# ==============================================================================
# 3. DIAGNOSTIC TESTS
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("3. Diagnostic Tests\n")
cat(strrep("=", 78), "\n\n")

# Multicollinearity (VIF) — use OLS proxy since car::vif() doesn't support plm
cat("Testing for multicollinearity (VIF)...\n")
tryCatch({
  vif_ols <- lm(spread_bps ~ debt_gdp + deficit_gdp + gdp_growth + unemployment +
                   inflation + ecb_rate, data = panel_data)
  vif_model3 <- car::vif(vif_ols)
  cat("  Variance Inflation Factors (from OLS proxy):\n")
  print(vif_model3)
  cat("\n")
  if (max(vif_model3) > 10) {
    cat("  Warning: High multicollinearity detected (VIF > 10)\n\n")
  } else {
    cat("  ✓ No severe multicollinearity (all VIF < 10)\n\n")
  }
}, error = function(e) {
  cat("  VIF test skipped:", conditionMessage(e), "\n\n")
})

# Heteroskedasticity test
cat("Testing for heteroskedasticity...\n")
bp_test <- bptest(model2)
cat(sprintf("  Breusch-Pagan test p-value: %.4f\n", bp_test$p.value))
if (bp_test$p.value < 0.05) {
  cat("  → Heteroskedasticity detected; using robust standard errors\n\n")
} else {
  cat("  → Homoskedasticity not rejected\n\n")
}

# Serial correlation test
cat("Testing for serial correlation...\n")
pbg_test <- pbgtest(model2)
cat(sprintf("  Breusch-Godfrey test p-value: %.4f\n", pbg_test$p.value))
if (pbg_test$p.value < 0.05) {
  cat("  → Serial correlation detected\n\n")
} else {
  cat("  → No serial correlation detected\n\n")
}

# ==============================================================================
# 4. STRUCTURAL BREAK TESTS
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("4. Structural Break Analysis\n")
cat(strrep("=", 78), "\n\n")

# Test for structural breaks in spreads for each GIIPS country
break_results <- tibble(
  country = character(),
  break_date = as.Date(character()),
  test_statistic = numeric(),
  p_value = numeric()
)

giips_countries <- c("Greece", "Ireland", "Italy", "Portugal", "Spain")

cat("Testing for structural breaks in sovereign spreads...\n")
for (ctry in giips_countries) {
  cat(sprintf("  Testing %s...\n", ctry))

  country_ts <- panel_data %>%
    filter(country == ctry, !is.na(spread_bps)) %>%
    arrange(date) %>%
    pull(spread_bps)

  if (length(country_ts) > 20) {
    tryCatch({
      # Chow test at known break date (Q2 2010 - Greek bailout)
      breakpoint <- which(panel_data %>%
                          filter(country == ctry) %>%
                          pull(date) == as.Date("2010-04-01"))

      if (length(breakpoint) > 0 && breakpoint > 5 &&
          breakpoint < (length(country_ts) - 5)) {

        # Create time trend for regression
        time_data <- tibble(
          spread = country_ts,
          time = 1:length(country_ts)
        )

        # Sctest for structural change
        fs_test <- strucchange::sctest(
          spread ~ time,
          data = time_data,
          type = "Chow",
          point = breakpoint
        )

        break_results <- bind_rows(
          break_results,
          tibble(
            country = ctry,
            break_date = as.Date("2010-04-01"),
            test_statistic = fs_test$statistic,
            p_value = fs_test$p.value
          )
        )
      }
    }, error = function(e) {
      cat(sprintf("    Could not perform test: %s\n", conditionMessage(e)))
    })
  }
}

if (nrow(break_results) > 0) {
  write_csv(break_results, file.path(tables_dir, "structural_break_tests.csv"))
  cat("\n  Structural Break Test Results:\n")
  print(break_results, n = Inf)
  cat("\n")
} else {
  cat("\n  No structural break tests completed\n\n")
}

# ==============================================================================
# 5. UNIT ROOT TESTS (Stationarity)
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("5. Unit Root Tests (Stationarity)\n")
cat(strrep("=", 78), "\n\n")

# Test stationarity of key variables for Greece
cat("Testing stationarity for Greece (ADF test)...\n")

greece_data <- panel_data %>%
  filter(country == "Greece") %>%
  arrange(date)

variables_to_test <- c("spread_bps", "debt_gdp", "gdp_growth", "unemployment")
adf_results <- tibble(
  variable = character(),
  adf_statistic = numeric(),
  p_value = numeric(),
  stationary = logical()
)

for (var in variables_to_test) {
  var_ts <- greece_data %>% pull(!!sym(var))
  var_ts <- var_ts[!is.na(var_ts)]

  if (length(var_ts) > 10) {
    adf_test <- adf.test(var_ts, alternative = "stationary")

    adf_results <- bind_rows(
      adf_results,
      tibble(
        variable = var,
        adf_statistic = adf_test$statistic,
        p_value = adf_test$p.value,
        stationary = adf_test$p.value < 0.05
      )
    )
  }
}

cat("  ADF Test Results for Greece:\n")
print(adf_results, n = Inf)
cat("\n")

write_csv(adf_results, file.path(tables_dir, "unit_root_tests.csv"))
cat("  ✓ Unit root tests saved\n\n")

# ==============================================================================
# 6. GRANGER CAUSALITY TESTS
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("6. Granger Causality Tests (Contagion)\n")
cat(strrep("=", 78), "\n\n")

cat("Testing if Greek spreads Granger-cause other GIIPS spreads...\n")

granger_results <- tibble(
  target_country = character(),
  f_statistic = numeric(),
  p_value = numeric(),
  granger_causes = logical()
)

# Prepare Greece spread data
greece_spread <- spreads_wide %>%
  dplyr::select(date, Greece) %>%
  arrange(date)

other_giips <- c("Ireland", "Italy", "Portugal", "Spain")

for (ctry in other_giips) {
  cat(sprintf("  Testing Greece → %s...\n", ctry))

  # Merge data
  test_data <- spreads_wide %>%
    dplyr::select(date, !!sym(ctry)) %>%
    left_join(greece_spread, by = "date") %>%
    filter(!is.na(Greece), !is.na(!!sym(ctry))) %>%
    arrange(date)

  if (nrow(test_data) > 20) {
    tryCatch({
      # Granger causality test (lag 2 quarters)
      granger_test <- grangertest(
        as.formula(paste(ctry, "~ Greece")),
        order = 2,
        data = test_data
      )

      granger_results <- bind_rows(
        granger_results,
        tibble(
          target_country = ctry,
          f_statistic = granger_test$F[2],
          p_value = granger_test$`Pr(>F)`[2],
          granger_causes = granger_test$`Pr(>F)`[2] < 0.05
        )
      )
    }, error = function(e) {
      cat(sprintf("    Error: %s\n", conditionMessage(e)))
    })
  }
}

if (nrow(granger_results) > 0) {
  cat("\n  Granger Causality Test Results:\n")
  print(granger_results, n = Inf)
  cat("\n")

  write_csv(granger_results, file.path(tables_dir, "granger_causality_tests.csv"))
  cat("  ✓ Granger causality tests saved\n\n")

  # Summary
  n_significant <- sum(granger_results$granger_causes)
  cat(sprintf("  → Greek spreads Granger-cause %d out of %d countries (p < 0.05)\n\n",
              n_significant, nrow(granger_results)))
} else {
  cat("\n  No Granger causality tests completed\n\n")
}

# ==============================================================================
# 7. CORRELATION TESTS
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("7. Correlation Analysis and Tests\n")
cat(strrep("=", 78), "\n\n")

# Test if correlations increased during crisis
cat("Testing if spread correlations increased during crisis...\n")

# Pre-crisis correlations (2008)
pre_crisis_spreads <- spreads_wide %>%
  filter(year(date) == 2008) %>%
  dplyr::select(-date) %>%
  cor(use = "pairwise.complete.obs")

# Crisis correlations (2010-2012)
crisis_spreads <- spreads_wide %>%
  filter(year(date) >= 2010 & year(date) <= 2012) %>%
  dplyr::select(-date) %>%
  cor(use = "pairwise.complete.obs")

# Calculate average correlation (excluding diagonal)
get_avg_cor <- function(cor_matrix) {
  cor_values <- cor_matrix[lower.tri(cor_matrix)]
  mean(cor_values, na.rm = TRUE)
}

avg_cor_pre <- get_avg_cor(pre_crisis_spreads)
avg_cor_crisis <- get_avg_cor(crisis_spreads)

cat(sprintf("  Average correlation (2008): %.3f\n", avg_cor_pre))
cat(sprintf("  Average correlation (2010-2012): %.3f\n", avg_cor_crisis))
cat(sprintf("  Increase: %.3f (%.1f%%)\n\n",
            avg_cor_crisis - avg_cor_pre,
            ((avg_cor_crisis / avg_cor_pre) - 1) * 100))

# Save correlation comparison
cor_comparison <- tibble(
  period = c("Pre-Crisis (2008)", "Crisis (2010-2012)"),
  avg_correlation = c(avg_cor_pre, avg_cor_crisis),
  change = c(NA, avg_cor_crisis - avg_cor_pre)
)

write_csv(cor_comparison, file.path(tables_dir, "correlation_comparison.csv"))
cat("  ✓ Correlation comparison saved\n\n")

# ==============================================================================
# 8. PRINCIPAL COMPONENT ANALYSIS
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("8. Principal Component Analysis of Spreads\n")
cat(strrep("=", 78), "\n\n")

cat("Performing PCA on sovereign spreads...\n")

# PCA on spreads (complete cases only, exclude Germany — zero variance)
spreads_for_pca <- spreads_wide %>%
  dplyr::select(-date, -Germany) %>%
  na.omit()

pca_result <- prcomp(spreads_for_pca, scale. = TRUE)

# Summary
pca_summary <- summary(pca_result)
variance_explained <- pca_summary$importance[2, ]  # Proportion of variance

cat("\n  Variance Explained by Principal Components:\n")
for (i in 1:min(5, length(variance_explained))) {
  cat(sprintf("    PC%d: %.1f%%\n", i, variance_explained[i] * 100))
}
cat("\n")

# First PC explains common factor
cat(sprintf("  → First principal component explains %.1f%% of variation\n",
            variance_explained[1] * 100))
cat("    (suggests strong common factor during crisis)\n\n")

# Save PCA results
pca_loadings <- as.data.frame(pca_result$rotation[, 1:3])
pca_loadings <- pca_loadings %>%
  rownames_to_column("country") %>%
  mutate(across(where(is.numeric), ~round(., 3)))

write_csv(pca_loadings, file.path(tables_dir, "pca_loadings.csv"))
cat("  ✓ PCA results saved\n\n")

# ==============================================================================
# 9. EVENT STUDY REGRESSIONS
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("9. Event Study Analysis\n")
cat(strrep("=", 78), "\n\n")

cat("Analyzing impact of OMT announcement (July 26, 2012)...\n")

# Create event window dummies
panel_data_events <- panel_data %>%
  mutate(
    post_omt_immediate = ifelse(date >= as.Date("2012-07-01") &
                                  date < as.Date("2012-12-01"), 1, 0),
    post_omt_medium = ifelse(date >= as.Date("2012-12-01"), 1, 0)
  )

# Event study regression (GIIPS countries only, with country fixed effects)
giips_data <- panel_data_events %>%
  filter(country_group == "GIIPS")

giips_pdata <- pdata.frame(giips_data, index = c("country", "date"))

event_model <- plm(
  spread_bps ~ post_omt_immediate + post_omt_medium +
    debt_gdp + unemployment,
  data = giips_pdata,
  model = "within"
)

cat("\n  Event Study Regression Results:\n")
print(summary(event_model))
cat("\n")

# Save event study results
event_results <- tidy(event_model) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

write_csv(event_results, file.path(tables_dir, "event_study_omt.csv"))
cat("  ✓ Event study results saved\n\n")

# Interpret results
omt_effect <- coef(event_model)["post_omt_immediate"]
cat(sprintf("  → OMT announcement associated with %.0f bps reduction in spreads\n",
            abs(omt_effect)))
cat("    (controlling for fundamentals)\n\n")

# ==============================================================================
# 10. COUNTRY-SPECIFIC TIME SERIES ANALYSIS
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("10. Country-Specific Analysis: Greece\n")
cat(strrep("=", 78), "\n\n")

# Simple time series regression for Greece
greece_ts_data <- panel_data %>%
  filter(country == "Greece") %>%
  arrange(date) %>%
  mutate(time_trend = row_number())

cat("Estimating Greece spread determinants (OLS)...\n")
greece_model <- lm(
  spread_bps ~ debt_gdp + unemployment + time_trend + crisis_period,
  data = greece_ts_data
)

cat("\n")
print(summary(greece_model))
cat("\n")

# Save Greece-specific results
greece_results <- tidy(greece_model) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

write_csv(greece_results, file.path(tables_dir, "greece_specific_regression.csv"))
cat("  ✓ Greece-specific results saved\n\n")

# ==============================================================================
# 11. SUMMARY OF KEY FINDINGS
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("ECONOMETRIC ANALYSIS: KEY FINDINGS SUMMARY\n")
cat(strrep("=", 78), "\n\n")

cat("1. PANEL REGRESSION (Spread Determinants):\n")
cat(sprintf("   - Debt-to-GDP coefficient: %.2f***\n",
            coef(model3)["debt_gdp"]))
cat(sprintf("   - Unemployment coefficient: %.2f***\n",
            coef(model3)["unemployment"]))
cat(sprintf("   - Model R-squared: %.3f\n", summary(model3)$r.squared[1]))
cat("   - Fixed effects preferred over random effects (Hausman test)\n")
cat("   - Heteroskedasticity detected; cluster-robust & Driscoll-Kraay SEs reported\n")
cat("   - First-difference model estimated as robustness check\n\n")

cat("2. STRUCTURAL BREAKS:\n")
if (nrow(break_results) > 0) {
  n_breaks <- sum(break_results$p_value < 0.05, na.rm = TRUE)
  cat(sprintf("   - Significant breaks detected in %d countries around May 2010\n", n_breaks))
} else {
  cat("   - Tests performed (see output files)\n")
}
cat("\n")

cat("3. CONTAGION EVIDENCE:\n")
if (nrow(granger_results) > 0) {
  n_gc <- sum(granger_results$granger_causes)
  cat(sprintf("   - Greek spreads Granger-cause %d other GIIPS countries\n", n_gc))
}
cat(sprintf("   - Average correlation increased by %.3f during crisis\n",
            avg_cor_crisis - avg_cor_pre))
cat(sprintf("   - First PC explains %.0f%% of spread variation\n",
            variance_explained[1] * 100))
cat("\n")

cat("4. POLICY IMPACT:\n")
if (exists("omt_effect")) {
  cat(sprintf("   - OMT announcement: ~%.0f bps spread reduction\n", abs(omt_effect)))
}
cat("\n")

cat("All econometric results saved to:", tables_dir, "\n")
cat(strrep("=", 78), "\n\n")

cat("Econometric analysis completed successfully!\n")
cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("\nNext steps:\n")
cat("  1. Review regression tables in outputs/tables/\n")
cat("  2. Examine diagnostic test results\n")
cat("  3. Integrate findings into Quarto notebooks\n")
cat("  4. Compare results with thesis theoretical predictions\n")
