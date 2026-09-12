"""Search custom settings in the real Remote Admin shell without contacting a device."""
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
plugin = dict(capabilities=['shizuku'], id='hello', name='Hello World', description='A sample plugin', version='1.0.0', enabled=True,
              settings=[dict(key='greeting', title='Greeting', description='Text shown in the floating window.', type='string', default='Hello')],
              commands=[dict(id='show', title='Show greeting')], values={})
plugins = [plugin]
enabled = True
calls = []
def api(route):
    name = route.request.url.rsplit('/', 1)[-1]
    calls.append(name)
    data = dict(enabled=enabled, plugins=plugins) if name == 'getPluginState' else dict(status='ready', granted=True, uid=2000) if name == 'getShizukuState' else {}
    route.fulfill(json=dict(ok=True, data=data))
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, args=['--no-sandbox'])
        page = browser.new_page(viewport=dict(width=1200, height=1000))
        errors = []
        page.on('pageerror', lambda error: errors.append(str(error)))
        html = (ROOT / 'index.html').read_text().replace('<script type="module" src="static/main.js?v=__KSV__"></script>', '')
        page.route(base+'/', lambda route: route.fulfill(body=html, content_type='text/html'))
        page.route('**/api/commands/*', api)
        page.route('**/api/settings', lambda route: route.fulfill(json=dict(settings=[])))
        page.goto(base+'/')
        page.evaluate("""async () => {
          const core = await import('/static/core.js'); core.showView('app');
          core.state.settings = [{key:'shizuku.install_updates', type:'boolean', value:false, category:'Device', subpage:'Shizuku', title:'Install updates through Shizuku', description:'Install Kiosk Satellite updates without on-device confirmation. Shizuku must be running and authorized.'}];
          const panel = document.createElement('div'); panel.className='subpage'; panel.dataset.subpage='Shizuku';
          document.querySelector('#tab-device').append(panel);
          (await import('/static/shizuku.js')).renderShizukuPage(panel);
          (await import('/static/tabs.js')).showTab('device/Shizuku', {refresh:false});
          const search = await import('/static/search.js');
          // A malformed custom entry previously crashed every query.
          search.SEARCH_EXTRAS.push({tab:'device', title:'Missing description'}, {tab:'device', desc:'Missing title'});
        }""")
        field = page.locator('#settingsSearch')
        results = page.locator('#tab-search')
        field.fill('Plugin')
        for title in ['Enable Plugins', 'Add plugin', 'Create a plugin', 'Hello World']:
            expect(results.get_by_text(title, exact=True).first).to_be_visible()
        assert 'runShizukuAction' not in calls
        field.fill('Shizuku')
        for title in ['Shizuku access', 'Set up Shizuku', 'Install updates through Shizuku']:
            expect(results.get_by_text(title, exact=True).first).to_be_visible()
        expect(results.get_by_text('Test connection', exact=True)).to_have_count(0)
        field.fill('Missing description')
        expect(results.get_by_text('Missing description', exact=True)).to_be_visible()
        field.fill('Test connection')
        results.get_by_text('Test connection', exact=True).click()
        expect(page.locator('[data-search-id="x:shizuku:identity"]')).to_have_class('row shizuku-action search-hit')
        assert page.url.endswith('#device/Shizuku')
        field.fill('Nearby devices')
        results.get_by_text('Nearby devices', exact=True).last.click()
        expect(page.locator('[data-search-id="x:shizuku:bluetooth"]')).to_have_class('row shizuku-action search-hit')
        field.fill('floating window')
        results.get_by_text('Greeting', exact=True).click()
        target = page.locator('[data-search-id="plugin:hello:setting:greeting"]')
        expect(target).to_be_visible()
        expect(target).to_have_class('row search-hit')
        assert page.url.endswith('#plugins/hello')
        field.fill('Shizuku access')
        results.get_by_text('Shizuku access', exact=True).last.click()
        expect(page.locator('[data-search-id="plugin:hello:shizuku"]')).to_have_class('row search-hit')
        field.fill('Hello World')
        expect(results.get_by_text('Greeting', exact=True)).to_have_count(0)
        field.fill('Show greeting')
        results.get_by_text('Show greeting', exact=True).click()
        expect(page.locator('[data-search-id="plugin:hello:action:show"]')).to_have_class('row search-hit')
        enabled = False
        field.fill('Install from ZIP')
        results.get_by_text('Install from ZIP', exact=True).click()
        expect(page.locator('[data-search-id="x:plugins:master"]')).to_have_class('row search-hit')
        assert page.url.endswith('#plugins')
        enabled = True
        plugins = []
        field.fill('')
        field.fill('floating window')
        expect(results.get_by_text('Greeting', exact=True)).to_have_count(0)
        assert all(name.startswith('get') or name in ['isScreenOn', 'evalJs'] for name in calls), calls
        assert errors == [], errors
        browser.close()
        print('Remote search: missing fields, row text, plugin manifests, target navigation, master gating and read-only searches passed')
finally:
    server.shutdown()
