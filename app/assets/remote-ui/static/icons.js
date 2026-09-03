// The glyph each second-level settings page wears, on its entry row and in
// the page title, drawn to match the device's subpageIcons map (the same
// Material glyph, traced in the nav rail's stroke style). Keyed by the
// subpage name the settings API serves, so a page reads alike on both
// surfaces. Bare glyphs, no disc: the rail spends the colored discs on the
// first level, and a second level that repeated them would flatten the
// hierarchy.

const STROKE = 'fill="none" stroke="currentColor" stroke-width="2"'
  + ' stroke-linecap="round" stroke-linejoin="round"';

const svg = (body, attrs = STROKE, viewBox = '0 0 24 24') =>
  `<svg viewBox="${viewBox}" ${attrs}>${body}</svg>`;

export const SUBPAGE_ICONS = {
  // Home Assistant.
  'User Interface': svg('<rect x="3" y="3" width="7" height="9" rx="1.5"/>'
    + '<rect x="14" y="3" width="7" height="5" rx="1.5"/>'
    + '<rect x="14" y="12" width="7" height="9" rx="1.5"/>'
    + '<rect x="3" y="16" width="7" height="5" rx="1.5"/>'),
  'Theme': svg('<path d="M12 3a9 9 0 1 0 0 18c1 0 1.7-.8 1.7-1.7 0-.5-.2-.9-.5-1.2'
    + '-.3-.3-.5-.7-.5-1.1 0-.9.8-1.7 1.7-1.7H16a5 5 0 0 0 5-5c0-4.1-4-7.3-9-7.3z"/>'
    + '<circle cx="7.5" cy="12" r="1"/><circle cx="9.5" cy="7.5" r="1"/>'
    + '<circle cx="14.5" cy="7.5" r="1"/><circle cx="17" cy="11" r="1"/>'),
  'Dashboard View Rotation': svg('<path d="M21 12a9 9 0 0 1-15.5 6.2L3 16"/>'
    + '<path d="M3 21v-5h5"/><path d="M3 12a9 9 0 0 1 15.5-6.2L21 8"/>'
    + '<path d="M21 3v5h-5"/>'),
  'Return to home dashboard view': svg('<path d="M3 10.5 12 3l9 7.5"/>'
    + '<path d="M5 9.5V20a1 1 0 0 0 1 1h4v-6h4v6h4a1 1 0 0 0 1-1V9.5"/>'),
  'Hold mode': svg('<path d="M12 17v5"/>'
    + '<path d="M9 3h6l-.5 5.5 2.5 2.5v2H7v-2l2.5-2.5z"/>'),
  'Optimizations': svg('<path d="M4 15a8 8 0 1 1 16 0"/>'
    + '<path d="M12 15 16.5 9"/><circle cx="12" cy="15" r="1.5"/>'
    + '<path d="M4 19h16"/>'),
  // Voice Satellite.
  'Wake Word': svg('<path d="M6 8.5a6 6 0 0 1 12 0c0 3-1.5 4-2.5 5.5S14 17 14 18.5'
    + 'a2.5 2.5 0 0 1-5 0"/><path d="M10 8.5a2 2 0 0 1 4 0c0 1.2-.7 1.8-1.3 2.6'
    + '-.4.5-.7 1-.7 1.9"/>'),
  'Appearance': svg('<path d="m20 3-9.5 9.5"/>'
    + '<path d="M13 10.5 15.5 13 19.5 9 21 3z"/>'
    + '<path d="M9 14c-2.5 0-4 1.6-4 3.5 0 1.2-1 2-2 2.5 1.2.7 2.6 1 3.9 1'
    + ' 2.6 0 4.6-1.6 4.6-3.7 0-1.8-1.1-3.3-2.5-3.3z"/>'),
  // Screen & Audio.
  'Microphone settings': svg('<rect x="9" y="3" width="6" height="11" rx="3"/>'
    + '<path d="M5 11a7 7 0 0 0 14 0"/><path d="M12 18v3M9 21h6"/>'),
  'Adaptive brightness': svg('<circle cx="12" cy="12" r="5"/>'
    + '<path d="M12 2v2m0 16v2M4.9 4.9l1.4 1.4m11.4 11.4 1.4 1.4M2 12h2m16 0h2'
    + 'M4.9 19.1l1.4-1.4m11.4-11.4 1.4-1.4"/>'
    + '<path d="m10.2 14.5 1.8-5 1.8 5m-3-1.6h2.4" stroke-width="1.6"/>'),
  // Screensaver.
  'Clock screensaver': svg('<circle cx="12" cy="12" r="9"/>'
    + '<path d="M12 7v5l3.5 2"/>'),
  'Home Assistant Media screensaver': svg('<circle cx="12" cy="12" r="9"/>'
    + '<path d="m10 8.5 5 3.5-5 3.5z"/>'),
  'Local Media screensaver': svg('<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2'
    + 'v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>'),
  'Photo Gallery screensaver': svg('<rect x="7" y="3" width="14" height="12" rx="2"/>'
    + '<path d="M17 19v.5A1.5 1.5 0 0 1 15.5 21h-11A1.5 1.5 0 0 1 3 19.5V9.5'
    + 'A1.5 1.5 0 0 1 4.5 8H5"/><circle cx="11" cy="7.5" r="1.5"/>'
    + '<path d="m7 15 4-4 3 3 2-2 5 5"/>'),
  // The Immich mark, the five petals monochrome, the same rendition as
  // assets/svg/immich.svg on the device.
  'Immich Media screensaver': svg('<path d="M375.48,267.63c38.64,34.21,69.78,70.87,89.82,105.42c34.42-61.56,57.42-134.71,57.71-181.3c0-0.33,0-0.63,0-0.91c0-68.94-68.77-95.77-128.01-95.77s-128.01,26.83-128.01,95.77c0,0.94,0,2.2,0,3.72C300.01,209.24,339.15,235.47,375.48,267.63z'
    + 'M164.7,455.63c24.15-26.87,61.2-55.99,103.01-80.61c44.48-26.18,88.97-44.47,128.02-52.84c-47.91-51.76-110.37-96.24-154.6-110.91c-0.31-0.1-0.6-0.19-0.86-0.28c-65.57-21.3-112.34,35.81-130.64,92.15c-18.3,56.34-14.04,130.04,51.53,151.34C162.05,454.77,163.25,455.16,164.7,455.63z'
    + 'M681.07,302.19c-18.3-56.34-65.07-113.45-130.64-92.15c-0.9,0.29-2.1,0.68-3.54,1.15c-3.75,35.93-16.6,81.27-35.96,125.76c-20.59,47.32-45.84,88.27-72.51,118c69.18,13.72,145.86,12.98,190.26-1.14c0.31-0.1,0.6-0.2,0.86-0.28C695.11,432.22,699.37,358.52,681.07,302.19z'
    + 'M336.54,510.71c-11.15-50.39-14.8-98.36-10.7-138.08c-64.03,29.57-125.63,75.23-153.26,112.76c-0.19,0.26-0.37,0.51-0.53,0.73c-40.52,55.78-0.66,117.91,47.27,152.72c47.92,34.82,119.33,53.54,159.86-2.24c0.56-0.76,1.3-1.78,2.19-3.01C363.28,602.32,347.02,558.08,336.54,510.71z'
    + 'M617.57,482.52c-35.33,7.54-82.42,9.33-130.72,4.66c-51.37-4.96-98.11-16.32-134.63-32.5c8.33,70.03,32.73,142.73,59.88,180.6c0.19,0.26,0.37,0.51,0.53,0.73c40.52,55.78,111.93,37.06,159.86,2.24c47.92-34.82,87.79-96.95,47.27-152.72C619.2,484.77,618.46,483.75,617.57,482.52z"/>',
    'fill="currentColor"', '60 48 670 670'),
  'Camera Streams screensaver': svg('<rect x="3" y="5" width="14" height="14" rx="2.5"/>'
    + '<path d="m17 10 4-2v8l-4-2z"/>'),
  'Widgets': svg('<rect x="3" y="3" width="7" height="7" rx="1.5"/>'
    + '<rect x="3" y="14" width="7" height="7" rx="1.5"/>'
    + '<rect x="14" y="14" width="7" height="7" rx="1.5"/>'
    + '<path d="m17.5 2.5 4 4-4 4-4-4z"/>'),
  'At a Glance': svg('<path d="M2 12s3.5-6.5 10-6.5S22 12 22 12s-3.5 6.5-10 6.5'
    + 'S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>'),
  'Motion Detection': svg('<circle cx="13.5" cy="4.5" r="1.7"/>'
    + '<path d="m9 21 2.5-6 3 2.5V21"/><path d="m6.5 12 3-3.5 3 1.5 2.5 3.5 3 1"/>'
    + '<path d="M11.5 15.5 9.5 13"/>'),
  'Face Detection': svg('<circle cx="12" cy="12" r="9"/>'
    + '<path d="M8.5 14.5s1.2 1.5 3.5 1.5 3.5-1.5 3.5-1.5"/>'
    + '<path d="M9 9.5h.01M15 9.5h.01"/>'),
  'Person Detection': svg('<circle cx="12" cy="7" r="3"/>'
    + '<path d="M6 21v-2a6 6 0 0 1 12 0v2"/>'
    + '<path d="M3 10a9 9 0 0 1 0 5m18-5a9 9 0 0 1 0 5"/>'),
  'Proximity Detection': svg('<circle cx="12" cy="12" r="1.5"/>'
    + '<path d="M8.5 8.5a5 5 0 0 0 0 7m7-7a5 5 0 0 1 0 7"/>'
    + '<path d="M5.6 5.6a9 9 0 0 0 0 12.8m12.8-12.8a9 9 0 0 1 0 12.8"/>'),
  'Scheduled Screensavers': svg('<rect x="3" y="5" width="18" height="16" rx="2"/>'
    + '<path d="M3 10h18M8 3v4m8-4v4"/>'),
  // Media Player. Sendspin and Music Assistant wear their own marks:
  // Sendspin the record from its favicon (the disc, a groove, the label
  // with the spindle hole cut out), Music Assistant the one the category
  // rail used to.
  'Sendspin Player': svg('<circle cx="12" cy="12" r="9.6" stroke-width="1.8"/>'
    + '<circle cx="12" cy="12" r="6.9" stroke-width="0.8" opacity="0.55"/>'
    + '<path fill="currentColor" stroke="none" fill-rule="evenodd" '
    + 'd="M12 7.7a4.3 4.3 0 1 0 0 8.6a4.3 4.3 0 1 0 0-8.6zm0 3.15a1.15 1.15 '
    + '0 1 1 0 2.3a1.15 1.15 0 1 1 0-2.3z"/>'),
  'Music Assistant': svg('<path d="M68.371 2.73837C72.0263 -0.912791 77.9927 -0.912791 81.629 2.73837L143.371 64.5432C147.026 68.1943 150 75.4021 150 80.5667V136.886L149.997 137.108C149.868 142.162 145.696 146.25 140.625 146.25H9.375C4.22349 146.25 1.50296e-05 142.012 0 136.867V80.5478C7.52069e-05 75.3832 2.99271 68.1754 6.62903 64.5243L68.371 2.73837ZM22.5 75.0003C19.7386 75.0003 17.5 77.2389 17.5 80.0003V128.75H27.5V80.0003C27.5 77.2389 25.2614 75.0003 22.5 75.0003ZM42.5 75.0003C39.7386 75.0003 37.5 77.2389 37.5 80.0003V128.75H47.5V80.0003C47.5 77.2389 45.2614 75.0003 42.5 75.0003ZM62.5 75.0003C59.7386 75.0003 57.5 77.2389 57.5 80.0003V128.75H67.5V80.0003C67.5 77.2389 65.2614 75.0003 62.5 75.0003ZM98.9954 75.2671C96.3753 74.395 93.5442 75.8122 92.6721 78.4323L75.9241 128.75H86.4636L102.16 81.5903C103.032 78.9703 101.615 76.1393 98.9954 75.2671ZM117.943 78.4323C117.07 75.8123 114.239 74.3951 111.619 75.2671C108.999 76.1392 107.582 78.9702 108.454 81.5903L124.151 128.75H134.69L117.943 78.4323Z"/>', 'fill="currentColor"', '-11 -13 172 172'),
  'Sonos': svg('<rect x="6" y="2" width="12" height="20" rx="2"/>'
    + '<circle cx="12" cy="14" r="3.5"/><circle cx="12" cy="7" r="1"/>'),
  'Floating Player': svg('<rect x="3" y="5" width="18" height="14" rx="2"/>'
    + '<rect x="12" y="11" width="7" height="5" rx="1"/>'),
  'Now Playing': svg('<path d="M8 3H5a2 2 0 0 0-2 2v3"/><path d="M21 8V5a2 2 0 0 0-2-2h-3"/>'
    + '<path d="M3 16v3a2 2 0 0 0 2 2h3"/><path d="M16 21h3a2 2 0 0 0 2-2v-3"/>'),
  'Lyrics': svg('<path d="M4 4h16a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1h-9l-5 4v-4H4a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1z"/>'
    + '<path d="M9 8h6"/><path d="M9 11.5h4"/>'),
  // ESPHome.
  'Notifications': svg('<path d="M6 16V11a6 6 0 1 1 12 0v5l1.5 2h-15z"/>'
    + '<path d="M10 20a2 2 0 0 0 4 0"/>'),
  'Bluetooth Proxy': svg('<path d="m6.5 7 11 10-5.5 5V2l5.5 5-11 10"/>'),
  'GPS Sensor': svg('<path d="M12 21s-6.5-6.2-6.5-11a6.5 6.5 0 0 1 13 0c0 4.8-6.5 11-6.5 11z"/>'
    + '<circle cx="12" cy="10" r="2.5"/>'),
  'Advanced settings': svg('<path d="M4 7h10m4 0h2M4 12h2m4 0h10M4 17h8m4 0h4"/>'
    + '<circle cx="16" cy="7" r="2"/><circle cx="8" cy="12" r="2"/>'
    + '<circle cx="14" cy="17" r="2"/>'),
  // Kiosk.
  'Allowed Actions': svg('<path d="m3 6 1.5 1.5L7.5 4.5M3 12l1.5 1.5 3-3'
    + 'M3 18l1.5 1.5 3-3"/><path d="M11 6h10M11 12h10M11 18h10"/>'),
  // Device.
  'Kiosk Satellite Service': svg('<path d="M13 2 4 14h7l-1 8 9-12h-7z"/>'),
  'Remote Administration': svg('<rect x="3" y="4" width="18" height="12" rx="2"/>'
    + '<path d="M8 20h8m-4-4v4"/>'),
  // The read-only reports the remote shows about the tablet; the device
  // has no page for them, so only this side names a glyph.
  'Hardware': svg('<rect x="5" y="5" width="14" height="14" rx="2"/>'
    + '<rect x="9" y="9" width="6" height="6" rx="1"/>'
    + '<path d="M9 2v3m6-3v3M9 19v3m6-3v3M2 9h3m-3 6h3m14-6h3m-3 6h3"/>'),
  // The Home Assistant mark, the same rendition as the nav rail's.
  'Home Assistant': svg('<path d="M21.8,13H20V21H13V17.67L15.79,14.88L16.5,15C17.66,15 18.6,14.06 18.6,12.9C18.6,11.74 17.66,10.8 16.5,10.8A2.1,2.1 0 0,0 14.4,12.9L14.5,13.61L13,15.13V9.65C13.66,9.29 14.1,8.6 14.1,7.8A2.1,2.1 0 0,0 12,5.7A2.1,2.1 0 0,0 9.9,7.8C9.9,8.6 10.34,9.29 11,9.65V15.13L9.5,13.61L9.6,12.9A2.1,2.1 0 0,0 7.5,10.8A2.1,2.1 0 0,0 5.4,12.9A2.1,2.1 0 0,0 7.5,15L8.21,14.88L11,17.67V21H4V13H2.25C1.83,13 1.42,13 1.42,12.79C1.43,12.57 1.85,12.15 2.28,11.72L11,3C11.33,2.67 11.67,2.33 12,2.33C12.33,2.33 12.67,2.67 13,3L17,7V6H19V9L21.78,11.78C22.18,12.18 22.59,12.59 22.6,12.8C22.6,13 22.2,13 21.8,13M7.5,12A0.9,0.9 0 0,1 8.4,12.9A0.9,0.9 0 0,1 7.5,13.8A0.9,0.9 0 0,1 6.6,12.9A0.9,0.9 0 0,1 7.5,12M16.5,12C17,12 17.4,12.4 17.4,12.9C17.4,13.4 17,13.8 16.5,13.8A0.9,0.9 0 0,1 15.6,12.9A0.9,0.9 0 0,1 16.5,12M12,6.9C12.5,6.9 12.9,7.3 12.9,7.8C12.9,8.3 12.5,8.7 12,8.7C11.5,8.7 11.1,8.3 11.1,7.8C11.1,7.3 11.5,6.9 12,6.9Z"/>',
    'fill="currentColor"', '1.31 0.97 21.4 21.4'),
  'WebView': svg('<rect x="3" y="4" width="18" height="16" rx="2"/>'
    + '<path d="M3 9h18M7 6.5h.01M10 6.5h.01"/>'),
};

// A neutral glyph for a page the map has not met, so a new page still draws
// a row rather than a hole.
const FALLBACK = svg('<path d="M6 3h9l4 4v14H6z"/><path d="M14 3v5h5M9 12h6M9 16h6"/>');

// The glyph as an element, ready to drop ahead of a row's name or into the
// page title. A fresh node each call: the same page draws it twice.
export function subpageIcon(sub) {
  const span = document.createElement('span');
  span.className = 'page-icon';
  span.innerHTML = SUBPAGE_ICONS[sub] || FALLBACK;
  return span;
}
