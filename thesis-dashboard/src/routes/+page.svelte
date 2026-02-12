<script lang="ts">
	import { get } from 'svelte/store';
	import { masterData, dataLoaded, regressionCoefficients } from '$lib/stores/data';
	import StatCard from '$lib/components/StatCard.svelte';
	import { GIIPS, CORE, mean, validNumbers, getCoef, type RegressionCoefficient } from '$lib/utils/data';

	let loaded = $derived($dataLoaded);
	let data = $derived($masterData);
	let regCoefs = $derived($regressionCoefficients);

	let unempCoef = $derived(getCoef(regCoefs, 'unemployment', 'Full'));
	let omtCoef = $derived(getCoef(regCoefs, 'post_omt', 'Crisis Interactions'));

	let stats = $derived.by(() => {
		if (!data.length) return null;
		const giips = data.filter((d) => GIIPS.includes(d.country));
		const core = data.filter((d) => CORE.includes(d.country));
		const greece = data.filter((d) => d.country === 'Greece');
		const germany = data.filter((d) => d.country === 'Germany');

		return {
			nObs: data.length,
			nCountries: new Set(data.map((d) => d.country)).size,
			giipsSpread: mean(giips.map((d) => d.spread_bps)),
			coreSpread: mean(core.map((d) => d.spread_bps)),
			giipsUnemp: mean(giips.map((d) => d.unemployment)),
			coreUnemp: mean(core.map((d) => d.unemployment)),
			greecePeakSpread: Math.max(...validNumbers(greece.map((d) => d.spread_bps))),
			greecePeakUnemp: Math.max(...validNumbers(greece.map((d) => d.unemployment))),
			germanyMinUnemp: Math.min(...validNumbers(germany.map((d) => d.unemployment))),
			spreadGap: mean(giips.map((d) => d.spread_bps)) - mean(core.map((d) => d.spread_bps))
		};
	});
</script>

