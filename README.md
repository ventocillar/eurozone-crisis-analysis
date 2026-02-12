# Of Rules and (Dis)order

**Ordoliberalism, Institutional Design, and Political Polarisation in the Eurozone Crisis**

An empirical analysis of the 2008--2015 Eurozone sovereign debt crisis, coupling a rigorous R econometric pipeline with an interactive SvelteKit + D3.js dashboard. The central finding reframes the crisis narrative: **unemployment, not debt, was the dominant market signal** --- and the policy response targeted the wrong variable.

---

## The Question

Between 2008 and 2015, sovereign bond spreads in Greece reached 3,298 basis points over Germany. Unemployment hit 27.6%. Cumulative GDP fell 26.9%. The standard ordoliberal interpretation blamed fiscal profligacy --- high debt, broken Maastricht rules, moral hazard. The policy response followed: austerity, structural adjustment, conditionality.

This project asks a simple question: **what did markets actually price?**

The answer, across five progressive panel regression specifications, 40+ statistical tests, and 288 panel observations spanning 9 countries and 32 quarters, is unambiguous. A 1% increase in unemployment predicted a **63.4 basis-point** rise in sovereign spreads (p < 0.001, robust across every model specification). The debt-to-GDP coefficient? It starts at +4.93 when tested alone --- then flips to -2.28 (not significant) the moment unemployment enters the model. Markets were pricing labour market devastation, not fiscal metrics.

The implication is a vicious cycle. Austerity increased unemployment. Unemployment increased spreads. Spreads increased borrowing costs. Borrowing costs increased debt. The cycle only broke when the ECB abandoned ordoliberal orthodoxy: Draghi's "whatever it takes" and the OMT programme reduced spreads by **509 basis points** (p < 0.001) --- roughly the entire GIIPS-Core gap, eliminated by a policy that was never even activated.

---

## Key Findings

| Finding | Evidence | Significance |
|---|---|---|
| Unemployment dominates debt as spread predictor | 63.4 bps per 1% unemployment vs. unstable debt coefficient | p < 0.001 across all specs |
| GIIPS-Core divergence is structural | 4 of 5 group-difference t-tests at p < 0.001 | Cluster analysis confirms |
| OMT was transformational | -509 bps medium-term reduction | p < 0.001, t = -6.96 |
| Debt coefficient is unstable | +4.93*** alone, -2.28 ns with unemployment, -5.89*** in crisis model | Likely reverse causality |
| No convergence found | All ADF unit root tests p > 0.5; sigma divergence increased | Challenges endogenous OCA theory |
| Contagion was selective | Greece to Spain only (Granger F = 7.22, p = 0.003) | Common factor, not sequential |
| Ireland is a quantitative outlier | +27.1% cumulative GDP vs. Greece -26.9%; separate PCA component | Challenges uniform periphery narrative |

---

## Project Architecture

```
eurozone_crisis/
|
|-- scripts/                          # R econometric pipeline (5 steps)
|   |-- 01_data_collection.R          # Download from Eurostat, ECB, IMF, OECD
|   |-- 02_data_cleaning.R            # Merge, compute spreads, create dummies
|   |-- 03_descriptive_stats.R        # Summary statistics, group comparisons
|   |-- 04_visualization.R            # 13 publication-quality figures
|   |-- 05_econometric_analysis.R     # Panel regressions, PCA, Granger, ADF, event study
|   +-- download_unemployment.R       # Eurostat unemployment utility
|
|-- run_all.R                         # Master orchestration (runs steps 1-5 with validation)
|
|-- notebooks/                        # 4 Quarto notebooks with narrative analysis
|   |-- 01_sovereign_spreads_analysis.qmd
|   |-- 02_contagion_spillovers.qmd
|   |-- 03_time_series_trends.qmd
|   +-- 04_country_comparisons.qmd
|
|-- data/
|   |-- raw/                          # 9 CSV files from Eurostat, ECB
|   +-- processed/                    # 8 analysis-ready datasets (CSV + RDS)
|
|-- outputs/
|   |-- figures/                      # 13 PNG figures
|   +-- tables/                       # 25 output files (CSV + LaTeX)
|
|-- thesis-dashboard/                 # Interactive SvelteKit + D3 web app
|   |-- src/
|   |   |-- app.html                  # Playfair Display, Inter, JetBrains Mono fonts
|   |   |-- app.css                   # Nattier palette CSS custom properties
|   |   |-- lib/
|   |   |   |-- components/           # 6 reusable D3 chart components
|   |   |   |-- stores/               # Svelte writable stores for reactive data
|   |   |   +-- utils/                # CSV loading, statistics, colour system
|   |   +-- routes/                   # 6 pages mapped to thesis structure
|   +-- static/data/                  # 17 CSV files consumed at runtime
|
+-- Ventocilla Franco_v2.pdf          # The thesis itself
```

