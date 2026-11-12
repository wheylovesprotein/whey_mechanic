import { brandMark, icon } from './icons';
import { locale } from './locale';
import { ask, nui } from './nui';
import { toast } from './toast';
import type { Category, Named, Option, Payer, Result, Section, ShopMeta, Value, Values } from './types';
import { $, clone, esc, hexToRgb, money, rgbToHex, same, toArray } from './util';

interface Shop {
  meta: ShopMeta;
  original: Values;
  current: Values;
  category: string | null;
  rimType: number | null;
  rims: Record<number, Option[]>;
  busy: boolean;
  waiting: string | null;
  picking: { list: Payer[] | null } | null;
  damaged: boolean;
}

const LIGHT_PRESETS = ['#ffffff', '#ff2f2f', '#ff8b2c', '#ffe834', '#9cff2e', '#2fff8b', '#38b6ff', '#2a6dff', '#a447ff', '#ff2fa4'];
const HEX_CODE = /^#?([0-9a-f]{6})$/i;
const NEON_SIDES = ['side_left', 'side_right', 'side_front', 'side_back'];

const shopEl = $('shop');
const dragEl = $('drag');
const camHint = $('camHint');

let shop: Shop | null = null;
let queued: Values | null = null;
let focused: string | null = null;

const groupOf = (s: Shop, key: string) => s.meta.groups[key];
const groupKeys = (s: Shop, group: string) => Object.keys(s.meta.groups).filter((k) => s.meta.groups[k] === group);
const extrasOf = (values: Values) => (values.extras ?? {}) as Record<string, number>;
const focusKey = (section: Section) => ('key' in section ? section.key : section.type);
const valueAttr = (value: unknown) => `data-value="${esc(JSON.stringify(value))}"`;

function finishOf(s: Shop, key: string) {
  const finish = s.current[key];

  return typeof finish === 'number' && finish >= 0 && finish <= 5 ? finish : 0;
}

function groupPrice(s: Shop, group: string) {
  const prices = s.meta.prices;
  const value = prices[group] ?? prices.part;

  return typeof value === 'number' ? value : 0;
}

function levelPrice(s: Shop, key: string, value: unknown) {
  const levels = s.meta.prices.performance[key];

  if (!levels) return null;

  return toArray<number>(levels)[Number(value) + 1] || 0;
}

function preview(patch: Values) {
  if (!queued) {
    queued = {};
    requestAnimationFrame(() => {
      const body = queued;

      queued = null;
      void nui('customs:preview', body);
    });
  }

  Object.assign(queued, clone(patch));
}

function set(s: Shop, patch: Values) {
  if (s.meta.bike) {
    if ('modFrontWheels' in patch) patch.modBackWheels = patch.modFrontWheels;
    if ('modCustomTiresF' in patch) patch.modCustomTiresR = patch.modCustomTiresF;
  }

  Object.assign(s.current, patch);

  const out: Values = {};

  for (const group of new Set(Object.keys(patch).map((key) => groupOf(s, key)))) {
    for (const key of groupKeys(s, group)) {
      if (s.current[key] !== undefined) out[key] = s.current[key];
    }
  }

  preview(out);
}

function changes(s: Shop) {
  const { original, current, meta } = s;
  const keys = Object.keys(meta.groups).filter((k) => k !== 'extras' && current[k] !== undefined);
  const dirty = new Set(keys.filter((k) => !same(current[k], original[k])).map((k) => meta.groups[k]));
  const out: Values = {};

  for (const key of keys) {
    if (dirty.has(meta.groups[key])) out[key] = current[key];
  }

  const before = extrasOf(original);
  const extras: Record<string, number> = {};

  for (const [id, off] of Object.entries(extrasOf(current))) {
    if (before[id] !== off) extras[id] = off;
  }

  if (Object.keys(extras).length) out.extras = extras;

  return out;
}

