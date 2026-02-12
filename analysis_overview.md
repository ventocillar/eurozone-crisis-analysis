# Eurozone Sovereign Debt Crisis: Empirical Analysis Overview

## Executive Summary

This document provides a comprehensive overview of the empirical analysis supporting the thesis on sovereign debt crisis causes and contagion in the Eurozone. The analysis covers the period 2008-2015, focusing on GIIPS countries (Greece, Ireland, Italy, Portugal, Spain) and core Eurozone members (Germany, France, Netherlands, Austria), with particular attention to the divergence between Germany and Greece.

## Research Questions and Hypotheses

### Primary Research Questions
1. **What factors determined sovereign bond yield spreads during the Eurozone crisis?**
   - Hypothesis: Debt-to-GDP ratios, fiscal deficits, GDP growth, and unemployment significantly explain spread variations

2. **How did the sovereign debt crisis spread across Eurozone countries (contagion)?**
   - Hypothesis: Strong correlation exists between bond spreads of GIIPS countries, indicating contagion effects

3. **What macroeconomic divergence occurred between core and peripheral Eurozone countries?**
   - Hypothesis: GIIPS countries experienced significantly worse macroeconomic outcomes than core countries during 2008-2015

4. **How did policy interventions affect sovereign debt markets?**
   - Hypothesis: ECB interventions and bailout programs reduced bond spreads and stabilized markets

## Data Sources and Variables

### Data Sources
- **Eurostat**: Primary source for macroeconomic indicators and government finance statistics
- **ECB Statistical Data Warehouse**: Government bond yields, ECB policy rates, financial indicators
- **IMF World Economic Outlook**: GDP growth, fiscal indicators, debt projections
- **OECD**: Structural indicators, competitiveness measures

### Key Variables

#### Dependent Variables
- **Government Bond Yields**: 10-year government bond yields (%)
- **Sovereign Spreads**: Difference between country bond yields and German Bund yields (basis points)

#### Independent Variables

**Fiscal Variables**
- Gross government debt-to-GDP ratio (%)
- Government budget deficit/surplus as % of GDP
- Primary balance as % of GDP

**Macroeconomic Variables**
- Real GDP growth rate (%)
- Unemployment rate (%)
- Inflation rate (HICP, %)
- Current account balance as % of GDP

**Financial Variables**
- Credit ratings (converted to numerical scale)
- Banking sector non-performing loans (% of total loans)

**Policy Variables**
- ECB main refinancing rate (%)
- Bailout program amounts (EUR billions)
- Structural reform indices

### Country Coverage
- **GIIPS (Peripheral)**: Greece, Ireland, Italy, Portugal, Spain
- **Core**: Germany, France, Netherlands, Austria
- **Total**: 9 Eurozone countries

### Time Period
- **Main Analysis**: 2008-2015 (quarterly data where available, annual otherwise)
- **Crisis Peak**: 2010-2012
- **Observations**: ~288 country-quarter observations (9 countries × 8 years × 4 quarters)

## Empirical Methodology

### 1. Descriptive Analysis
**Objective**: Characterize the evolution of key variables and document divergence

**Methods**:
- Summary statistics by country and period (pre-crisis 2008, crisis 2009-2012, recovery 2013-2015)
- Time series plots of bond spreads, debt ratios, GDP growth, unemployment
- Correlation matrices of key variables

**Key Outputs**:
- Table 1: Summary statistics of sovereign spreads by country
- Table 2: Macroeconomic indicators by country group (GIIPS vs Core)
- Figure 1: Evolution of 10-year government bond yields (2008-2015)
- Figure 2: Sovereign spreads over German Bunds (2008-2015)
- Figure 3: Government debt-to-GDP ratios evolution
- Figure 4: GDP growth rates comparison (GIIPS vs Core)
- Figure 5: Unemployment rates comparison

### 2. Contagion and Spillover Analysis
**Objective**: Test for contagion effects across countries

**Methods**:
- **Correlation Analysis**: Pairwise correlations of sovereign spreads
  - Full period correlations
  - Rolling 6-month correlations to identify changes during crisis
  - Statistical tests for significant correlation increases

- **Principal Component Analysis**: Identify common factors driving spreads

- **Event Study Analysis**: Impact of key crisis events on spreads
  - Greek bailout announcements
  - ECB policy interventions (LTRO, OMT announcement)
  - Rating downgrades

