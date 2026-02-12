<script lang="ts">
	let {
		label,
		value,
		detail = '',
		color = 'accent',
		icon = ''
	}: {
		label: string;
		value: string;
		detail?: string;
		color?: string;
		icon?: string;
	} = $props();

	const colorMap: Record<string, string> = {
		'text-amber-400': 'var(--accent-primary)',
		'text-red-400': 'var(--color-negative)',
		'text-emerald-400': 'var(--color-positive)',
		'text-blue-400': 'var(--color-info)',
		'text-slate-300': 'var(--text-primary)',
		'text-slate-400': 'var(--text-muted)',
		'accent': 'var(--accent-primary)'
	};

	let resolvedColor = $derived(colorMap[color] ?? color);
</script>

<div style="background: var(--bg-card); border: 1px solid var(--border-default); backdrop-filter: blur(8px)" class="rounded-lg p-4">
	<p class="text-xs font-medium tracking-wide uppercase" style="color: var(--text-dim); font-family: var(--font-body); letter-spacing: 0.08em">{label}</p>
	<p class="mt-1 text-2xl font-bold" style="color: {resolvedColor}; font-family: var(--font-display)">
		{#if icon}{icon}{/if}
		{value}
	</p>
	{#if detail}
		<p class="mt-1 text-xs" style="color: var(--text-dim)">{detail}</p>
	{/if}
</div>
