<script lang="ts">
	import { masterData, spreadsWide, dataLoaded, regressionCoefficients } from '$lib/stores/data';
	import LineChart from '$lib/components/LineChart.svelte';
	import BarChart from '$lib/components/BarChart.svelte';
	import Heatmap from '$lib/components/Heatmap.svelte';
	import StatCard from '$lib/components/StatCard.svelte';
	import ThesisClaim from '$lib/components/ThesisClaim.svelte';
	import { GIIPS, CORE, COUNTRY_COLORS, COLORS, mean, std, groupBy, validNumbers, getCoef, sigStars } from '$lib/utils/data';
	import { loadCSV } from '$lib/utils/data';
	import { onMount } from 'svelte';

	let loaded = $derived($dataLoaded);
	let data = $derived($masterData);
	let spreads = $derived($spreadsWide);
	let regCoefs = $derived($regressionCoefficients);

	let unempCoef = $derived(getCoef(regCoefs, 'unemployment', 'Full'));
	let omtMedCoef = $derived(getCoef(regCoefs, 'post_omt_medium', 'Crisis Interactions') ?? getCoef(regCoefs, 'post_omt', 'Crisis Interactions'));

	let pcaLoadings: any[] = $state([]);
	let grangerResults: any[] = $state([]);
	let eventStudy: any[] = $state([]);

	onMount(async () => {
		[pcaLoadings, grangerResults, eventStudy] = await Promise.all([
			loadCSV('/data/pca_loadings.csv'),
			loadCSV('/data/granger_causality_tests.csv'),
			loadCSV('/data/event_study_omt.csv')
		]);
	});

	const crisisEvents = [
		{ date: new Date('2010-05-02'), label: 'Greek Bailout', color: '#EF4444' },
		{ date: new Date('2012-07-26'), label: 'Draghi "whatever it takes"', color: '#10B981' },
		{ date: new Date('2012-09-06'), label: 'OMT', color: '#10B981' }
	];

	// 1.1 GIIPS vs Core spread series
	let spreadSeries = $derived.by(() => {
		if (!data.length) return [];
		const byGroup = groupBy(data, 'country_group');
		return ['GIIPS', 'Core'].map((g) => {
			const rows = byGroup[g] || [];
			const byDate = groupBy(rows, 'date');
			const points = Object.entries(byDate)
				.map(([d, rs]) => ({
					date: new Date(d),
					value: mean(validNumbers(rs.map((r) => r.spread_bps)))
				}))
				.sort((a, b) => +a.date - +b.date);
			return {
				label: g,
				color: g === 'GIIPS' ? COLORS.giips : COLORS.core,
				data: points
			};
		});
	});

	// 1.1 Unemployment series
	let unempSeries = $derived.by(() => {
		if (!data.length) return [];
		const byGroup = groupBy(data, 'country_group');
		return ['GIIPS', 'Core'].map((g) => {
			const rows = byGroup[g] || [];
			const byDate = groupBy(rows, 'date');
			const points = Object.entries(byDate)
				.map(([d, rs]) => ({
					date: new Date(d),
					value: mean(validNumbers(rs.map((r) => r.unemployment)))
				}))
				.sort((a, b) => +a.date - +b.date);
			return { label: g, color: g === 'GIIPS' ? COLORS.giips : COLORS.core, data: points };
		});
	});

	// 1.2 Germany vs Greece
	let deGrSeries = $derived.by(() => {
		if (!data.length) return { spreads: [], unemp: [], gdp: [] };
		const make = (variable: 'spread_bps' | 'unemployment' | 'gdp_growth') => {
			return ['Greece', 'Germany'].map((c) => {
				const rows = data
					.filter((d) => d.country === c)
					.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
				return {
					label: c,
					color: COUNTRY_COLORS[c],
					data: rows.map((r) => ({
						date: new Date(r.date),
						value: r[variable]
					}))
				};
			});
		};
		return { spreads: make('spread_bps'), unemp: make('unemployment'), gdp: make('gdp_growth') };
	});

	// 1.3 All GIIPS country spreads
	let giipsSeries = $derived.by(() => {
		if (!data.length) return [];
		return GIIPS.map((c) => {
			const rows = data
				.filter((d) => d.country === c)
				.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
			return {
				label: c,
				color: COUNTRY_COLORS[c],
				data: rows.map((r) => ({ date: new Date(r.date), value: r.spread_bps }))
			};
		});
	});

	// 1.5 Correlation heatmap data
	let corCells = $derived.by(() => {
		if (!spreads.length) return { cells: [], countries: [] as string[] };
		const countries = GIIPS.filter((c) => c !== 'Germany');
		const cells: { row: string; col: string; value: number }[] = [];
		for (const r of countries) {
			for (const c of countries) {
				const rVals = validNumbers(spreads.map((s) => (s as any)[r]));
				const cVals = validNumbers(spreads.map((s) => (s as any)[c]));
				const n = Math.min(rVals.length, cVals.length);
				if (n < 3) { cells.push({ row: r, col: c, value: 0 }); continue; }
				const mr = mean(rVals.slice(0, n));
				const mc = mean(cVals.slice(0, n));
				let num = 0, dr = 0, dc = 0;
				for (let i = 0; i < n; i++) {
					num += (rVals[i] - mr) * (cVals[i] - mc);
					dr += (rVals[i] - mr) ** 2;
					dc += (cVals[i] - mc) ** 2;
				}
				cells.push({ row: r, col: c, value: dr && dc ? num / Math.sqrt(dr * dc) : 0 });
			}
		}
		return { cells, countries };
	});

	// Stats
	let groupStats = $derived.by(() => {
		if (!data.length) return null;
		const giips = data.filter((d) => GIIPS.includes(d.country));
		const core = data.filter((d) => CORE.includes(d.country));
		return {
			giipsSpread: mean(giips.map((d) => d.spread_bps)),
			coreSpread: mean(core.map((d) => d.spread_bps)),
			giipsUnemp: mean(giips.map((d) => d.unemployment)),
			coreUnemp: mean(core.map((d) => d.unemployment)),
			giipsDebt: mean(giips.map((d) => d.debt_gdp)),
			coreDebt: mean(core.map((d) => d.debt_gdp)),
			greecePeakUnemp: Math.max(...validNumbers(data.filter((d) => d.country === 'Greece').map((d) => d.unemployment))),
			germanyMinUnemp: Math.min(...validNumbers(data.filter((d) => d.country === 'Germany').map((d) => d.unemployment)))
		};
	});