**Key Outputs**:
- Table 3: Correlation matrix of sovereign spreads
- Figure 6: Rolling correlations between Greek and other GIIPS spreads
- Figure 7: First principal component explaining spread variation
- Table 4: Event study results for major crisis events

**Expected Findings**:
- Significant increase in spread correlations during crisis period
- Evidence of contagion from Greece to other peripheral countries
- Common factors explain 60-80% of spread variation during crisis

### 3. Determinants of Sovereign Spreads (Panel Regression)
**Objective**: Identify factors explaining sovereign spread levels

**Models**:

**Baseline Model**:
```
Spread_it = α + β₁ Debt_it + β₂ Deficit_it + β₃ GDP_growth_it +
            β₄ Unemployment_it + β₅ Current_Account_it +
            CountryFE + TimeFE + ε_it
```

**Extended Model** (includes financial variables):
```
Spread_it = α + β₁ Debt_it + β₂ Deficit_it + β₃ GDP_growth_it +
            β₄ Unemployment_it + β₅ Current_Account_it +
            β₆ Credit_Rating_it + β₇ NPL_it +
            CountryFE + TimeFE + ε_it
```

**Crisis Interaction Model**:
```
Spread_it = α + β₁ Debt_it + β₂ Deficit_it + β₃ GDP_growth_it +
            β₄ (Debt_it × Crisis_t) + β₅ (Deficit_it × Crisis_t) +
            CountryFE + TimeFE + ε_it
```

**Estimation Methods**:
- Fixed effects panel regression (primary)
- Random effects (robustness check)
- Hausman test for model selection
- Robust standard errors clustered by country

**Key Outputs**:
- Table 5: Baseline regression results
- Table 6: Extended model with financial variables
- Table 7: Crisis interaction effects
- Figure 8: Marginal effects of debt-to-GDP on spreads

**Expected Findings**:
- Debt-to-GDP has positive, significant effect on spreads
- Effect magnified during crisis period (interaction term)
- Unemployment and GDP growth also significant predictors
- Model explains 70-85% of spread variation (R²)

### 4. Time Series Analysis
**Objective**: Document temporal patterns and structural breaks

**Methods**:
- **Trend Analysis**: Linear and non-linear trends in key variables
- **Structural Break Tests**:
  - Chow tests for known break dates (e.g., Lehman collapse, Greek crisis)
  - Bai-Perron tests for unknown breaks

- **Unit Root Tests**: Test for stationarity (ADF, PP tests)

- **Granger Causality**: Test whether Greek spreads predict other countries' spreads

**Key Outputs**:
- Table 8: Structural break test results
- Figure 9: Debt sustainability trajectories by country
- Table 9: Granger causality test results
- Figure 10: Impulse response functions (Greek shock on other countries)

**Expected Findings**:
- Structural breaks identified in 2010 (Greek crisis) and 2012 (OMT announcement)
- Evidence of Granger causality from Greek to other GIIPS spreads
- Clear divergence trends between GIIPS and core countries

### 5. Cross-Country Comparison and Divergence
**Objective**: Quantify economic divergence between country groups

**Methods**:
- **Divergence Metrics**:
  - Coefficient of variation for key indicators
  - σ-convergence tests

- **Mean Comparison Tests**:
  - t-tests comparing GIIPS vs Core averages
  - Pre-crisis vs crisis vs recovery periods

- **Cluster Analysis**: Identify country groupings based on economic performance

**Key Outputs**:
- Table 10: Mean comparison tests (GIIPS vs Core)
- Figure 11: Divergence index over time
- Figure 12: Cluster dendrogram of countries
- Table 11: Distance matrix between countries (2015 vs 2008)

**Expected Findings**:
- Significant divergence between GIIPS and core during 2010-2012
- Partial convergence during recovery (2013-2015)
- Germany-Greece divergence most pronounced

## How the Analysis Maps to the Thesis

The systematic mapping below categorises findings into what the data **confirms**, **supplements**, **challenges**, and what **could be added**.

### CONFIRMED — Strong Quantitative Support

