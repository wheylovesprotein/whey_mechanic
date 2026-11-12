import { brandMark, icon } from './icons';
import { locale } from './locale';
import { ask, nui } from './nui';
import { toast } from './toast';
import type { PartRequest, RequestStatus } from './types';
import { $, esc, money, toArray } from './util';

interface Tablet {
  list: PartRequest[] | null;
  busy: number | null;
}

const STATUS: Record<RequestStatus, string> = {
  requested: 'pill--muted',
  billed: 'pill--accent',
  paid: 'pill--ok',
  installing: 'pill--accent',
  fitted: 'pill--warn',
};

const tabletEl = $('tablet');

let tablet: Tablet | null = null;

function ago(ms: number) {
  const mins = Math.max(0, Math.round((Date.now() - ms) / 60000));

  if (mins < 1) return locale('ui_just_now');
  if (mins < 60) return locale('ui_mins_ago', mins);

  const hours = Math.round(mins / 60);

  return hours < 24 ? locale('ui_hours_ago', hours) : locale('ui_days_ago', Math.round(hours / 24));
}

function requestNote(r: PartRequest) {
  if (r.status === 'requested' && !r.online) return locale('ui_note_offline');
  if (r.status === 'billed') return locale('ui_note_billed');
  if (r.status === 'paid') return locale('ui_note_paid');
  if (r.status === 'installing') return locale('ui_note_installing', r.installer ?? '');
  if (r.status === 'fitted') return locale('ui_note_fitted', r.installer ?? '');

  return locale('ui_note_requested', ago(r.createdAt));
}

function requestCard(t: Tablet, r: PartRequest) {
  const status: RequestStatus = r.status in STATUS ? r.status : 'requested';
  const busy = t.busy === r.id;
  const parts = toArray<string>(r.parts)
    .map((p) => `<li>${esc(p)}</li>`)
    .join('');

  let actions = '';

  if (r.status === 'requested') {
    actions = `
      <button class="btn btn--ghost" data-decline="${r.id}" ${t.busy ? 'disabled' : ''}>${esc(locale('ui_decline'))}</button>
      <button class="btn btn--primary" data-bill="${r.id}" ${t.busy || !r.online ? 'disabled' : ''}>
        ${busy ? icon('loader', 14, 2.4, 'spin') : icon('wrench', 14, 2.4)}${esc(locale('ui_bill_customer'))}
      </button>`;
  }

  return `
    <section class="card request">
      <header class="card-head">
        <h2>${esc(r.customer)}<span class="request-sub">${esc(r.model || locale('ui_vehicle'))} · ${esc(r.plate)}</span></h2>
        <span class="pill ${STATUS[status]}">${esc(locale(`ui_status_${status}`))}</span>
      </header>
      <div class="card-body">
        <ul class="parts">${parts}</ul>
        <div class="request-foot">
          <div class="total">
            <strong>${money(r.total)}</strong>
            <small>${esc(requestNote(r))}</small>
          </div>
          ${actions}
        </div>
      </div>
    </section>`;
}

function renderTablet(t: Tablet) {
  const list = t.list;
  const body = $('tabletBody');
  const scroll = body.scrollTop;

  let html = `<div class="empty">${esc(locale('ui_loading_requests'))}</div>`;

  if (list && list.length === 0) html = `<div class="empty">${esc(locale('ui_no_requests'))}</div>`;
  else if (list) html = list.map((r) => requestCard(t, r)).join('');

  const ready = (list ?? []).filter((r) => r.status === 'paid' || r.status === 'billed').length;

  $('tabletSub').textContent = list ? locale('ui_tablet_sub', list.length, ready) : locale('ui_tablet_brand');
  $('tabletTime').textContent = new Date().toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
  body.innerHTML = html;
  body.scrollTop = scroll;
}

export function openTablet() {
  const opened: Tablet = { list: null, busy: null };

  tablet = opened;

  tabletEl.innerHTML = `
    <div class="device">
      <span class="device-cam"></span>
      <div class="device-screen">
        <div class="device-bar">
          <span id="tabletTime"></span>
          <span>${esc(locale('ui_tablet_brand'))}</span>
        </div>
        <header class="panel-head">
          ${brandMark()}
          <div class="panel-title">
            <h1>${esc(locale('ui_pending_installs'))}</h1>
            <p id="tabletSub"></p>
          </div>
          <button class="key-btn" data-tablet="refresh" title="${esc(locale('ui_refresh'))}">${icon('reset', 13, 2.4)}</button>
          <button class="key-btn" data-tablet="close">${esc(locale('ui_esc'))}</button>
        </header>
        <main class="tablet-body" id="tabletBody"></main>
      </div>
    </div>`;

  tabletEl.hidden = false;
  renderTablet(opened);
}

export function closeTablet() {
  tablet = null;
  tabletEl.hidden = true;
  tabletEl.innerHTML = '';
}

export function listTablet(list: unknown) {
  if (!tablet) return;

  tablet.list = toArray<PartRequest>(list);
  renderTablet(tablet);
}

export function escapeTablet() {
  if (!tablet) return false;

  void nui('tablet:close');

  return true;
}

tabletEl.addEventListener('click', async (e) => {
  const t = tablet;

  if (!t) return;

  const el = (e.target as Element).closest('button');

  if (!el || el.disabled) return;

  const d = el.dataset;

  if (d.tablet === 'close') {
    void nui('tablet:close');
    return;
  }

  if (d.tablet === 'refresh') {
    void nui('tablet:refresh');
    return;
  }

  const id = Number(d.bill ?? d.decline);

  if (!id || t.busy) return;

  t.busy = id;
  renderTablet(t);

  const res = await ask(d.bill ? 'tablet:bill' : 'tablet:decline', { id });

  if (tablet !== t) return;

  t.busy = null;

  if (res.msg) toast(res.msg, res.ok);

  renderTablet(t);
});
