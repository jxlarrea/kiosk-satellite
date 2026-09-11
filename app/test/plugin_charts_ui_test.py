"""Verify live charts in the real Remote Admin UI using a local fixture only."""
import copy
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
              description='Chart demo', commands=[], values={'message': 'Hello'},
              settings=[dict(key='message', title='Greeting', type='string', default='Hello')])
chart = dict(key='demo', title='Simulated activity', unit='%', timestamps=[1000, 2000, 3000],
             series=[dict(name='Wave', color='#1976D2', values=[10, None, 30]), dict(name='Reference', values=[5, 5, 5])])
charts = [copy.deepcopy(chart)]
polls = 0
writes = 0

def api(route):
    global polls, writes
    name = route.request.url.rsplit('/', 1)[-1]
    if name == 'getPluginState': data = dict(enabled=True, plugins=[plugin])
    elif name == 'getPluginCharts': polls += 1; data = charts
    elif name == 'configurePlugin':
        writes += 1
        plugin['values'] = route.request.post_data_json['values']
        data = [plugin]
    else: data = []
    route.fulfill(json=dict(ok=True, data=data))

try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, args=['--no-sandbox'])
        page = browser.new_page(viewport=dict(width=1100, height=1000))
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
        plot = root.locator('.plugin-chart svg')
        expect(root.get_by_text('Wave: 30 %', exact=True)).to_be_visible()
        plot.focus(); plot.press('ArrowLeft')
        expect(root.get_by_text('Wave: No data', exact=True)).to_be_visible()
        plot.press('ArrowLeft')
        expect(root.get_by_text('Wave: 10 %', exact=True)).to_be_visible()
        chart['timestamps'].append(4000); chart['series'][0]['values'].append(40); chart['series'][1]['values'].append(5)
        charts = [copy.deepcopy(chart)]
        # The selected sample survives a live update.
        end_time = page.evaluate("new Date(4000).toLocaleString([], {month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:false})")
        expect(root.locator('.plugin-chart-dates span').last).to_have_text(end_time)
        expect(root.get_by_text('Wave: 10 %', exact=True)).to_be_visible()
        plot.press('End')
        expect(root.get_by_text('Wave: 40 %', exact=True)).to_be_visible()
        field = root.get_by_role('textbox', name='Greeting')
        field.fill('Unsaved draft')
        chart['timestamps'].append(5000); chart['series'][0]['values'].append(50); chart['series'][1]['values'].append(5)
        charts = [copy.deepcopy(chart)]
        expect(root.get_by_text('Wave: 50 %', exact=True)).to_be_visible()
        expect(field).to_have_value('Unsaved draft'); expect(field).to_be_focused()
        assert writes == 0
        field.press('Enter'); expect(field).to_have_value('Unsaved draft')
        page.wait_for_function("document.querySelector('#tab-plugins').getAttribute('aria-busy') !== 'true'")
        assert writes == 1
        for width, theme in [(1100, 'light'), (390, 'dark')]:
            page.set_viewport_size(dict(width=width, height=1000))
            page.wait_for_timeout(300)
            page.evaluate('(theme) => document.documentElement.dataset.theme = theme', theme)
            expect(plot).to_be_visible()
            assert page.evaluate('document.documentElement.scrollWidth <= innerWidth')
            bounds = root.locator('.plugin-chart').bounding_box()
            assert bounds['x'] + bounds['width'] <= width, bounds
            page.screenshot(path=f'/tmp/kiosk-plugin-charts-{theme}.png', full_page=True)
        chart['compact'] = True; charts = [copy.deepcopy(chart)]
        expect(root.locator('.plugin-chart')).to_have_class('card plugin-chart compact')
        assert plot.bounding_box()['height'] == 56
        expect(root.locator('.plugin-chart-dates')).to_be_hidden()
        plot.focus(); plot.press('ArrowLeft')
        expect(root.get_by_text('Wave: 40 %', exact=True)).to_be_visible()
        page.screenshot(path='/tmp/kiosk-plugin-charts-mini.png', full_page=True)
        charts = [dict(key='demo', title='<img src=x onerror=alert(1)>', timestamps=[1000], series=[dict(name='Only', values=[-5])])]
        expect(root.get_by_text('Only: -5', exact=True)).to_be_visible()
        expect(root.locator('.plugin-chart img')).to_have_count(0)
        charts = [dict(key='demo', title='Empty', timestamps=[], series=[dict(name='Only', values=[])])]
        expect(root.get_by_text('Waiting for samples', exact=True)).to_be_visible()
        charts = []
        expect(root.locator('.plugin-charts')).to_be_hidden()
        page.evaluate("async () => (await import('/static/tabs.js')).showTab('plugins', {refresh:false})")
        baseline = polls; page.wait_for_timeout(1200); assert polls == baseline
        assert not errors, errors
        browser.close()
        print('PASS: chart inspection, gaps, updates, settings focus, autosave, layouts, safe labels, removal and polling scope.')
finally:
    server.shutdown(); server.server_close()