---

## The R Pipeline

The analysis runs as a sequential 5-step pipeline. Each script validates its outputs before the next step begins.

### Step 1: Data Collection

Downloads quarterly macroeconomic data for 9 Eurozone countries from four institutional sources:

- **Eurostat**: Debt-to-GDP, deficit, GDP growth, unemployment, inflation (HICP)
- **ECB Statistical Data Warehouse**: 10-year government bond yields, main refinancing rate
- **IMF World Economic Outlook**: General government gross debt, fiscal balance
- **OECD**: Current account balance, structural indicators

**Countries**: Greece, Ireland, Italy, Portugal, Spain (GIIPS) + Germany, France, Netherlands, Austria (Core)

**Window**: 2008 Q1 -- 2015 Q4 (32 quarters, 288 panel observations)

### Step 2: Data Cleaning

Harmonises country codes and time periods across sources. Computes sovereign spreads as `(country_yield - germany_yield) * 100` in basis points. Germany's spread is always zero by construction --- a critical detail, since JavaScript's `filter(Boolean)` silently drops zeros. The script creates crisis period dummies (`crisis_period`, `post_omt`) and interaction terms for the panel regressions.

### Step 3: Descriptive Statistics

Generates summary statistics by country, country group (GIIPS vs. Core), and period (pre-crisis, crisis, recovery). Runs group-comparison t-tests --- 4 of 5 are significant at p < 0.001, with GDP growth marginally significant at p = 0.058. The hierarchical cluster analysis naturally separates countries into two groups matching the GIIPS/Core division, validating the Varieties of Capitalism framework.

### Step 4: Visualization

Produces 13 publication-quality PNG figures: bond yield time series, spread evolution, debt ratios, GDP growth and unemployment comparisons, rolling correlations, correlation heatmaps, debt-spread scatter plots, divergence indices, the Germany-Greece panel, OMT event study, period boxplots, and fiscal deficit trajectories.

### Step 5: Econometric Analysis

The core of the project. Five progressive panel regression specifications test the ordoliberal crisis narrative:

| Model | Specification | Purpose |
|---|---|---|
| 1. Baseline | `spread ~ debt + deficit` | Test the fiscal profligacy narrative |
| 2. Macro | + `gdp_growth + unemployment` | Does debt survive when real economy enters? |
| 3. Full | + `inflation + ECB rate` | Kitchen sink stability check |
| 4. Crisis Interactions | + `debt*crisis + deficit*crisis + post_omt` | Did relationships change during/after the crisis? |
| 5. First-Difference | Model 2 in first differences | Robustness to non-stationarity |

**Standard errors**: Cluster-robust by country (primary) and Driscoll-Kraay (robustness), both exported to `regression_coefficients.csv`. With only 9 clusters, Driscoll-Kraay standard errors --- robust to cross-sectional dependence, heteroskedasticity, and autocorrelation --- are more conservative.

Additional tests: Hausman (rejects random effects), Breusch-Pagan (heteroskedasticity detected), ADF unit root tests (all variables non-stationary, all p > 0.5), Chow structural break tests at May 2010, Granger causality from Greece to each GIIPS country, PCA on spreads (PC1 explains ~75% of variance), and an OMT event study with immediate and medium-term windows.

### Running the Pipeline

```bash
# Full pipeline (~1 hour, requires internet for data download)
Rscript run_all.R

# Or step by step
Rscript scripts/01_data_collection.R
Rscript scripts/02_data_cleaning.R
Rscript scripts/03_descriptive_stats.R
Rscript scripts/04_visualization.R
Rscript scripts/05_econometric_analysis.R
```

**R packages** (installed automatically via `pacman`): `tidyverse`, `plm`, `lmtest`, `sandwich`, `tseries`, `strucchange`, `vars`, `urca`, `broom`, `estimatr`, `stargazer`, `factoextra`, `cluster`, and 20 others.

---

## The Dashboard

The interactive dashboard translates 3,000+ lines of R output into a navigable web application. Every number displayed on screen is read from CSV files produced by the R pipeline --- there are no hardcoded values. Re-running the R scripts automatically updates the dashboard.

### Design Philosophy

The visual language draws from the **MetBrewer Nattier palette** --- inspired by Jean-Marc Nattier's 18th-century French court paintings. The palette replaces the typical cold tech-dashboard aesthetic with warm earth tones: terracotta for GIIPS/periphery distress, deep teal for Core stability, golden ochre for accents and ambiguous findings, olive for positive results.

Typography uses **Playfair Display** (serif) for headings and emphasis --- evoking scholarly authority --- **Inter** for body text and data labels, and **JetBrains Mono** for statistical output. The combination signals that this is academic research, not a fintech product.

### Technology Stack