| Thesis Argument | Evidence | Strength |
|---|---|---|
| GIIPS-Core divergence (Ch. 1 & 3) | 4 of 5 t-tests p<0.001 (GDP growth p=0.058); cluster analysis naturally separates groups | Very strong |
| Germany-Greece as extreme case (Ch. 2 & 3) | 894 bps mean spread gap; 12.8 pp unemployment gap; largest cluster distance | Very strong |
| Austerity devastated Greek economy (Ch. 2) | Unemployment = strongest predictor (63.4 bps/1%, p<0.001); spreads *higher* during bailout (1,179 bps) than overall average (894 bps) | Very strong |
| OMT was transformational (Ch. 3) | -509 bps medium-term effect (p<0.001); single largest policy impact identified | Very strong |
| Contagion was real (Ch. 1) | PCA PC1 explains ~75% of variance; Greece→Spain Granger causal (F=7.22, p=0.003) | Moderate-strong |

### SUPPLEMENTED — New Quantitative Evidence

1. **Unemployment > Debt as crisis driver**: Unemployment coefficient (63.4 bps/1%) is robust across all specifications; debt coefficient reverses sign when unemployment is included. Markets priced labour market distress, not fiscal metrics.
2. **Non-stationarity / permanent effects**: ADF tests show all variables have unit roots (all p>0.5). Shocks do not mean-revert — supporting the OCA theory critique.
3. **No convergence (sigma or beta)**: Standard deviation of key variables *increased* during crisis and remained elevated; no catch-up growth found. Challenges endogenous OCA theory (Frankel & Rose 1998).
4. **Ireland as quantitative outlier**: +27.1% cumulative GDP (vs Greece -26.9%); loaded on separate PCA component (PC3 = -0.830). Motivates within-type VoC variation analysis.

### CHALLENGED — Productive Complications

1. **Debt-to-GDP as crisis cause**: Coefficient is +4.93*** alone, but -2.28 (ns) with unemployment, and -5.89*** in crisis model. Likely reflects reverse causality. *Strengthens* the critique of ordoliberal fiscal focus.
2. **Universal contagion**: Granger causality confirmed only for Greece→Spain. Other GIIPS pairs not significant. Suggests common factor (ECB policy, breakup fears) rather than direct Greek contagion.
3. **Correlation decline during crisis**: Average spread correlation fell from 0.98 (pre-crisis) to 0.74 (crisis). Consistent with "wake-up call" contagion — markets differentiated by fundamentals.

### KEY QUANTITATIVE TAKEAWAY

**Unemployment, not debt, is the dominant market signal** (63.4 bps/1%, p<0.001 vs. unstable debt coefficients). Ordoliberal crisis management focused on the wrong variable. Austerity increased unemployment → increased spreads → increased borrowing costs → increased debt. This vicious cycle only broke with the OMT (-509 bps).

## Technical Implementation

### R Analysis Pipeline

#### R Packages Used
- **Data Collection**: `eurostat`, `ecb`, `IMF`, `OECD`, `quantmod`
- **Data Manipulation**: `tidyverse`, `dplyr`, `tidyr`, `lubridate`
- **Panel Data**: `plm`, `lmtest`, `sandwich`
- **Time Series**: `tseries`, `strucchange`, `vars`, `urca`
- **Visualization**: `ggplot2`, `gridExtra`, `patchwork`, `gghighlight`
- **Tables**: `stargazer`, `kableExtra`, `modelsummary`
- **Econometrics**: `car`, `broom`, `estimatr`
- **Clustering**: `cluster`, `factoextra`

#### Reproducibility
All analyses are fully reproducible by running:
1. `scripts/01_data_collection.R` - Downloads data (requires internet)
2. `scripts/02_data_cleaning.R` - Processes and merges data
3. `scripts/03_descriptive_stats.R` - Generates summary statistics
4. `scripts/04_visualization.R` - Creates all figures
5. `scripts/05_econometric_analysis.R` - Runs regressions and tests

Alternatively, render the Quarto notebooks in `notebooks/` folder for integrated analysis with narrative.

### Interactive Dashboard (Svelte + D3)

A standalone SvelteKit web application at `thesis-dashboard/` provides interactive visualisation of all quantitative findings mapped to thesis arguments.

#### Technology Stack
- **Framework**: SvelteKit (TypeScript)
- **Visualisation**: D3.js (line charts, bar charts, heatmaps)
- **Styling**: Tailwind CSS v4 (dark theme)
- **Data**: Loads processed CSV files from the R pipeline at runtime

