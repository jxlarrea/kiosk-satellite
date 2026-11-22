"""Ground Control page: Version, Architecture and Runs on under the Ground Control app row."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
from threading import Thread
from playwright.sync_api import sync_playwright, expect

APP = Path(__file__).resolve().parents[1]
ROOT = APP / 'remote-ui'
english = {k:v for p in (APP/'l10n/source').glob('*_en.arb') for k,v in json.loads(p.read_text()).items() if not k.startswith('@')}
spanish = {k:v for k,v in json.loads((APP/'l10n/effective/ui_es.arb').read_text()).items() if not k.startswith('@')}
language = dict(key='ui.language',value='en',type='string',category='Device',hidden=True)
settings = [language,
            dict(key='ground_control.enabled',value=True,type='boolean',category='Ground Control',
                 title='Enable Ground Control',description='')]
status = {}
def api(route):
    path = route.request.url.split('/api/',1)[1]
    if path == 'settings':
        return route.fulfill(json={'settings':settings,'subpageHints':{}})
    if path == 'commands/groundControlStatus':
        return route.fulfill(json={'ok':True,'data':status})
    route.fulfill(json={'ok':True,'data':{}})
class Handler(SimpleHTTPRequestHandler):
    def log_message(self,*_): pass
server = ThreadingHTTPServer(('127.0.0.1',0),partial(Handler,directory=str(ROOT)))
Thread(target=server.serve_forever,daemon=True).start(); base = f'http://127.0.0.1:{server.server_port}'
connected = dict(enabled=True,status='connected',baseUrl='http://192.168.1.10:10900',version='2026.11.10',
                 people=[{'id':'a','name':'Ana'}],appUrl='http://192.168.1.10:10900/',haApp=False,
                 install=dict(install='docker',arch='amd64',cuda='12.9',onGpu=True))
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True,args=['--no-sandbox']); page = browser.new_page()
        errors = []; page.on('pageerror',lambda e: errors.append(str(e)))
        html = (ROOT/'index.html').read_text().replace('<script type="module" src="static/main.js?v=__KSV__"></script>','')
        page.route(base+'/',lambda route: route.fulfill(body=html,content_type='text/html'))
        page.route('**/static/catalogs.js',lambda route: route.fulfill(body='export const catalogs = '+json.dumps({'en':english,'es':spanish})+';',content_type='text/javascript'))
        page.route('**/api/**',api)
        draw = """async()=>{
          await (await import('/static/settings.js')).loadSettings();
          const {state} = await import('/static/core.js');
          document.getElementById('card')?.remove();
          const card = document.createElement('div'); card.id = 'card'; document.body.appendChild(card);
          card.appendChild((await import('/static/rows.js')).settingRow(state.settings.find((o) => o.key === 'ground_control.enabled')));
          (await import('/static/ground_control.js')).renderGroundControl(card);
        }"""
        def rows(state):
            status.clear(); status.update(state)
            page.goto(base+'/'); page.evaluate(draw)
            expect(page.locator('#card .gc-status').first).to_be_visible()
            page.wait_for_timeout(200)
            found = page.locator('#card .gc-status')
            return [(found.nth(i).locator('.name').inner_text(), found.nth(i).locator(':scope > span').last.inner_text())
                    for i in range(found.count())]
        # Connected, speaker model on the GPU: after the app row, in order.
        assert rows(connected)[2:] == [('Version','2026.11.10'),('Architecture','amd64'),('Runs on','CUDA')], rows(connected)
        assert rows(connected)[1][0] == 'Ground Control app'
        # The CUDA image without a usable GPU.
        cpu = {**connected,'install':dict(install='docker',arch='aarch64',cuda='12.9',onGpu=False)}
        assert rows(cpu)[2:] == [('Version','2026.11.10'),('Architecture','aarch64'),('Runs on','CPU')], rows(cpu)
        # An older Ground Control only gives its version.
        assert rows({**connected,'install':{}})[2:] == [('Version','2026.11.10')]
        # Away: the status row alone.
        away = dict(enabled=True,status='unreachable',baseUrl='http://192.168.1.10:10900',version='2026.11.10',
                    people=[],appUrl=None,install=connected['install'])
        assert [name for name,_ in rows(away)] == ['Ground Control'], rows(away)
        # The labels follow the language, the values don't.
        language['value'] = 'es'
        assert rows(connected)[2:] == [(spanish['deviceVersion'],'2026.11.10'),('Arquitectura','amd64'),('Se ejecuta en','CUDA')], rows(connected)
        assert not errors, errors
        browser.close()
finally: server.shutdown()
print('Ground Control rows passed.')
