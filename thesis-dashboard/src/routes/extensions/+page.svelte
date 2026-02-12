<script lang="ts">
	import ThesisClaim from '$lib/components/ThesisClaim.svelte';
</script>

<div class="space-y-10">
	<div>
		<h1 class="text-2xl font-bold text-purple-400">4. What Could Be Added</h1>
		<p class="mt-2 text-sm text-slate-400">
			Five feasible extensions that would deepen the quantitative evidence, mapped to specific thesis assumptions.
		</p>
	</div>

	<!-- 4.1 Austerity → Populism -->
	<section class="space-y-4">
		<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
			4.1 Testing Assumption 4: Austerity → Populism Link
		</h2>
		<ThesisClaim
			claim="Austerity produces political polarisation and populist backlash."
			chapter="Assumption 4"
			status="extension"
		/>

		<div class="grid gap-4 md:grid-cols-2">
			<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
				<h3 class="text-sm font-semibold text-slate-300">Available Data</h3>
				<ul class="mt-2 space-y-1 text-xs text-slate-400">
					<li>Unemployment, GDP growth, austerity proxies (deficit changes) by country</li>
					<li>9 countries x multiple elections</li>
				</ul>
			</div>
			<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
				<h3 class="text-sm font-semibold text-slate-300">Missing but Feasible</h3>
				<ul class="mt-2 space-y-1 text-xs text-slate-400">
					<li>SYRIZA vote share (2012/2015)</li>
					<li>AfD (2013/2017), Podemos, Five Star</li>
					<li>Cross-national regression: anti-system vote ~ unemployment + austerity + MoU dummies</li>
				</ul>
			</div>
		</div>

		<div class="rounded-md bg-purple-900/20 border border-purple-800/40 p-3 text-sm text-slate-300">
			<strong class="text-purple-400">Feasibility:</strong> High. Small N but testable with robust standard errors.
			Directly tests the core thesis hypothesis.
		</div>
	</section>

	<!-- 4.2 OCA / Business Cycle -->
	<section class="space-y-4">
		<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
			4.2 Testing Assumption 6: OCA / Business Cycle Synchronisation
		</h2>
		<ThesisClaim
			claim="The Eurozone satisfies (or can endogenously develop) OCA criteria."
			chapter="Assumption 6 (Frankel & Rose 1998)"
			status="extension"
		/>

		<div class="grid gap-4 md:grid-cols-2">
			<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
				<h3 class="text-sm font-semibold text-slate-300">Method</h3>
				<p class="mt-2 text-xs text-slate-400">
					Compute pairwise GDP growth correlations for sub-periods (pre-euro 1999–2007, early euro 2002–2008,
					crisis 2009–2012, recovery 2013–2015) to test whether business cycles were converging or diverging.
				</p>
			</div>
			<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
				<h3 class="text-sm font-semibold text-slate-300">Available Data</h3>
				<p class="mt-2 text-xs text-slate-400">
					Quarterly GDP growth for all 9 countries already in the dataset. Beta-convergence test partially
					addresses this but pairwise correlation analysis would be more direct.
				</p>
			</div>
		</div>
	</section>

	<!-- 4.3 Synthetic Control -->
	<section class="space-y-4">
		<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
			4.3 Synthetic Control Method for Greek Counterfactual
		</h2>
		<ThesisClaim
			claim="What would Greece look like without the bailout/MoU?"
			chapter="Counterfactual analysis"
			status="extension"
		/>

		<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
			<h3 class="text-sm font-semibold text-slate-300">Approach</h3>
			<p class="mt-2 text-xs text-slate-400">
				Construct counterfactual Greece using non-Eurozone EU countries (Poland, Czech Republic, Romania)
				to estimate what Greek GDP/unemployment would have looked like without the bailout/MoU. Requires
				sourcing additional country data but is methodologically straightforward using the <code class="text-purple-300">Synth</code> R package.
			</p>
		</div>

		<div class="rounded-md bg-purple-900/20 border border-purple-800/40 p-3 text-sm text-slate-300">
			<strong class="text-purple-400">Feasibility:</strong> Medium. Requires non-Eurozone data but the
			methodology is well-established (Abadie et al. 2010).
		</div>
	</section>

	<!-- 4.4 Multiple Structural Breaks -->
	<section class="space-y-4">
		<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
			4.4 Structural Break Tests at Multiple Crisis Junctures
		</h2>
		<ThesisClaim
			claim="Critical junctures framework from historical institutionalism."
			chapter="Methodological framework"
			status="extension"
		/>

		<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
			<p class="text-xs text-slate-400">Currently tests May 2010 (Greek bailout). Could extend to:</p>
			<div class="mt-3 grid grid-cols-2 gap-2 md:grid-cols-4">
				{#each [
					{ date: 'Oct 2009', event: 'Greek deficit revelation' },
					{ date: 'Jul 2012', event: 'Draghi speech' },
					{ date: 'Sep 2012', event: 'OMT announcement' },
					{ date: 'Jul 2015', event: 'Greek referendum' }
				] as { date, event }}
					<div class="rounded border border-purple-800/40 bg-purple-900/20 p-2.5">
						<p class="text-xs font-semibold text-purple-300">{date}</p>
						<p class="text-[10px] text-slate-400">{event}</p>
					</div>
				{/each}
			</div>
		</div>

		<div class="rounded-md bg-purple-900/20 border border-purple-800/40 p-3 text-sm text-slate-300">
			<strong class="text-purple-400">Feasibility:</strong> High. Data and methods already in place.
			Maps directly to the "critical junctures" framework.
		</div>
	</section>

	<!-- 4.5 Non-linear Debt -->
	<section class="space-y-4">
		<h2 class="border-b border-slate-700 pb-2 text-lg font-semibold text-white">
			4.5 Non-linear Debt Effects (Threshold Models)
		</h2>
		<ThesisClaim
			claim="The linear specification may miss non-linear effects at extreme debt levels."
			chapter="Methodological limitation"
			status="extension"
		/>

		<div class="rounded-lg border border-slate-700 bg-slate-800/40 p-4">
			<p class="text-xs text-slate-400">
				Add a quadratic debt term (debt_gdp²) or estimate threshold regressions to test whether the
				debt-spread relationship changes above 90% or 120% of GDP. This tests the Reinhart-Rogoff
				"90% threshold" hypothesis that underpinned much of the austerity debate.
			</p>
		</div>

		<div class="rounded-md bg-purple-900/20 border border-purple-800/40 p-3 text-sm text-slate-300">
			<strong class="text-purple-400">Feasibility:</strong> High. Can be added as a single additional
			model specification with <code class="text-purple-300">I(debt_gdp^2)</code>.
		</div>
	</section>
</div>
