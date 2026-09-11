"""Exercise Device Shizuku controls in the real Remote Admin shell."""
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
state = dict(status='unavailable', available=False, granted=False)
requests = []
polls = 0

def api(route):
    global polls
    name = route.request.url.rsplit('/', 1)[-1]
    if name == 'getShizukuState':
        polls += 1
        data = state
    elif name == 'requestShizukuPermission':
        requests.append((name, route.request.post_data_json))
        data = state
    elif name == 'runShizukuAction':
        args = route.request.post_data_json
        requests.append((name, args))
        data = dict(exitCode=0, stdout='uid=2000(shell)', timedOut=False) if args['action'] == 'identity' else dict(results=[dict(key='writeSettings', ok=False, error='Android rejected the request')])
    else: data = {}
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
          const panel = document.createElement('div');
          panel.className = 'subpage'; panel.dataset.subpage = 'Shizuku';
          document.querySelector('#tab-device').append(panel);
          (await import('/static/shizuku.js')).renderShizukuPage(panel);
          (await import('/static/tabs.js')).showTab('device/Shizuku', {refresh:false});
        }""")
        root = page.locator('#tab-device [data-subpage="Shizuku"]')
        expect(root.locator('[data-connection] .desc')).to_have_text('Start Shizuku on this device.')
        expect(root.get_by_role('button', name='Test', exact=True)).to_be_disabled()
        assert requests == []
        expect(root.locator('[data-shizuku-action]')).to_have_count(15)
        expect(root.get_by_text('Grant all permissions', exact=True)).to_be_visible()
        for name in ['Microphone', 'Camera', 'Nearby devices', 'Notifications', 'System UI guard', 'Device admin', 'Location']:
            expect(root.get_by_text(name, exact=True)).to_have_count(1)
        state = dict(status='permission_required', available=True, granted=False)
        grant = root.locator('[data-shizuku-action="permission"]')
        expect(grant).to_be_enabled()
        grant.click()
        expect(root.locator('[data-connection] .desc')).to_contain_text('Grant access')
        assert requests == [('requestShizukuPermission', {})]
        state = dict(status='ready', available=True, granted=True, uid=2000)
        expect(root.locator('[data-connection] .desc')).to_have_text('Connected with shell access')
        expect(grant).to_be_hidden()
        root.get_by_role('button', name='Test', exact=True).click()
        expect(page.get_by_text('Shizuku successfully ran a command with shell access.', exact=True)).to_be_visible()
        page.get_by_role('button', name='OK', exact=True).click()
        root.locator('[data-shizuku-action="writeSettings"]').click()
        expect(page.get_by_text('Modify system settings: Android rejected the request', exact=True)).to_be_visible()
        page.get_by_role('button', name='OK', exact=True).click()
        assert requests[-1] == ('runShizukuAction', {'action':'writeSettings'})
        for width, theme in [(1100, 'light'), (390, 'dark')]:
            page.set_viewport_size(dict(width=width, height=1300))
            page.evaluate('(theme) => document.documentElement.dataset.theme = theme', theme)
            page.evaluate("document.querySelector('#sidebar').classList.remove('open')")
            page.wait_for_timeout(300)
            assert root.locator('[data-shizuku-action=identity]').evaluate("el => getComputedStyle(el).borderRadius") != '0px'
            assert page.evaluate('document.documentElement.scrollWidth <= innerWidth')
            page.screenshot(path=f'/tmp/kiosk-shizuku-device-{theme}.png', full_page=True)
        state = dict(status='unavailable', available=False, granted=False)
        expect(root.get_by_role('button', name='Test', exact=True)).to_be_disabled()
        page.evaluate("async () => (await import('/static/tabs.js')).showTab('device', {refresh:false})")
        page.wait_for_timeout(300)
        before = polls
        page.wait_for_timeout(1700)
        assert polls == before
        assert errors == [], errors
        browser.close()
        print('Shizuku Device UI: connection, explicit actions, failures, layouts and polling passed')
finally:
    server.shutdown()