#### Dashboard Structure (5 Sections)
1. **Confirms** — Interactive charts for all 5 confirmed thesis claims (GIIPS-Core divergence, Germany-Greece, austerity effects, OMT turning point, contagion)
2. **Supplements** — Unemployment > debt evidence, unit root tests, convergence analysis, Ireland outlier
3. **Challenges** — Debt coefficient instability, selective contagion, correlation decline
4. **Extensions** — 5 feasible extensions mapped to thesis assumptions
5. **Synthesis** — Summary tables, vicious cycle visualisation, methodology arsenal

#### Running the Dashboard
```bash
cd thesis-dashboard
npm install
npm run dev      # Development: http://localhost:5173
npm run build    # Production build
npm run preview  # Preview production build
```

### Data Storage
- Raw data saved in `data/raw/` (CSV format)
- Processed data in `data/processed/` (RDS and CSV format)
- All R outputs (figures/tables) in `outputs/` folder
- Dashboard data in `thesis-dashboard/static/data/` (CSV copies)

## Script Descriptions

### scripts/01_data_collection.R
**Purpose**: Download and save raw data from all sources

**Data Downloaded**:
- Eurostat: gov_10q_ggdebt, gov_10q_ggnfa, nama_10_gdp, une_rt_q, prc_hicp_manr
- ECB: Government bond yields (IRS.M.*.L.L40.CI.0000.EUR.N.Z), ECB rates
- IMF WEO: General government gross debt, fiscal balance
- OECD: Current account balance, structural indicators

**Output**: Individual CSV files for each indicator in `data/raw/`

### scripts/02_data_cleaning.R
**Purpose**: Clean, merge, and prepare analysis-ready datasets

**Tasks**:
- Harmonize country codes and time periods
- Calculate sovereign spreads (vs Germany)
- Handle missing values (interpolation where appropriate)
- Create crisis period dummy variables
- Merge all datasets into master file

**Output**: `data/processed/eurozone_master.rds`

### scripts/03_descriptive_stats.R
**Purpose**: Generate summary statistics and descriptive tables

**Outputs**:
- Summary statistics by country
- Summary statistics by period and country group
- Correlation matrices
- Basic diagnostic tests

**Saved to**: `outputs/tables/`

### scripts/04_visualization.R
**Purpose**: Create all figures and charts

**Figures Generated** (20+ charts):
- Time series plots of all key variables
- Comparative charts (GIIPS vs Core)
- Scatterplots (spreads vs fundamentals)
- Correlation heatmaps
- Box plots by period
- Event study charts

**Saved to**: `outputs/figures/`

### scripts/05_econometric_analysis.R
**Purpose**: Run all regression models and statistical tests

**Analyses**:
- Panel regressions (FE, RE)
- Structural break tests
- Granger causality tests
- PCA and factor analysis
- Unit root tests
- Event studies

**Outputs**: Regression tables saved to `outputs/tables/`

## Quarto Notebooks

### notebooks/01_sovereign_spreads_analysis.qmd
**Focus**: Regression analysis of spread determinants

**Contents**:
- Introduction and motivation
- Data description
- Model specification
- Estimation results with interpretation
- Robustness checks
- Discussion of findings

**Output**: HTML report with embedded code, tables, and figures

### notebooks/02_contagion_spillovers.qmd
**Focus**: Evidence for contagion effects

**Contents**:
- Contagion definition and measures
- Correlation analysis (static and rolling)
- Principal component analysis
- Event study methodology and results
- Granger causality tests
- Interpretation and policy implications

### notebooks/03_time_series_trends.qmd
**Focus**: Temporal evolution of crisis

**Contents**:
- Time series plots of key indicators
- Structural break analysis
- Unit root tests and stationarity
- Trend decomposition
- Critical events timeline
- Narrative of crisis evolution

### notebooks/04_country_comparisons.qmd
**Focus**: Cross-country divergence and convergence

**Contents**:
- Descriptive comparison GIIPS vs Core
- Statistical tests for differences
- Divergence metrics over time
- Cluster analysis
- Germany vs Greece case study
- Sigma and beta convergence tests
- Policy lessons from divergent paths

