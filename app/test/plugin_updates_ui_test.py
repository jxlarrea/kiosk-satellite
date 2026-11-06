"""The Overview's plugin update rows and the remote Plugin Manager's new version note.

Run with Python 3 and Playwright's Chromium installed. No device is contacted.
"""
import json
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread

from playwright.sync_api import sync_playwright, expect

APP = Path(__file__).resolve().parents[1]
ROOT = APP / 'remote-ui'
english = {k: v for p in (APP / 'l10n/source').glob('*.arb')
           for k, v in json.loads(p.read_text()).items() if not k.startswith('@')}
commands = []
updates = [dict(id='hello-world', name='<b>Hello World</b>', version='1.2.0')]
plugin = dict(id='hello-world', name='<b>Hello World</b>', version='1.0.0', description='', capabilities=[],
              enabled=True, running=True, settings=[], source=dict(repository='https://github.com/example/hello'),
              updateVersion='1.2.0')
preview = dict(previewId='token', repository='https://github.com/example/hello', installedVersion='1.0.0',
               updateAvailable=True, releaseTag='v1.2.0', readme='# Hello', readmeBaseUrl='https://example.com/',
               sha256='0' * 64, listed=True, compatible=True,
               manifest=dict(id='hello-world', name='Hello World', version='1.2.0', capabilities=[]))


def api(route):
    name = route.request.url.split('/api/', 1)[1].removeprefix('commands/')
    commands.append(name)
    data = {'getPluginUpdates': updates, 'getPluginState': dict(enabled=True, plugins=[plugin]),
            'checkPluginUpdate': preview, 'installPluginRepository': []}.get(name, {})
    if name == 'installPluginRepository':
        updates.clear()
    route.fulfill(json=dict(ok=True, data=data))


class Handler(SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass


server = ThreadingHTTPServer(('127.0.0.1', 0), partial(Handler, directory=str(ROOT)))
Thread(target=server.serve_forever, daemon=True).start()
base = f'http://127.0.0.1:{server.server_port}'
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, args=['--no-sandbox'])
        page = browser.new_page(viewport=dict(width=1200, height=1000))
        errors = []
        page.on('pageerror', lambda e: errors.append(str(e)))
        html = (ROOT / 'index.html').read_text().replace('<script type="module" src="static/main.js?v=__KSV__"></script>', '')
        page.route(base + '/', lambda r: r.fulfill(body=html, content_type='text/html'))
        page.route('**/static/catalogs.js', lambda r: r.fulfill(
            body='export const catalogs = ' + json.dumps({'en': english}) + ';', content_type='text/javascript'))
        page.route('**/api/**', api)
        page.goto(base + '/')
        page.evaluate("""async () => {
          const c = await import('/static/core.js');
          c.showView('app');
          c.cacheSettings([{ key: 'ui.language', value: 'en' }]);
          (await import('/static/tabs.js')).showTab('dashboard', { refresh: false });
          await (await import('/static/overview.js')).refreshHealth();
        }""")

        row = page.locator('#attentionCard [data-key="plugin-update:hello-world"]')
        expect(row.locator('.name')).to_have_text('<b>Hello World</b> update available')
        expect(row.locator('.desc')).to_have_text('Version 1.2.0 is ready to review and install.')
        assert row.locator('.name b').count() == 0, 'a plugin name is text, never markup'

        # Update opens the review and installs nothing until it is accepted.
        row.locator('button').click()
        review = page.locator('.modal-back')
        expect(review).to_be_visible()
        assert 'checkPluginUpdate' in commands
        assert 'installPluginRepository' not in commands
        review.get_by_role('button', name='Trust and update').click()
        expect(review).to_have_count(0)
        assert 'installPluginRepository' in commands

        # The list the device reads next no longer has it.
        page.evaluate("async () => (await import('/static/overview.js')).refreshHealth()")
        expect(row).to_have_count(0)

        page.evaluate("""async () => {
          await (await import('/static/plugins.js')).loadPlugins();
          (await import('/static/tabs.js')).showTab('plugins', { refresh: false });
        }""")
        expect(page.locator('#tab-plugins [data-subpage-entry], #tab-plugins .row', has_text='example/hello').first
               ).to_contain_text('example/hello · 1.0.0 · New version: 1.2.0')
        assert not errors, errors
        browser.close()
    print('plugin update rows passed')
finally:
    server.shutdown()