function price(s: Shop, order: Values) {
  const billed = new Set<string>();
  let total = 0;

  for (const [key, value] of Object.entries(order)) {
    const group = groupOf(s, key);
    const level = levelPrice(s, key, value);

    if (level !== null) total += level;
    else if (group === 'turbo') total += value ? groupPrice(s, 'turbo') : 0;
    else if (group === 'extra') total += groupPrice(s, 'extra') * Object.keys(value as object).length;
    else if (!billed.has(group)) {
      billed.add(group);
      total += groupPrice(s, group);
    }
  }

  return total;
}

function optionPrice(s: Shop, key: string, value: Value) {
  if (same(value, s.original[key])) return `<small class="is-installed">${esc(locale('desc_installed'))}</small>`;

  let amount = levelPrice(s, key, value) ?? groupPrice(s, groupOf(s, key));

  if (key === 'modTurbo') amount = value ? groupPrice(s, 'turbo') : 0;

  return `<small>${amount > 0 ? money(amount) : esc(locale('ui_free'))}</small>`;
}

function sectionKeys(section: Section) {
  switch (section.type) {
    case 'paint':
      return [section.key, section.finishKey];
    case 'wheels':
      return ['wheels', 'modFrontWheels'];
    case 'smoke':
      return ['modSmokeEnabled', 'tyreSmokeColor'];
    case 'xenon':
      return ['modXenon', 'xenonColor'];
    case 'neon':
      return ['neonEnabled', 'neonColor'];
    case 'extras':
      return ['extras'];
    default:
      return [section.key];
  }
}

const isChanged = (section: Section, order: Values) => sectionKeys(section).some((k) => k in order);

function rgbOf(s: Shop, key: string) {
  const value = s.current[key];

  if (Array.isArray(value)) return (value as number[]).slice(0, 3);

  const colour = typeof value === 'number' ? s.meta.colours.find((c) => c.id === value) : undefined;

  return colour?.hex ? hexToRgb(colour.hex) : [120, 120, 120];
}

function focusSection(key: string) {
  if (key === focused) return;

  focused = key;
  void nui('customs:focus', { section: key });
}

function card(section: Section, body: string, pill: string) {
  return `
    <section class="card" data-focus="${esc(focusKey(section))}">
      <header class="card-head"><h2>${esc(section.title)}</h2>${pill}</header>
      <div class="card-body">${body}</div>
    </section>`;
}

function changedPill(section: Section, order: Values) {
  return isChanged(section, order) ? `<span class="pill pill--warn">${esc(locale('ui_changed'))}</span>` : '';
}

function groupPill(s: Shop, group: string, section: Section, order: Values) {
  if (isChanged(section, order)) return changedPill(section, order);

  return `<span class="pill pill--muted">${money(groupPrice(s, group))}</span>`;
}

function tile(attrs: string, label: string, sub: string, active: boolean, dot?: string) {
  return `
    <button class="tile ${active ? 'is-active' : ''}" ${attrs}>
      <span class="tile-head">
        ${dot ? `<span class="dot" style="background:${dot}"></span>` : ''}
        <strong>${esc(label)}</strong>
        ${active ? `<span class="tile-check">${icon('check', 14, 2.6)}</span>` : ''}
      </span>
      ${sub}
    </button>`;
}

function rgbBlock(s: Shop, key: string, finishKey: string | null, presets?: string[]) {
  const hexes = presets ?? s.meta.colours.map((colour) => colour.hex ?? '');
  const current = rgbToHex(rgbOf(s, key));
  const finishAttr = finishKey ? `data-finish-key="${finishKey}"` : '';

  const swatches = hexes
    .map(
      (hex) =>
        `<button class="swatch ${hex === current ? 'is-active' : ''}" style="background:${hex}"
          data-rgb-preset="${key}" data-hex="${hex}" ${finishAttr}></button>`,
    )
    .join('');

  return `
    <div class="swatches">${swatches}</div>
    <div class="rgb">
      <span class="rgb-preview" data-rgb-preview="${key}" style="background:${current}"></span>
      <label class="hex">
        <span class="field-label">${esc(locale('ui_hex'))}</span>
        <input class="hex-input" type="text" maxlength="7" spellcheck="false" autocomplete="off"
          value="${current.toUpperCase()}" data-hex-input="${key}" ${finishAttr} />
      </label>
    </div>`;
}

