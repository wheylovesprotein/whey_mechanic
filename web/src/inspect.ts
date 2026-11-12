import { icon } from './icons';
import { locale } from './locale';
import type { Inspection, Upgrade } from './types';
import { $, esc, toArray } from './util';

const inspectEl = $('inspect');

function condition(data: Inspection) {
  const worst = Math.min(data.engine, data.body);

  if (worst >= 75) return { tone: 'is-ok', label: locale('ui_condition_good') };
  if (worst >= 40) return { tone: 'is-warn', label: locale('ui_condition_work') };

  return { tone: 'is-bad', label: locale('ui_condition_bad') };
}

function upgradeRow(label: string, level: number, max: number, name: string) {
  const pips = Array.from({ length: max }, (_, i) => `<span class="pip ${i < level ? 'is-on' : ''}"></span>`).join('');
  const none = max === 0 || level === 0;

  return `
    <div class="board-row ${max > 0 && level === max ? 'is-maxed' : ''}">
      <span class="board-name">${esc(label)}</span>
      <span class="pips">${pips}</span>
      <span class="board-stat ${none ? 'is-none' : ''}">${esc(max === 0 ? locale('ui_na') : name)}</span>
    </div>`;
}

export function renderInspect(data: Inspection | false | null) {
  if (!data) {
    inspectEl.innerHTML = '';
    return;
  }

  const state = condition(data);
  const rows = toArray<Upgrade>(data.upgrades).map((u) => upgradeRow(u.label, u.level, u.max, u.name));

  rows.push(upgradeRow(locale('group_turbo'), data.turbo ? 1 : 0, 1, locale(data.turbo ? 'desc_installed' : 'option_none')));

  const html = `
    <div class="hud-head">
      <span class="mode-mark">${icon('wrench', 13)}</span>
      <div class="grow">
        <div class="hud-title">${esc(data.name)}</div>
        <div class="hud-sub">${esc(data.plate)} · ${esc(locale('ui_inspection'))}</div>
      </div>
    </div>
    <div class="status ${state.tone}">
      <span class="status-dot"></span>
      <div>
        <strong>${esc(state.label)}</strong>
        <small>${esc(locale('ui_engine'))} ${data.engine}% · ${esc(locale('ui_body'))} ${data.body}%</small>
      </div>
    </div>
    <div class="hud-cap">${esc(locale('ui_installed_upgrades'))}</div>
    <div class="board">${rows.join('')}</div>`;

  let card = inspectEl.firstElementChild;

  if (!card) {
    card = document.createElement('div');
    card.className = 'hud-card';
    inspectEl.appendChild(card);
  }

  card.innerHTML = html;
}
