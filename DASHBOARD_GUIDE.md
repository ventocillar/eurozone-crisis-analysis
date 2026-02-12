# Dashboard Build Guide: SvelteKit + D3 Web App

## Step-by-Step Creation of the Thesis Dashboard

This guide documents every decision made in building the interactive dashboard that maps quantitative analysis to thesis arguments. It serves as both a reproducibility record and a tutorial for building academic data dashboards with SvelteKit and D3.

---

## 1. Technology Choices

### Why SvelteKit?
- **Svelte 5 runes** (`$state`, `$derived`, `$effect`) make reactive data transformations declarative — perfect for a data dashboard where everything derives from a single CSV load
- **SvelteKit** provides file-based routing (each thesis section = a route) and static site generation for easy deployment
- **No virtual DOM overhead** — important when D3 is doing direct DOM manipulation

### Why D3?
- **Full control** over chart rendering — academic visualisations need precise axis labels, annotations, and layout
- **SVG output** — crisp at any resolution, suitable for publication
- D3 handles scales, axes, and data joins; Svelte handles reactivity and lifecycle

### Why Tailwind CSS v4?
- **Utility-first** means no CSS files to maintain — all styling is in the template
- **Dark theme** via `bg-slate-900` / `text-slate-200` — better for data-dense dashboards
- v4 uses `@tailwindcss/vite` plugin (no PostCSS config needed)

---

## 2. Project Scaffolding

### Initial Setup
```bash
npx sv create thesis-dashboard
# Selected: SvelteKit, TypeScript, Tailwind CSS v4
cd thesis-dashboard
npm install d3 @types/d3 d3-dsv
```

### Key Configuration

**`tsconfig.json`**: Set `noImplicitAny: false` to work with D3's callback patterns (D3 heavily uses `any` internally).

**`svelte.config.js`**: Uses `adapter-auto` for development. For deployment, switch to `adapter-static` (GitHub Pages) or `adapter-node` (server).

**`vite.config.ts`**: Standard SvelteKit + Tailwind v4 setup.

---

## 3. Data Layer Architecture

### 3a. Static CSV Files (`static/data/`)

All data is pre-computed by the R pipeline and served as static CSV files:

```
static/data/
├── eurozone_master.csv          # 288-row panel dataset (main data)
├── spreads_wide.csv             # Country spreads in wide format (for correlations)
├── regression_coefficients.csv  # Model coefficients with CIs (drives dashboard)
├── pca_loadings.csv             # PCA component loadings
├── granger_causality_tests.csv  # Granger test results
├── event_study_omt.csv          # OMT event study coefficients
├── unit_root_tests.csv          # ADF test results
└── ... (15 more CSVs)
```

**Why static CSVs instead of an API?**
- No backend needed — the dataset is fixed (historical data, 2008-2015)
- CSVs are human-readable and version-controlled
- `d3-dsv` parses them efficiently with `autoType` for number coercion
- Re-running R scripts updates CSVs, which automatically updates the dashboard

### 3b. Data Loading (`src/lib/utils/data.ts`)

```typescript
import { csvParse, autoType } from 'd3-dsv';

export async function loadCSV<T>(path: string): Promise<T[]> {
  const res = await fetch(path);
  const text = await res.text();
  return csvParse(text, autoType) as T[];
}
```

**`autoType`** automatically converts string columns to numbers, dates, etc. This eliminates manual `Number()` calls throughout the codebase.

### 3c. Svelte Stores (`src/lib/stores/data.ts`)

```typescript
import { writable } from 'svelte/store';

export const masterData = writable<MasterRow[]>([]);
export const spreadsWide = writable<SpreadRow[]>([]);
export const regressionCoefficients = writable<RegressionCoefficient[]>([]);
export const dataLoaded = writable(false);
```

**Why writable stores?** Data is loaded once in `+layout.svelte` and consumed by all pages. Stores provide reactive subscriptions — when data loads, all dependent `$derived` values recompute automatically.

### 3d. Layout Data Loading (`src/routes/+layout.svelte`)

```typescript
onMount(async () => {
  const [master, spreads, regCoefRaw] = await Promise.all([
    loadCSV<MasterRow>('/data/eurozone_master.csv'),
    loadCSV<SpreadRow>('/data/spreads_wide.csv'),
    loadCSV('/data/regression_coefficients.csv').catch(() => [])
  ]);
  masterData.set(master);
  spreadsWide.set(spreads);
  regressionCoefficients.set(parseRegressionCoefficients(regCoefRaw));
  dataLoaded.set(true);
});
```