function renderSection(s: Shop, section: Section, order: Values) {
  switch (section.type) {
    case 'list': {
      const current = s.current[section.key];
      const tiles = toArray<Option>(section.options)
        .map((o) => {
          const attrs = `data-set="${esc(section.key)}" ${valueAttr(o.value)}`;

          return tile(attrs, o.label, optionPrice(s, section.key, o.value), same(current, o.value));
        })
        .join('');

      return card(section, `<div class="tiles">${tiles}</div>`, changedPill(section, order));
    }

    case 'paint': {
      const finish = finishOf(s, section.finishKey);
      const finishes = s.meta.finishes
        .map(
          (f) =>
            `<button class="segment ${f.id === finish ? 'is-active' : ''}"
              data-finish="${section.finishKey}" data-colour-key="${section.key}" data-id="${f.id}">${esc(f.label)}</button>`,
        )
        .join('');

      return card(
        section,
        `<span class="field-label">${esc(locale('ui_finish'))}</span><div class="segmented">${finishes}</div>
         <span class="field-label">${esc(locale('ui_colour'))}</span>${rgbBlock(s, section.key, section.finishKey)}`,
        groupPill(s, groupOf(s, section.key), section, order),
      );
    }

    case 'swatch': {
      const current = s.current[section.key];
      const swatches = s.meta.colours
        .map(
          (c) =>
            `<button class="swatch ${c.id === current ? 'is-active' : ''}" style="background:${c.hex}"
              title="${esc(c.label)}" data-set="${section.key}" ${valueAttr(c.id)}></button>`,
        )
        .join('');
      const name = s.meta.colours.find((c) => c.id === current)?.label;

      return card(
        section,
        `<div class="swatches">${swatches}</div>${name ? `<p class="hint">${esc(name)}</p>` : ''}`,
        groupPill(s, groupOf(s, section.key), section, order),
      );
    }

    case 'wheels': {
      const chips = toArray<Named>(section.types)
        .map((t) => `<button class="chip ${t.id === s.rimType ? 'is-active' : ''}" data-rim-type="${t.id}">${esc(t.label)}</button>`)
        .join('');
      const rims = s.rimType === null ? undefined : s.rims[s.rimType];
      const installed = s.original.wheels === s.rimType;

      const rimTile = (r: Option) => {
        const active = s.current.wheels === s.rimType && s.current.modFrontWheels === r.value;
        const sub =
          installed && s.original.modFrontWheels === r.value
            ? `<small class="is-installed">${esc(locale('desc_installed'))}</small>`
            : `<small>${money(groupPrice(s, 'wheels'))}</small>`;

        return tile(`data-rim="${r.value}"`, r.label, sub, active);
      };

      let list = `<div class="tiles">${(rims ?? []).map(rimTile).join('')}</div>`;

      if (!rims) list = `<div class="empty">${esc(locale('ui_loading_rims'))}</div>`;
      else if (rims.length <= 1) list = `<div class="empty">${esc(locale('ui_no_rims'))}</div>`;

      return card(section, `<div class="chips">${chips}</div>${list}`, changedPill(section, order));
    }

    case 'smoke': {
      const on = s.current.modSmokeEnabled === true;
      const toggles = [false, true]
        .map((v) => {
          const label = locale(v ? 'ui_smoke_coloured' : 'ui_smoke_stock');

          return tile(`data-set="modSmokeEnabled" ${valueAttr(v)}`, label, optionPrice(s, 'modSmokeEnabled', v), on === v);
        })
        .join('');
      const colour = on ? rgbBlock(s, 'tyreSmokeColor', null, LIGHT_PRESETS) : '';

      return card(section, `<div class="tiles">${toggles}</div>${colour}`, groupPill(s, 'tyreSmoke', section, order));
    }

    case 'xenon': {
      const on = s.current.modXenon === true;
      const tiles = toArray<Named>(section.options)
        .map((o) => {
          const active = o.id === -1 ? !on : on && s.current.xenonColor === o.id;

          return tile(`data-xenon="${o.id}"`, o.label, '', active, o.hex);
        })
        .join('');

      return card(section, `<div class="tiles">${tiles}</div>`, groupPill(s, 'xenon', section, order));
    }

    case 'neon': {
      const enabled = toArray<boolean>(s.current.neonEnabled);
      const sides = NEON_SIDES.map((side, i) => {
        const sub = `<small>${esc(locale(enabled[i] ? 'desc_on' : 'desc_off'))}</small>`;

        return tile(`data-neon="${i}"`, locale(side), sub, enabled[i] === true);
      }).join('');
      const colour = `<span class="field-label">${esc(locale('ui_colour'))}</span>${rgbBlock(s, 'neonColor', null, LIGHT_PRESETS)}`;

      return card(section, `<div class="tiles">${sides}</div>${colour}`, groupPill(s, 'neon', section, order));
    }

    case 'extras': {
      const extras = extrasOf(s.current);
      const tiles = toArray<number>(section.ids)
        .map((id) => {
          const on = extras[String(id)] === 0;
          const sub = `<small>${esc(locale(on ? 'ui_fitted' : 'ui_removed'))}</small>`;

          return tile(`data-extra="${id}"`, locale('ui_extra_n', id), sub, on);
        })
        .join('');
      const hint = esc(locale('ui_extra_hint', money(groupPrice(s, 'extra'))));

      return card(section, `<div class="tiles">${tiles}</div><p class="hint">${hint}</p>`, changedPill(section, order));
    }
  }
}

