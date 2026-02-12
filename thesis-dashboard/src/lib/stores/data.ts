import { writable } from 'svelte/store';
import type { MasterRow, SpreadRow, RegressionCoefficient } from '$lib/utils/data';

export const masterData = writable<MasterRow[]>([]);
export const spreadsWide = writable<SpreadRow[]>([]);
export const regressionCoefficients = writable<RegressionCoefficient[]>([]);
export const dataLoaded = writable(false);
