import './style.css';
import { renderInspect } from './inspect';
import { closeInstall, escapeInstall, openInstall } from './install';
import { setLocale } from './locale';
import { nui } from './nui';
import { billed, closeShop, escapeShop, openShop } from './shop';
import { closeTablet, escapeTablet, listTablet, openTablet } from './tablet';
import type { InstallJob, Inspection, Result, ShopMeta } from './types';
import { $, wait } from './util';

const frame = $('frame');

function fit() {
  const scale = Math.min(innerWidth / 1920, innerHeight / 1080);

  frame.style.width = `${innerWidth / scale}px`;
  frame.style.height = `${innerHeight / scale}px`;
  frame.style.transform = `scale(${scale})`;
}

async function loadLocale() {
  for (;;) {
    try {
      const init = await nui<{ locale: Record<string, string> }>('ready');

      setLocale(init.locale);
      return;
    } catch {
      await wait(1000);
    }
  }
}

window.addEventListener('keydown', (e) => {
  if (e.key !== 'Escape') return;

  if (!escapeInstall() && !escapeTablet()) escapeShop();
});

window.addEventListener('message', (e: MessageEvent<{ action?: string; data?: unknown }>) => {
  const { action, data } = e.data ?? {};

  switch (action) {
    case 'inspect':
      renderInspect(data as Inspection | false);
      break;
    case 'customs:open':
      openShop(data as ShopMeta);
      break;
    case 'customs:close':
      closeShop();
      break;
    case 'customs:billed':
      billed((data ?? { ok: false }) as Result);
      break;
    case 'tablet:open':
      openTablet();
      break;
    case 'tablet:list':
      listTablet(data);
      break;
    case 'tablet:close':
      closeTablet();
      break;
    case 'install:start':
      openInstall((data ?? {}) as InstallJob);
      break;
    case 'install:close':
      closeInstall();
      break;
  }
});

window.addEventListener('resize', fit);
fit();
void loadLocale();