**`Promise.all`** loads all CSVs in parallel. The `.catch(() => [])` on regression_coefficients provides graceful fallback if the file doesn't exist yet.

### 3e. Utility Functions

```typescript
// Filter valid numbers (preserves 0, removes null/undefined/NaN)
export function validNumbers(arr: (number | null | undefined)[]): number[] {
  return arr.filter((v): v is number => v != null && !isNaN(v));
}

// Lookup a specific coefficient from the CSV
export function getCoef(coefficients, variable, model, seType = 'cluster-robust') {
  return coefficients.find(c =>
    c.variable === variable && c.model === model && c.se_type === seType
  );
}

// Significance stars
export function sigStars(pValue: number): string {
  if (pValue < 0.001) return '***';
  if (pValue < 0.01) return '**';
  if (pValue < 0.05) return '*';
  return ' ns';
}
```

**Critical: `validNumbers` vs `filter(Boolean)`**

JavaScript's `Boolean(0) === false`, so `.filter(Boolean)` drops zeros. For a Eurozone spread dataset where Germany's spread is always 0 bps, this silently removes all German data. `validNumbers` only removes `null`, `undefined`, and `NaN`.

---

## 4. Page Structure (Routing)

The dashboard follows the thesis analysis structure:

```
src/routes/
├── +layout.svelte        # Shell: nav bar, data loading, footer
├── +page.svelte           # Overview: key metrics, section links
├── confirms/+page.svelte  # Section 1: What the data confirms (5 subsections)
├── supplements/+page.svelte # Section 2: What the data supplements (4 subsections)
├── challenges/+page.svelte  # Section 3: What the data challenges (3 subsections)
├── extensions/+page.svelte  # Section 4: What could be added
└── synthesis/+page.svelte   # Section 5: Synthesis and key takeaway
```

Each page follows the same pattern:
1. Import stores + components
2. Derive computed values from data using `$derived`
3. Render with conditional `{#if loaded}` blocks

---

## 5. Component Design

### 5a. StatCard (`src/lib/components/StatCard.svelte`)

A simple display card for key statistics:
```svelte
<StatCard
  label="OMT Effect"
  value="{omtCoef ? Math.round(omtCoef.estimate) : '-509'} bps"
  detail="Medium-term, p<0.001"
  color="text-emerald-400"
/>
```

Values use the pattern `{csvValue ?? fallback}` — the CSV-driven value is used when available, with a hardcoded fallback for resilience.

### 5b. LineChart (`src/lib/components/LineChart.svelte`)

Time series chart accepting multiple series:
```typescript
interface SeriesPoint { date: Date; value: number }
interface Series { label: string; color: string; data: SeriesPoint[] }
```

**Key patterns**:
- D3 renders in `onMount` (needs DOM)
- `ResizeObserver` redraws on container resize
- `$effect(() => { if (series) draw() })` redraws when data changes
- Crisis event annotations via vertical dashed lines

### 5c. BarChart (`src/lib/components/BarChart.svelte`)

Horizontal or vertical bar chart with zero-reference line for coefficient displays.

### 5d. CoefficientPlot (`src/lib/components/CoefficientPlot.svelte`)

Forest plot (point-and-whisker) for regression coefficients:

```typescript
interface CoefPoint {
  variable: string;
  estimate: number;
  ci_lower: number;
  ci_upper: number;
  model: string;
  significant: boolean;
}
```

**Design decisions**:
- **Horizontal layout**: Variables on Y-axis, coefficient magnitude on X-axis
- **Grouped by model**: Each variable row shows multiple models (color-coded)
- **Filled circles** = significant (p < 0.05); **hollow circles** = not significant
- **Whiskers** = 95% confidence interval
- **Zero reference line** (dashed) — coefficients crossing zero are visually ambiguous
- **Dark theme**: Matches dashboard (slate-800 background, white text)

### 5e. Heatmap (`src/lib/components/Heatmap.svelte`)

Correlation matrix heatmap for spread co-movement analysis.

### 5f. ThesisClaim (`src/lib/components/ThesisClaim.svelte`)

Displays a thesis claim with its source chapter and confirmation status (confirmed/supplemented/challenged).

---

## 6. Data Flow: From R to Pixels

