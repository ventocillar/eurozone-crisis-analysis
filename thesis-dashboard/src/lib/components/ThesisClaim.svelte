<script lang="ts">
	let {
		claim,
		chapter = '',
		status = 'confirmed'
	}: {
		claim: string;
		chapter?: string;
		status?: 'confirmed' | 'supplemented' | 'challenged' | 'extension';
	} = $props();

	const statusConfig = {
		confirmed: {
			bg: 'rgba(127,121,60,0.15)',
			border: 'rgba(127,121,60,0.35)',
			badge: '#565c33',
			text: 'Confirmed'
		},
		supplemented: {
			bg: 'rgba(24,73,72,0.2)',
			border: 'rgba(24,73,72,0.4)',
			badge: '#184948',
			text: 'Supplemented'
		},
		challenged: {
			bg: 'rgba(192,142,57,0.12)',
			border: 'rgba(192,142,57,0.35)',
			badge: '#c08e39',
			text: 'Challenged'
		},
		extension: {
			bg: 'rgba(148,72,57,0.15)',
			border: 'rgba(148,72,57,0.35)',
			badge: '#944839',
			text: 'Extension'
		}
	};

	const cfg = $derived(statusConfig[status]);
</script>

<div class="rounded-lg p-4" style="background: {cfg.bg}; border: 1px solid {cfg.border}">
	<div class="flex items-start justify-between gap-3">
		<div>
			{#if chapter}
				<span class="text-[10px] font-medium tracking-wider uppercase" style="color: var(--text-dim)">{chapter}</span>
			{/if}
			<p class="text-sm italic leading-relaxed" style="color: var(--text-muted); font-family: var(--font-display)">"{claim}"</p>
		</div>
		<span class="shrink-0 rounded-full px-2.5 py-0.5 text-[10px] font-semibold uppercase" style="background: {cfg.badge}; color: var(--text-primary)">
			{cfg.text}
		</span>
	</div>
</div>
