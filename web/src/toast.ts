import { icon } from './icons';
import { locale } from './locale';
import { $, esc } from './util';

const TOAST_MS = 3200;

const toastsEl = $('toasts');

export function toast(text: string, ok: boolean) {
  const el = document.createElement('div');

  el.className = `toast ${ok ? '' : 'toast--error'}`;
  el.innerHTML = `
    <span class="toast-icon">${icon(ok ? 'check' : 'x', 15, 3)}</span>
    <div class="toast-body">
      <div class="toast-title">${esc(locale(ok ? 'ui_done' : 'ui_failed'))}</div>
      <div class="toast-text">${esc(text)}</div>
    </div>
    <span class="toast-bar" style="animation-duration:${TOAST_MS}ms"></span>`;

  while (toastsEl.children.length > 2) toastsEl.firstChild?.remove();
  toastsEl.appendChild(el);

  setTimeout(() => {
    el.classList.add('is-leaving');
    setTimeout(() => el.remove(), 200);
  }, TOAST_MS);
}
