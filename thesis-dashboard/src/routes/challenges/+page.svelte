<script lang="ts">
	import { masterData, spreadsWide, dataLoaded, regressionCoefficients } from '$lib/stores/data';
	import LineChart from '$lib/components/LineChart.svelte';
	import BarChart from '$lib/components/BarChart.svelte';
	import CoefficientPlot from '$lib/components/CoefficientPlot.svelte';
	import StatCard from '$lib/components/StatCard.svelte';
	import ThesisClaim from '$lib/components/ThesisClaim.svelte';
	import { GIIPS, COUNTRY_COLORS, COLORS, mean, groupBy, getCoef, sigStars } from '$lib/utils/data';

	let loaded = $derived($dataLoaded);
	let data = $derived($masterData);
	let spreads = $derived($spreadsWide);
	let regCoefs = $derived($regressionCoefficients);

	const crisisEvents = [
		{ date: new Date('2010-05-02'), label: 'Greek Bailout', color: '#EF4444' },
		{ date: new Date('2012-07-26'), label: 'OMT', color: '#10B981' }
	];

	// 3.1 Debt coefficient instability — CSV-driven
	let debtCoeffBars = $derived.by(() => [
		{ label: 'Model 1 (baseline)', value: getCoef(regCoefs, 'debt_gdp', 'Baseline')?.estimate ?? 4.93, color: COLORS.positive },
		{ label: 'Model 2 (+ unemp)', value: getCoef(regCoefs, 'debt_gdp', 'Macro')?.estimate ?? -2.28, color: '#94a3b8' },
		{ label: 'Model 4 (crisis)', value: getCoef(regCoefs, 'debt_gdp', 'Crisis Interactions')?.estimate ?? -5.89, color: COLORS.negative },
		{ label: 'First-Difference', value: getCoef(regCoefs, 'debt_gdp', 'First-Difference')?.estimate ?? 0, color: COLORS.warning }
	]);

	// 3.1b CoefficientPlot data for debt instability
	let debtCoefPlotData = $derived.by(() => {
		if (!regCoefs.length) return [];
		const models = ['Baseline', 'Macro', 'Full', 'Crisis Interactions', 'First-Difference'];
		const result: { variable: string; estimate: number; ci_lower: number; ci_upper: number; model: string; significant: boolean }[] = [];
		for (const m of models) {
			const c = getCoef(regCoefs, 'debt_gdp', m);
			if (c) {
				result.push({
					variable: 'debt gdp',
					estimate: c.estimate,
					ci_lower: c.ci_lower,
					ci_upper: c.ci_upper,
					model: m,
					significant: c.p_value < 0.05
				});
			}
		}
		return result;
	});

	// 3.2 Granger p-value bars
	let grangerBars = $derived.by(() => [
		{ label: 'Greece → Spain', value: 0.003, color: COLORS.positive },
		{ label: 'Greece → Italy', value: 0.11, color: COLORS.warning },
		{ label: 'Greece → Portugal', value: 0.57, color: COLORS.negative },
		{ label: 'Greece → Ireland', value: 0.27, color: COLORS.negative }
	]);

	// 3.3 Rolling average correlation for GIIPS
	let rollingCorSeries = $derived.by(() => {
		if (!spreads.length) return [];

		const window = 6;
		const pairs: [string, string][] = [];
		for (let i = 0; i < GIIPS.length; i++) {
			for (let j = i + 1; j < GIIPS.length; j++) {
				pairs.push([GIIPS[i], GIIPS[j]]);
			}
		}

		const sorted = [...spreads].sort(
			(a, b) => new Date(a.date).getTime() - new Date(b.date).getTime()
		);

		const avgCorPoints: { date: Date; value: number }[] = [];

		for (let k = window; k <= sorted.length; k++) {
			const windowSlice = sorted.slice(k - window, k);
			let totalCor = 0;
			let nPairs = 0;

			for (const [c1, c2] of pairs) {
				const v1 = windowSlice.map((s) => (s as any)[c1]).filter((v: any) => v != null);
				const v2 = windowSlice.map((s) => (s as any)[c2]).filter((v: any) => v != null);
				const n = Math.min(v1.length, v2.length);
				if (n < 3) continue;
				const m1 = mean(v1.slice(0, n));
				const m2 = mean(v2.slice(0, n));
				let num = 0,
					d1 = 0,
					d2 = 0;
				for (let i = 0; i < n; i++) {
					num += (v1[i] - m1) * (v2[i] - m2);
					d1 += (v1[i] - m1) ** 2;
					d2 += (v2[i] - m2) ** 2;
				}
				if (d1 && d2) {
					totalCor += num / Math.sqrt(d1 * d2);
					nPairs++;
				}
			}

			if (nPairs > 0) {
				avgCorPoints.push({
					date: new Date(windowSlice[windowSlice.length - 1].date),
					value: totalCor / nPairs
				});
			}
		}

		return [
			{
				label: 'Avg GIIPS Spread Correlation (6Q rolling)',
				color: COLORS.warning,
				data: avgCorPoints
			}
		];
	});
</script>

