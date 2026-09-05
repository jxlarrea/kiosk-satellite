import { $, cmd, state } from './core.js';
import { currentPath } from './tabs.js';
import { hintRow, modalShell } from './widgets.js';

/* ---- The kiosk switcher ----
   Every kiosk with its remote admin on announces itself on the network and
   hears the others (the device's fleet manager, over mDNS). The device name
   under the logo is the trigger: plain text alone on the network, a
   dropdown once another kiosk is heard. Picking one opens its remote admin
   in this tab, on the page this one is showing: a first-level tab lands on
   itself, a second-level page on itself where that kiosk has it and on its
   parent tab where it is gated away (showTab's own fallback). */

let devices = [];
let picker = null;

function others() { return devices.filter((d) => !d.self); }

function apply(list) {
  devices = Array.isArray(list) ? list : [];
  state.fleet = devices;
  document.body.classList.toggle('has-fleet', others().length > 0);
  if (picker) picker.render();
}

export async function refreshFleet() {
  try {
    const r = await cmd('fleet');
    if (r.ok) apply(r.data?.devices || []);
  } catch (_) {}
}

// The device pushes every change over the socket; the picker follows it
// while open, so a kiosk that boots shows up without reopening.
document.addEventListener('ks-event', (e) => {
  if (e.detail?.event === 'fleet') apply(e.detail.data?.devices || []);
});

function tag(text, kind = '') {
  const t = document.createElement('span');
  t.className = 'tag' + (kind ? ' ' + kind : '');
  t.textContent = text;
  return t;
}

// A tap is the pick, so the row carries no control: the name on its own
// line, then the address, the version tag and, on the one this page came
// from, the This device tag. The tags share the second line so a long
// name has the first to itself and truncates there.
function deviceRow(d) {
  const row = document.createElement('div');
  row.className = 'row fleet-row' + (d.self ? ' self' : '');
  const info = document.createElement('div');
  info.className = 'info';
  const name = document.createElement('div');
  name.className = 'name';
  const nameText = document.createElement('span');
  nameText.textContent = d.name || d.address;
  name.appendChild(nameText);
  const desc = document.createElement('div');
  desc.className = 'desc';
  const addr = document.createElement('span');
  addr.textContent = d.address;
  desc.appendChild(addr);
  if (d.version) desc.appendChild(tag(d.version));
  if (d.self) desc.appendChild(tag('This device', 'device'));
  info.append(name, desc);
  row.appendChild(info);
  if (!d.self) {
    row.setAttribute('role', 'button');
    row.tabIndex = 0;
    const go = () => switchTo(d);
    row.addEventListener('click', go);
    row.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); go(); }
    });
  }
  return row;
}

// The same page on the other kiosk. A second-level page that kiosk does
// not have falls back to its tab there (showTab), and its own login card
// shows first if its password differs.
function switchTo(d) {
  const base = d.url || `http://${d.address}:${d.port}`;
  location.href = `${base}/#${currentPath}`;
}

export function openFleetPicker() {
  if (picker) return;
  const openedAt = Date.now();
  const shell = modalShell({
    title: 'Switch kiosk',
    onDismiss: close,
  });
  const cancel = document.createElement('button');
  cancel.className = 'btn-text';
  cancel.textContent = 'Cancel';
  cancel.addEventListener('click', close);
  shell.foot.appendChild(cancel);
  let lookTimer = null;
  let poll = null;

  function close() {
    clearTimeout(lookTimer);
    clearInterval(poll);
    shell.close();
    picker = null;
  }

  function render() {
    const body = shell.body;
    body.innerHTML = '';
    devices.forEach((d) => body.appendChild(deviceRow(d)));
    if (others().length) {
      body.appendChild(hintRow('Kiosks on this network with the remote admin on. '
        + 'Picking one opens its admin here, on this same page.'));
    } else if (Date.now() - openedAt < 6000) {
      // A query went out when this device started; give the answers a
      // moment before calling the network empty.
      const looking = document.createElement('div');
      looking.className = 'fleet-looking';
      looking.innerHTML = '<span class="fleet-spinner"></span><span></span>';
      looking.querySelector('span:last-child').textContent = 'Looking for other kiosks…';
      body.appendChild(looking);
      clearTimeout(lookTimer);
      lookTimer = setTimeout(render, 6000 - (Date.now() - openedAt) + 50);
    } else {
      body.appendChild(hintRow('No other kiosk found on this network. A kiosk shows '
        + 'up once its remote admin is on and it shares this network.'));
    }
  }

  picker = { render };
  render();
  refreshFleet();
  // The socket carries changes; the poll covers a socket that is down.
  poll = setInterval(refreshFleet, 5000);
}

export function initFleet() {
  document.querySelectorAll('.js-fleet-pick').forEach((btn) => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      if (document.body.classList.contains('has-fleet')) openFleetPicker();
    });
  });
  refreshFleet();
}

// The name under the logo, in the rail and in the phone top bar alike.
export function setDeviceName(name) {
  document.querySelectorAll('.js-device-name').forEach((el) => {
    el.textContent = name;
  });
  const rail = $('#deviceName');
  if (rail) rail.title = name;
}
