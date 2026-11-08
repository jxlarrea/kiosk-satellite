/* ---- Devices without a screen ----
   An Echo Dot and its kind run the kiosk headless (core/headless.dart):
   voice, audio and this admin page, nothing on a display. The device says
   so in its info, and the page then leaves out everything that draws,
   watches a camera or manages what is on screen. Markup marks those parts
   with the no-headless class (hidden by app.css under html[data-headless]);
   tabs and search ask tabHidden(). */

import { localizeNavigation } from './localization.js';

// The pages with nothing that works without a screen.
const HIDDEN_TABS = new Set([
  'navigation', 'screensaver', 'browser', 'camera', 'cameras', 'kiosk', 'lockdown', 'home', 'launcher',
  'calendar',
]);

export function isHeadless() {
  return document.documentElement.hasAttribute('data-headless');
}

export function applyHeadless(on) {
  if (isHeadless() === !!on) return;
  document.documentElement.toggleAttribute('data-headless', !!on);
  // The nav's data-headless-text labels.
  localizeNavigation();
}

export function tabHidden(tab) {
  return isHeadless() && HIDDEN_TABS.has(tab);
}
