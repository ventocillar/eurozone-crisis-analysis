import { csvParse, autoType } from 'd3-dsv';

export async function loadCSV<T = Record<string, unknown>>(path: string): Promise<T[]> {
	const res = await fetch(path);
	const text = await res.text();
	return csvParse(text, autoType) as T[];
}

export interface MasterRow {
	date: string;
	country: string;
	country_group: string;
	debt_gdp: number;
	deficit_gdp: number;
	gdp_growth: number;
	unemployment: number;
	inflation: number;
	spread_bps: number;
	bond_yield: number;
	ecb_rate: number;
	crisis_period: number;
	post_omt: number;
	giips: number;
	year: number;
	quarter: number;
	period: string;
}

export interface SpreadRow {
	date: string;
	Austria: number;
	France: number;
	Germany: number;
	Greece: number;
	Ireland: number;
	Italy: number;
	Netherlands: number;
	Portugal: number;
	Spain: number;
}

export const GIIPS = ['Greece', 'Ireland', 'Italy', 'Portugal', 'Spain'];
export const CORE = ['Germany', 'France', 'Netherlands', 'Austria'];

export const COLORS = {
	giips: '#944839',
	core: '#184948',
	germany: '#022a2a',
	greece: '#944839',
	ireland: '#7f793c',
	italy: '#c08e39',
	portugal: '#a8664f',
	spain: '#b57845',
	france: '#184948',
	netherlands: '#2d6765',
	austria: '#4a5d52',
	accent: '#c08e39',
	bg: '#0a1514',
	surface: '#0f2322',
	surfaceLight: '#184948',
	text: '#f4efe8',
	textMuted: '#c9bfb3',
	positive: '#7f793c',
	negative: '#944839',
	warning: '#c08e39'
};

export const COUNTRY_COLORS: Record<string, string> = {
	Greece: COLORS.greece,
	Ireland: COLORS.ireland,
	Italy: COLORS.italy,
	Portugal: COLORS.portugal,
	Spain: COLORS.spain,
	Germany: COLORS.germany,
	France: COLORS.france,
	Netherlands: COLORS.netherlands,
	Austria: COLORS.austria
};

export function groupBy<T>(arr: T[], key: keyof T): Record<string, T[]> {
	return arr.reduce(
		(acc, item) => {
			const k = String(item[key]);
			(acc[k] = acc[k] || []).push(item);
			return acc;
		},
		{} as Record<string, T[]>
	);
}

export function validNumbers(arr: (number | null | undefined)[]): number[] {
	return arr.filter((v): v is number => v != null && !isNaN(v));
}

export function mean(arr: number[]): number {
	const valid = arr.filter((v) => v != null && !isNaN(v));
	return valid.length ? valid.reduce((a, b) => a + b, 0) / valid.length : 0;
}

export function std(arr: number[]): number {
	const valid = arr.filter((v) => v != null && !isNaN(v));
	if (valid.length < 2) return 0;
	const m = mean(valid);
	return Math.sqrt(valid.reduce((sum, v) => sum + (v - m) ** 2, 0) / (valid.length - 1));
}

// Regression coefficient types and parser for CSV-driven dashboard
export interface RegressionCoefficient {
	variable: string;
	estimate: number;
	std_error: number;
	ci_lower: number;
	ci_upper: number;
	p_value: number;
	model: string;
	se_type: string;
}

export function parseRegressionCoefficients(rows: Record<string, unknown>[]): RegressionCoefficient[] {
	return rows.map((r) => ({
		variable: String(r.variable),
		estimate: Number(r.estimate),
		std_error: Number(r.std_error),
		ci_lower: Number(r.ci_lower),
		ci_upper: Number(r.ci_upper),
		p_value: Number(r.p_value),
		model: String(r.model),
		se_type: String(r.se_type)
	}));
}

export function getCoef(
	coefficients: RegressionCoefficient[],
	variable: string,
	model: string,
	seType = 'cluster-robust'
): RegressionCoefficient | undefined {
	return coefficients.find(
		(c) => c.variable === variable && c.model === model && c.se_type === seType
	);
}

export function fmtCoef(value: number, decimals = 2): string {
	return value.toFixed(decimals);
}

export function sigStars(pValue: number): string {
	if (pValue < 0.001) return '***';
	if (pValue < 0.01) return '**';
	if (pValue < 0.05) return '*';
	return ' ns';
}
