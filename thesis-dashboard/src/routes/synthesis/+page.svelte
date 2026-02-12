<script lang="ts">
	import { masterData, dataLoaded, regressionCoefficients } from '$lib/stores/data';
	import LineChart from '$lib/components/LineChart.svelte';
	import StatCard from '$lib/components/StatCard.svelte';
	import { GIIPS, CORE, COLORS, mean, groupBy, getCoef } from '$lib/utils/data';

	let loaded = $derived($dataLoaded);
	let data = $derived($masterData);
	let regCoefs = $derived($regressionCoefficients);

	let unempCoef = $derived(getCoef(regCoefs, 'unemployment', 'Full'));
	let omtCoef = $derived(getCoef(regCoefs, 'post_omt', 'Crisis Interactions'));

	const confirmations = [
		{
			argument: 'GIIPS-Core divergence is real and measurable',
			evidence: '4 of 5 t-tests p<0.001 (GDP growth p=0.058); cluster analysis confirms',
			strength: 'Very strong'
		},
		{
			argument: 'Greece is an extreme case',
			evidence: 'Largest economic distance from Germany in all metrics',
			strength: 'Very strong'
		},
		{
			argument: 'OMT was transformational',
			evidence: '-509 bps medium-term, p<0.001',
			strength: 'Very strong'
		},
		{
			argument: 'Crisis had permanent effects',
			evidence: 'Unit roots in all variables; no convergence',
			strength: 'Strong'
		},
		{
			argument: 'Contagion existed',
			evidence: 'PCA common factor 75%; Greece→Spain Granger causal',
			strength: 'Moderate-strong'
		}
	];

	const challenges = [
		{
			argument: 'Debt caused the crisis',
			challenge: 'Debt coefficient unstable/negative when controlling for unemployment',
			opportunity: 'Strengthens critique of ordoliberal focus on fiscal rules'
		},
		{
			argument: 'Uniform periphery experience',
			challenge: 'Ireland is a quantitative outlier (PCA, GDP trajectory)',
			opportunity: 'Motivates within-type variation analysis'
		},
		{
			argument: 'Greece→all GIIPS contagion',
			challenge: 'Only Greece→Spain confirmed by Granger',
			opportunity: 'Refine to "common factor + selective transmission"'
		}
	];

	const strengthColors: Record<string, string> = {
		'Very strong': 'bg-emerald-600',
		Strong: 'bg-emerald-700',
		'Moderate-strong': 'bg-emerald-800'
	};

	// Key takeaway chart: unemployment vs debt regression coefficients over time
	let viciousCycleSteps = [
		{ label: 'Austerity imposed', value: 0, color: COLORS.warning },
		{ label: 'Unemployment rises', value: 63.4, color: COLORS.giips },
		{ label: 'Spreads increase', value: 63.4, color: COLORS.giips },
		{ label: 'Borrowing costs rise', value: 63.4, color: COLORS.negative },
		{ label: 'Debt increases', value: -5.89, color: '#94a3b8' },
		{ label: 'OMT breaks cycle', value: -509, color: COLORS.positive }
	];
</script>

