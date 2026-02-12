# Methodology: Thought Process and Analytical Design

## "Of Rules and (Dis)order" — Quantitative Analysis Pipeline

This document maps the reasoning behind every analytical choice in the R pipeline and Quarto notebooks. It is designed to make the project reproducible and the methodological decisions transparent for reviewers.

---

## 1. Research Question to Data Strategy

### Core Question
> Does the quantitative evidence support the thesis's argument that ordoliberal crisis management — focused on fiscal austerity and debt reduction — was counterproductive because it targeted the wrong variable?

### Operationalisation

| Thesis Concept | Quantitative Proxy | Source |
|---|---|---|
| "Crisis severity" | Sovereign bond spreads vs Germany (bps) | ECB bond yield data |
| "Fiscal profligacy" (ordoliberal claim) | Debt-to-GDP ratio, budget deficit | Eurostat |
| "Real economy damage" | Unemployment rate, GDP growth | Eurostat |
| "Policy intervention" | OMT announcement dummy, crisis period dummies | Constructed |
| "Contagion" | Cross-country spread correlations, Granger causality | Computed |
| "Convergence/divergence" | Standard deviation across countries, beta-convergence | Computed |

### Why Sovereign Spreads?
Spreads over Germany capture the market's real-time assessment of country risk relative to the Eurozone "safe haven." They reflect both fundamentals and sentiment — exactly what the thesis argues about. Using bps (basis points) gives interpretable coefficients: "a 1% increase in unemployment is associated with X bps higher borrowing cost."

---

## 2. Data Architecture

### 2a. Country Selection (9 countries)

**GIIPS** (periphery): Greece, Ireland, Italy, Portugal, Spain
**Core**: Germany, France, Netherlands, Austria

**Why these?** The GIIPS/Core distinction is central to the thesis argument about two-speed Europe. Germany is included as both the benchmark (spreads = 0 by definition) and the contrasting case. We excluded Belgium, Finland, and Luxembourg due to missing data or idiosyncratic profiles.

### 2b. Time Window: 2008Q1 to 2015Q4

- **Start (2008Q1)**: Pre-crisis baseline — before the Greek fiscal revelations but after the global financial crisis onset
- **End (2015Q4)**: Post-OMT stabilisation with enough quarters to observe medium-term effects
- **Quarterly frequency**: Matches macroeconomic data availability; 32 periods per country = 288 panel observations

### 2c. Variable Construction

**Spread calculation**: `spread_bps = (country_bond_yield - germany_bond_yield) * 100`

Germany spread is always 0 by construction. This is critical for the `filter(Boolean)` bug fix — zero is a valid value that must not be dropped.

**Crisis dummies**:
- `crisis_period`: 1 if date >= 2010-04-01 (Greek bailout quarter), else 0
- `post_omt`: 1 if date >= 2012-07-01 (Draghi "whatever it takes"), else 0
- `debt_crisis`, `deficit_crisis`: Interaction terms (variable * crisis_period)

---

## 3. Econometric Strategy

### 3a. Model Progression (Why 5+ models?)

The models are designed as a **progressive specification test** — each model adds variables to see what happens to earlier coefficients:

| Model | Specification | Purpose |
|---|---|---|
| 1. Baseline | `spread ~ debt + deficit` | Test the ordoliberal narrative: do fiscal variables drive spreads? |
| 2. Macro | `spread ~ debt + deficit + gdp_growth + unemployment` | Add real economy — does debt survive? |
| 3. Full | Model 2 + inflation + ECB rate | Kitchen sink — coefficient stability check |
| 4. Crisis Interactions | Model 2 + debt*crisis + deficit*crisis + post_omt | Key policy question: did relationships change during/after crisis? |
| 5. Random Effects | Same as Model 2 but RE | Hausman test comparison only |
| FD. First-Difference | Model 2 in first differences | Robustness to non-stationarity |

**Key finding from this progression**: Debt-to-GDP goes from +4.93*** (Model 1) to -2.28 ns (Model 2) when unemployment enters. This single result reframes the entire crisis narrative: markets priced unemployment, not debt.

### 3b. Why Fixed Effects?

- **Two-way FE** (country + time): Controls for unobserved country-specific factors (institutional quality, banking exposure) and common time shocks (ECB policy, global risk appetite)
- **Hausman test**: Rejects random effects (p < 0.05), confirming FE is appropriate
- Individual country heterogeneity is the defining feature of the Eurozone crisis — we must control for it

### 3c. Standard Errors: Three Approaches