function renderNav(s: Shop, order: Values) {
  $('nav').innerHTML = s.meta.categories
    .map((c) => {
      const changed = c.sections.some((section) => isChanged(section, order));

      return `
        <button class="nav-tab ${c.id === s.category ? 'is-active' : ''}" data-category="${c.id}">
          ${changed ? '<span class="nav-dot"></span>' : ''}
          ${icon(c.icon, 18)}
          <span>${esc(c.label)}</span>
        </button>`;
    })
    .join('');
}

function repairCard(s: Shop) {
  if (!s.damaged) return '';

  return `
    <section class="repair">
      <span class="repair-mark">${icon('wrench', 18)}</span>
      <div class="grow">
        <strong>${esc(locale('ui_damaged'))}</strong>
        <small>${esc(locale('ui_repair_it'))}</small>
      </div>
      <button class="btn btn--primary" data-action="repair" ${s.busy ? 'disabled' : ''}>
        ${s.busy ? icon('loader', 14, 2.4, 'spin') : ''}${esc(locale('ui_repair_price', money(s.meta.repairPrice || 0)))}
      </button>
    </section>`;
}

function renderBody(s: Shop, order: Values) {
  const body = $('body');
  const category = s.meta.categories.find((c) => c.id === s.category);
  const scroll = body.dataset.category === s.category ? body.scrollTop : 0;
  const sections = (category?.sections ?? []).map((section) => renderSection(s, section, order));

  body.dataset.category = s.category ?? '';
  body.innerHTML = repairCard(s) + sections.join('');
  body.scrollTop = scroll;
}