<div class="space-y-10">
	<div>
		<h1 class="text-2xl font-bold text-amber-400">5. Synthesis</h1>
		<p class="mt-2 text-sm text-slate-400">
			What the data means for the thesis — strong confirmations, productive challenges, and the key quantitative takeaway.
		</p>
	</div>

	{#if !loaded}
		<div class="py-20 text-center text-slate-500">Loading data...</div>
	{:else}
		<!-- Key Takeaway -->
		<section class="rounded-lg border-2 border-amber-600/40 bg-amber-900/10 p-6">
			<h2 class="text-lg font-bold text-amber-300">Key Quantitative Takeaway</h2>
			<p class="mt-3 text-sm text-slate-300 leading-relaxed">
				<strong class="text-amber-200">Unemployment, not debt, is the dominant market signal</strong>
				({unempCoef ? unempCoef.estimate.toFixed(1) : '63.4'} bps/1%, p&lt;0.001 vs. unstable debt coefficients). This reframes the crisis narrative:
				ordoliberal crisis management focused on the wrong variable (debt reduction via austerity) while
				the market was pricing labour market distress.
			</p>
			<p class="mt-3 text-sm text-slate-400 leading-relaxed">
				Austerity <em>increased</em> unemployment → which <em>increased</em> spreads → which <em>increased</em>
				borrowing costs → which <em>increased</em> debt — a vicious cycle that only broke when the ECB
				provided a credible backstop (OMT, {omtCoef ? Math.round(omtCoef.estimate) : '-509'} bps). This directly supports the thesis's central argument
				about the counterproductive nature of ordoliberal crisis management.
			</p>

			<!-- Vicious cycle visualisation -->
			<div class="mt-6">
				<h3 class="mb-3 text-xs font-semibold text-slate-400 uppercase">The Vicious Cycle</h3>
				<div class="flex flex-wrap items-center gap-2">
					{#each ['Austerity', 'Unemployment ↑', `Spreads ↑ (+${unempCoef ? unempCoef.estimate.toFixed(0) : '63'} bps/1%)`, 'Borrowing costs ↑', 'Debt ↑', 'More austerity'] as step, i}
						<div class="rounded-md border px-3 py-1.5 text-xs font-medium
							{i < 5 ? 'border-red-700/50 bg-red-900/30 text-red-300' : 'border-red-700/50 bg-red-900/30 text-red-300'}">
							{step}
						</div>
						{#if i < 5}
							<span class="text-slate-600">→</span>
						{/if}
					{/each}
				</div>
				<div class="mt-3 flex items-center gap-2">
					<span class="text-emerald-400 text-lg font-bold">↓</span>
					<div class="rounded-md border border-emerald-700/50 bg-emerald-900/30 px-3 py-1.5 text-xs font-medium text-emerald-300">
						OMT breaks cycle (-509 bps)
					</div>
				</div>
			</div>
		</section>

		<!-- Strong Confirmations Table -->
		<section class="space-y-4">
			<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
				Strong Confirmations
			</h2>

			<div class="overflow-x-auto rounded-lg border border-slate-700">
				<table class="w-full text-sm">
					<thead class="bg-slate-800">
						<tr>
							<th class="px-4 py-3 text-left text-xs text-slate-400">Thesis Argument</th>
							<th class="px-4 py-3 text-left text-xs text-slate-400">Evidence</th>
							<th class="px-4 py-3 text-center text-xs text-slate-400">Strength</th>
						</tr>
					</thead>
					<tbody>
						{#each confirmations as row}
							<tr class="border-t border-slate-700/50">
								<td class="px-4 py-3 text-slate-300">{row.argument}</td>
								<td class="px-4 py-3 text-xs text-slate-400">{row.evidence}</td>
								<td class="px-4 py-3 text-center">
									<span class="rounded-full {strengthColors[row.strength]} px-2.5 py-0.5 text-[10px] font-semibold text-white">
										{row.strength}
									</span>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</section>

		<!-- Productive Challenges Table -->
		<section class="space-y-4">
			<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
				Productive Challenges
			</h2>

			<div class="overflow-x-auto rounded-lg border border-slate-700">
				<table class="w-full text-sm">
					<thead class="bg-slate-800">
						<tr>
							<th class="px-4 py-3 text-left text-xs text-slate-400">Thesis Argument</th>
							<th class="px-4 py-3 text-left text-xs text-slate-400">Challenge</th>
							<th class="px-4 py-3 text-left text-xs text-slate-400">Opportunity</th>
						</tr>
					</thead>
					<tbody>
						{#each challenges as row}
							<tr class="border-t border-slate-700/50">
								<td class="px-4 py-3 text-slate-300">{row.argument}</td>
								<td class="px-4 py-3 text-xs text-amber-400">{row.challenge}</td>
								<td class="px-4 py-3 text-xs text-emerald-400">{row.opportunity}</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</section>

		<!-- Summary Stats Grid -->
		<section class="space-y-4">
			<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
				By the Numbers
			</h2>

			<div class="grid grid-cols-2 gap-3 md:grid-cols-4">
				<StatCard label="Panel Observations" value="~288" detail="9 countries × 32 quarters" color="text-slate-300" />
				<StatCard label="Variables Tested" value="8" detail="Spreads, debt, deficit, GDP, unemp, inflation, bond yield, ECB rate" color="text-slate-300" />
				<StatCard label="Statistical Tests" value="40+" detail="t-tests, Granger, ADF, PCA, Hausman, etc." color="text-slate-300" />
				<StatCard label="Significant at p<0.001" value="4/5" detail="Group difference tests (GDP growth p=0.058)" color="text-emerald-400" />
			</div>

			<div class="grid grid-cols-2 gap-3 md:grid-cols-4">
				<StatCard label="Strongest Predictor" value="Unemployment" detail="{unempCoef ? unempCoef.estimate.toFixed(1) : '63.4'} bps per 1%" color="text-amber-400" />
				<StatCard label="Weakest Predictor" value="Debt-to-GDP" detail="Unstable across models" color="text-slate-400" />
				<StatCard label="Largest Policy Effect" value="OMT {omtCoef ? Math.round(omtCoef.estimate) : '-509'} bps" detail="Single largest identified" color="text-emerald-400" />
				<StatCard label="Common Factor" value="75%" detail="PCA PC1 variance explained" color="text-amber-400" />
			</div>
		</section>

		<!-- Methodology Summary -->
		<section class="space-y-4">
			<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
				Methodological Arsenal
			</h2>

			<div class="grid gap-3 md:grid-cols-3">
				{#each [
					{ title: 'Econometric', methods: ['Two-way FE panel regression', 'Robust clustered SE', 'Driscoll-Kraay SE', 'First-difference model', 'Hausman test', 'Crisis interaction models'] },
					{ title: 'Time Series', methods: ['ADF unit root tests', 'Structural break tests (Chow)', 'Granger causality', 'Rolling correlations', 'Event study analysis'] },
					{ title: 'Multivariate', methods: ['PCA on spreads', 'Hierarchical clustering', 'Sigma/beta convergence', 'Coefficient of variation', 'Distance matrices'] }
				] as group}
					<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
						<h3 class="text-sm font-semibold text-slate-300">{group.title}</h3>
						<ul class="mt-2 space-y-1">
							{#each group.methods as method}
								<li class="text-xs text-slate-400">{method}</li>
							{/each}
						</ul>
					</div>
				{/each}
			</div>
		</section>
	{/if}
</div>
