"""Exercise plugin navigation and repository previews in a local browser fixture.

Run with Python 3 and Playwright's Chromium installed. No device is contacted.
"""
import copy
import json
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread

from playwright.sync_api import sync_playwright, expect

ROOT = Path(__file__).resolve().parents[1] / 'assets/remote-ui'


class Handler(SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass


server = ThreadingHTTPServer(('127.0.0.1', 0), partial(Handler, directory=str(ROOT)))
Thread(target=server.serve_forever, daemon=True).start()
base = f'http://127.0.0.1:{server.server_port}'
plugin = {
    'id': 'hello-world', 'name': 'Hello World', 'version': '1.0.0',
    'description': 'A floating greeting', 'author': 'Example', 'license': 'Apache-2.0',
    'capabilities': ['overlay'], 'enabled': True, 'running': True,
    'settings': [{'key': 'message', 'title': 'Greeting', 'type': 'string', 'default': 'Hello'}],
    'commands': [{'id': 'show', 'title': 'Show window'}], 'values': {'message': 'Hello'},
}
installed = [copy.deepcopy(plugin)]
requests = []
compatible = True
held = []
delay_preview = False
preview = {
    'previewId': 'reviewed-token', 'repository': 'https://github.com/example/hello',
    'manifest': plugin, 'compatible': True,
    'readmeBaseUrl': 'https://raw.githubusercontent.com/example/hello/' + 'a' * 40 + '/',
    'readme': '# Reviewed README\n\n**Bold greeting**\n\n[Guide](docs/guide.md)\n\n'
              '<script>window.readmeExecuted = true</script>\n'
              '<img src="javascript:alert(1)" onerror="window.readmeExecuted = true">\n'
              '[Unsafe](javascript:alert(1))',
}


def api(route):
    global installed
    name = route.request.url.rsplit('/', 1)[-1]
    params = route.request.post_data_json or {}
    requests.append((name, params))
    if name == 'previewPluginRepository':
        result = {**preview, 'compatible': compatible, 'compatibilityError': 'Unsupported SDK' if not compatible else ''}
        if delay_preview:
            held.append((route, result))
            return
    elif name == 'installPluginRepository':
        assert params == {'previewId': 'reviewed-token', 'trusted': True}
        installed = [{**copy.deepcopy(plugin), 'enabled': False, 'source': preview}]
        result = installed
    else:
        if name in ('enablePlugin', 'disablePlugin'):
            installed[0]['enabled'] = name == 'enablePlugin'
        elif name == 'configurePlugin':
            installed[0]['values'] = params['values']
        elif name == 'removePlugin':
            installed = []
        result = installed
    route.fulfill(json={'ok': True, 'data': result})


try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, args=['--no-sandbox'])
        page = browser.new_page(viewport={'width': 1440, 'height': 1100})
        errors = []
        page.on('pageerror', lambda error: errors.append(str(error)))
        # Load the real DOM and modules without bootstrapping unrelated services.
        html = (ROOT / 'index.html').read_text().replace('<script type="module" src="static/main.js?v=__KSV__"></script>', '')
        page.route(base + '/', lambda route: route.fulfill(body=html, content_type='text/html'))
        page.route('**/api/commands/*', api)
        page.goto(base + '/')
        page.evaluate("""async () => {
          (await import('/static/core.js')).showView('app');
          await (await import('/static/plugins.js')).loadPlugins();
          (await import('/static/tabs.js')).showTab('plugins', {refresh: false});
        }""")
        root = page.locator('#tab-plugins')
        row = root.locator('.subpage-entry')
        expect(row.get_by_text('Hello World', exact=True)).to_be_visible()
        expect(root.get_by_role('button', name='Save settings')).not_to_be_visible()
        row.locator('label.switch').click()
        expect(row.get_by_role('checkbox')).not_to_be_checked()
        assert page.url.endswith('#plugins')
        row.get_by_text('Hello World', exact=True).click()
        expect(root.get_by_role('button', name='Show window')).to_be_disabled()
        expect(root.get_by_role('button', name='Uninstall Hello World')).not_to_be_visible()
        expect(page.locator('#pageTitle')).to_contain_text('Hello World')
        root.get_by_role('textbox', name='Greeting').fill('Changed on the subpage')
        root.get_by_role('button', name='Save settings').click()
        expect(root.get_by_role('textbox', name='Greeting')).to_have_value('Changed on the subpage')
        assert page.url.endswith('#plugins/hello-world')
        page.locator('#pageTitle').get_by_role('button', name='Back').click()
        expect(row).to_be_visible()
        row.locator('label.switch').click()
        expect(row.get_by_role('checkbox')).to_be_checked()
        expect(root.get_by_role('button', name='Add plugin')).to_be_enabled()
        page.screenshot(path='/tmp/kiosk-plugins-restyled.png', full_page=True)
        expect(root.get_by_text('Refresh', exact=True)).to_have_count(0)
        expect(root.locator('input[type=file]')).to_have_count(0)
        expect(root.locator('.hint-row.warn')).to_contain_text('expose private information')
        def open_preview():
            root.get_by_role('button', name='Add plugin', exact=True).click()
            modal = page.locator('.modal-card')
            modal.get_by_role('textbox', name='Repository URL').fill('https://github.com/example/hello')
            modal.get_by_role('button', name='Preview', exact=True).click()
        delay_preview = True
        before = row.bounding_box()
        open_preview()
        expect(root.get_by_role('button', name='Add plugin')).to_have_class('icon-btn plugin-busy')
        assert row.bounding_box() == before, 'Loading moved the installed plugin row'
        expect(root.get_by_text('Working…', exact=True)).to_have_count(0)
        page.wait_for_timeout(100)
        assert held, 'Preview request was not made'
        route, response = held.pop()
        route.fulfill(json={'ok': True, 'data': response})
        delay_preview = False
        modal = page.locator('.modal-card')
        expect(modal.get_by_role('heading', name='Reviewed README')).to_be_visible()
        assert not any(name == 'installPluginRepository' for name, _ in requests)
        assert page.evaluate('window.readmeExecuted') is None
        expect(modal.locator('script,[onerror]')).to_have_count(0)
        expect(modal.get_by_role('link', name='Guide')).to_have_attribute('href', 'https://github.com/example/hello/blob/' + 'a' * 40 + '/docs/guide.md')
        modal.get_by_role('button', name='Cancel').click()
        assert not any(name == 'installPluginRepository' for name, _ in requests)
        compatible = False
        open_preview()
        expect(modal.get_by_role('button', name='Trust and install')).to_be_disabled()
        modal.get_by_role('button', name='Cancel').click()
        compatible = True
        open_preview()
        modal.get_by_role('button', name='Trust and install').click()
        expect(row.get_by_role('checkbox')).not_to_be_checked()
        row.get_by_text('Hello World', exact=True).click()
        expect(root.get_by_role('heading', name='Reviewed README')).to_be_visible()
        page.set_viewport_size({'width': 390, 'height': 844})
        assert page.evaluate('document.documentElement.scrollWidth <= innerWidth')
        page.locator('#pageTitle').get_by_role('button', name='Back').click()
        expect(row).to_be_visible()
        assert page.evaluate('document.documentElement.scrollWidth <= innerWidth')
        row.get_by_role('button', name='Uninstall Hello World').click()
        modal.get_by_role('button', name='Uninstall', exact=True).click()
        expect(root.get_by_text('No plugins installed. Add a repository to get started.')).to_be_visible()
        assert page.url.endswith('#plugins')
        assert not errors, errors
        page.screenshot(path='/tmp/kiosk-plugins-empty.png', full_page=True)
        browser.close()
        print('PASS: repository review, cancel, compatibility, trust, sanitized README, entry controls, subpages and mobile layout.')
finally:
    server.shutdown()
    server.server_close()
