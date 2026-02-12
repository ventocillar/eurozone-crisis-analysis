<script lang="ts">
	import { onMount } from 'svelte';
	import * as d3 from 'd3';
	import { COLORS } from '$lib/utils/data';

	interface Bar {
		label: string;
		value: number;
		color: string;
	}

	let {
		bars,
		title = '',
		yLabel = '',
		yFormat = (v: number) => String(Math.round(v)),
		horizontal = false,
		height = 350
	}: {
		bars: Bar[];
		title?: string;
		yLabel?: string;
		yFormat?: (v: number) => string;
		horizontal?: boolean;
		height?: number;
	} = $props();

	let container: HTMLDivElement;

	function draw() {
		if (!container || !bars.length) return;
		d3.select(container).selectAll('*').remove();

		const margin = horizontal
			? { top: 10, right: 30, bottom: 30, left: 90 }
			: { top: 10, right: 20, bottom: 50, left: 60 };
		const width = container.clientWidth;
		const innerW = width - margin.left - margin.right;
		const innerH = height - margin.top - margin.bottom;

		const svg = d3
			.select(container)
			.append('svg')
			.attr('width', width)
			.attr('height', height);

		const g = svg.append('g').attr('transform', `translate(${margin.left},${margin.top})`);

		if (horizontal) {
			const x = d3
				.scaleLinear()
				.domain([
					Math.min(0, d3.min(bars, (b) => b.value) ?? 0),
					(d3.max(bars, (b) => b.value) ?? 0) * 1.1
				])
				.range([0, innerW]);

			const y = d3
				.scaleBand()
				.domain(bars.map((b) => b.label))
				.range([0, innerH])
				.padding(0.25);

			g.selectAll('rect')
				.data(bars)
				.join('rect')
				.attr('y', (d) => y(d.label)!)
				.attr('x', (d) => (d.value >= 0 ? x(0) : x(d.value)))
				.attr('width', (d) => Math.abs(x(d.value) - x(0)))
				.attr('height', y.bandwidth())
				.attr('fill', (d) => d.color)
				.attr('rx', 3);

			g.selectAll('.bar-label')
				.data(bars)
				.join('text')
				.attr('x', (d) => x(d.value) + (d.value >= 0 ? 5 : -5))
				.attr('y', (d) => y(d.label)! + y.bandwidth() / 2)
				.attr('dy', '0.35em')
				.attr('text-anchor', (d) => (d.value >= 0 ? 'start' : 'end'))
				.attr('fill', COLORS.textMuted)
				.style('font-size', '11px')
				.text((d) => yFormat(d.value));

			g.append('g')
				.call(d3.axisLeft(y))
				.selectAll('text')
				.attr('fill', COLORS.text)
				.style('font-size', '11px');

			g.append('g')
				.attr('transform', `translate(0,${innerH})`)
				.call(d3.axisBottom(x).ticks(5).tickFormat(yFormat as any))
				.selectAll('text')
				.attr('fill', COLORS.textMuted)
				.style('font-size', '11px');

			// Zero line
			if (d3.min(bars, (b) => b.value)! < 0) {
				g.append('line')
					.attr('x1', x(0))
					.attr('x2', x(0))
					.attr('y1', 0)
					.attr('y2', innerH)
					.attr('stroke', COLORS.textMuted)
					.attr('stroke-dasharray', '3,2');
			}
		} else {
			const x = d3
				.scaleBand()
				.domain(bars.map((b) => b.label))
				.range([0, innerW])
				.padding(0.25);

			const y = d3
				.scaleLinear()
				.domain([
					Math.min(0, d3.min(bars, (b) => b.value) ?? 0),
					(d3.max(bars, (b) => b.value) ?? 0) * 1.1
				])
				.nice()
				.range([innerH, 0]);

			g.selectAll('rect')
				.data(bars)
				.join('rect')
				.attr('x', (d) => x(d.label)!)
				.attr('y', (d) => (d.value >= 0 ? y(d.value) : y(0)))
				.attr('width', x.bandwidth())
				.attr('height', (d) => Math.abs(y(0) - y(d.value)))
				.attr('fill', (d) => d.color)
				.attr('rx', 3);

			g.append('g')
				.attr('transform', `translate(0,${innerH})`)
				.call(d3.axisBottom(x))
				.selectAll('text')
				.attr('fill', COLORS.text)
				.style('font-size', '11px')
				.attr('transform', 'rotate(-25)')
				.attr('text-anchor', 'end');

			g.append('g')
				.call(d3.axisLeft(y).ticks(5).tickFormat(yFormat as any))
				.selectAll('text')
				.attr('fill', COLORS.textMuted)
				.style('font-size', '11px');

			// Zero line
			if (d3.min(bars, (b) => b.value)! < 0) {
				g.append('line')
					.attr('x1', 0)
					.attr('x2', innerW)
					.attr('y1', y(0))
					.attr('y2', y(0))
					.attr('stroke', COLORS.textMuted)
					.attr('stroke-dasharray', '3,2');
			}
		}

		g.selectAll('.domain').attr('stroke', COLORS.surfaceLight);
		g.selectAll('.tick line').attr('stroke', COLORS.surfaceLight);
	}

	onMount(() => {
		draw();
		const ro = new ResizeObserver(() => draw());
		ro.observe(container);
		return () => ro.disconnect();
	});

	$effect(() => {
		if (bars) draw();
	});
</script>

<div>
	{#if title}
		<h3 class="mb-2 text-sm font-semibold text-slate-300">{title}</h3>
	{/if}
	<div bind:this={container} class="w-full" style="height:{height}px"></div>
</div>
