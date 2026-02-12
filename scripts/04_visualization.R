# ==============================================================================
# Eurozone Crisis Analysis: Visualization Script
# ==============================================================================
# Purpose: Create comprehensive visualizations and charts
# Author: Generated for Eurozone Crisis Thesis Analysis
# Date: November 2025
# ==============================================================================

# Clear environment
rm(list = ls())

# Load required packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse,     # Data manipulation and ggplot2
  here,          # File paths
  scales,        # Scale functions for ggplot2
  gridExtra,     # Multiple plots
  patchwork,     # Combine plots
  ggrepel,       # Better label positioning
  gghighlight,   # Highlight specific data
  RColorBrewer,  # Color palettes
  viridis,       # Color scales
  lubridate,     # Date handling
  zoo            # Rolling statistics
)

# ==============================================================================
# Configuration
# ==============================================================================

processed_dir <- here("data/processed")
figures_dir <- here("outputs/figures")
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

# Set ggplot2 theme
theme_set(theme_minimal(base_size = 12))
theme_update(
  plot.title = element_text(face = "bold", size = 14),
  plot.subtitle = element_text(size = 11, color = "gray40"),
  legend.position = "bottom",
  panel.grid.minor = element_blank()
)

# Color schemes
giips_color <- "#E74C3C"
core_color <- "#3498DB"
germany_color <- "#2C3E50"
greece_color <- "#E74C3C"

country_colors <- c(
  "Greece" = "#E74C3C", "Ireland" = "#E67E22", "Italy" = "#F39C12",
  "Portugal" = "#F1C40F", "Spain" = "#E59866",
  "Germany" = "#2C3E50", "France" = "#34495E",
  "Netherlands" = "#7F8C8D", "Austria" = "#95A5A6"
)

cat(strrep("=", 78), "\n")
cat("EUROZONE CRISIS VISUALIZATION\n")
cat(strrep("=", 78), "\n\n")

# ==============================================================================
# 1. Load Data
# ==============================================================================

cat("1. Loading processed data...\n\n")
master_data <- readRDS(file.path(processed_dir, "eurozone_master.rds"))
panel_data <- readRDS(file.path(processed_dir, "panel_data.rds"))
spreads_wide <- readRDS(file.path(processed_dir, "spreads_wide.rds"))
crisis_events <- read_csv(file.path(processed_dir, "crisis_events.csv"),
                          show_col_types = FALSE)

cat("  ✓ Data loaded successfully\n\n")

# ==============================================================================
# 2. Figure 1: Evolution of 10-Year Government Bond Yields
# ==============================================================================

cat("2. Creating Figure 1: Bond yields evolution...\n")

fig1 <- ggplot(master_data %>% filter(!is.na(bond_yield)),
               aes(x = date, y = bond_yield, color = country, group = country)) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = country_colors) +
  scale_y_continuous(labels = label_percent(scale = 1),
                     breaks = seq(0, 40, by = 5)) +
  labs(
    title = "10-Year Government Bond Yields (2008-2015)",
    subtitle = "Eurozone countries show significant divergence during crisis period",
    x = NULL,
    y = "Bond Yield (%)",
    color = "Country"
  ) +
  theme(legend.position = "right")

ggsave(file.path(figures_dir, "fig1_bond_yields.png"),
       fig1, width = 10, height = 6, dpi = 300)
cat("  ✓ Figure 1 saved\n\n")

# ==============================================================================
# 3. Figure 2: Sovereign Spreads over German Bunds
# ==============================================================================

cat("3. Creating Figure 2: Sovereign spreads...\n")

fig2 <- ggplot(master_data %>% filter(country != "Germany", !is.na(spread_bps)),
               aes(x = date, y = spread_bps, color = country, group = country)) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  scale_color_manual(values = country_colors) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title = "Sovereign Spreads over German Bunds (2008-2015)",
    subtitle = "Spread measured in basis points; GIIPS countries show dramatic increases",
    x = NULL,
    y = "Spread (basis points)",
    color = "Country"
  ) +
  theme(legend.position = "right")

ggsave(file.path(figures_dir, "fig2_sovereign_spreads.png"),
       fig2, width = 10, height = 6, dpi = 300)
cat("  ✓ Figure 2 saved\n\n")

# ==============================================================================
# 4. Figure 3: Government Debt-to-GDP Evolution
# ==============================================================================