| Layer | Technology | Rationale |
|---|---|---|
| Framework | SvelteKit (TypeScript) | File-based routing maps 1:1 to thesis sections; Svelte 5 runes make reactive data transforms declarative |
| Visualization | D3.js v7 | Full control over SVG rendering; precise axis labels, annotations, and layout for publication quality |
| Styling | Tailwind CSS v4 + CSS custom properties | Utility-first with a coherent design token system via `--nattier-*` variables |
| Data | Static CSV files via `d3-dsv` | No backend needed for a fixed historical dataset; `autoType` handles number coercion |
| Fonts | Google Fonts (Playfair Display, Inter, JetBrains Mono) | Scholarly serif + clean sans-serif + monospace for data |

### Data Flow

```
R Pipeline                         Dashboard
----------                         ---------
05_econometric_analysis.R
  |
  |-- plm() panel models
  |     |
  |     |-- coeftest(vcovHC)  -->  regression_coefficients.csv
  |     +-- coeftest(vcovSCC) -->       |
  |                                     v
  |                            static/data/ (17 CSVs)
  |                                     |
  |                                     v
  |                            +layout.svelte loads via d3-dsv
  |                                     |
  |                                     v
  |                            Svelte writable stores
  |                                     |
  |                                     v
  |                            $derived values recompute
  |                                     |
  |                                     v
  |                            $effect triggers D3 redraw
  |                                     |
  |                                     v
  |                            SVG renders in browser
```

### Component Architecture

Six reusable D3+Svelte components, each following the same pattern: render in `onMount`, observe resize with `ResizeObserver`, redraw reactively via `$effect`.

| Component | Purpose | Key Features |
|---|---|---|
| `LineChart` | Multi-series time series | Crisis event annotations (dashed vertical lines with auto-staggered labels), warm tooltip with backdrop-blur, 2.5px strokes with round linecaps |
| `BarChart` | Grouped comparisons | Horizontal/vertical modes, rounded corners (`rx: 4`), darker stroke outlines, dashed zero-reference line |
| `CoefficientPlot` | Forest plot for regression coefficients | Grouped by model (colour-coded), filled = significant / hollow = not, whiskers = 95% CI, multi-row legend with "how to read" explainer |
| `Heatmap` | Correlation matrices | Diverging colour scale (teal -- warm white -- terracotta), contrast-aware cell text |
| `StatCard` | Key metric display | Display font for values, uppercase dim labels, colour mapped through CSS variable system |
| `ThesisClaim` | Thesis argument with status badge | Nattier-tinted backgrounds per status (confirmed/supplemented/challenged/extension), italic Playfair Display |

### Dashboard Structure

The dashboard mirrors the thesis analysis through five navigable sections:

1. **What the Data Confirms** --- GIIPS-Core divergence, Germany-Greece extremes, austerity effects, OMT turning point, contagion evidence. Interactive line charts, heatmaps, Granger causality and event study tables.

2. **What the Data Supplements** --- Unemployment dominates debt (coefficient plot across 5 models), non-stationarity (unit root test table), no sigma/beta convergence (SD time series), Ireland as outlier (cumulative GDP comparison).

3. **What the Data Challenges** --- Debt coefficient instability (coefficient plot showing sign reversal), selective Granger causality (bar chart of p-values), correlation decline during crisis (rolling correlation line chart).

4. **What Could Be Added** --- Five feasible extensions: austerity-to-populism link, OCA business cycle synchronisation, synthetic control counterfactual, multiple structural breaks, non-linear debt thresholds.

5. **Synthesis** --- Summary tables of confirmations and productive challenges, the vicious cycle visualisation, full methodology arsenal, and the key quantitative takeaway.

### Running the Dashboard

```bash
cd thesis-dashboard
npm install
npm run dev        # Development server at http://localhost:5173
npm run build      # Production build
npm run preview    # Preview production build locally
```

### Updating Data

When the R pipeline is re-run, CSV outputs update automatically. The dashboard reads these at runtime:

```bash
Rscript run_all.R                                              # Re-run analysis
cp outputs/tables/regression_coefficients.csv \
   thesis-dashboard/static/data/                               # Copy new outputs
cd thesis-dashboard && npm run build                           # Rebuild
```

---

## Methodological Reasoning

### Why Sovereign Spreads?

Spreads over Germany capture the market's real-time assessment of country risk relative to the Eurozone "safe haven." They reflect both fundamentals and sentiment --- precisely the terrain the thesis operates on. Using basis points gives interpretable coefficients: *a 1% increase in unemployment is associated with X bps higher borrowing cost.*

### Why Fixed Effects?

Two-way fixed effects (country + time) control for unobserved country-specific factors (institutional quality, banking exposure, labour market structure) and common time shocks (ECB policy changes, global risk appetite). The Hausman test rejects random effects (p < 0.05). Individual country heterogeneity is the defining feature of the Eurozone crisis --- it must be controlled for.

