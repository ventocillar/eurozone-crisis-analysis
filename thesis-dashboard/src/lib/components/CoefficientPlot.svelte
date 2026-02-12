<script lang="ts">
	import { onMount } from 'svelte';
	import * as d3 from 'd3';
	import { COLORS } from '$lib/utils/data';

	interface CoefPoint {
		variable: string;
		estimate: number;
		ci_lower: number;
		ci_upper: number;
		model: string;
		significant: boolean;
	}

	let {
		data,
		title = '',
		zeroLine = true,
		height = 400
	}: {
		data: CoefPoint[];
		title?: string;
		zeroLine?: boolean;
		height?: number;
	} = $props();

	let container: HTMLDivElement;

	const MODEL_COLORS: Record<string, string> = {
		Baseline: '#7f793c',
		Macro: '#184948',
		Full: '#944839',
		'Crisis Interactions': '#c08e39',
		'First-Difference': '#6b4f3a',
		'Driscoll-Kraay': '#8b8374'
	};

	function draw() {
		if (!container || !data.length) return;
		d3.select(container).selectAll('*').remove();

		const models = [...new Set(data.map((d) => d.model))];
		const legendRows = Math.ceil(models.length / 3);
		const legendSpace = 20 + legendRows * 18;
		const margin = { top: 10, right: 20, bottom: 30 + legendSpace, left: 120 };
		const width = container.clientWidth;
		const innerW = width - margin.left - margin.right;
		const innerH = height - margin.top - margin.bottom;

		const svg = d3
			.select(container)
			.append('svg')
			.attr('width', width)
			.attr('height', height);

		const g = svg.append('g').attr('transform', `translate(${margin.left},${margin.top})`);

		// Get unique variables
		const variables = [...new Set(data.map((d) => d.variable))];

		// Y scale: one band per variable, subdivided by model
		const yOuter = d3.scaleBand().domain(variables).range([0, innerH]).padding(0.3);

		const yInner = d3
			.scaleBand()
			.domain(models)
			.range([0, yOuter.bandwidth()])
			.padding(0.15);

		// X scale: from min CI to max CI
		const xMin = d3.min(data, (d) => d.ci_lower) ?? 0;
		const xMax = d3.max(data, (d) => d.ci_upper) ?? 0;
		const xPad = (xMax - xMin) * 0.1 || 10;
		const x = d3
			.scaleLinear()
			.domain([Math.min(xMin - xPad, 0), xMax + xPad])
			.range([0, innerW]);

		// Draw zero reference line
		if (zeroLine) {
			g.append('line')
				.attr('x1', x(0))
				.attr('x2', x(0))
				.attr('y1', 0)
				.attr('y2', innerH)
				.attr('stroke', COLORS.textMuted)
				.attr('stroke-dasharray', '4,3')
				.attr('stroke-width', 1);
		}

		// Draw variable groups
		for (const variable of variables) {
			const varData = data.filter((d) => d.variable === variable);
			const yBase = yOuter(variable)!;

			for (const d of varData) {
				const yPos = yBase + (yInner(d.model) ?? 0) + yInner.bandwidth() / 2;
				const color = MODEL_COLORS[d.model] || COLORS.textMuted;

				// Whisker (CI line)
				g.append('line')
					.attr('x1', x(d.ci_lower))
					.attr('x2', x(d.ci_upper))
					.attr('y1', yPos)
					.attr('y2', yPos)
					.attr('stroke', color)
					.attr('stroke-width', 2);

				// CI caps
				for (const val of [d.ci_lower, d.ci_upper]) {
					g.append('line')
						.attr('x1', x(val))
						.attr('x2', x(val))
						.attr('y1', yPos - 3)
						.attr('y2', yPos + 3)
						.attr('stroke', color)
						.attr('stroke-width', 2);
				}

				// Point estimate
				g.append('circle')
					.attr('cx', x(d.estimate))
					.attr('cy', yPos)
					.attr('r', 5)
					.attr('fill', d.significant ? color : 'none')
					.attr('stroke', color)
					.attr('stroke-width', 2);
			}
		}

		// Y axis (variable names)
		g.append('g')
			.call(d3.axisLeft(yOuter).tickSize(0))
			.selectAll('text')
			.attr('fill', COLORS.text)
			.style('font-family', 'var(--font-body)')
			.style('font-size', '11px');

		g.select('.domain').attr('stroke', COLORS.surfaceLight);

		// X axis
		g.append('g')
			.attr('transform', `translate(0,${innerH})`)
			.call(d3.axisBottom(x).ticks(6))
			.selectAll('text')
			.attr('fill', COLORS.textMuted)
			.style('font-family', 'var(--font-body)')
			.style('font-size', '11px');

		g.selectAll('.tick line').attr('stroke', COLORS.surfaceLight);

		// Legend — positioned below x-axis, wrapping into rows of 3
		const colsPerRow = 3;
		const colWidth = innerW / colsPerRow;
		const legendTop = margin.top + innerH + 32;

		const legendG = svg
			.append('g')
			.attr('transform', `translate(${margin.left},${legendTop})`);

		models.forEach((model, i) => {
			const col = i % colsPerRow;
			const row = Math.floor(i / colsPerRow);
			const lx = col * colWidth;
			const ly = row * 18;
			const color = MODEL_COLORS[model] || COLORS.textMuted;

			legendG
				.append('circle')
				.attr('cx', lx + 4)
				.attr('cy', ly)
				.attr('r', 4)
				.attr('fill', color);

			legendG
				.append('text')
				.attr('x', lx + 14)
				.attr('y', ly)
				.attr('dy', '0.35em')
				.attr('fill', COLORS.textMuted)
				.style('font-family', 'var(--font-body)')
				.style('font-size', '11px')
				.text(model);
		});
	}

	onMount(() => {
		draw();
		const ro = new ResizeObserver(() => draw());
		ro.observe(container);
		return () => ro.disconnect();
	});

	$effect(() => {
		if (data) draw();
	});
</script>

<div>
	{#if title}
		<h3 class="mb-2 text-sm font-semibold" style="color: var(--text-muted); font-family: var(--font-display)">{title}</h3>
	{/if}
	<div bind:this={container} class="w-full" style="height:{height}px"></div>
	<p class="mt-1 text-[10px]" style="color: var(--text-dim)">Filled = significant (p&lt;0.05); hollow = not significant. Whiskers = 95% CI.</p>
</div>