cat("4. Creating Figure 3: Debt-to-GDP ratios...\n")

fig3 <- ggplot(master_data %>% filter(!is.na(debt_gdp)),
               aes(x = date, y = debt_gdp, color = country, group = country)) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = 60, linetype = "dashed", color = "red",
             linewidth = 0.5, alpha = 0.7) +
  annotate("text", x = as.Date("2008-06-01"), y = 65,
           label = "Maastricht 60% limit", color = "red", size = 3) +
  scale_color_manual(values = country_colors) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(
    title = "Government Debt-to-GDP Ratios (2008-2015)",
    subtitle = "Dashed line shows Maastricht Treaty 60% reference value",
    x = NULL,
    y = "Debt-to-GDP (%)",
    color = "Country"
  ) +
  theme(legend.position = "right")

ggsave(file.path(figures_dir, "fig3_debt_gdp.png"),
       fig3, width = 10, height = 6, dpi = 300)
cat("  ✓ Figure 3 saved\n\n")

# ==============================================================================
# 5. Figure 4: GDP Growth Comparison (GIIPS vs Core)
# ==============================================================================

cat("5. Creating Figure 4: GDP growth comparison...\n")

gdp_group <- master_data %>%
  filter(!is.na(gdp_growth)) %>%
  group_by(date, country_group) %>%
  summarise(gdp_growth = mean(gdp_growth, na.rm = TRUE), .groups = "drop")

fig4 <- ggplot(gdp_group, aes(x = date, y = gdp_growth,
                               color = country_group, group = country_group)) +
  geom_line(linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  scale_color_manual(values = c("GIIPS" = giips_color, "Core" = core_color)) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(
    title = "Average GDP Growth: GIIPS vs Core Countries (2008-2015)",
    subtitle = "GIIPS countries experienced deeper and more prolonged recession",
    x = NULL,
    y = "GDP Growth Rate (%)",
    color = "Country Group"
  )

ggsave(file.path(figures_dir, "fig4_gdp_growth_comparison.png"),
       fig4, width = 10, height = 6, dpi = 300)
cat("  ✓ Figure 4 saved\n\n")

# ==============================================================================
# 6. Figure 5: Unemployment Rates Comparison
# ==============================================================================

cat("6. Creating Figure 5: Unemployment comparison...\n")

unemp_group <- master_data %>%
  filter(!is.na(unemployment)) %>%
  group_by(date, country_group) %>%
  summarise(unemployment = mean(unemployment, na.rm = TRUE), .groups = "drop")

fig5 <- ggplot(unemp_group, aes(x = date, y = unemployment,
                                 color = country_group, group = country_group)) +
  geom_line(linewidth = 1) +
  scale_color_manual(values = c("GIIPS" = giips_color, "Core" = core_color)) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(
    title = "Average Unemployment Rates: GIIPS vs Core (2008-2015)",
    subtitle = "Dramatic divergence in labor market outcomes",
    x = NULL,
    y = "Unemployment Rate (%)",
    color = "Country Group"
  )

ggsave(file.path(figures_dir, "fig5_unemployment_comparison.png"),
       fig5, width = 10, height = 6, dpi = 300)
cat("  ✓ Figure 5 saved\n\n")

# ==============================================================================
# 7. Figure 6: Rolling Correlations (Contagion Analysis)
# ==============================================================================

cat("7. Creating Figure 6: Rolling correlations...\n")

# Calculate rolling correlation between Greece and other GIIPS
greece_spreads <- spreads_wide %>% select(date, Greece)

rolling_cor_data <- tibble()

for (country in c("Ireland", "Italy", "Portugal", "Spain")) {
  country_data <- spreads_wide %>%
    select(date, !!sym(country)) %>%
    left_join(greece_spreads, by = "date") %>%
    arrange(date)

  # 6-month (2 quarters) rolling correlation
  roll_cor <- zoo::rollapply(
    data.frame(country_data[[country]], country_data$Greece),
    width = 6,
    FUN = function(x) cor(x[,1], x[,2], use = "complete.obs"),
    by.column = FALSE,
    fill = NA,
    align = "right"
  )

  rolling_cor_data <- bind_rows(
    rolling_cor_data,
    tibble(
      date = country_data$date,
      country = country,
      correlation = as.numeric(roll_cor)
    )
  )
}

fig6 <- ggplot(rolling_cor_data %>% filter(!is.na(correlation)),
               aes(x = date, y = correlation, color = country, group = country)) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = as.Date("2010-05-01"), linetype = "dotted",
             color = "red", alpha = 0.7) +
  annotate("text", x = as.Date("2010-05-01"), y = 0.2,
           label = "Greek bailout", angle = 90, vjust = -0.5, size = 3) +
  scale_color_manual(values = country_colors) +
  scale_y_continuous(limits = c(-0.5, 1)) +
  labs(
    title = "Rolling Correlation of Sovereign Spreads with Greece (6-quarter / 1.5-year window)",
    subtitle = "Evidence of contagion: correlations increase significantly during crisis",
    x = NULL,
    y = "Correlation with Greece",
    color = "Country"
  )

