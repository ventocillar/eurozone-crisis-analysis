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

<div class="min-h-screen" style="background: var(--bg-primary); color: var(--text-primary)">
	<nav class="sticky top-0 z-50" style="background: rgba(10,21,20,0.9); backdrop-filter: blur(12px); border-bottom: 1px solid var(--border-subtle)">
		<div class="mx-auto flex max-w-7xl items-center gap-1 overflow-x-auto px-4 py-3">
			<span class="mr-4 shrink-0 text-sm font-bold tracking-wide uppercase" style="color: var(--accent-primary); font-family: var(--font-display)"
				>Thesis Dashboard</span
			>
			{#each nav as { href, label }}
				<a
					{href}
					class="shrink-0 rounded-md px-3 py-1.5 text-sm transition-colors"
					style="{page.url.pathname === href
						? 'background: rgba(192,142,57,0.15); color: var(--accent-primary); font-weight: 500'
						: 'color: var(--text-muted)'}"
				>
					{label}
				</a>
			{/each}
		</div>
	</nav>

	<main class="mx-auto max-w-7xl px-4 py-8">
		{@render children()}
	</main>

	<footer class="py-6 text-center text-xs" style="border-top: 1px solid var(--border-subtle); color: var(--text-dim)">
		<p style="font-family: var(--font-display); font-style: italic">"Of Rules and (Dis)order" — Quantitative Analysis Dashboard</p>
		<p class="mt-1">Data: 9 Eurozone countries, 2008 Q1 – 2015 Q4</p>
	</footer>
</div>