function renderFoot(s: Shop, order: Values) {
  const count = Object.keys(order).length;
  const total = price(s, order);

  let who = locale(s.meta.billsOwner ? 'ui_who_pick' : 'ui_who_bank');

  if (s.meta.requests) who = locale('ui_who_request');

  let note = count === 0 ? locale('ui_no_changes') : locale(count === 1 ? 'ui_change_one' : 'ui_change_many', count, who);

  if (s.damaged) note = locale('ui_repair_before');
  if (s.waiting) note = locale('ui_waiting_for', s.waiting);

  let verb = locale(s.meta.billsOwner ? 'ui_bill_install' : 'ui_pay_install');

  if (total === 0) verb = locale('ui_install');
  if (s.meta.requests) verb = locale('ui_request_install');

  const canReset = count > 0 && !s.busy;
  const canApply = canReset && !s.damaged;

  $('foot').innerHTML = `
    <div class="foot-row">
      <div class="total">
        <strong>${money(total)}</strong>
        <small class="${s.waiting || s.damaged ? 'is-waiting' : ''}">${esc(note)}</small>
      </div>
      <button class="btn btn--ghost" data-action="reset" ${canReset ? '' : 'disabled'}>${icon('reset', 14, 2.4)}${esc(locale('ui_reset'))}</button>
      <button class="btn btn--primary" data-action="apply" ${canApply ? '' : 'disabled'}>
        ${s.busy ? icon('loader', 14, 2.4, 'spin') : icon('wrench', 14, 2.4)}${esc(verb)}
      </button>
    </div>`;
}

function payerRows(list: Payer[] | null) {
  if (list === null) return `<div class="empty">${esc(locale('ui_looking'))}</div>`;
  if (list.length === 0) return `<div class="empty">${esc(locale('ui_nobody'))}</div>`;

  return list
    .map(
      (p) => `
        <button class="tile payer" data-payer="${p.id}" data-name="${esc(p.name)}">
          <span class="tile-head">
            <strong>${esc(p.name)}</strong>
            ${p.owner ? `<span class="pill pill--accent">${esc(locale('ui_owner'))}</span>` : ''}
            ${p.you ? `<span class="pill pill--muted">${esc(locale('ui_you'))}</span>` : ''}
          </span>
          <small>${esc(locale(p.you ? 'ui_pay_own' : 'ui_send_bill'))}</small>
        </button>`,
    )
    .join('');
}

function renderPicker(s: Shop | null) {
  const el = $('picker');
  const picking = s?.picking;

  if (!s || !picking) {
    el.hidden = true;
    el.innerHTML = '';
    return;
  }

  el.hidden = false;
  el.innerHTML = `
    <section class="card picker-card">
      <header class="card-head">
        <h2>${esc(locale('ui_who_pays', money(price(s, changes(s)))))}</h2>
        <button class="key-btn" data-action="cancel-pick">${esc(locale('ui_cancel'))}</button>
      </header>
      <div class="card-body">
        <p class="hint">${esc(locale('ui_within', s.meta.payerDistance ?? 5))}</p>
        <div class="payers">${payerRows(picking.list)}</div>
      </div>
    </section>`;
}

async function openPicker(s: Shop) {
  s.picking = { list: null };
  renderPicker(s);

  const list = toArray<Payer>(await nui('customs:payers'));

  if (shop !== s || !s.picking) return;

  s.picking.list = list;
  renderPicker(s);
}

function closePicker(s: Shop) {
  s.picking = null;
  renderPicker(s);
}

function render(s: Shop) {
  const order = changes(s);

  renderNav(s, order);
  renderBody(s, order);
  renderFoot(s, order);
}

async function repair(s: Shop) {
  s.busy = true;
  render(s);

  const res = await ask('customs:repair');

  if (shop !== s) return;

  s.busy = false;

  if (res.ok) s.damaged = false;
  if (res.msg) toast(res.msg, res.ok);

  render(s);
}

async function loadRims(s: Shop, type: number) {
  s.rimType = type;

  if (!s.rims[type]) {
    render(s);
    s.rims[type] = toArray<Option>(await nui('customs:rims', { type }));
  }

  if (shop === s) render(s);
}

function selectCategory(s: Shop, id: string) {
  s.category = id;

  const sections = s.meta.categories.find((c) => c.id === id)?.sections ?? [];
  const first = sections[0];

  focusSection(first ? focusKey(first) : 'overview');

  const wheels = sections.find((section) => section.type === 'wheels');

  if (wheels?.type === 'wheels' && s.rimType === null) {
    const types = toArray<Named>(wheels.types);
    const fits = types.find((t) => t.id === s.current.wheels) ?? types[0];

    if (fits) {
      void loadRims(s, fits.id);
      return;
    }
  }

  render(s);
}