ggsave(file.path(figures_dir, "fig6_rolling_correlations.png"),
       fig6, width = 10, height = 6, dpi = 300)
cat("  ✓ Figure 6 saved\n\n")

# ==============================================================================
# 8. Figure 7: Correlation Heatmap of Spreads
# ==============================================================================

cat("8. Creating Figure 7: Spreads correlation heatmap...\n")

spreads_cor <- spreads_wide %>%
  select(-date) %>%
  cor(use = "pairwise.complete.obs")

spreads_cor_long <- spreads_cor %>%
  as.data.frame() %>%
  rownames_to_column("country1") %>%
  pivot_longer(-country1, names_to = "country2", values_to = "correlation")

fig7 <- ggplot(spreads_cor_long, aes(x = country1, y = country2, fill = correlation)) +
  geom_tile() +
  geom_text(aes(label = round(correlation, 2)), size = 3) +
  scale_fill_gradient2(low = "#3498DB", mid = "white", high = "#E74C3C",
                       midpoint = 0, limits = c(-1, 1)) +
  labs(
    title = "Correlation Matrix of Sovereign Spreads (2008-2015)",
    subtitle = "High correlations among GIIPS countries suggest contagion",
    x = NULL,
    y = NULL,
    fill = "Correlation"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(figures_dir, "fig7_correlation_heatmap.png"),
       fig7, width = 8, height = 7, dpi = 300)
cat("  ✓ Figure 7 saved\n\n")

# ==============================================================================
# 9. Figure 8: Scatter Plot - Debt vs Spreads
# ==============================================================================

cat("9. Creating Figure 8: Debt vs spreads scatter...\n")

fig8 <- ggplot(panel_data %>% filter(!is.na(debt_gdp), !is.na(spread_bps)),
               aes(x = debt_gdp, y = spread_bps, color = country_group)) +
  geom_point(alpha = 0.5, size = 2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1) +
  scale_color_manual(values = c("GIIPS" = giips_color, "Core" = core_color)) +
  scale_x_continuous(labels = label_percent(scale = 1)) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title = "Relationship between Government Debt and Sovereign Spreads",
    subtitle = "Positive relationship stronger for GIIPS countries",
    x = "Government Debt-to-GDP (%)",
    y = "Sovereign Spread (bps)",
    color = "Country Group"
  )

ggsave(file.path(figures_dir, "fig8_debt_spreads_scatter.png"),
       fig8, width = 10, height = 6, dpi = 300)
cat("  ✓ Figure 8 saved\n\n")

# ==============================================================================
# 10. Figure 9: Divergence Index Over Time
# ==============================================================================

cat("10. Creating Figure 9: Divergence index...\n")

