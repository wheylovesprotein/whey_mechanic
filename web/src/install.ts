import { brandMark, icon } from './icons';
import { locale } from './locale';
import { nui } from './nui';
import type { InstallJob } from './types';
import { $, esc, toArray } from './util';

interface Wire {
  id: string;
  hex: string;
}

interface Fluid {
  label: string;
  hex: string;
  level: number;
}

interface NutsGame {
  type: 'nuts';
  done: Set<number>;
  holding: { i: number; el: SVGGElement; start: number } | null;
}

interface HarnessGame {
  type: 'harness';
  left: Wire[];
  right: Wire[];
  picked: string | null;
  linked: Set<string>;
}

interface FluidsGame {
  type: 'fluids';
  index: number;
  pouring: boolean;
  fluids: Fluid[];
}

interface Job {
  seconds: number;
  penalty: number;
  endsAt: number;
  step: number;
  game: NutsGame | HarnessGame | FluidsGame | null;
}

const STEPS = ['ui_step_nuts', 'ui_step_harness', 'ui_step_fluids'];
const NUT_HOLD = 650;
const NUT_ORDER = [0, 2, 4, 1, 3];
const WIRES: Wire[] = [
  { id: 'red', hex: '#ff4d5e' },
  { id: 'yellow', hex: '#ffd23f' },
  { id: 'blue', hex: '#3d8bff' },
  { id: 'green', hex: '#35d07f' },
];
const POUR_RATE = 0.3;
const FILL_BAND = [0.72, 0.86];

const installEl = $('install');

let job: Job | null = null;
let lastTick = 0;

const stageEl = () => $('stage');

function shuffle<T>(list: T[]) {
  const out = [...list];

  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));

    [out[i], out[j]] = [out[j], out[i]];
  }

  return out;
}

function hexPoints(x: number, y: number, r: number) {
  return Array.from({ length: 6 }, (_, i) => {
    const a = (Math.PI / 3) * i;

    return `${(x + r * Math.cos(a)).toFixed(1)},${(y + r * Math.sin(a)).toFixed(1)}`;
  }).join(' ');
}

function setHint(text: string) {
  $('installHint').textContent = text;
}

function penalize(j: Job) {
  j.endsAt -= j.penalty * 1000;

  const bar = $('installClock');

  bar.classList.remove('is-hit');
  void bar.offsetWidth;
  bar.classList.add('is-hit');
}

function renderSteps(j: Job) {
  $('installSteps').innerHTML = STEPS.map((label, i) => {
    const state = i < j.step ? 'is-done' : i === j.step ? 'is-active' : '';

    return `<span class="step ${state}"><b>${i < j.step ? icon('check', 12, 3) : i + 1}</b>${esc(locale(label))}</span>`;
  }).join('');
}

function closeJob() {
  job = null;
  installEl.hidden = true;
  installEl.innerHTML = '';
}

function finishInstall(ok: boolean, reason?: string) {
  if (!job) return;

  closeJob();
  void nui('install:done', { ok, reason });
}

function nextNut(g: NutsGame) {
  return NUT_ORDER.find((i) => !g.done.has(i));
}

function renderNuts(g: NutsGame) {
  const next = nextNut(g);
  const nuts = [0, 1, 2, 3, 4]
    .map((i) => {
      const a = ((i * 72 - 90) * Math.PI) / 180;
      const x = 130 + Math.cos(a) * 62;
      const y = 130 + Math.sin(a) * 62;

      if (g.done.has(i)) return `<circle cx="${x}" cy="${y}" r="9" class="nut-hole" />`;

      return `
        <g class="nut ${i === next ? 'is-next' : ''}" data-nut="${i}" style="transform-origin:${x}px ${y}px">
          <circle cx="${x}" cy="${y}" r="21" class="nut-hit" />
          <polygon points="${hexPoints(x, y, 13)}" class="nut-body" />
          <circle cx="${x}" cy="${y}" r="18" class="nut-ring" pathLength="100" />
        </g>`;
    })
    .join('');

  stageEl().innerHTML = `
    <svg class="wheel" viewBox="0 0 260 260">
      <circle cx="130" cy="130" r="124" class="tyre" />
      <circle cx="130" cy="130" r="98" class="rim" />
      <circle cx="130" cy="130" r="32" class="hub" />
      ${nuts}
    </svg>`;
}

function nutsStage(j: Job) {
  const g: NutsGame = { type: 'nuts', done: new Set(), holding: null };

  j.game = g;
  setHint(locale('ui_hint_nuts'));
  renderNuts(g);
}

function ring(el: SVGGElement) {
  return el.querySelector<SVGCircleElement>('.nut-ring');
}