export function openShop(raw: ShopMeta) {
  const categories = toArray<Category>(raw.categories).map((c) => ({ ...c, sections: toArray<Section>(c.sections) }));
  const meta: ShopMeta = {
    ...raw,
    categories,
    colours: toArray<Named>(raw.colours),
    finishes: toArray<Named>(raw.finishes),
    bike: categories.some((c) => c.sections.some((section) => section.type === 'wheels' && section.bike === true)),
  };
  const values: Values = { ...(raw.values ?? {}) };

  values.extras = Array.isArray(values.extras) || !values.extras ? {} : values.extras;

  const opened: Shop = {
    meta,
    original: clone(values),
    current: clone(values),
    category: null,
    rimType: null,
    rims: {},
    busy: false,
    waiting: null,
    picking: null,
    damaged: meta.damaged === true,
  };

  shop = opened;
  focused = 'overview';

  shopEl.innerHTML = `
    <header class="panel-head">
      ${brandMark()}
      <div class="panel-title">
        <h1>${esc(meta.shop)}</h1>
        <p>${esc(meta.vehicle?.name)} · ${esc(String(meta.vehicle?.plate ?? '').trim())}</p>
      </div>
      <button class="key-btn" data-action="close">${esc(locale('ui_esc'))}</button>
    </header>
    <nav class="nav" id="nav"></nav>
    <main class="body" id="body"></main>
    <footer class="foot" id="foot"></footer>
    <div class="picker" id="picker" hidden></div>`;

  shopEl.hidden = false;
  dragEl.hidden = false;
  camHint.textContent = locale('ui_cam_hint');
  camHint.hidden = false;

  const first = meta.categories[0];

  if (first) selectCategory(opened, first.id);
}

export function closeShop() {
  shop = null;
  shopEl.hidden = true;
  dragEl.hidden = true;
  camHint.hidden = true;
  shopEl.innerHTML = '';
}

async function apply(s: Shop, payer?: { id: number; name: string }) {
  const order = changes(s);

  if (!Object.keys(order).length || s.busy) return;

  if (s.meta.billsOwner && !s.meta.requests && price(s, order) > 0 && !payer) {
    await openPicker(s);
    return;
  }

  s.busy = true;
  renderFoot(s, order);

  const res = await ask('customs:apply', { changes: order, payer: payer?.id });

  if (shop !== s) return;
  if (res.msg) toast(res.msg, res.ok);

  if (res.ok && res.requested) {
    void nui('customs:close');
    return;
  }

  if (res.ok && res.waiting) {
    s.waiting = payer?.name || locale('ui_them');
    renderFoot(s, order);
    return;
  }

  s.busy = false;

  if (res.ok) s.original = clone(s.current);

  render(s);
}

export function billed(result: Result) {
  const s = shop;

  if (!s) return;

  s.busy = false;
  s.waiting = null;

  if (result.ok) s.original = clone(s.current);
  if (result.msg) toast(result.msg, result.ok);

  render(s);
}

export function escapeShop() {
  const s = shop;

  if (!s) return false;

  if (s.picking) closePicker(s);
  else void nui('customs:close');

  return true;
}

function change(s: Shop, d: DOMStringMap) {
  if (d.set) {
    set(s, { [d.set]: JSON.parse(d.value ?? 'null') as Value });
  } else if (d.rim !== undefined) {
    set(s, { wheels: s.rimType ?? 0, modFrontWheels: Number(d.rim) });
  } else if (d.finish && d.colourKey) {
    set(s, { [d.finish]: Number(d.id), [d.colourKey]: rgbOf(s, d.colourKey) });
  } else if (d.rgbPreset && d.hex) {
    const patch: Values = { [d.rgbPreset]: hexToRgb(d.hex) };

    if (d.finishKey) patch[d.finishKey] = finishOf(s, d.finishKey);

    set(s, patch);
  } else if (d.xenon !== undefined) {
    const id = Number(d.xenon);

    set(s, id === -1 ? { modXenon: false } : { modXenon: true, xenonColor: id });
  } else if (d.neon !== undefined) {
    const enabled = toArray<boolean>(s.current.neonEnabled).slice(0, 4);

    while (enabled.length < 4) enabled.push(false);

    enabled[Number(d.neon)] = !enabled[Number(d.neon)];
    set(s, { neonEnabled: enabled, neonColor: rgbOf(s, 'neonColor') });
  } else if (d.extra !== undefined) {
    const extras = { ...extrasOf(s.current) };

    extras[d.extra] = extras[d.extra] === 0 ? 1 : 0;
    set(s, { extras });
  } else {
    return false;
  }

  return true;
}