divergence_data <- master_data %>%
  group_by(date) %>%
  summarise(
    cv_debt = sd(debt_gdp, na.rm = TRUE) / mean(debt_gdp, na.rm = TRUE),
    cv_unemployment = sd(unemployment, na.rm = TRUE) / mean(unemployment, na.rm = TRUE),
    cv_spread = sd(spread_bps, na.rm = TRUE) / mean(spread_bps[spread_bps > 0], na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_longer(-date, names_to = "metric", values_to = "cv") %>%
  mutate(metric = case_when(
    metric == "cv_debt" ~ "Debt-to-GDP",
    metric == "cv_unemployment" ~ "Unemployment",
    metric == "cv_spread" ~ "Sovereign Spreads"
  ))

fig9 <- ggplot(divergence_data %>% filter(!is.na(cv), is.finite(cv)),
               aes(x = date, y = cv, color = metric, group = metric)) +
  geom_line(linewidth = 1) +
  scale_color_brewer(palette = "Set1") +
  labs(
    title = "Economic Divergence Index (Coefficient of Variation)",
    subtitle = "Higher values indicate greater divergence across countries",
    x = NULL,
    y = "Coefficient of Variation",
    color = "Indicator"
  )

ggsave(file.path(figures_dir, "fig9_divergence_index.png"),
       fig9, width = 10, height = 6, dpi = 300)
cat("  ✓ Figure 9 saved\n\n")

# ==============================================================================
# 11. Figure 10: Germany vs Greece Direct Comparison
# ==============================================================================

cat("11. Creating Figure 10: Germany vs Greece comparison...\n")

de_gr_data <- master_data %>%
  filter(country %in% c("Germany", "Greece")) %>%
  select(date, country, debt_gdp, unemployment, spread_bps, gdp_growth)

# Create panel of 4 charts
p1 <- ggplot(de_gr_data, aes(x = date, y = debt_gdp, color = country)) +
  geom_line(linewidth = 1) +
  scale_color_manual(values = c("Germany" = germany_color, "Greece" = greece_color)) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(title = "Debt-to-GDP", x = NULL, y = "%", color = NULL) +
  theme(legend.position = "none")

p2 <- ggplot(de_gr_data, aes(x = date, y = unemployment, color = country)) +
  geom_line(linewidth = 1) +
  scale_color_manual(values = c("Germany" = germany_color, "Greece" = greece_color)) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(title = "Unemployment", x = NULL, y = "%", color = NULL) +
  theme(legend.position = "none")

p3 <- ggplot(de_gr_data, aes(x = date, y = spread_bps, color = country)) +
  geom_line(linewidth = 1) +
  scale_color_manual(values = c("Germany" = germany_color, "Greece" = greece_color)) +
  scale_y_continuous(labels = label_comma()) +
  labs(title = "Sovereign Spread", x = NULL, y = "bps", color = NULL) +
  theme(legend.position = "none")

p4 <- ggplot(de_gr_data, aes(x = date, y = gdp_growth, color = country)) +
  geom_line(linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  scale_color_manual(values = c("Germany" = germany_color, "Greece" = greece_color)) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(title = "GDP Growth", x = NULL, y = "%", color = NULL)

fig10 <- (p1 | p2) / (p3 | p4) +
  plot_annotation(
    title = "Germany vs Greece: Tale of Two Economies (2008-2015)",
    subtitle = "Dramatic divergence in all key indicators",
    theme = theme(plot.title = element_text(face = "bold", size = 14))
  )

ggsave(file.path(figures_dir, "fig10_germany_greece_panel.png"),
       fig10, width = 12, height = 8, dpi = 300)
cat("  ✓ Figure 10 saved\n\n")

# ==============================================================================
# 12. Figure 11: Event Study - Key Crisis Events
# ==============================================================================

cat("12. Creating Figure 11: Event study visualization...\n")

# Select major events
major_events <- crisis_events %>%
  filter(type == "Policy Response" | event == "Greek Deficit Revelation") %>%
  slice(1:6)

# Create plot with event markers
fig11 <- ggplot(master_data %>% filter(country_group == "GIIPS", !is.na(spread_bps)),
                aes(x = date, y = spread_bps, color = country, group = country)) +
  geom_line(linewidth = 0.8, alpha = 0.7) +
  geom_vline(data = major_events, aes(xintercept = date),
             linetype = "dashed", color = "red", alpha = 0.5) +
  scale_color_manual(values = country_colors) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title = "GIIPS Sovereign Spreads with Major Crisis Events",
    subtitle = "Vertical lines mark key policy interventions",
    x = NULL,
    y = "Sovereign Spread (bps)",
    color = "Country"
  ) +
  theme(legend.position = "right")

ggsave(file.path(figures_dir, "fig11_event_study.png"),
       fig11, width = 12, height = 6, dpi = 300)
cat("  ✓ Figure 11 saved\n\n")

# ==============================================================================
# 13. Figure 12: Box Plots by Period
# ==============================================================================

cat("13. Creating Figure 12: Box plots by period...\n")

period_data <- master_data %>%
  filter(period %in% c("Pre-Crisis", "Crisis", "Recovery")) %>%
  mutate(period = factor(period, levels = c("Pre-Crisis", "Crisis", "Recovery")))

b1 <- ggplot(period_data, aes(x = period, y = spread_bps, fill = country_group)) +
  geom_boxplot() +
  scale_fill_manual(values = c("GIIPS" = giips_color, "Core" = core_color)) +
  scale_y_continuous(labels = label_comma()) +
  labs(title = "Sovereign Spreads", x = NULL, y = "bps", fill = NULL) +
  theme(legend.position = "none")

b2 <- ggplot(period_data, aes(x = period, y = unemployment, fill = country_group)) +
  geom_boxplot() +
  scale_fill_manual(values = c("GIIPS" = giips_color, "Core" = core_color)) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(title = "Unemployment", x = NULL, y = "%", fill = NULL) +
  theme(legend.position = "none")

b3 <- ggplot(period_data, aes(x = period, y = debt_gdp, fill = country_group)) +
  geom_boxplot() +
  scale_fill_manual(values = c("GIIPS" = giips_color, "Core" = core_color)) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(title = "Debt-to-GDP", x = NULL, y = "%", fill = NULL)

fig12 <- (b1 | b2 | b3) +
  plot_annotation(
    title = "Distribution of Key Indicators by Period",
    subtitle = "Pre-Crisis (2008), Crisis (2009-2012), Recovery (2013-2015)",
    theme = theme(plot.title = element_text(face = "bold", size = 14))
  )

ggsave(file.path(figures_dir, "fig12_boxplots_by_period.png"),
       fig12, width = 14, height = 5, dpi = 300)
cat("  ✓ Figure 12 saved\n\n")

# ==============================================================================
# 14. Figure 13: Fiscal Deficit Evolution
# ==============================================================================

cat("14. Creating Figure 13: Fiscal deficits...\n")

fig13 <- ggplot(master_data %>% filter(!is.na(deficit_gdp)),
                aes(x = date, y = deficit_gdp, color = country, group = country)) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = -3, linetype = "dashed", color = "red",
             linewidth = 0.5, alpha = 0.7) +
  geom_hline(yintercept = 0, linetype = "solid", color = "gray50") +
  annotate("text", x = as.Date("2008-06-01"), y = -3.5,
           label = "Maastricht -3% limit", color = "red", size = 3) +
  scale_color_manual(values = country_colors) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(
    title = "Government Budget Balance (% of GDP, 2008-2015)",
    subtitle = "Negative values indicate deficits; dashed line shows Maastricht limit",
    x = NULL,
    y = "Budget Balance (% of GDP)",
    color = "Country"
  ) +
  theme(legend.position = "right")

ggsave(file.path(figures_dir, "fig13_fiscal_deficits.png"),
       fig13, width = 10, height = 6, dpi = 300)
cat("  ✓ Figure 13 saved\n\n")

# ==============================================================================
# 15. Summary Visualization Report
# ==============================================================================

cat(strrep("=", 78), "\n")
cat("VISUALIZATION SUMMARY\n")
cat(strrep("=", 78), "\n\n")

cat("Figures created:\n")
cat("  1. 10-year government bond yields evolution\n")
cat("  2. Sovereign spreads over German Bunds\n")
cat("  3. Government debt-to-GDP ratios\n")
cat("  4. GDP growth comparison (GIIPS vs Core)\n")
cat("  5. Unemployment rates comparison\n")
cat("  6. Rolling correlations (contagion analysis)\n")
cat("  7. Correlation heatmap of spreads\n")
cat("  8. Scatter plot: Debt vs spreads\n")
cat("  9. Divergence index over time\n")
cat("  10. Germany vs Greece panel comparison\n")
cat("  11. Event study with crisis events\n")
cat("  12. Box plots by period\n")
cat("  13. Fiscal deficit evolution\n\n")

cat("All figures saved to:", figures_dir, "\n")
cat("Format: PNG, 300 DPI, optimized for thesis inclusion\n")
cat(strrep("=", 78), "\n\n")

cat("Visualization script completed successfully!\n")
cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("\nNext steps:\n")
cat("  1. Review figures in outputs/figures/\n")
cat("  2. Run scripts/05_econometric_analysis.R for regressions\n")
cat("  3. Include figures in Quarto notebooks for integrated analysis\n")
