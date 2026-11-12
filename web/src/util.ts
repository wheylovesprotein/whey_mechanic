const ESCAPES: Record<string, string> = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };

export const $ = <T extends HTMLElement = HTMLElement>(id: string) => document.getElementById(id) as T;
export const esc = (s: unknown) => String(s ?? '').replace(/[&<>"']/g, (c) => ESCAPES[c]);
export const money = (n: number) => '$' + Math.round(n).toLocaleString('en-US');
export const clone = <T>(v: T): T => (v === undefined ? v : (JSON.parse(JSON.stringify(v)) as T));
export const same = (a: unknown, b: unknown) => JSON.stringify(a) === JSON.stringify(b);
export const toArray = <T>(v: unknown): T[] => (Array.isArray(v) ? (v as T[]) : v ? (Object.values(v as object) as T[]) : []);
export const hexToRgb = (hex: string) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
export const rgbToHex = (c: number[]) => '#' + c.map((n) => n.toString(16).padStart(2, '0')).join('');
export const wait = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));
