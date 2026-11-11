"""Check that the rotation's views and external pages reorder by the arrows, a mouse drag and a finger on the handle."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import sys
from threading import Thread
from playwright.sync_api import sync_playwright, expect

APP = Path(__file__).resolve().parents[1]
ROOT = APP / 'remote-ui'
english = {k: v for p in (APP / 'l10n/source').glob('*_en.arb')
           for k, v in json.loads(p.read_text()).items() if not k.startswith('@')}
settings = []
def setting(key, value, kind='boolean', subpage=None, **extra):
    settings.append(dict(key=key, value=value, type=kind, category='Home Assistant',
                         title=key, description='', **({'subpage': subpage} if subpage else {}), **extra))
setting('ui.language', 'en', 'select')
setting('ha.url', 'http://ha.example', 'string')
setting('browser.start_url', 'http://ha.example/wall/clock', 'string', hidden=True)
setting('ha.rotation_enabled', True, subpage='Dashboard View Rotation')
setting('ha.rotation_dashboards', '["wall/clock","wall/weather","wall/laundry"]', 'string', hidden=True)
setting('ha.rotation_urls', '["https://a.example","https://b.example","https://c.example"]', 'string', hidden=True)
saved = []

def api(route):
    path = route.request.url.split('/api/', 1)[1]
    if path == 'settings':
        if route.request.method == 'PATCH':
            values = route.request.post_data_json
            saved.append(values)
            for item in settings:
                if item['key'] in values: item['value'] = values[item['key']]
            return route.fulfill(json={'ok': True})
        return route.fulfill(json={'settings': settings, 'subpageHints': {}})
    name = path.removeprefix('commands/')
    args = route.request.post_data_json or {}
    data = {'haStatus': {'connected': True},
            'getUpdateInstallerStatus': {'nativeSilent': True},
            'haListDashboards': [{'title': 'Wall', 'url_path': 'wall'}],
            'haListDashboardViews': ([{'title': 'Clock', 'route': 'clock'},
                                      {'title': 'Weather', 'route': 'weather'},
                                      {'title': 'Laundry', 'route': 'laundry'}]
                                     if args.get('url_path') == 'wall' else []),
            'listPlugins': [], 'listFiles': [], 'mediaPlayers': {'players': []},
            'getAudioDevices': {'inputs': [], 'outputs': []}}.get(name, {})
    route.fulfill(json={'ok': True, 'data': data})

class Handler(SimpleHTTPRequestHandler):
    def log_message(self, *_): pass
server = ThreadingHTTPServer(('127.0.0.1', 0), partial(Handler, directory=str(ROOT)))
Thread(target=server.serve_forever, daemon=True).start()
base = f'http://127.0.0.1:{server.server_port}'
shots = Path(sys.argv[1]) if len(sys.argv) > 1 else None
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, args=['--no-sandbox'])
        page = browser.new_page(viewport={'width': 1200, 'height': 1000})
        errors = []
        page.on('pageerror', lambda error: errors.append(str(error)))
        html = (ROOT / 'index.html').read_text().replace('<script type="module" src="static/main.js?v=__KSV__"></script>', '')
        page.route(base+'/', lambda route: route.fulfill(body=html, content_type='text/html'))
        page.route('**/static/catalogs.js', lambda route: route.fulfill(
            body='export const catalogs = '+json.dumps({'en': english})+';', content_type='text/javascript'))
        page.route('**/api/**', api)
        page.goto(base+'/')
        page.evaluate("""async () => {
          (await import('/static/core.js')).showView('app');
          await (await import('/static/settings.js')).loadSettings();
          (await import('/static/tabs.js')).showTab('homeassistant/Dashboard View Rotation', {refresh:false});
        }""")
        panel = page.locator('#tab-homeassistant [data-subpage="Dashboard View Rotation"]')
        views = panel.locator('.dp-pick-row')
        pages = panel.locator('.rotation-url-row')
        titles = lambda: [t.strip() for t in views.locator('.dp-title').all_inner_texts()]
        addresses = lambda: [t.strip() for t in pages.locator('.name').all_inner_texts()]
        def last(key): return json.loads(saved[-1][key])
        expect(views).to_have_count(3)
        expect(views.first).to_contain_text('Clock')
        if shots: page.screenshot(path=str(shots / 'rotation-order-desktop.png'), full_page=True)

        # The first row cannot move up, the last cannot move down.
        expect(views.nth(0).get_by_role('button', name='Move up')).to_be_disabled()
        expect(views.nth(2).get_by_role('button', name='Move down')).to_be_disabled()
        expect(views.nth(0).locator('.order-handle')).to_be_visible()

        with page.expect_response('**/api/settings'):
            views.nth(0).get_by_role('button', name='Move down').click()
        assert last('ha.rotation_dashboards') == ['wall/weather', 'wall/clock', 'wall/laundry']
        assert titles() == ['Weather', 'Clock', 'Laundry'], titles()

        # A row dragged with the mouse past the middle of another takes its
        # place, from any part of the row.
        def above(row): return {'x': 200, 'y': row.bounding_box()['height'] * 0.25}
        def below(row): return {'x': 200, 'y': row.bounding_box()['height'] * 0.75}
        with page.expect_response('**/api/settings'):
            views.nth(2).drag_to(views.nth(0), target_position=above(views.nth(0)))
        assert last('ha.rotation_dashboards') == ['wall/laundry', 'wall/weather', 'wall/clock']
        assert titles() == ['Laundry', 'Weather', 'Clock'], titles()

        with page.expect_response('**/api/settings'):
            pages.nth(2).get_by_role('button', name='Move up').click()
        assert last('ha.rotation_urls') == ['https://a.example', 'https://c.example', 'https://b.example']
        with page.expect_response('**/api/settings'):
            pages.nth(0).drag_to(pages.nth(2), target_position=below(pages.nth(2)))
        assert last('ha.rotation_urls') == ['https://c.example', 'https://b.example', 'https://a.example']
        assert addresses() == ['https://c.example', 'https://b.example', 'https://a.example'], addresses()

        # A view dragged down over the pages stays in its own list, last.
        with page.expect_response('**/api/settings'):
            views.nth(0).drag_to(pages.nth(1))
        assert last('ha.rotation_dashboards') == ['wall/weather', 'wall/clock', 'wall/laundry']
        assert 'ha.rotation_urls' not in saved[-1]

        # A press that does not move, and a click on a button, are not drags.
        count = len(saved)
        views.nth(1).click(position={'x': 200, 'y': 10})
        page.wait_for_timeout(200)
        assert len(saved) == count, saved[count:]
        assert not page.locator('.order-row.dragging').count()

        # A finger: on a phone, a real touch on the handle drags the row
        # and a touch on the rest of the row scrolls the page.
        phone = browser.new_context(viewport={'width': 390, 'height': 520}, has_touch=True, is_mobile=True)
        touch = phone.new_page()
        touch.on('pageerror', lambda error: errors.append(str(error)))
        touch.route(base+'/', lambda route: route.fulfill(body=html, content_type='text/html'))
        touch.route('**/static/catalogs.js', lambda route: route.fulfill(
            body='export const catalogs = '+json.dumps({'en': english})+';', content_type='text/javascript'))
        touch.route('**/api/**', api)
        touch.goto(base+'/')
        touch.evaluate("""async () => {
          (await import('/static/core.js')).showView('app');
          await (await import('/static/settings.js')).loadSettings();
          (await import('/static/tabs.js')).showTab('homeassistant/Dashboard View Rotation', {refresh:false});
        }""")
        tpanel = touch.locator('#tab-homeassistant [data-subpage="Dashboard View Rotation"]')
        tviews = tpanel.locator('.dp-pick-row')
        expect(tviews).to_have_count(3)
        # A phone has no room for the arrows: the handle and remove stay.
        expect(tviews.nth(0).locator('.order-handle')).to_be_visible()
        expect(tviews.nth(0).get_by_role('button', name='Remove')).to_be_visible()
        expect(tpanel.locator('.order-arrow').first).to_be_hidden()
        if shots: touch.screenshot(path=str(shots / 'rotation-order-phone.png'), full_page=True)
        # Mid-screen, clear of the edges where a held row scrolls the list.
        tviews.nth(0).evaluate("row => row.scrollIntoView({block: 'center'})")
        touch.wait_for_timeout(200)
        cdp = phone.new_cdp_session(touch)
        def swipe(x, y, dy, steps=8):
            cdp.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': [{'x': x, 'y': y}]})
            for step in range(1, steps + 1):
                cdp.send('Input.dispatchTouchEvent', {'type': 'touchMove',
                         'touchPoints': [{'x': x, 'y': y + dy * step / steps}]})
                touch.wait_for_timeout(30)
            if shots and dy > 0 and x < 80: touch.screenshot(path=str(shots / 'rotation-order-touch-drag.png'))
            cdp.send('Input.dispatchTouchEvent', {'type': 'touchEnd', 'touchPoints': []})
            touch.wait_for_timeout(300)
        scroll_top = "(() => { for (let p = document.querySelector('.dp-pick-row'); p; p = p.parentElement) if (p.scrollTop) return p.scrollTop; return 0; })()"
        def center(locator):
            box = locator.bounding_box()
            return box['x'] + box['width'] / 2, box['y'] + box['height'] / 2
        height = tviews.nth(0).bounding_box()['height']
        # By the handle: the first view goes one row down, the page stays.
        count = len(saved)
        before_scroll = touch.evaluate(scroll_top)
        x, y = center(tviews.nth(0).locator('.order-handle'))
        swipe(x, y, height * 1.1)
        assert len(saved) == count + 1, saved[count:]
        assert last('ha.rotation_dashboards') == ['wall/clock', 'wall/weather', 'wall/laundry']
        assert touch.evaluate(scroll_top) == before_scroll, 'the page scrolled under a handle drag'
        # By the title: nothing reorders and the page scrolls.
        count = len(saved)
        x, y = center(tviews.nth(2).locator('.dp-text'))
        swipe(x, y, -height * 2)
        assert len(saved) == count, saved[count:]
        assert touch.evaluate(scroll_top) > before_scroll, 'a touch on the row did not scroll the page'
        phone.close()

        # A lone row has nothing to reorder against: only its remove button.
        for _ in range(2):
            with page.expect_response('**/api/settings'):
                pages.nth(0).get_by_role('button', name='Remove').click()
        assert last('ha.rotation_urls') == ['https://a.example']
        expect(pages).to_have_count(1)
        expect(pages.locator('.order-handle')).to_have_count(0)
        expect(pages.get_by_role('button', name='Move up')).to_have_count(0)
        expect(pages.get_by_role('button', name='Remove')).to_have_count(1)

        assert not errors, errors
        browser.close()
finally:
    server.shutdown()
print('ok')
