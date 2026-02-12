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
		'Very strong': '#565c33',
		Strong: '#7f793c',
		'Moderate-strong': '#8b8374'
	};

	// Key takeaway chart: unemployment vs debt regression coefficients over time
	let viciousCycleSteps = [
		{ label: 'Austerity imposed', value: 0, color: COLORS.warning },
		{ label: 'Unemployment rises', value: 63.4, color: COLORS.giips },
		{ label: 'Spreads increase', value: 63.4, color: COLORS.giips },
		{ label: 'Borrowing costs rise', value: 63.4, color: COLORS.negative },
		{ label: 'Debt increases', value: -5.89, color: '#8b8374' },
		{ label: 'OMT breaks cycle', value: -509, color: COLORS.positive }
	];
</script>

<div class="space-y-10">
	<div>
		<h1 class="text-2xl font-bold" style="color: var(--accent-primary); font-family: var(--font-display)">5. Synthesis</h1>
		<p class="mt-2 text-sm" style="color: var(--text-muted)">
			What the data means for the thesis — strong confirmations, productive challenges, and the key quantitative takeaway.
		</p>
	</div>

	{#if !loaded}
		<div class="py-20 text-center" style="color: var(--text-dim)">Loading data...</div>
	{:else}
		<!-- Key Takeaway -->
		<section class="rounded-lg p-6" style="border: 2px solid rgba(192,142,57,0.4); background: rgba(192,142,57,0.08)">
			<h2 class="text-lg font-bold" style="color: var(--accent-primary); font-family: var(--font-display)">Key Quantitative Takeaway</h2>
			<p class="mt-3 text-sm leading-relaxed" style="color: var(--text-muted)">
				<strong style="color: var(--accent-secondary)">Unemployment, not debt, is the dominant market signal</strong>
				({unempCoef ? unempCoef.estimate.toFixed(1) : '63.4'} bps/1%, p&lt;0.001 vs. unstable debt coefficients). This reframes the crisis narrative:
				ordoliberal crisis management focused on the wrong variable (debt reduction via austerity) while
				the market was pricing labour market distress.
			</p>
			<p class="mt-3 text-sm leading-relaxed" style="color: var(--text-dim)">
				Austerity <em>increased</em> unemployment → which <em>increased</em> spreads → which <em>increased</em>
				borrowing costs → which <em>increased</em> debt — a vicious cycle that only broke when the ECB
				provided a credible backstop (OMT, {omtCoef ? Math.round(omtCoef.estimate) : '-509'} bps). This directly supports the thesis's central argument
				about the counterproductive nature of ordoliberal crisis management.
			</p>

			<!-- Vicious cycle visualisation -->
			<div class="mt-6">
				<h3 class="mb-3 text-xs font-semibold uppercase" style="color: var(--text-dim); font-family: var(--font-body); letter-spacing: 0.08em">The Vicious Cycle</h3>
				<div class="flex flex-wrap items-center gap-2">
					{#each ['Austerity', 'Unemployment ↑', `Spreads ↑ (+${unempCoef ? unempCoef.estimate.toFixed(0) : '63'} bps/1%)`, 'Borrowing costs ↑', 'Debt ↑', 'More austerity'] as step, i}
						<div class="rounded-md px-3 py-1.5 text-xs font-medium" style="border: 1px solid rgba(148,72,57,0.4); background: rgba(148,72,57,0.2); color: #d4a54a">
							{step}
						</div>
						{#if i < 5}
							<span style="color: var(--text-dim)">→</span>
						{/if}
					{/each}
				</div>
				<div class="mt-3 flex items-center gap-2">
					<span class="text-lg font-bold" style="color: var(--color-positive)">↓</span>
					<div class="rounded-md px-3 py-1.5 text-xs font-medium" style="border: 1px solid rgba(127,121,60,0.4); background: rgba(127,121,60,0.2); color: #c9bfb3">
						OMT breaks cycle (-509 bps)
					</div>
				</div>
			</div>
		</section>

		<!-- Strong Confirmations Table -->
		<section class="space-y-4">
			<h2 class="pb-2 text-lg font-semibold" style="color: var(--text-primary); font-family: var(--font-display); border-bottom: 1px solid var(--border-default)">
				Strong Confirmations
			</h2>

			<div class="overflow-x-auto rounded-lg" style="border: 1px solid var(--border-default)">
				<table class="w-full text-sm">
					<thead style="background: var(--bg-surface)">
						<tr>
							<th class="px-4 py-3 text-left text-xs" style="color: var(--text-dim)">Thesis Argument</th>
							<th class="px-4 py-3 text-left text-xs" style="color: var(--text-dim)">Evidence</th>
							<th class="px-4 py-3 text-center text-xs" style="color: var(--text-dim)">Strength</th>
						</tr>
					</thead>
					<tbody>
						{#each confirmations as row}
							<tr style="border-top: 1px solid var(--border-subtle)">
								<td class="px-4 py-3" style="color: var(--text-muted)">{row.argument}</td>
								<td class="px-4 py-3 text-xs" style="color: var(--text-dim)">{row.evidence}</td>
								<td class="px-4 py-3 text-center">
									<span class="rounded-full px-2.5 py-0.5 text-[10px] font-semibold" style="background: {strengthColors[row.strength]}; color: var(--text-primary)">
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
			<h2 class="pb-2 text-lg font-semibold" style="color: var(--text-primary); font-family: var(--font-display); border-bottom: 1px solid var(--border-default)">
				Productive Challenges
			</h2>

			<div class="overflow-x-auto rounded-lg" style="border: 1px solid var(--border-default)">
				<table class="w-full text-sm">
					<thead style="background: var(--bg-surface)">
						<tr>
							<th class="px-4 py-3 text-left text-xs" style="color: var(--text-dim)">Thesis Argument</th>
							<th class="px-4 py-3 text-left text-xs" style="color: var(--text-dim)">Challenge</th>
							<th class="px-4 py-3 text-left text-xs" style="color: var(--text-dim)">Opportunity</th>
						</tr>
					</thead>
					<tbody>
						{#each challenges as row}
							<tr style="border-top: 1px solid var(--border-subtle)">
								<td class="px-4 py-3" style="color: var(--text-muted)">{row.argument}</td>
								<td class="px-4 py-3 text-xs" style="color: var(--accent-primary)">{row.challenge}</td>
								<td class="px-4 py-3 text-xs" style="color: var(--color-positive)">{row.opportunity}</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</section>

		<!-- Summary Stats Grid -->
		<section class="space-y-4">
			<h2 class="pb-2 text-lg font-semibold" style="color: var(--text-primary); font-family: var(--font-display); border-bottom: 1px solid var(--border-default)">
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
			<h2 class="pb-2 text-lg font-semibold" style="color: var(--text-primary); font-family: var(--font-display); border-bottom: 1px solid var(--border-default)">
				Methodological Arsenal
			</h2>

			<div class="grid gap-3 md:grid-cols-3">
				{#each [
					{ title: 'Econometric', methods: ['Two-way FE panel regression', 'Robust clustered SE', 'Driscoll-Kraay SE', 'First-difference model', 'Hausman test', 'Crisis interaction models'] },
					{ title: 'Time Series', methods: ['ADF unit root tests', 'Structural break tests (Chow)', 'Granger causality', 'Rolling correlations', 'Event study analysis'] },
					{ title: 'Multivariate', methods: ['PCA on spreads', 'Hierarchical clustering', 'Sigma/beta convergence', 'Coefficient of variation', 'Distance matrices'] }
				] as group}
					<div class="rounded-lg p-4" style="background: var(--bg-card); border: 1px solid var(--border-default)">
						<h3 class="text-sm font-semibold" style="color: var(--text-muted); font-family: var(--font-display)">{group.title}</h3>
						<ul class="mt-2 space-y-1">
							{#each group.methods as method}
								<li class="text-xs" style="color: var(--text-dim)">{method}</li>
							{/each}
						</ul>
					</div>
				{/each}
			</div>
		</section>
	{/if}
</div>