</script>

<div class="space-y-10">
	<div>
		<h1 class="text-2xl font-bold text-emerald-400">1. What the Data Confirms</h1>
		<p class="mt-2 text-sm text-slate-400">
			Five thesis claims directly confirmed by the quantitative analysis, 4 of 5 at p&lt;0.001 (GDP growth p=0.058).
		</p>
	</div>

	{#if !loaded}
		<div class="py-20 text-center text-slate-500">Loading data...</div>
	{:else if groupStats}
		<!-- 1.1 Two-Speed Europe -->
		<section class="space-y-4">
			<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
				1.1 The "Two-Speed Europe" / Core-Periphery Divergence
			</h2>
			<ThesisClaim
				claim="GIIPS and Core countries experienced fundamentally divergent economic trajectories within the same monetary union."
				chapter="Chapter 1 & 3"
				status="confirmed"
			/>

			<div class="grid grid-cols-2 gap-3 md:grid-cols-4">
				<StatCard
					label="GIIPS-Core Spread Gap"
					value="{Math.round(groupStats.giipsSpread - groupStats.coreSpread)} bps"
					detail="t=9.359, p<0.001"
					color="text-red-400"
				/>
				<StatCard
					label="GIIPS Unemployment"
					value="{groupStats.giipsUnemp.toFixed(1)}%"
					detail="vs Core: {groupStats.coreUnemp.toFixed(1)}%"
					color="text-red-400"
				/>
				<StatCard
					label="GIIPS Debt-to-GDP"
					value="{groupStats.giipsDebt.toFixed(1)}%"
					detail="vs Core: {groupStats.coreDebt.toFixed(1)}%"
					color="text-red-400"
				/>
				<StatCard
					label="t-tests"
					value="p<0.001"
					detail="4/5 significant (GDP growth p=0.058)"
					color="text-emerald-400"
				/>
			</div>

			<div class="grid gap-4 lg:grid-cols-2">
				<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
					<LineChart
						series={spreadSeries}
						title="Average Sovereign Spreads: GIIPS vs Core"
						yLabel="Spread (bps)"
						events={crisisEvents}
					/>
				</div>
				<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
					<LineChart
						series={unempSeries}
						title="Average Unemployment: GIIPS vs Core"
						yLabel="Unemployment (%)"
						yFormat={(v) => v.toFixed(1) + '%'}
						events={crisisEvents}
					/>
				</div>
			</div>

			<div class="rounded-md bg-emerald-900/20 border border-emerald-800/40 p-4 text-sm text-slate-300">
				<strong class="text-emerald-400">Strength:</strong> The statistical significance of group differences (4 of 5 at p&lt;0.001; GDP growth p=0.058)
				means the GIIPS-Core distinction is not arbitrary but data-driven. The hierarchical cluster analysis
				<em>naturally separates</em> countries into two clusters matching the GIIPS/Core division — directly
				supporting the VoC framework (Assumption 3).
			</div>
		</section>

		<!-- 1.2 Germany-Greece -->
		<section class="space-y-4">
			<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
				1.2 The Germany-Greece Divergence as Extreme Case
			</h2>
			<ThesisClaim
				claim="Germany and Greece represent polar extremes within the Eurozone, illustrating the structural incompatibility of CMEs and MMEs under a single currency."
				chapter="Chapter 2 & 3"
				status="confirmed"
			/>

			<div class="grid grid-cols-2 gap-3 md:grid-cols-4">
				<StatCard label="Spread Gap" value="894 bps" detail="Greece peaked at 3,298 bps" color="text-red-400" />
				<StatCard label="Unemployment Gap" value="12.8 pp" detail="Greece 27.6% vs Germany 4.5%" color="text-red-400" />
				<StatCard label="Debt Gap" value="78.7 pp" detail="Greece 153% vs Germany 74%" color="text-red-400" />
				<StatCard label="GDP Growth Gap" value="4.1 pp" detail="Greece: -26.9% cumulative" color="text-red-400" />
			</div>

			<div class="grid gap-4 lg:grid-cols-3">
				<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
					<LineChart
						series={deGrSeries.spreads}
						title="Sovereign Spreads"
						yLabel="bps"
						events={crisisEvents}
						height={320}
					/>
				</div>
				<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
					<LineChart
						series={deGrSeries.unemp}
						title="Unemployment Rate"
						yLabel="%"
						yFormat={(v) => v.toFixed(1) + '%'}
						events={crisisEvents}
						height={320}
					/>
				</div>
				<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
					<LineChart
						series={deGrSeries.gdp}
						title="GDP Growth Rate"
						yLabel="%"
						yFormat={(v) => v.toFixed(1) + '%'}
						events={crisisEvents}
						height={320}
					/>
				</div>
			</div>
		</section>

		<!-- 1.3 Austerity -->
		<section class="space-y-4">
			<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
				1.3 Austerity and Labour Market Devastation
			</h2>
			<ThesisClaim
				claim="Troika-imposed austerity destroyed the Greek economy and produced a humanitarian crisis."
				chapter="Chapter 2"
				status="confirmed"
			/>

			<div class="grid grid-cols-2 gap-3 md:grid-cols-4">
				<StatCard
					label="Unemployment → Spreads"
					value="{unempCoef ? unempCoef.estimate.toFixed(1) : '63.4'} bps/1%"
					detail="p<0.001 — strongest predictor"
					color="text-amber-400"
				/>
				<StatCard
					label="Greece-specific"
					value="141.2 bps/1%"
					detail="Unemployment coefficient"
					color="text-red-400"
				/>
				<StatCard
					label="Bailout Funding"
					value="EUR 274.5B"
					detail="3.4x more than Ireland"
					color="text-amber-400"
				/>
				<StatCard
					label="Spreads During Bailout"
					value="1,179 bps"
					detail="Higher than overall avg (894)"
					color="text-red-400"
				/>
			</div>

			<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
				<LineChart
					series={giipsSeries}
					title="GIIPS Sovereign Spreads with Crisis Events"
					yLabel="Spread (bps)"
					events={crisisEvents}
					height={380}
				/>
			</div>

			<div class="rounded-md bg-amber-900/20 border border-amber-800/40 p-4 text-sm text-slate-300">
				<strong class="text-amber-400">Critical finding:</strong> Spreads were <em>higher</em> during
				bailout periods than the overall average, challenging the narrative that bailouts stabilised
				markets. Conditionality without credible backstop (pre-OMT) was counterproductive.
			</div>
		</section>

		<!-- 1.4 OMT -->
		<section class="space-y-4">
			<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
				1.4 The OMT as Turning Point
			</h2>
			<ThesisClaim
				claim="Draghi's 'whatever it takes' and the OMT announcement marked a decisive turning point, halting polarisation through institutional credibility."
				chapter="Chapter 3"
				status="confirmed"
			/>

			<div class="grid grid-cols-2 gap-3 md:grid-cols-4">
				<StatCard
					label="OMT Medium-term"
					value="{omtMedCoef ? Math.round(omtMedCoef.estimate) : '-509'} bps"
					detail="p<0.001, t=-6.96"
					color="text-emerald-400"
				/>
				<StatCard
					label="OMT Immediate"
					value="-83 bps"
					detail="Not significant"
					color="text-slate-400"
				/>
				<StatCard
					label="Effect Size"
					value="Eliminates gap"
					detail="509 bps ~ entire GIIPS-Core spread"
					color="text-emerald-400"
				/>
				<StatCard
					label="Break Date"
					value="May 2010"
					detail="Structural break confirmed"
					color="text-amber-400"
				/>
			</div>

			{#if eventStudy.length}
				<div class="overflow-x-auto rounded-lg border border-slate-700">
					<table class="w-full text-sm">
						<thead class="bg-slate-800">
							<tr>
								<th class="px-4 py-2 text-left text-xs text-slate-400">Variable</th>
								<th class="px-4 py-2 text-right text-xs text-slate-400">Estimate</th>
								<th class="px-4 py-2 text-right text-xs text-slate-400">Std. Error</th>
								<th class="px-4 py-2 text-right text-xs text-slate-400">t-value</th>
								<th class="px-4 py-2 text-right text-xs text-slate-400">p-value</th>
							</tr>
						</thead>
						<tbody>
							{#each eventStudy as row}
								<tr class="border-t border-slate-700/50">
									<td class="px-4 py-2 font-mono text-xs text-slate-300">{row.term}</td>
									<td class="px-4 py-2 text-right font-mono text-xs {(row.estimate as number) < 0 ? 'text-emerald-400' : 'text-red-400'}">{Number(row.estimate).toFixed(2)}</td>
									<td class="px-4 py-2 text-right font-mono text-xs text-slate-400">{Number(row.std_error || row['std.error'] || 0).toFixed(2)}</td>
									<td class="px-4 py-2 text-right font-mono text-xs text-slate-400">{Number(row.statistic || 0).toFixed(2)}</td>
									<td class="px-4 py-2 text-right font-mono text-xs {(row.p_value || row['p.value'] || 1) < 0.05 ? 'text-emerald-400 font-semibold' : 'text-slate-400'}">{Number(row.p_value || row['p.value'] || 0).toFixed(4)}</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{/if}

			<div class="rounded-md bg-emerald-900/20 border border-emerald-800/40 p-4 text-sm text-slate-300">
				<strong class="text-emerald-400">Strength:</strong> The 509 bps reduction quantifies the "Merkel paradox" —
				breaking ordoliberal principles (no ECB bond purchases) to save the ordoliberal-designed system.
			</div>
		</section>

		<!-- 1.5 Contagion -->
		<section class="space-y-4">
			<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
				1.5 Contagion Was Real
			</h2>
			<ThesisClaim
				claim="Crisis spread from Greece to other periphery countries through financial linkages and market panic."
				chapter="Chapter 1"
				status="confirmed"
			/>

			<div class="grid grid-cols-2 gap-3 md:grid-cols-4">
				<StatCard label="Greece → Spain" value="F=7.22" detail="p=0.003 (Granger causal)" color="text-emerald-400" />
				<StatCard label="PCA Common Factor" value="~75%" detail="Variance explained by PC1" color="text-amber-400" />
				<StatCard label="Italy-Spain Corr." value="0.956" detail="Highest GIIPS pair" color="text-amber-400" />
				<StatCard label="Peak Timing" value="Q1 2012" detail="6/8 countries peaked together" color="text-amber-400" />
			</div>

			<div class="grid gap-4 lg:grid-cols-2">
				{#if corCells.cells.length}
					<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
						<Heatmap
							cells={corCells.cells}
							rows={corCells.countries}
							cols={corCells.countries}
							title="GIIPS Spread Correlation Matrix"
							height={350}
						/>
					</div>
				{/if}

				{#if pcaLoadings.length}
					<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
						<BarChart
							bars={pcaLoadings.map((r) => ({
								label: String(r.country),
								value: Number(r.PC1),
								color: GIIPS.includes(String(r.country)) ? COLORS.giips : COLORS.core
							}))}
							title="PCA First Component Loadings (Common Crisis Factor)"
							horizontal={true}
							height={350}
						/>
					</div>
				{/if}
			</div>

			{#if grangerResults.length}
				<div class="overflow-x-auto rounded-lg border border-slate-700">
					<table class="w-full text-sm">
						<thead class="bg-slate-800">
							<tr>
								<th class="px-4 py-2 text-left text-xs text-slate-400">Target Country</th>
								<th class="px-4 py-2 text-right text-xs text-slate-400">F-Statistic</th>
								<th class="px-4 py-2 text-right text-xs text-slate-400">p-value</th>
								<th class="px-4 py-2 text-center text-xs text-slate-400">Significant</th>
							</tr>
						</thead>
						<tbody>
							{#each grangerResults as row}
								<tr class="border-t border-slate-700/50">
									<td class="px-4 py-2 text-slate-300">Greece → {row.target_country}</td>
									<td class="px-4 py-2 text-right font-mono text-xs text-slate-400">{Number(row.f_statistic).toFixed(3)}</td>
									<td class="px-4 py-2 text-right font-mono text-xs {Number(row.p_value) < 0.05 ? 'text-emerald-400' : 'text-slate-400'}">{Number(row.p_value).toFixed(4)}</td>
									<td class="px-4 py-2 text-center">{row.granger_causes === 'TRUE' || row.granger_causes === true ? '✓' : '—'}</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{/if}

			<div class="rounded-md bg-amber-900/20 border border-amber-800/40 p-4 text-sm text-slate-300">
				<strong class="text-amber-400">Nuance:</strong> Granger causality from Greece was confirmed
				only for Spain (not Italy, Portugal, Ireland). Contagion existed but was selective — the high PCA
				loading suggests a common factor, possibly ECB policy or breakup fears rather than direct Greek contagion.
			</div>
		</section>
	{/if}
</div>
