<script lang="ts">
	import { masterData, spreadsWide, dataLoaded, regressionCoefficients } from '$lib/stores/data';
	import LineChart from '$lib/components/LineChart.svelte';
	import BarChart from '$lib/components/BarChart.svelte';
	import CoefficientPlot from '$lib/components/CoefficientPlot.svelte';
	import StatCard from '$lib/components/StatCard.svelte';
	import ThesisClaim from '$lib/components/ThesisClaim.svelte';
	import { GIIPS, CORE, COUNTRY_COLORS, COLORS, mean, std, groupBy, validNumbers, getCoef, sigStars, type RegressionCoefficient } from '$lib/utils/data';
	import { loadCSV } from '$lib/utils/data';
	import { onMount } from 'svelte';

	let loaded = $derived($dataLoaded);
	let data = $derived($masterData);
	let regCoefs = $derived($regressionCoefficients);

	let unitRootTests: any[] = $state([]);
	onMount(async () => {
		unitRootTests = await loadCSV('/data/unit_root_tests.csv');
	});

	const crisisEvents = [
		{ date: new Date('2010-05-02'), label: 'Greek Bailout', color: '#944839' },
		{ date: new Date('2012-07-26'), label: 'OMT', color: '#7f793c' }
	];

	// 2.1 Unemployment vs Debt — driven from regression_coefficients.csv
	let regressionBars = $derived.by(() => {
		const unemp = getCoef(regCoefs, 'unemployment', 'Full');
		const gdp = getCoef(regCoefs, 'gdp_growth', 'Full');
		const debtBase = getCoef(regCoefs, 'debt_gdp', 'Baseline');
		const debtMacro = getCoef(regCoefs, 'debt_gdp', 'Macro');
		const debtCrisis = getCoef(regCoefs, 'debt_gdp', 'Crisis Interactions');
		return [
			{ label: 'Unemployment', value: unemp?.estimate ?? 63.4, color: COLORS.giips },
			{ label: 'GDP Growth', value: gdp?.estimate ?? -39.2, color: COLORS.core },
			{ label: 'Debt (baseline)', value: debtBase?.estimate ?? 4.93, color: COLORS.warning },
			{ label: 'Debt (w/ unemp)', value: debtMacro?.estimate ?? -2.28, color: '#8b8374' },
			{ label: 'Debt (crisis)', value: debtCrisis?.estimate ?? -5.89, color: '#6b5d4f' }
		];
	});

	// 2.1b CoefficientPlot data: unemployment vs debt across models
	let coefPlotData = $derived.by(() => {
		if (!regCoefs.length) return [];
		const vars = ['unemployment', 'debt_gdp', 'gdp_growth'];
		const models = ['Baseline', 'Macro', 'Full', 'Crisis Interactions', 'First-Difference'];
		const result: { variable: string; estimate: number; ci_lower: number; ci_upper: number; model: string; significant: boolean }[] = [];
		for (const v of vars) {
			for (const m of models) {
				const c = getCoef(regCoefs, v, m);
				if (c) {
					result.push({
						variable: v.replace('_', ' '),
						estimate: c.estimate,
						ci_lower: c.ci_lower,
						ci_upper: c.ci_upper,
						model: m,
						significant: c.p_value < 0.05
					});
				}
			}
		}
		return result;
	});

	// 2.3 Sigma convergence - SD over time
	let sigmaData = $derived.by(() => {
		if (!data.length) return [];
		const byDate = groupBy(data, 'date');
		const points = Object.entries(byDate)
			.map(([d, rows]) => ({
				date: new Date(d),
				unemp: std(validNumbers(rows.map((r) => r.unemployment))),
				debt: std(validNumbers(rows.map((r) => r.debt_gdp))),
				spread: std(validNumbers(rows.map((r) => r.spread_bps)))
			}))
			.filter((p) => p.unemp > 0)
			.sort((a, b) => +a.date - +b.date);

		return [
			{ label: 'Unemployment SD', color: COLORS.giips, data: points.map((p) => ({ date: p.date, value: p.unemp })) },
			{ label: 'Debt SD', color: COLORS.warning, data: points.map((p) => ({ date: p.date, value: p.debt })) }
		];
	});

	// 2.4 Ireland outlier - cumulative GDP
	let cumulativeGDP = $derived.by(() => {
		if (!data.length) return [];
		const countries = ['Greece', 'Ireland', 'Italy', 'Portugal', 'Spain', 'Germany'];
		return countries.map((c) => {
			const rows = data
				.filter((d) => d.country === c && d.gdp_growth != null)
				.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
			let cum = 0;
			return {
				label: c,
				color: COUNTRY_COLORS[c],
				data: rows.map((r) => {
					cum += r.gdp_growth / 4; // quarterly to approx annual
					return { date: new Date(r.date), value: cum };
				})
			};
		});
	});