<div class="space-y-10">
	<div>
		<h1 class="text-2xl font-bold text-amber-400">3. What the Data Challenges</h1>
		<p class="mt-2 text-sm text-slate-400">
			Three areas where the data complicates or nuances the thesis's arguments — all of which
			<em>strengthen</em> the central critique of ordoliberal crisis management.
		</p>
	</div>

	{#if !loaded}
		<div class="py-20 text-center text-slate-500">Loading data...</div>
	{:else}
		<!-- 3.1 Debt Ambiguity -->
		<section class="space-y-4">
			<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
				3.1 Debt-to-GDP as Crisis Cause — Ambiguous Evidence
			</h2>
			<ThesisClaim
				claim="High debt-to-GDP ratios are a fundamental cause of the crisis (Maastricht violation narrative)."
				chapter="Ordoliberal assumption"
				status="challenged"
			/>

			<div class="grid grid-cols-2 gap-3 md:grid-cols-4">
				<StatCard label="Baseline" value="+{(getCoef(regCoefs, 'debt_gdp', 'Baseline')?.estimate ?? 4.93).toFixed(2)}{sigStars(getCoef(regCoefs, 'debt_gdp', 'Baseline')?.p_value ?? 0)}" detail="Significant alone" color="text-emerald-400" />
				<StatCard label="With Unemployment" value="{(getCoef(regCoefs, 'debt_gdp', 'Macro')?.estimate ?? -2.28).toFixed(2)}{sigStars(getCoef(regCoefs, 'debt_gdp', 'Macro')?.p_value ?? 1)}" detail="Not significant" color="text-slate-400" />
				<StatCard label="Crisis Model" value="{(getCoef(regCoefs, 'debt_gdp', 'Crisis Interactions')?.estimate ?? -5.89).toFixed(2)}{sigStars(getCoef(regCoefs, 'debt_gdp', 'Crisis Interactions')?.p_value ?? 0)}" detail="Significant but NEGATIVE" color="text-amber-400" />
				<StatCard label="Greece-only" value="-22.07" detail="p=0.07, marginally sig." color="text-amber-400" />
			</div>

			{#if debtCoefPlotData.length}
				<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
					<CoefficientPlot
						data={debtCoefPlotData}
						title="Debt-to-GDP Coefficient Across Model Specifications"
						height={300}
					/>
				</div>
			{:else}
				<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
					<BarChart
						bars={debtCoeffBars}
						title="Debt-to-GDP Coefficient Across Model Specifications"
						yLabel="bps per 1% debt increase"
						horizontal={true}
						height={280}
					/>
				</div>
			{/if}

			<div class="rounded-md bg-amber-900/20 border border-amber-800/40 p-4 text-sm text-slate-300">
				<strong class="text-amber-400">Interpretation:</strong> Once you control for unemployment and GDP
				growth, debt <em>per se</em> does not drive spreads upward. The negative sign likely reflects reverse
				causality: countries with rising spreads saw debt explode due to recession + bailout costs. This
				challenges the ordoliberal framing — but actually <strong class="text-amber-300">strengthens</strong>
				your critique of German crisis management.
			</div>
		</section>

		<!-- 3.2 Selective Contagion -->
		<section class="space-y-4">
			<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
				3.2 Selective Contagion vs. Universal Contagion
			</h2>
			<ThesisClaim
				claim="Crisis spread broadly from Greece to all GIIPS countries."
				chapter="Chapter 1 assumption"
				status="challenged"
			/>

			<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
				<BarChart
					bars={grangerBars}
					title="Granger Causality p-values (Greece → target)"
					yLabel="p-value (lower = more significant)"
					yFormat={(v) => v.toFixed(3)}
					horizontal={true}
					height={280}
				/>
			</div>

			<div class="flex items-center gap-2 text-xs text-slate-500">
				<span class="inline-block h-3 w-6 rounded" style="background:{COLORS.positive}"></span> p&lt;0.05 (significant)
				<span class="ml-2 inline-block h-3 w-6 rounded" style="background:{COLORS.negative}"></span> p&gt;0.05 (not significant)
			</div>

			<div class="rounded-md bg-amber-900/20 border border-amber-800/40 p-4 text-sm text-slate-300">
				<strong class="text-amber-400">Reconciliation:</strong> High bilateral correlations (Italy-Spain 0.956)
				and the dominant first PCA component (~75%) suggest a <em>common factor</em> drove all spreads simultaneously —
				but that factor was not Greek contagion specifically. It could have been ECB policy, global risk aversion,
				or Eurozone breakup fears. This is more nuanced than simple Greece-to-periphery contagion.
			</div>
		</section>

		<!-- 3.3 Correlation Decline -->
		<section class="space-y-4">
			<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
				3.3 Correlation Decline During Crisis
			</h2>
			<ThesisClaim
				claim="Correlations should increase during contagion (co-movement increases as panic spreads)."
				chapter="Contagion hypothesis"
				status="challenged"
			/>

			<div class="grid grid-cols-2 gap-3 md:grid-cols-3">
				<StatCard label="Pre-crisis Corr." value="0.98" detail="Very high co-movement" color="text-blue-400" />
				<StatCard label="Crisis Corr." value="0.74" detail="Fell by 24 pp" color="text-amber-400" />
				<StatCard label="Decline" value="-24 pp" detail="Suggests decoupling, not contagion" color="text-red-400" />
			</div>

			{#if rollingCorSeries.length}
				<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
					<LineChart
						series={rollingCorSeries}
						title="Rolling Average GIIPS Spread Correlation"
						yLabel="Correlation"
						yFormat={(v) => v.toFixed(2)}
						events={crisisEvents}
						showLegend={false}
					/>
				</div>
			{/if}

			<div class="rounded-md bg-emerald-900/20 border border-emerald-800/40 p-4 text-sm text-slate-300">
				<strong class="text-emerald-400">Reconciliation:</strong> This is consistent with "wake-up call"
				contagion (Section 1.1) — markets didn't panic blindly but reassessed each country individually
				based on fundamentals. The PCA common factor captures shared vulnerability, while the declining
				correlation captures the differentiated response. This is a <em>more sophisticated</em> story
				than simple contagion.
			</div>
		</section>
	{/if}
</div>
