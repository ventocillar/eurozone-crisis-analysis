<script lang="ts">
	import '../app.css';
	import { page } from '$app/state';
	import { onMount } from 'svelte';
	import { loadCSV, parseRegressionCoefficients, type MasterRow, type SpreadRow } from '$lib/utils/data';
	import { masterData, spreadsWide, regressionCoefficients, dataLoaded } from '$lib/stores/data';

	let { children } = $props();

	const nav = [
		{ href: '/', label: 'Overview' },
		{ href: '/confirms', label: '1. Confirms' },
		{ href: '/supplements', label: '2. Supplements' },
		{ href: '/challenges', label: '3. Challenges' },
		{ href: '/extensions', label: '4. Extensions' },
		{ href: '/synthesis', label: '5. Synthesis' }
	];

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
</script>

<div class="min-h-screen bg-slate-900 text-slate-200">
	<nav class="sticky top-0 z-50 border-b border-slate-700 bg-slate-900/95 backdrop-blur">
		<div class="mx-auto flex max-w-7xl items-center gap-1 overflow-x-auto px-4 py-3">
			<span class="mr-4 shrink-0 text-sm font-bold tracking-wide text-amber-400 uppercase"
				>Thesis Dashboard</span
			>
			{#each nav as { href, label }}
				<a
					{href}
					class="shrink-0 rounded-md px-3 py-1.5 text-sm transition-colors {page.url.pathname ===
					href
						? 'bg-amber-500/20 text-amber-300 font-medium'
						: 'text-slate-400 hover:text-slate-200 hover:bg-slate-800'}"
				>
					{label}
				</a>
			{/each}
		</div>
	</nav>

	<main class="mx-auto max-w-7xl px-4 py-8">
		{@render children()}
	</main>

	<footer class="border-t border-slate-800 py-6 text-center text-xs text-slate-500">
		<p>"Of Rules and (Dis)order" — Quantitative Analysis Dashboard</p>
		<p class="mt-1">Data: 9 Eurozone countries, 2008 Q1 – 2015 Q4</p>
	</footer>
</div>
