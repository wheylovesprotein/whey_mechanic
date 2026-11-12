export type Value = number | boolean | number[] | boolean[] | Record<string, number>;
export type Values = Record<string, Value | undefined>;

export interface Result {
  ok: boolean;
  msg?: string;
  waiting?: boolean;
  requested?: boolean;
  netId?: number;
}

export interface Option {
  value: number | boolean;
  label: string;
}

export interface Named {
  id: number;
  label: string;
  hex?: string;
}

export interface ListSection {
  type: 'list';
  title: string;
  key: string;
  options: Option[];
}

export interface PaintSection {
  type: 'paint';
  title: string;
  key: string;
  finishKey: string;
}

export interface SwatchSection {
  type: 'swatch';
  title: string;
  key: string;
}

export interface WheelsSection {
  type: 'wheels';
  title: string;
  types: Named[];
  bike?: boolean;
}

export interface SmokeSection {
  type: 'smoke';
  title: string;
}

export interface XenonSection {
  type: 'xenon';
  title: string;
  options: Named[];
}

export interface NeonSection {
  type: 'neon';
  title: string;
}

export interface ExtrasSection {
  type: 'extras';
  title: string;
  ids: number[];
}

export type Section =
  | ListSection
  | PaintSection
  | SwatchSection
  | WheelsSection
  | SmokeSection
  | XenonSection
  | NeonSection
  | ExtrasSection;

export interface Category {
  id: string;
  label: string;
  icon: string;
  sections: Section[];
}

export type Prices = { performance: Record<string, unknown> } & Record<string, unknown>;

export interface ShopMeta {
  shop: string;
  vehicle?: { name?: string; plate?: string };
  billsOwner: boolean;
  requests: boolean;
  payerDistance?: number;
  damaged?: boolean;
  repairPrice?: number;
  prices: Prices;
  groups: Record<string, string>;
  values?: Values;
  categories: Category[];
  colours: Named[];
  finishes: Named[];
  bike: boolean;
}

export interface Payer {
  id: number;
  name: string;
  owner?: boolean;
  you?: boolean;
}

export interface Upgrade {
  label: string;
  level: number;
  max: number;
  name: string;
}

export interface Inspection {
  name: string;
  plate: string;
  engine: number;
  body: number;
  turbo: boolean;
  upgrades: Upgrade[];
}

export type RequestStatus = 'requested' | 'billed' | 'paid' | 'installing' | 'fitted';

export interface PartRequest {
  id: number;
  customer: string;
  online: boolean;
  plate: string;
  model?: string;
  parts: string[];
  total: number;
  status: RequestStatus;
  installer?: string;
  paidBy?: string;
  createdAt: number;
}

export interface InstallJob {
  seconds?: number;
  penalty?: number;
  parts?: string[];
  vehicle?: string;
  plate?: string;
}