### Why Progressive Specification?

The five-model sequence is designed as a coefficient stability test. If debt truly drives spreads, its coefficient should survive the addition of other variables. It does not. This single empirical fact --- that debt flips from +4.93*** to -2.28 ns when unemployment enters --- reframes the entire crisis narrative and is the strongest piece of evidence against the ordoliberal "fiscal profligacy" interpretation.

### Why Three SE Approaches?

Default standard errors assume i.i.d. errors (violated: Breusch-Pagan detects heteroskedasticity). Cluster-robust SEs correct for within-country correlation but require ~30+ clusters to be reliable; we have 9. Driscoll-Kraay SEs are robust to cross-sectional dependence, heteroskedasticity, and autocorrelation --- appropriate for macro panels with few cross-sections. Both are reported; conclusions hold under both.

### Why Correlations Fell (Not Rose)

The most counterintuitive finding. If contagion increases co-movement, why did GIIPS spread correlations fall from 0.98 to 0.74 during the crisis? The resolution is "wake-up call contagion": Greece's crisis didn't cause blind panic --- it prompted markets to reassess each country individually based on fundamentals. The PCA common factor (~75%) captures shared vulnerability; the falling correlations capture the differentiated response. This is a more sophisticated story than simple sequential contagion.

---

## Highlights

- **3,000+ lines of R** across 6 scripts producing 13 figures, 25 tables, and 17 dashboard-ready CSV files
- **5 progressive panel regression specifications** testing the ordoliberal narrative, with cluster-robust and Driscoll-Kraay standard errors
- **40+ statistical tests** including Hausman, Breusch-Pagan, ADF unit root, Chow structural break, Granger causality, PCA, sigma/beta convergence, and hierarchical clustering
- **Interactive SvelteKit + D3 dashboard** with 6 chart components, warm Nattier palette, Playfair Display typography, and fully reactive data binding from CSV to SVG
- **Zero hardcoded values** in the dashboard --- every number traces back to a CSV file produced by the R pipeline
- **The vicious cycle visualised**: Austerity --> Unemployment (+63.4 bps) --> Spreads --> Borrowing costs --> Debt --> More austerity ... until OMT breaks it (-509 bps)

## Challenges Encountered

- **9-cluster problem**: Cluster-robust standard errors require ~30+ clusters for asymptotic reliability. With only 9 countries, we supplemented with Driscoll-Kraay SEs and verified that all key coefficients retain significance under both approaches.

- **Non-stationarity**: All variables have unit roots (ADF p > 0.5), meaning levels regressions could be spurious. The first-difference model serves as a robustness check --- unemployment remains the dominant predictor in changes as well as levels.

- **Germany's zero spread**: Sovereign spreads are defined as the difference from Germany, so Germany always has a spread of exactly 0. JavaScript's `filter(Boolean)` treats 0 as falsy and silently drops all German observations. The `validNumbers()` utility function was written specifically to avoid this.

- **Reverse causality in debt**: The negative debt coefficient in the crisis model likely reflects that countries with rising spreads saw their debt explode (recession + bailout costs), not that high debt lowered spreads. This endogeneity strengthens the thesis argument but complicates naive causal interpretation.

- **Svelte 5 + D3 integration**: D3 performs direct DOM manipulation, which can conflict with Svelte's compiler-driven reactivity. The solution: D3 renders inside `onMount` (after the DOM exists), and Svelte's `$effect` triggers complete redraws when data changes, avoiding partial-update conflicts.

- **Tailwind v4 + CSS variables**: Tailwind's utility classes (`bg-slate-800`, `text-emerald-400`) cannot be dynamically interpolated from data. The Nattier redesign replaced all colour-bearing Tailwind classes with inline `style` attributes referencing CSS custom properties (`var(--accent-primary)`), enabling a coherent theme while preserving Tailwind's layout utilities.

- **Colour legibility on dark backgrounds**: Several country colours in the Nattier palette were too close to the dark background (`#0a1514`). Germany's original deep teal (`#022a2a`) was virtually invisible. The solution was a desaturated steel-navy (`#7b96b0`) that reads clearly while remaining elegant. Core/France colours were similarly brightened to `#5ba3a0` for contrast.

---

## Requirements

### R Pipeline
- R >= 4.0
- Internet connection (for Step 1 data download)
- All packages installed automatically via `pacman`

### Dashboard
- Node.js >= 18
- npm >= 9

---

## Licence

Academic use. The thesis PDF and all original analysis are by Renato Ventocilla Franco.

---

*Data: 9 Eurozone countries, 2008 Q1 -- 2015 Q4, ~288 panel observations.*
*Dashboard styled with the MetBrewer Nattier palette after Jean-Marc Nattier (1685--1766).*