</script>

<div class="space-y-10">
	<div>
		<h1 class="text-2xl font-bold" style="color: var(--color-info); font-family: var(--font-display)">2. What the Data Supplements</h1>
		<p class="mt-2 text-sm" style="color: var(--text-muted)">
			New evidence that adds quantitative depth to the thesis's qualitative arguments.
		</p>
	</div>

	{#if !loaded}
		<div class="py-20 text-center" style="color: var(--text-dim)">Loading data...</div>
	{:else}
		<!-- 2.1 Unemployment > Debt -->
		<section class="space-y-4">
			<h2 class="pb-2 text-lg font-semibold" style="color: var(--text-primary); font-family: var(--font-display); border-bottom: 1px solid var(--border-default)">
				2.1 Unemployment > Debt as Crisis Driver
			</h2>
			<ThesisClaim
				claim="Debt-to-GDP and fiscal profligacy as root causes of the crisis."
				chapter="Chapter 3 (Thesis emphasis)"
				status="supplemented"
			/>

			<div class="grid grid-cols-2 gap-3 md:grid-cols-3">
				<StatCard label="Unemployment coeff." value="{(getCoef(regCoefs, 'unemployment', 'Full')?.estimate ?? 63.4).toFixed(1)} bps/1%" detail="p<0.001, robust across all specs" color="text-red-400" />
				<StatCard label="Debt coeff. (baseline)" value="+{(getCoef(regCoefs, 'debt_gdp', 'Baseline')?.estimate ?? 4.93).toFixed(2)}{sigStars(getCoef(regCoefs, 'debt_gdp', 'Baseline')?.p_value ?? 0)}" detail="Significant alone" color="text-amber-400" />
				<StatCard label="Debt coeff. (w/ unemp)" value="{(getCoef(regCoefs, 'debt_gdp', 'Macro')?.estimate ?? -2.28).toFixed(2)}{sigStars(getCoef(regCoefs, 'debt_gdp', 'Macro')?.p_value ?? 1)}" detail="Reverses sign, not significant" color="text-slate-400" />
			</div>

			{#if coefPlotData.length}
				<div class="rounded-lg p-4" style="background: var(--bg-card); border: 1px solid var(--border-default)">
					<CoefficientPlot
						data={coefPlotData}
						title="Coefficient Estimates with 95% CI Across Model Specifications"
						height={420}
					/>
				</div>
				<div class="rounded-md p-3 text-xs" style="background: rgba(15,35,34,0.6); border: 1px solid var(--border-subtle); color: var(--text-dim)">
					<strong style="color: var(--text-muted)">How to read this chart:</strong> Each dot represents the estimated effect of a variable on sovereign bond spreads (in basis points per 1% change). The horizontal whiskers show the 95% confidence interval — if they cross the dashed vertical zero line, the effect is not statistically distinguishable from zero. <strong style="color: var(--text-muted)">Filled circles</strong> indicate statistical significance (p&lt;0.05); <strong style="color: var(--text-muted)">hollow circles</strong> indicate the estimate is not significant. Different colours represent different model specifications, allowing comparison of how robust each variable's effect is across models.
				</div>
			{:else}
				<div class="rounded-lg p-4" style="background: var(--bg-card); border: 1px solid var(--border-default)">
					<BarChart
						bars={regressionBars}
						title="Regression Coefficients: Effect on Spreads (bps per 1% change)"
						yLabel="bps"
						height={320}
					/>
				</div>
			{/if}

			<div class="rounded-md p-4 text-sm" style="background: rgba(24,73,72,0.15); border: 1px solid rgba(24,73,72,0.3); color: var(--text-muted)">
				<strong style="color: #2d6765">Implication:</strong> Ordoliberal crisis management focused on
				debt reduction (Maastricht criteria, Fiscal Compact), but markets cared more about labour market
				health. Austerity <em>increased</em> unemployment, which <em>increased</em> spreads — the opposite
				of the intended effect. This strengthens the critique of mis-targeted policy.
			</div>
		</section>

		<!-- 2.2 Non-Stationarity -->
		<section class="space-y-4">
			<h2 class="pb-2 text-lg font-semibold" style="color: var(--text-primary); font-family: var(--font-display); border-bottom: 1px solid var(--border-default)">
				2.2 Non-Stationarity: Shocks Have Permanent Effects
			</h2>
			<ThesisClaim
				claim="Without automatic stabilisers, shocks become permanent — exactly what OCA theory predicts for a non-optimal currency area without fiscal transfers."
				chapter="New evidence"
				status="supplemented"
			/>

			{#if unitRootTests.length}
				<div class="overflow-x-auto rounded-lg" style="border: 1px solid var(--border-default)">
					<table class="w-full text-sm">
						<thead style="background: var(--bg-surface)">
							<tr>
								<th class="px-4 py-2 text-left text-xs" style="color: var(--text-dim)">Variable</th>
								<th class="px-4 py-2 text-right text-xs" style="color: var(--text-dim)">ADF Statistic</th>
								<th class="px-4 py-2 text-right text-xs" style="color: var(--text-dim)">p-value</th>
								<th class="px-4 py-2 text-center text-xs" style="color: var(--text-dim)">Stationary?</th>
							</tr>
						</thead>
						<tbody>
							{#each unitRootTests as row}
								<tr style="border-top: 1px solid var(--border-subtle)">
									<td class="px-4 py-2 text-xs" style="font-family: var(--font-mono); color: var(--text-muted)">{row.variable}</td>
									<td class="px-4 py-2 text-right text-xs" style="font-family: var(--font-mono); color: var(--text-dim)">{Number(row.adf_statistic).toFixed(3)}</td>
									<td class="px-4 py-2 text-right text-xs" style="font-family: var(--font-mono); color: {Number(row.p_value) < 0.05 ? 'var(--color-positive)' : 'var(--color-negative)'}">{Number(row.p_value).toFixed(3)}</td>
									<td class="px-4 py-2 text-center">{row.stationary === 'TRUE' || row.stationary === true ? '✓ Yes' : '✗ No'}</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{/if}

			<div class="grid grid-cols-2 gap-3 md:grid-cols-3">
				<StatCard label="All p-values" value=">0.5" detail="Cannot reject unit root" color="text-red-400" />
				<StatCard label="Recovery Volatility" value="1.9x" detail="vs pre-crisis levels" color="text-amber-400" />
				<StatCard label="Mean Reversion" value="None" detail="Shocks are permanent" color="text-red-400" />
			</div>

			<div class="rounded-md p-4 text-sm" style="background: rgba(24,73,72,0.15); border: 1px solid rgba(24,73,72,0.3); color: var(--text-muted)">
				<strong style="color: #2d6765">Implication:</strong> Without policy intervention, divergence becomes
				self-reinforcing. This provides statistical backing for the argument about the Eurozone's structural
				incompleteness — exactly what OCA theory predicts for a non-optimal currency area without fiscal transfers.
			</div>
		</section>

		<!-- 2.3 No Convergence -->
		<section class="space-y-4">
			<h2 class="pb-2 text-lg font-semibold" style="color: var(--text-primary); font-family: var(--font-display); border-bottom: 1px solid var(--border-default)">
				2.3 No Convergence — Sigma or Beta
			</h2>
			<ThesisClaim
				claim="Integration did not create convergence conditions; instead, the crisis amplified pre-existing divergences."
				chapter="New evidence (challenges Frankel & Rose 1998)"
				status="supplemented"
			/>

			<div class="grid grid-cols-2 gap-3 md:grid-cols-3">
				<StatCard label="Sigma Convergence" value="None" detail="SD increased during crisis, stayed elevated" color="text-red-400" />
				<StatCard label="Beta Convergence" value="Not significant" detail="No catch-up growth" color="text-red-400" />
				<StatCard label="Spread CV (recovery)" value="1.318" detail="2.1x pre-crisis (0.622)" color="text-amber-400" />
			</div>

			{#if sigmaData.length}
				<div class="rounded-lg p-4" style="background: var(--bg-card); border: 1px solid var(--border-default)">
					<LineChart
						series={sigmaData}
						title="Sigma-Convergence Test: Standard Deviation Over Time"
						yLabel="Standard Deviation"
						events={crisisEvents}
					/>
				</div>
			{/if}

			<div class="rounded-md p-4 text-sm" style="background: rgba(24,73,72,0.15); border: 1px solid rgba(24,73,72,0.3); color: var(--text-muted)">
				<strong style="color: #2d6765">Implication:</strong> Directly challenges Assumption 6 and the endogenous
				OCA hypothesis. The Eurozone's one-size-fits-all monetary policy was structurally inappropriate.
			</div>
		</section>

		<!-- 2.4 Ireland Outlier -->
		<section class="space-y-4">
			<h2 class="pb-2 text-lg font-semibold" style="color: var(--text-primary); font-family: var(--font-display); border-bottom: 1px solid var(--border-default)">
				2.4 Ireland as Outlier — Challenges "Periphery = Failure"
			</h2>
			<ThesisClaim
				claim="Within-type variation: Ireland (LME) recovered through a fundamentally different path, undermining the neat GIIPS grouping."
				chapter="Section 7.2 critique"
				status="supplemented"
			/>

			<div class="grid grid-cols-2 gap-3 md:grid-cols-3">
				<StatCard label="Ireland GDP" value="+27.1%" detail="Cumulative (vs Greece -26.9%)" color="text-emerald-400" />
				<StatCard label="PCA PC3 Loading" value="-0.830" detail="Separate component from other GIIPS" color="text-amber-400" />
				<StatCard label="Ireland Peak Spread" value="791 bps" detail="<½ of Portugal, ¼ of Greece" color="text-blue-400" />
			</div>

			<div class="rounded-lg p-4" style="background: var(--bg-card); border: 1px solid var(--border-default)">
				<LineChart
					series={cumulativeGDP}
					title="Cumulative GDP Growth: Ireland vs Other GIIPS and Germany"
					yLabel="Cumulative %"
					yFormat={(v) => v.toFixed(1) + '%'}
					events={crisisEvents}
				/>
			</div>

			<div class="rounded-md p-4 text-sm" style="background: rgba(24,73,72,0.15); border: 1px solid rgba(24,73,72,0.3); color: var(--text-muted)">
				<strong style="color: #2d6765">Implication:</strong> Ireland's divergent recovery path directly addresses
				the Section 7.2 critique about within-type variation. The thesis acknowledges this qualitatively — this
				data provides the quantitative evidence.
			</div>
		</section>
	{/if}
</div>