### thesis-dashboard/ (SvelteKit + D3)
**Focus**: Interactive mapping of all quantitative findings to thesis arguments

**Structure**: 5 route pages corresponding to Confirms / Supplements / Challenges / Extensions / Synthesis sections, with reactive D3 charts loading processed CSV data at runtime.

## Expected Timeline for Analysis Execution

1. **Data Collection** (01_data_collection.R): 15-30 minutes (depends on API response times)
2. **Data Cleaning** (02_data_cleaning.R): 5-10 minutes
3. **Descriptive Stats** (03_descriptive_stats.R): 5 minutes
4. **Visualization** (04_visualization.R): 10-15 minutes
5. **Econometric Analysis** (05_econometric_analysis.R): 15-20 minutes

**Total**: Approximately 1-1.5 hours for complete analysis

## Key References for Methodology

- **Panel Data**: Baltagi, B. H. (2013). Econometric Analysis of Panel Data
- **Contagion**: Forbes & Rigobon (2002). "No Contagion, Only Interdependence"
- **Sovereign Spreads**: Afonso et al. (2015). "Sovereign credit ratings and financial markets linkages"
- **Structural Breaks**: Bai & Perron (2003). "Computation and analysis of multiple structural change models"

## Validation and Robustness

To ensure reliable results, the analysis includes:
- Multiple model specifications (baseline + extensions)
- Alternative estimation methods (FE, RE, pooled OLS)
- Robust standard errors (clustered by country)
- Diagnostic tests (multicollinearity, heteroskedasticity, autocorrelation)
- Sensitivity analysis (excluding outliers, different time periods)
- Hausman test for FE vs RE model selection

## Current Status (February 2026)

### Completed
- Full R analysis pipeline (scripts 01–05) producing 13 figures, 23 tables
- 4 Quarto notebooks with narrative analysis
- Interactive SvelteKit + D3 dashboard mapping all findings to thesis
- Systematic thesis mapping across 5 categories (confirms/supplements/challenges/extensions/synthesis)

### Key Results Achieved
- **4 of 5 group-difference t-tests significant at p<0.001** (GDP growth at p=0.058) — GIIPS/Core distinction is data-driven
- **Unemployment is dominant spread predictor** (63.4 bps/1%) — reframes the crisis narrative
- **OMT reduced spreads by 509 bps** — quantifies institutional credibility
- **No convergence found** — challenges endogenous OCA theory
- **Debt coefficient unstable** — strengthens critique of ordoliberal fiscal focus

## Future Objectives

### Extension 1: Austerity → Populism Link (Assumption 4)
Add election data (SYRIZA, AfD, Podemos, Five Star) and regress anti-system vote shares on unemployment changes, austerity severity, and MoU dummies. Cross-national regression with 9 countries. **Feasibility: High.**

### Extension 2: OCA Business Cycle Synchronisation (Assumption 6)
Compute pairwise GDP growth correlations for sub-periods (pre-euro, early euro, crisis, recovery) to test Frankel & Rose endogenous OCA hypothesis directly. **Feasibility: High — data already available.**

### Extension 3: Synthetic Control for Greek Counterfactual
Construct counterfactual Greece using non-Eurozone EU countries (Poland, Czech Republic, Romania). Requires sourcing additional data. **Feasibility: Medium.**

### Extension 4: Multiple Structural Break Tests
Extend Chow tests to additional dates: Oct 2009 (deficit revelation), Jul 2012 (Draghi speech), Sep 2012 (OMT), Jul 2015 (referendum). Maps to critical junctures framework. **Feasibility: High — infrastructure exists.**

### Extension 5: Non-linear Debt Effects
Add quadratic debt term (debt_gdp²) or threshold regressions to test whether the Reinhart-Rogoff 90% threshold hypothesis holds. **Feasibility: High — single model specification.**

## Contact and Questions

For questions about the analysis or to request additional tests, please refer to:
- Script comments for implementation details
- Quarto notebooks for integrated analysis and narrative
- Interactive dashboard (`thesis-dashboard/`) for visual exploration
- This overview document for methodological justification

---

**Last Updated**: February 2026
**Analysis Period**: 2008-2015
**Countries**: Greece, Ireland, Italy, Portugal, Spain, Germany, France, Netherlands, Austria
**Primary Software**: R (version 4.0+), Quarto, SvelteKit + D3.js