```
R Pipeline                    Dashboard
─────────                    ─────────
05_econometric_analysis.R
  │
  ├─ plm() models
  │    │
  │    ├─ coeftest(vcovHC)  ──→  regression_coefficients.csv
  │    ├─ coeftest(vcovSCC) ──→       │
  │    └─ stargazer()       ──→  regression_table_spreads.txt
  │                                   │
  │                                   v
  │                          static/data/ (copied)
  │                                   │
  │                                   v
  │                          +layout.svelte (loadCSV)
  │                                   │
  │                                   v
  │                          stores/data.ts (regressionCoefficients)
  │                                   │
  │                                   v
  │                          getCoef('unemployment', 'Full')
  │                                   │
  │                                   v
  │                          <StatCard value="{coef.estimate}" />
  │                          <CoefficientPlot data={coefPlotData} />
```

### Reactive Chain (Svelte 5 Runes)

```
Store changes ($masterData.set)
  ↓
$derived values recompute (stats, series, coefPlotData)
  ↓
$effect triggers D3 redraw
  ↓
SVG updates in DOM
```

---

## 7. Styling System

### Dark Theme Palette

```typescript
const COLORS = {
  giips: '#E74C3C',      // Red family — distress
  core: '#3498DB',        // Blue family — stability
  positive: '#10B981',    // Emerald — good news (OMT effect)
  negative: '#EF4444',    // Red — bad news
  warning: '#F59E0B',     // Amber — ambiguous
  bg: '#0f172a',          // Slate-900
  surface: '#1e293b',     // Slate-800
  text: '#e2e8f0',        // Slate-200
  textMuted: '#94a3b8'    // Slate-400
};
```

**Country colours** are consistent across all charts — Greece is always red, Germany is always dark blue.

### Tailwind Utility Patterns

- **Cards**: `rounded-lg border border-slate-700 bg-slate-800/40 p-4`
- **Grids**: `grid grid-cols-2 gap-3 md:grid-cols-4` (responsive)
- **Interpretation boxes**: `rounded-md bg-emerald-900/20 border border-emerald-800/40 p-4`
- **Navigation**: `sticky top-0 z-50 ... backdrop-blur`

---

## 8. Running the Dashboard

### Development
```bash
cd thesis-dashboard
npm install
npm run dev
# Opens at http://localhost:5173
```

### Production Build
```bash
npm run build
npm run preview  # Test production build locally
```

### Updating Data
```bash
# 1. Re-run R pipeline
cd ..
Rscript run_all.R

# 2. Copy outputs to dashboard
cp outputs/tables/regression_coefficients.csv thesis-dashboard/static/data/

# 3. Rebuild
cd thesis-dashboard
npm run build
```

---

## 9. Deployment Options

| Platform | Adapter | Command |
|---|---|---|
| GitHub Pages | `adapter-static` | `npm run build` then deploy `build/` |
| Vercel | `adapter-auto` (auto-detected) | Connect repo |
| Netlify | `adapter-auto` (auto-detected) | Connect repo |
| Docker/VPS | `adapter-node` | `node build/index.js` |

For static hosting (recommended for this project — no dynamic data):
```bash
npm install @sveltejs/adapter-static
```
Then update `svelte.config.js`:
```js
import adapter from '@sveltejs/adapter-static';
```

---

## 10. File Reference

### Components (6 files)

| Component | Lines | Purpose |
|---|---|---|
| `LineChart.svelte` | ~170 | Multi-series time series with event annotations |
| `BarChart.svelte` | ~183 | Horizontal/vertical bars with zero line |
| `CoefficientPlot.svelte` | ~170 | Forest plot for regression coefficients |
| `Heatmap.svelte` | ~120 | Correlation matrix |
| `StatCard.svelte` | ~30 | Key metric display card |
| `ThesisClaim.svelte` | ~25 | Thesis argument with status badge |

### Pages (6 files)

| Page | Key Charts | Data Sources |
|---|---|---|
| Overview | StatCards | masterData, regressionCoefficients |
| Confirms | LineChart, Heatmap, BarChart, tables | masterData, spreadsWide, PCA, Granger, event study CSVs |
| Supplements | CoefficientPlot, LineChart | masterData, regressionCoefficients, unit root CSVs |
| Challenges | CoefficientPlot, BarChart, LineChart | masterData, spreadsWide, regressionCoefficients |
| Extensions | Text-only | None (future work descriptions) |
| Synthesis | Tables, StatCards | masterData, regressionCoefficients |

### Utilities (2 files)

| File | Exports |
|---|---|
| `utils/data.ts` | `loadCSV`, `validNumbers`, `mean`, `std`, `groupBy`, `getCoef`, `sigStars`, `parseRegressionCoefficients`, types, constants |
| `stores/data.ts` | `masterData`, `spreadsWide`, `regressionCoefficients`, `dataLoaded` |