<div class="space-y-8">
	<!-- Hero -->
	<div class="text-center">
		<h1 class="text-3xl font-bold" style="color: var(--text-primary); font-family: var(--font-display)">Of Rules and (Dis)order</h1>
		<p class="mt-2 text-lg" style="color: var(--text-muted)">
			How Quantitative Analysis Maps to the Thesis
		</p>
		<p class="mx-auto mt-4 max-w-2xl text-sm leading-relaxed" style="color: var(--text-dim)">
			This dashboard maps panel regressions, contagion analysis, PCA, Granger causality, event
			studies, structural break tests, convergence tests, and cluster analysis across 9 Eurozone
			countries (2008–2015) to the qualitative arguments in the master's thesis on ordoliberalism,
			institutional design, and political polarisation.
		</p>
	</div>

	{#if !loaded}
		<div class="flex justify-center py-20">
			<div class="animate-pulse" style="color: var(--text-dim)">Loading data...</div>
		</div>
	{:else if stats}
		<!-- Key metrics -->
		<div class="grid grid-cols-2 gap-3 md:grid-cols-4">
			<StatCard
				label="GIIPS-Core Spread Gap"
				value="{Math.round(stats.spreadGap)} bps"
				detail="t=9.359, p<0.001"
				color="text-red-400"
			/>
			<StatCard
				label="Greece Peak Spread"
				value="{Math.round(stats.greecePeakSpread)} bps"
				detail="vs Germany: always 0"
				color="text-red-400"
			/>
			<StatCard
				label="OMT Effect"
				value="{omtCoef ? Math.round(omtCoef.estimate) : '-509'} bps"
				detail="Medium-term, p<0.001"
				color="text-emerald-400"
			/>
			<StatCard
				label="Unemployment Coeff."
				value="{unempCoef ? unempCoef.estimate.toFixed(1) : '63.4'} bps/1%"
				detail="Strongest predictor of spreads"
				color="text-amber-400"
			/>
		</div>

		<!-- Sections overview -->
		<div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
			<a href="/confirms" class="nav-card group rounded-lg p-5 transition-all">
				<div class="flex items-center gap-2">
					<span class="rounded-full px-2 py-0.5 text-xs font-bold" style="background: var(--color-positive); color: var(--text-primary)">1</span>
					<h2 class="font-semibold" style="color: var(--text-primary); font-family: var(--font-display)">What the Data Confirms</h2>
				</div>
				<p class="mt-2 text-xs leading-relaxed" style="color: var(--text-muted)">
					GIIPS-Core divergence, Germany-Greece extremes, austerity effects, OMT turning point, and contagion — 4 of 5 confirmed at p&lt;0.001.
				</p>
				<ul class="mt-3 space-y-1 text-xs" style="color: var(--text-dim)">
					<li>5 subsections with interactive charts</li>
					<li>T-tests, cluster analysis, Granger causality</li>
				</ul>
			</a>

			<a href="/supplements" class="nav-card group rounded-lg p-5 transition-all">
				<div class="flex items-center gap-2">
					<span class="rounded-full px-2 py-0.5 text-xs font-bold" style="background: var(--color-info); color: var(--text-primary)">2</span>
					<h2 class="font-semibold" style="color: var(--text-primary); font-family: var(--font-display)">What the Data Supplements</h2>
				</div>
				<p class="mt-2 text-xs leading-relaxed" style="color: var(--text-muted)">
					Unemployment dominates debt as crisis driver. Non-stationarity shows permanent effects. No convergence found. Ireland as outlier.
				</p>
				<ul class="mt-3 space-y-1 text-xs" style="color: var(--text-dim)">
					<li>4 new evidence streams</li>
					<li>Unit root tests, sigma/beta convergence</li>
				</ul>
			</a>

			<a href="/challenges" class="nav-card group rounded-lg p-5 transition-all">
				<div class="flex items-center gap-2">
					<span class="rounded-full px-2 py-0.5 text-xs font-bold" style="background: var(--accent-primary); color: var(--bg-primary)">3</span>
					<h2 class="font-semibold" style="color: var(--text-primary); font-family: var(--font-display)">What the Data Challenges</h2>
				</div>
				<p class="mt-2 text-xs leading-relaxed" style="color: var(--text-muted)">
					Debt-to-GDP coefficient is unstable. Contagion was selective (Greece to Spain only). Correlations fell during crisis.
				</p>
				<ul class="mt-3 space-y-1 text-xs" style="color: var(--text-dim)">
					<li>3 productive challenges</li>
					<li>Strengthens the thesis critique</li>
				</ul>
			</a>

			<a href="/extensions" class="nav-card group rounded-lg p-5 transition-all">
				<div class="flex items-center gap-2">
					<span class="rounded-full px-2 py-0.5 text-xs font-bold" style="background: var(--color-negative); color: var(--text-primary)">4</span>
					<h2 class="font-semibold" style="color: var(--text-primary); font-family: var(--font-display)">What Could Be Added</h2>
				</div>
				<p class="mt-2 text-xs leading-relaxed" style="color: var(--text-muted)">
					Austerity-to-populism link, OCA business cycle sync, synthetic counterfactual, multiple breaks, non-linear debt.
				</p>
				<ul class="mt-3 space-y-1 text-xs" style="color: var(--text-dim)">
					<li>5 feasible extensions</li>
					<li>Maps to thesis assumptions 4 & 6</li>
				</ul>
			</a>

			<a href="/synthesis" class="nav-card group rounded-lg p-5 transition-all md:col-span-2 lg:col-span-2">
				<div class="flex items-center gap-2">
					<span class="rounded-full px-2 py-0.5 text-xs font-bold" style="background: var(--accent-primary); color: var(--bg-primary)">5</span>
					<h2 class="font-semibold" style="color: var(--text-primary); font-family: var(--font-display)">Synthesis</h2>
				</div>
				<p class="mt-2 text-xs leading-relaxed" style="color: var(--text-muted)">
					Summary tables of strong confirmations and productive challenges. The key takeaway:
					<strong style="color: var(--accent-primary)">unemployment, not debt, is the dominant market signal</strong> —
					reframing the ordoliberal crisis management critique.
				</p>
			</a>
		</div>

		<!-- Quick data overview -->
		<div class="grid grid-cols-2 gap-3 md:grid-cols-5">
			<StatCard label="Observations" value={String(stats.nObs)} color="text-slate-300" />
			<StatCard label="Countries" value={String(stats.nCountries)} color="text-slate-300" />
			<StatCard label="GIIPS Avg Unemp." value={stats.giipsUnemp.toFixed(1) + '%'} color="text-red-400" />
			<StatCard label="Core Avg Unemp." value={stats.coreUnemp.toFixed(1) + '%'} color="text-blue-400" />
			<StatCard label="Greece Peak Unemp." value={stats.greecePeakUnemp.toFixed(1) + '%'} detail={'vs Germany min: ' + stats.germanyMinUnemp.toFixed(1) + '%'} color="text-red-400" />
		</div>
	{/if}
</div>
