<script lang="ts">
	let {
		label,
		value,
		detail = '',
		color = 'text-amber-400',
		icon = ''
	}: {
		label: string;
		value: string;
		detail?: string;
		color?: string;
		icon?: string;
	} = $props();
</script>

<div class="rounded-lg border border-slate-700 bg-slate-800/60 p-4">
	<p class="text-xs font-medium tracking-wide text-slate-400 uppercase">{label}</p>
	<p class="mt-1 text-2xl font-bold {color}">
		{#if icon}{icon}{/if}
		{value}
	</p>
	{#if detail}
		<p class="mt-1 text-xs text-slate-500">{detail}</p>
	{/if}
</div>
