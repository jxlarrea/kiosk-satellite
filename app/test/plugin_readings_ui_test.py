"""Exercise live readings in the real Remote Admin UI with local fixtures."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread
from playwright.sync_api import sync_playwright, expect

ROOT = Path(__file__).resolve().parents[1] / 'assets/remote-ui'
class Handler(SimpleHTTPRequestHandler):
    def log_message(self, *_): pass
server = ThreadingHTTPServer(('127.0.0.1', 0), partial(Handler, directory=str(ROOT)))
Thread(target=server.serve_forever, daemon=True).start()
base = f'http://127.0.0.1:{server.server_port}'
plugin = dict(id='hello-world', name='Hello World', version='1.0.1', enabled=True, running=True,
              description='A floating greeting over the Home Assistant dashboard. Use this plugin as a starting point for your own.',
              status='Readings use simulated demo data.\nThis is a multiline status.', commands=[], values={'message': 'Hello'},
              settings=[dict(key='message', title='Greeting', type='string', default='Hello')])
readings = [
    dict(type='sensor', key='wave', name='Simulated wave', unit='%', accuracyDecimals=2, state=12.5),
    dict(type='text_sensor', key='status', name='Demo status', state='Chart running'),
    dict(type='binary_sensor', key='active', name='Demo chart active', state=False),
    dict(type='switch', key='chart', name='Demo chart', state=True),
    dict(type='select', key='pattern', name='Demo pattern', state='Triangle'),
    dict(type='sensor', key='samples', name='Samples in history', accuracyDecimals=0, state=40),
    dict(type='text_sensor', key='summary', name='Sample details', state='Pattern: Triangle\nHistory: up to 120 samples\nInterval: 2 seconds'),
]
polls = 0
writes = 0
permission_requests = 0
shizuku_polls = 0
shizuku_state = dict(status='permission_required', available=True, granted=False)

def api(route):
    global polls, writes, permission_requests, shizuku_polls
    name = route.request.url.rsplit('/', 1)[-1]
    if name == 'getPluginState': data = dict(enabled=True, plugins=[plugin])
    elif name == 'getPluginReadings':
        polls += 1; assert route.request.post_data_json == dict(id='hello-world'); data = readings
    elif name == 'getPluginShizukuState': shizuku_polls += 1; data = shizuku_state
    elif name == 'requestPluginShizukuPermission': permission_requests += 1; data = shizuku_state
    elif name == 'configurePlugin': writes += 1; data = [plugin]
    else: data = []
    route.fulfill(json=dict(ok=True, data=data))

try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, args=['--no-sandbox'])
        page = browser.new_page(viewport=dict(width=1100, height=1200))
        errors = []
        page.on('pageerror', lambda error: errors.append(str(error)))
        html = (ROOT / 'index.html').read_text().replace('<script type="module" src="static/main.js?v=__KSV__"></script>', '')
        page.route(base+'/', lambda route: route.fulfill(body=html, content_type='text/html'))
        page.route('**/api/commands/*', api)
        page.goto(base+'/')
        page.evaluate("""async () => {
          (await import('/static/core.js')).showView('app');
          await (await import('/static/plugins.js')).loadPlugins();
          (await import('/static/tabs.js')).showTab('plugins/hello-world', {refresh:false});
        }""")
        root = page.locator('#tab-plugins')
        panel = root.locator('.plugin-readings')
        expect(panel.locator('dd').first).to_have_text('12.50 %')
        expect(panel.locator('dd').nth(2)).to_have_text('Off')
        expect(panel.locator('dd').nth(3)).to_have_text('On')
        expect(panel.locator('dd').last).to_have_text(readings[-1]['state'])
        assert root.locator('.plugin-runtime-status').evaluate("el => getComputedStyle(el).whiteSpace") == 'pre-line'
        expect(panel.locator('input, select, button')).to_have_count(0)
        field = root.get_by_role('textbox', name='Greeting')
        field.fill('Draft while readings update')
        readings[0]['state'] = 67.891
        expect(panel.locator('dd').first).to_have_text('67.89 %')
        expect(field).to_have_value('Draft while readings update'); expect(field).to_be_focused()
        assert writes == 0
        for width, theme in [(1100, 'light'), (390, 'dark')]:
            page.set_viewport_size(dict(width=width, height=1200))
            page.evaluate('(theme) => document.documentElement.dataset.theme = theme', theme)
            page.wait_for_timeout(400)
            page.evaluate('window.scrollTo(0,0)')
            assert page.evaluate('document.documentElement.scrollWidth <= innerWidth')
            page.screenshot(path=f'/tmp/kiosk-plugin-readings-{theme}.png', full_page=True)
        readings[0]['state'] = None
        readings[1]['state'] = ''
        expect(panel.locator('dd').first).to_have_text('No data')
        expect(panel.locator('dd').nth(1)).to_have_text('Empty')
        readings[0]['state'] = 0
        readings[1]['state'] = '<img src=x onerror=alert(1)>\n' + 'x' * 480
        expect(panel.locator('dd').first).to_have_text('0.00 %')
        expect(panel.locator('dd').nth(1)).to_have_text(readings[1]['state'])
        expect(panel.locator('img')).to_have_count(0)
        page.set_viewport_size(dict(width=320, height=1000))
        assert page.evaluate('document.documentElement.scrollWidth <= innerWidth')
        for row in panel.locator('.plugin-reading').all():
            assert row.evaluate('el => el.scrollWidth <= el.clientWidth')
        readings.pop(2)
        expect(panel.locator('dd')).to_have_count(6)
        readings = []
        expect(panel).to_be_hidden()
        readings = [dict(type='sensor', key='new', name='New reading', state=1e12, accuracyDecimals=2)]
        expect(panel.locator('dd')).to_have_text('1.00e+12')
        page.evaluate("async () => (await import('/static/tabs.js')).showTab('plugins', {refresh:false})")
        baseline = polls; page.wait_for_timeout(1200); assert polls == baseline
        assert shizuku_polls == 0 and permission_requests == 0
        plugin['capabilities'] = ['shizuku']
        page.evaluate("async () => { await (await import('/static/plugins.js')).loadPlugins(); (await import('/static/tabs.js')).showTab('plugins/hello-world', {refresh:false}); }")
        access = root.locator('.plugin-shizuku')
        expect(access.get_by_role('button', name='Grant access')).to_be_visible()
        assert permission_requests == 0
        access.get_by_role('button', name='Grant access').click()
        page.wait_for_function("document.querySelector('#tab-plugins').getAttribute('aria-busy') !== 'true'")
        assert permission_requests == 1
        shizuku_state = dict(status='ready', available=True, granted=True, uid=2000)
        expect(access.get_by_text('Connected with shell access')).to_be_visible()
        expect(access.locator('button')).to_be_hidden()
        shizuku_state = dict(status='unavailable', available=False, granted=False)
        expect(access.get_by_text('Start Shizuku on this device.')).to_be_visible()
        expect(access.get_by_role('button', name='Set up')).to_be_visible()
        assert permission_requests == 1
        assert not errors, errors
        browser.close()
        print('PASS: live readings, precision, missing states, removal, multiline text, safe rendering, narrow layouts, settings focus and scoped polling.')
finally:
    server.shutdown(); server.server_close()