function nutsDown(j: Job, g: NutsGame, target: Element) {
  const nut = target.closest<SVGGElement>('[data-nut]');

  if (!nut) return;

  const i = Number(nut.dataset.nut);

  if (i !== nextNut(g)) {
    penalize(j);
    nut.classList.add('is-wrong');
    setTimeout(() => nut.classList.remove('is-wrong'), 300);
    return;
  }

  g.holding = { i, el: nut, start: performance.now() };
}

function nutsTick(j: Job, g: NutsGame, now: number) {
  const holding = g.holding;

  if (!holding) return;

  const p = Math.min(1, (now - holding.start) / NUT_HOLD);
  const circle = ring(holding.el);

  if (circle) circle.style.strokeDasharray = `${p * 100} 100`;

  holding.el.style.transform = `rotate(${-p * 300}deg)`;

  if (p < 1) return;

  g.done.add(holding.i);
  g.holding = null;

  if (g.done.size === NUT_ORDER.length) {
    nextStep(j);
    return;
  }

  renderNuts(g);
}

function nutsUp(g: NutsGame) {
  const holding = g.holding;

  if (!holding) return;

  const circle = ring(holding.el);

  if (circle) circle.style.strokeDasharray = '0 100';

  holding.el.style.transform = '';
  g.holding = null;
}

function renderHarness(g: HarnessGame) {
  const rowY = (i: number) => 45 + i * 56;
  const hex = (id: string) => WIRES.find((w) => w.id === id)?.hex ?? '';

  const links = [...g.linked]
    .map((id) => {
      const y1 = rowY(g.left.findIndex((w) => w.id === id));
      const y2 = rowY(g.right.findIndex((w) => w.id === id));

      return `<path d="M76 ${y1} C 210 ${y1}, 230 ${y2}, 364 ${y2}" stroke="${hex(id)}" class="wire" />`;
    })
    .join('');

  const left = g.left
    .map((w, i) => {
      const state = g.linked.has(w.id) ? 'is-linked' : g.picked === w.id ? 'is-picked' : '';

      return `
        <g class="plug ${state}" data-left="${w.id}">
          <rect x="20" y="${rowY(i) - 16}" width="56" height="32" rx="6" class="plug-body" />
          <rect x="28" y="${rowY(i) - 6}" width="40" height="12" rx="3" fill="${w.hex}" />
        </g>`;
    })
    .join('');

  const right = g.right
    .map((w, i) => {
      const state = g.linked.has(w.id) ? 'is-linked' : '';

      return `
        <g class="plug ${state}" data-right="${w.id}">
          <rect x="364" y="${rowY(i) - 16}" width="56" height="32" rx="6" class="plug-body" />
          <circle cx="392" cy="${rowY(i)}" r="8" fill="${w.hex}" />
        </g>`;
    })
    .join('');

  stageEl().innerHTML = `<svg class="harness" viewBox="0 0 440 250">${links}${left}${right}</svg>`;
}

function harnessStage(j: Job) {
  const g: HarnessGame = { type: 'harness', left: shuffle(WIRES), right: shuffle(WIRES), picked: null, linked: new Set() };

  j.game = g;
  setHint(locale('ui_hint_harness'));
  renderHarness(g);
}

function harnessDown(j: Job, g: HarnessGame, target: Element) {
  const left = target.closest<SVGGElement>('[data-left]')?.dataset.left;
  const right = target.closest<SVGGElement>('[data-right]')?.dataset.right;

  if (left && !g.linked.has(left)) {
    g.picked = left;
    renderHarness(g);
    return;
  }

  if (!right || !g.picked || g.linked.has(right)) return;

  if (right === g.picked) {
    g.linked.add(g.picked);
    g.picked = null;

    if (g.linked.size === WIRES.length) {
      nextStep(j);
      return;
    }
  } else {
    penalize(j);
    g.picked = null;
  }

  renderHarness(g);
}

function renderFluids(g: FluidsGame) {
  const gauges = g.fluids
    .map((f, i) => {
      const state = i < g.index ? 'is-done' : i === g.index ? 'is-active' : '';

      return `
        <div class="gauge ${state}">
          <div class="gauge-tube">
            <div class="gauge-band" style="bottom:${FILL_BAND[0] * 100}%;height:${(FILL_BAND[1] - FILL_BAND[0]) * 100}%"></div>
            <div class="gauge-fill" data-fill="${i}" style="height:${f.level * 100}%;background:${f.hex}"></div>
          </div>
          <span>${i < g.index ? icon('check', 12, 3) : ''}${esc(f.label)}</span>
        </div>`;
    })
    .join('');

  stageEl().innerHTML = `
    <div class="fluids">
      <div class="gauges">${gauges}</div>
      <button class="btn btn--primary pour" data-pour>${esc(locale('ui_pour', g.fluids[g.index].label))}</button>
    </div>`;
}

