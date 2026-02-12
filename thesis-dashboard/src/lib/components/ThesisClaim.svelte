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
		confirmed: { bg: 'bg-emerald-900/30', border: 'border-emerald-700/50', badge: 'bg-emerald-600', text: 'Confirmed' },
		supplemented: { bg: 'bg-blue-900/30', border: 'border-blue-700/50', badge: 'bg-blue-600', text: 'Supplemented' },
		challenged: { bg: 'bg-amber-900/30', border: 'border-amber-700/50', badge: 'bg-amber-600', text: 'Challenged' },
		extension: { bg: 'bg-purple-900/30', border: 'border-purple-700/50', badge: 'bg-purple-600', text: 'Extension' }
	};

	const cfg = $derived(statusConfig[status]);
</script>

<div class="rounded-lg border {cfg.border} {cfg.bg} p-4">
	<div class="flex items-start justify-between gap-3">
		<div>
			{#if chapter}
				<span class="text-[10px] font-medium tracking-wider text-slate-500 uppercase">{chapter}</span>
			{/if}
			<p class="text-sm italic text-slate-300 leading-relaxed">"{claim}"</p>
		</div>
		<span class="shrink-0 rounded-full {cfg.badge} px-2.5 py-0.5 text-[10px] font-semibold text-white uppercase">
			{cfg.text}
		</span>
	</div>
</div>