1. **Default (wrong)**: Assumes i.i.d. errors — clearly violated (heteroskedasticity detected via Breusch-Pagan)
2. **Cluster-robust by country**: `vcovHC(model, cluster="group")` — corrects for within-country correlation, but with only 9 clusters, may be unreliable (cluster-robust requires ~30+ clusters)
3. **Driscoll-Kraay**: `vcovSCC()` — robust to cross-sectional dependence AND heteroskedasticity AND autocorrelation. More appropriate for macro panels with few cross-sections. Added as robustness check

**Decision**: Report cluster-robust as primary (standard in the literature), Driscoll-Kraay as robustness. Both exported to `regression_coefficients.csv`.

### 3d. First-Difference Model

Unit root tests show spreads, debt, and unemployment are non-stationary (ADF p > 0.5). This means levels regressions could be spurious. The FD model estimates:

`delta(spread) ~ delta(debt) + delta(deficit) + delta(gdp_growth) + delta(unemployment)`

This eliminates fixed effects automatically and tests whether *changes* in fundamentals predict *changes* in spreads — a more conservative but cleaner test.

### 3e. Structural Break Tests

**Why May 2010 (Q2)?** The Greek bailout (May 2, 2010) is the canonical crisis trigger. In quarterly data, this maps to `2010-04-01` (Q2 start date), not `2010-05-01` (which doesn't exist in the quarterly grid).

**Method**: Chow test via `strucchange::sctest()` at the known break point. We test whether the relationship between time and spreads changes at this date for each GIIPS country.

---

## 4. Contagion Analysis

### 4a. Three Complementary Tests

Each captures a different contagion mechanism:

| Test | Mechanism | Result |
|---|---|---|
| **Granger causality** | Does Greece *cause* other countries' spreads to rise? | Only Greece -> Spain (p=0.003) |
| **PCA** | Is there a common factor driving all spreads? | PC1 explains ~75% of variance |
| **Correlation analysis** | Do spreads move together? | Correlations *fell* during crisis (0.98 -> 0.74) |

### 4b. Why Correlations Fell (Not Rose)

This initially seems paradoxical — shouldn't contagion increase co-movement? The resolution is "wake-up call contagion": Greece's crisis didn't cause blind panic; it prompted markets to reassess each country individually based on fundamentals. The result is *differentiation* (falling correlations) rather than herd behaviour. The PCA common factor captures shared vulnerability, while falling correlations capture the differentiated response.

### 4c. Selective Granger Causality

Only Greece -> Spain is significant. This doesn't mean no contagion — it means Granger causality is a very strict test (lagged prediction). The high PCA loadings suggest all countries were affected by a common factor (possibly ECB policy uncertainty or breakup fears) rather than sequential Greek contagion.

---

## 5. Event Study Design

### OMT Announcement (July 26, 2012)

**Design**: Two event windows:
- `post_omt_immediate`: Q3-Q4 2012 (announcement quarter)
- `post_omt_medium`: Q1 2013 onward (sustained effect)

**Sample**: GIIPS countries only (Core spreads are near zero — no spread to reduce).

**Finding**: -509 bps medium-term effect (p < 0.001). The immediate effect (-83 bps) is not significant because OMT worked through expectations — markets needed time to believe the commitment was credible.

---

## 6. Diagnostic Tests

| Test | Purpose | Result | Implication |
|---|---|---|---|
| Hausman | FE vs RE | Reject RE | Use fixed effects |
| Breusch-Pagan | Heteroskedasticity | Detected | Use robust SEs |
| Breusch-Godfrey | Serial correlation | Detected | Use Driscoll-Kraay |
| VIF | Multicollinearity | All < 10 | No severe collinearity |
| ADF (unit root) | Stationarity | Non-stationary | Use FD model as robustness |

---

## 7. Output Pipeline

```
R scripts --> outputs/tables/*.csv --> thesis-dashboard/static/data/
                                           |
                                           v
                                  regression_coefficients.csv
                                           |
                                           v
                               Dashboard reads at runtime
                               (no hardcoded values)
```

The `regression_coefficients.csv` is the single source of truth. Every dashboard StatCard and CoefficientPlot reads from this file. Re-running the R pipeline automatically updates the dashboard.

---

## 8. What the Numbers Mean for the Thesis

| Finding | Thesis Implication |
|---|---|
| Unemployment >> Debt as spread driver | Ordoliberal focus on debt was misdirected |
| OMT -509 bps | Breaking ordoliberal rules (no ECB bond purchases) saved the system |
| Debt coefficient reverses sign | Debt wasn't the cause — it was the consequence |
| 4/5 group tests significant | GIIPS-Core distinction is data-driven (GDP growth marginally significant at p=0.058) |
| No convergence | EMU did not create self-correcting mechanisms |
| Ireland outlier | Within-type variation challenges uniform periphery narrative |
| Selective Granger causality | Contagion was a common-factor phenomenon, not sequential |
