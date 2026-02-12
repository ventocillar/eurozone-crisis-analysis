<script lang="ts">
	import { onMount } from 'svelte';
	import * as d3 from 'd3';
	import { COLORS } from '$lib/utils/data';

	interface Cell {
		row: string;
		col: string;
		value: number;
	}

	let {
		cells,
		title = '',
		rows,
		cols,
		colorRange = ['#3498DB', '#ffffff', '#E74C3C'],
		domain = [-1, 0, 1],
		height = 400,
		valueFormat = (v: number) => v.toFixed(2)
	}: {
		cells: Cell[];
		title?: string;
		rows: string[];
		cols: string[];
		colorRange?: string[];
		domain?: number[];
		height?: number;
		valueFormat?: (v: number) => string;
	} = $props();

	let container: HTMLDivElement;

	function draw() {
		if (!container || !cells.length) return;
		d3.select(container).selectAll('*').remove();

		const margin = { top: 60, right: 20, bottom: 20, left: 90 };
		const width = container.clientWidth;
		const innerW = width - margin.left - margin.right;
		const innerH = height - margin.top - margin.bottom;

		const svg = d3
			.select(container)
			.append('svg')
			.attr('width', width)
			.attr('height', height);

		const g = svg.append('g').attr('transform', `translate(${margin.left},${margin.top})`);

		const x = d3.scaleBand().domain(cols).range([0, innerW]).padding(0.05);
		const y = d3.scaleBand().domain(rows).range([0, innerH]).padding(0.05);

		const color = d3.scaleLinear<string>().domain(domain).range(colorRange).clamp(true);

		g.selectAll('rect')
			.data(cells)
			.join('rect')
			.attr('x', (d) => x(d.col)!)
			.attr('y', (d) => y(d.row)!)
			.attr('width', x.bandwidth())
			.attr('height', y.bandwidth())
			.attr('fill', (d) => color(d.value))
			.attr('rx', 3);

		g.selectAll('.cell-text')
			.data(cells)
			.join('text')
			.attr('x', (d) => x(d.col)! + x.bandwidth() / 2)
			.attr('y', (d) => y(d.row)! + y.bandwidth() / 2)
			.attr('dy', '0.35em')
			.attr('text-anchor', 'middle')
			.attr('fill', (d) => (Math.abs(d.value) > 0.6 ? '#fff' : '#1e293b'))
			.style('font-size', '11px')
			.text((d) => valueFormat(d.value));

		// Labels
		g.append('g')
			.selectAll('text')
			.data(cols)
			.join('text')
			.attr('x', (d) => x(d)! + x.bandwidth() / 2)
			.attr('y', -8)
			.attr('text-anchor', 'middle')
			.attr('fill', COLORS.textMuted)
			.style('font-size', '11px')
			.text((d) => d);

		g.append('g')
			.selectAll('text')
			.data(rows)
			.join('text')
			.attr('x', -8)
			.attr('y', (d) => y(d)! + y.bandwidth() / 2)
			.attr('dy', '0.35em')
			.attr('text-anchor', 'end')
			.attr('fill', COLORS.textMuted)
			.style('font-size', '11px')
			.text((d) => d);
	}

	onMount(() => {
		draw();
		const ro = new ResizeObserver(() => draw());
		ro.observe(container);
		return () => ro.disconnect();
	});

	$effect(() => {
		if (cells) draw();
	});
</script>

<div>
	{#if title}
		<h3 class="mb-2 text-sm font-semibold text-slate-300">{title}</h3>
	{/if}
	<div bind:this={container} class="w-full" style="height:{height}px"></div>
</div>