function fluidsStage(j: Job) {
  const g: FluidsGame = {
    type: 'fluids',
    index: 0,
    pouring: false,
    fluids: [
      { label: locale('ui_engine_oil'), hex: '#d9a23a', level: 0.12 + Math.random() * 0.15 },
      { label: locale('ui_coolant'), hex: '#35d0c4', level: 0.12 + Math.random() * 0.15 },
    ],
  };

  j.game = g;
  setHint(locale('ui_hint_fluids'));
  renderFluids(g);
}

function fluidsDown(g: FluidsGame, target: Element) {
  if (target.closest('[data-pour]')) g.pouring = true;
}

function fluidsTick(j: Job, g: FluidsGame, dt: number) {
  if (!g.pouring) return;

  const fluid = g.fluids[g.index];

  fluid.level += POUR_RATE * dt;

  if (fluid.level >= 1) {
    g.pouring = false;
    fluid.level = 0.4;
    penalize(j);
    renderFluids(g);
    return;
  }

  const fill = stageEl().querySelector<HTMLElement>(`[data-fill="${g.index}"]`);

  if (fill) fill.style.height = `${fluid.level * 100}%`;
}

function fluidsUp(j: Job, g: FluidsGame) {
  if (!g.pouring) return;

  g.pouring = false;

  const fluid = g.fluids[g.index];

  if (fluid.level < FILL_BAND[0]) return;

  if (fluid.level > FILL_BAND[1]) {
    fluid.level = 0.5;
    penalize(j);
    renderFluids(g);
    return;
  }

  g.index += 1;

  if (g.index >= g.fluids.length) {
    nextStep(j);
    return;
  }

  renderFluids(g);
}

const STAGES = [nutsStage, harnessStage, fluidsStage];

function nextStep(j: Job) {
  j.step += 1;

  if (j.step >= STEPS.length) {
    finishInstall(true);
    return;
  }

  renderSteps(j);
  STAGES[j.step](j);
}

function tick(now: number) {
  const j = job;

  if (!j) return;

  const left = Math.max(0, j.endsAt - Date.now());

  $('installClock').style.width = `${(left / (j.seconds * 1000)) * 100}%`;
  $('installTime').textContent = `${Math.ceil(left / 1000)}s`;

  if (left <= 0) {
    finishInstall(false, 'time');
    return;
  }

  const dt = lastTick ? (now - lastTick) / 1000 : 0;
  const g = j.game;

  lastTick = now;

  if (g?.type === 'nuts') nutsTick(j, g, now);
  else if (g?.type === 'fluids') fluidsTick(j, g, dt);

  if (job) requestAnimationFrame(tick);
}

export function openInstall(data: InstallJob) {
  const seconds = data.seconds || 30;
  const opened: Job = {
    seconds,
    penalty: data.penalty || 1.5,
    endsAt: Date.now() + seconds * 1000,
    step: 0,
    game: null,
  };
  const parts = toArray<string>(data.parts);
  const summary = parts.length === 1 ? parts[0] : locale('ui_parts_n', parts.length);

  job = opened;

  installEl.innerHTML = `
    <section class="install-card">
      <header class="panel-head">
        ${brandMark()}
        <div class="panel-title">
          <h1>${esc(locale('ui_fitting'))}</h1>
          <p>${esc(data.vehicle)} · ${esc(String(data.plate ?? '').trim())} · ${esc(summary)}</p>
        </div>
        <span class="install-time" id="installTime"></span>
        <button class="key-btn" data-install="cancel">${esc(locale('ui_esc'))}</button>
      </header>
      <div class="install-clock"><span id="installClock"></span></div>
      <div class="steps" id="installSteps"></div>
      <div class="stage" id="stage"></div>
      <p class="hint install-hint" id="installHint"></p>
    </section>`;

  installEl.hidden = false;
  renderSteps(opened);
  nutsStage(opened);
  lastTick = 0;
  requestAnimationFrame(tick);
}

export function closeInstall() {
  closeJob();
}

export function escapeInstall() {
  if (!job) return false;

  finishInstall(false, 'cancel');

  return true;
}

installEl.addEventListener('pointerdown', (e) => {
  const j = job;
  const target = e.target as Element;

  if (!j) return;

  if (target.closest('[data-install="cancel"]')) {
    finishInstall(false, 'cancel');
    return;
  }

  const g = j.game;

  if (g?.type === 'nuts') nutsDown(j, g, target);
  else if (g?.type === 'harness') harnessDown(j, g, target);
  else if (g?.type === 'fluids') fluidsDown(g, target);
});

window.addEventListener('pointerup', () => {
  const j = job;
  const g = j?.game;

  if (!j || !g) return;

  if (g.type === 'nuts') nutsUp(g);
  else if (g.type === 'fluids') fluidsUp(j, g);
});
