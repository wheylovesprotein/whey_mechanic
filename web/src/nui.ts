import { locale } from './locale';
import type { Result } from './types';

declare global {
  interface Window {
    GetParentResourceName?: () => string;
  }
}

const resource = window.GetParentResourceName ? window.GetParentResourceName() : 'whey_mechanic';

export async function nui<T = unknown>(event: string, data: unknown = {}): Promise<T> {
  const res = await fetch(`https://${resource}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  });

  return (await res.json()) as T;
}

export async function ask(event: string, data: unknown = {}): Promise<Result> {
  try {
    return (await nui<Result | null>(event, data)) || { ok: false, msg: locale('no_reply') };
  } catch (err) {
    console.error(err);

    return { ok: false, msg: locale('ui_unreachable') };
  }
}
