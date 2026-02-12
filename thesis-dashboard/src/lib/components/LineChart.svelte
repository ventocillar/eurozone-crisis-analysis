<script lang="ts">
	import { onMount } from 'svelte';
	import * as d3 from 'd3';
	import { COLORS } from '$lib/utils/data';

	interface Series {
		label: string;
		color: string;
		data: { date: Date; value: number }[];
	}

	let {
		series,
		title = '',
		yLabel = '',
		yFormat = (v: number) => String(Math.round(v)),
		events = [] as { date: Date; label: string; color?: string }[],
		height = 400,
		showLegend = true
	}: {
		series: Series[];
		title?: string;
		yLabel?: string;
		yFormat?: (v: number) => string;
		events?: { date: Date; label: string; color?: string }[];
		height?: number;
		showLegend?: boolean;
	} = $props();

	let container: HTMLDivElement;

	function draw() {
		if (!container || !series.length) return;
		d3.select(container).selectAll('*').remove();

		const margin = { top: 20, right: 20, bottom: 40, left: 65 };
		const width = container.clientWidth;
		const innerW = width - margin.left - margin.right;
		const innerH = height - margin.top - margin.bottom;

		const svg = d3
			.select(container)
			.append('svg')
			.attr('width', width)
			.attr('height', height);

		const g = svg.append('g').attr('transform', `translate(${margin.left},${margin.top})`);

		const allDates = series.flatMap((s) => s.data.map((d) => d.date));
		const allValues = series.flatMap((s) => s.data.map((d) => d.value));

		const x = d3
			.scaleTime()
			.domain(d3.extent(allDates) as [Date, Date])
			.range([0, innerW]);

		const y = d3
			.scaleLinear()
			.domain([Math.min(0, d3.min(allValues) ?? 0), (d3.max(allValues) ?? 0) * 1.05])
			.nice()
			.range([innerH, 0]);

		// Grid
		g.append('g')
			.attr('class', 'grid')
			.call(
				d3
					.axisLeft(y)
					.tickSize(-innerW)
					.tickFormat(() => '')
			)
			.selectAll('line')
			.attr('stroke', COLORS.surfaceLight)
			.attr('stroke-opacity', 0.15);
		g.selectAll('.grid .domain').remove();

		// Axes
		g.append('g')
			.attr('transform', `translate(0,${innerH})`)
			.call(d3.axisBottom(x).ticks(8))
			.selectAll('text')
			.attr('fill', COLORS.textMuted)
			.style('font-family', 'var(--font-body)')
			.style('font-size', '11px');

		g.append('g')
			.call(d3.axisLeft(y).ticks(6).tickFormat(yFormat as any))
			.selectAll('text')
			.attr('fill', COLORS.textMuted)
			.style('font-family', 'var(--font-body)')
			.style('font-size', '11px');

		g.selectAll('.domain').attr('stroke', COLORS.surfaceLight);
		g.selectAll('.tick line').attr('stroke', COLORS.surfaceLight);

		// Y label
		if (yLabel) {
			g.append('text')
				.attr('transform', 'rotate(-90)')
				.attr('y', -50)
				.attr('x', -innerH / 2)
				.attr('text-anchor', 'middle')
				.attr('fill', COLORS.textMuted)
				.style('font-family', 'var(--font-body)')
				.style('font-size', '12px')
				.text(yLabel);
		}

		// Event lines — merge labels that are too close together
		let lastLabelY = -Infinity;
		let lastLabelX = -Infinity;
		for (const evt of events) {
			const ex = x(evt.date);
			if (ex >= 0 && ex <= innerW) {
				g.append('line')
					.attr('x1', ex)
					.attr('x2', ex)
					.attr('y1', 0)
					.attr('y2', innerH)
					.attr('stroke', evt.color ?? '#944839')
					.attr('stroke-dasharray', '4,3')
					.attr('stroke-opacity', 0.6);

				// Stagger labels vertically if they overlap horizontally
				let labelY = 14;
				if (Math.abs(ex - lastLabelX) < 80) {
					labelY = lastLabelY + 14;
				}
				lastLabelX = ex;
				lastLabelY = labelY;

				g.append('text')
					.attr('x', ex + 4)
					.attr('y', labelY)
					.attr('fill', evt.color ?? '#944839')
					.style('font-family', 'var(--font-body)')
					.style('font-size', '10px')
					.text(evt.label);
			}
		}

		// Lines
		const line = d3
			.line<{ date: Date; value: number }>()
			.x((d) => x(d.date))
			.y((d) => y(d.value))
			.defined((d) => d.value != null && !isNaN(d.value));

		for (const s of series) {
			g.append('path')
				.datum(s.data)
				.attr('fill', 'none')
				.attr('stroke', s.color)
				.attr('stroke-width', 2.5)
				.attr('stroke-linecap', 'round')
				.attr('d', line);
		}

		// Tooltip
		const tooltip = d3
			.select(container)
			.append('div')
			.style('position', 'absolute')
			.style('display', 'none')
			.style('background', 'rgba(15,35,34,0.92)')
			.style('border', '1px solid rgba(192,142,57,0.4)')
			.style('border-radius', '8px')
			.style('padding', '10px 14px')
			.style('font-size', '12px')
			.style('font-family', 'var(--font-body)')
			.style('color', COLORS.text)
			.style('pointer-events', 'none')
			.style('z-index', '10')
			.style('backdrop-filter', 'blur(8px)')
			.style('box-shadow', '0 4px 20px rgba(0,0,0,0.4)');

		svg
			.append('rect')
			.attr('width', width)
			.attr('height', height)
			.attr('fill', 'transparent')
			.on('mousemove', function (event) {
				const [mx] = d3.pointer(event);
				const dateAtMouse = x.invert(mx - margin.left);
				let html = `<strong>${d3.timeFormat('%Y Q%q')(dateAtMouse)}</strong><br/>`;
				for (const s of series) {
					const bisect = d3.bisector((d: { date: Date }) => d.date).left;
					const i = bisect(s.data, dateAtMouse);
					const d = s.data[Math.min(i, s.data.length - 1)];
					if (d) {
						html += `<span style="color:${s.color}">${s.label}: ${yFormat(d.value)}</span><br/>`;
					}
				}
				tooltip
					.html(html)
					.style('display', 'block')
					.style('left', `${event.offsetX + 15}px`)
					.style('top', `${event.offsetY - 10}px`);
			})
			.on('mouseleave', () => tooltip.style('display', 'none'));
	}

	onMount(() => {
		draw();
		const ro = new ResizeObserver(() => draw());
		ro.observe(container);
		return () => ro.disconnect();
	});

	$effect(() => {
		if (series) draw();
	});
</script>

<div class="relative">
	{#if title}
		<h3 class="mb-2 text-sm font-semibold" style="color: var(--text-muted); font-family: var(--font-display)">{title}</h3>
	{/if}
	{#if showLegend && series.length > 1}
		<div class="mb-2 flex flex-wrap gap-3 text-xs" style="color: var(--text-muted)">
			{#each series as s}
				<span class="flex items-center gap-1.5">
					<span class="inline-block h-2.5 w-4 rounded-sm" style="background:{s.color}"></span>
					{s.label}
				</span>
			{/each}
		</div>
	{/if}
	<div bind:this={container} class="relative w-full" style="height:{height}px"></div>
</div>