shopEl.addEventListener('pointerdown', (e) => {
  const section = (e.target as Element).closest<HTMLElement>('[data-focus]');

  if (shop && section?.dataset.focus) focusSection(section.dataset.focus);
});

shopEl.addEventListener('click', (e) => {
  const s = shop;

  if (!s) return;

  const el = (e.target as Element).closest('button');

  if (!el || el.disabled) return;

  const d = el.dataset;

  if (d.action === 'close') {
    void nui('customs:close');
    return;
  }

  if (s.busy) return;

  if (d.action === 'cancel-pick') {
    closePicker(s);
  } else if (d.payer !== undefined) {
    closePicker(s);
    void apply(s, { id: Number(d.payer), name: d.name ?? '' });
  } else if (d.action === 'apply') {
    void apply(s);
  } else if (d.action === 'repair') {
    void repair(s);
  } else if (d.action === 'reset') {
    s.current = clone(s.original);
    void nui('customs:reset');
    render(s);
  } else if (d.category) {
    selectCategory(s, d.category);
  } else if (d.rimType !== undefined) {
    void loadRims(s, Number(d.rimType));
  } else if (change(s, d)) {
    render(s);
  }
});

shopEl.addEventListener('input', (e) => {
  const s = shop;
  const input = e.target as HTMLInputElement;
  const key = input.dataset.hexInput;

  if (!s || !key) return;

  if (s.busy) {
    render(s);
    return;
  }

  const match = HEX_CODE.exec(input.value.trim());

  input.classList.toggle('is-invalid', !match);

  if (!match) return;

  const hex = `#${match[1].toLowerCase()}`;
  const patch: Values = { [key]: hexToRgb(hex) };

  if (input.dataset.finishKey) patch[input.dataset.finishKey] = finishOf(s, input.dataset.finishKey);

  set(s, patch);

  const swatch = shopEl.querySelector<HTMLElement>(`[data-rgb-preview="${key}"]`);

  if (swatch) swatch.style.background = hex;

  const order = changes(s);

  renderNav(s, order);
  renderFoot(s, order);
});

shopEl.addEventListener('change', (e) => {
  if (shop && (e.target as HTMLElement).dataset.hexInput) render(shop);
});

let drag: { x: number; y: number } | null = null;
let cam = { dx: 0, dy: 0, zoom: 0 };
let camQueued = false;

function sendCamera() {
  if (camQueued) return;

  camQueued = true;
  requestAnimationFrame(() => {
    const body = cam;

    camQueued = false;
    cam = { dx: 0, dy: 0, zoom: 0 };

    if (body.dx || body.dy || body.zoom) void nui('customs:camera', body);
  });
}

dragEl.addEventListener('mousedown', (e) => {
  drag = { x: e.clientX, y: e.clientY };
  dragEl.classList.add('is-dragging');
});

window.addEventListener('mousemove', (e) => {
  if (!drag) return;

  cam.dx += e.clientX - drag.x;
  cam.dy += e.clientY - drag.y;
  drag = { x: e.clientX, y: e.clientY };
  sendCamera();
});

window.addEventListener('mouseup', () => {
  drag = null;
  dragEl.classList.remove('is-dragging');
});

dragEl.addEventListener('wheel', (e) => {
  cam.zoom += Math.sign(e.deltaY);
  sendCamera();
});
