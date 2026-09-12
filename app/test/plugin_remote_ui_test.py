"""Exercise plugin navigation and repository previews in a local browser fixture.

Run with Python 3 and Playwright's Chromium installed. No device is contacted.
"""
import base64
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
    'settings': [{'key': 'message', 'title': 'Greeting', 'type': 'string', 'default': 'Hello'}, {'key': 'entity', 'title': 'Home Assistant entity', 'type': 'entity', 'default': ''}],
    'commands': [{'id': 'show', 'title': 'Show window'}], 'values': {'message': 'Hello'},
}
installed = [copy.deepcopy(plugin)]
requests = []
compatible = True
plugins_enabled = True
update_available = False
held = []
delay_preview = False
delay_zip = False
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
    global installed, plugins_enabled
    name = route.request.url.rsplit('/', 1)[-1]
    params = route.request.post_data_json or {}
    requests.append((name, params))
    if name == 'getPluginState':
        result = {'enabled': plugins_enabled, 'plugins': installed}
    elif name == 'setPluginsEnabled':
        plugins_enabled = params['enabled']
        for item in installed:
            item['running'] = plugins_enabled and item['enabled']
        result = {'enabled': plugins_enabled, 'plugins': installed}
    elif name == 'previewPluginRepository':
        result = {**preview, 'compatible': compatible, 'compatibilityError': 'Unsupported SDK' if not compatible else ''}
        if delay_preview:
            held.append((route, result))
            return
    elif name == 'installPlugin':
        assert params == {'data': base64.b64encode(b'development package').decode(), 'trusted': True}
        installed = [{**copy.deepcopy(plugin), 'enabled': False}]
        result = installed
        if delay_zip:
            held.append((route, result))
            return
    elif name == 'haSearchEntities':
        result = [{'entity_id': 'sensor.room', 'name': 'Room temperature', 'state': '21'}]
    elif name == 'checkPluginUpdate':
        assert params == {'id': 'hello-world'}
        result = {**preview, 'installedVersion': installed[0]['version'], 'updateAvailable': update_available, 'compatible': compatible, 'compatibilityError': 'Unsupported SDK' if not compatible else ''}
    elif name == 'installPluginRepository':
        assert params == {'previewId': 'reviewed-token', 'trusted': True}
        installed = [{**copy.deepcopy(plugin), 'enabled': installed[0]['enabled'] if installed else False, 'source': preview}]
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
        master = root.get_by_role('checkbox', name='Enable Plugins', exact=True)
        expect(master).to_be_checked()
        expect(root.get_by_text('Plugins add additional community developed features to Kiosk Satellite.', exact=True)).to_be_visible()
        expect(root.get_by_text('Plugins add optional features', exact=False)).to_have_count(0)
        warning = root.locator('.plugin-install-warning')
        assert warning.bounding_box()['y'] > root.get_by_role('button', name='Add plugin', exact=True).bounding_box()['y']
        expect(page.locator('#pageTitle')).to_contain_text('Plugin Manager')
        expect(page.locator('#tabs button[data-tab=plugins] .nav-title')).to_have_text('Plugin Manager')
        colors = [page.locator(f'#tabs button[data-tab={tab}] .disc').evaluate('(el) => getComputedStyle(el).backgroundColor') for tab in ['fleet', 'files', 'plugins', 'about', 'logs']]
        assert all(a != b for a, b in zip(colors, colors[1:])), 'Adjacent menu icons repeat a color'
        assert colors[0] == colors[4], 'Menu colors should continue the four-color cycle'
        before_master = root.locator('.plugin-master-switch').bounding_box()
        root.locator('.plugin-master-switch').click()
        expect(master).not_to_be_checked()
        expect(row).to_have_count(0)
        expect(root.get_by_text('Add plugin', exact=True)).to_have_count(0)
        expect(root.get_by_text('Developer Tools', exact=True)).to_have_count(0)
        expect(root.locator('.plugin-install-warning')).to_have_count(0)
        assert root.locator('.plugin-master-switch').bounding_box() == before_master
        assert installed[0]['enabled'] is True and installed[0]['running'] is False
        page.evaluate("async () => (await import('/static/tabs.js')).showTab('plugins/hello-world', {refresh:false})")
        expect(page.locator('#pageTitle')).to_contain_text('Plugin Manager')
        expect(root.get_by_role('button', name='Show window')).to_have_count(0)
        assert page.url.endswith('#plugins')
        root.locator('.plugin-master-switch').click()
        expect(master).to_be_checked()
        expect(row.get_by_role('checkbox')).to_be_checked()
        expect(row.get_by_role('checkbox')).to_be_enabled()
        row.locator('label.switch').click()
        expect(row.get_by_role('checkbox')).not_to_be_checked()
        assert page.url.endswith('#plugins')
        row.get_by_text('Hello World', exact=True).click()
        expect(root.get_by_role('button', name='Configure Show window', exact=True)).to_be_enabled()
        expect(root.get_by_role('button', name='Uninstall Hello World')).not_to_be_visible()
        expect(page.locator('#pageTitle')).to_contain_text('Hello World')
        root.get_by_role('button', name='Choose Home Assistant entity').click()
        modal = page.locator('.modal-card')
        modal.get_by_placeholder('Search by name or entity id').fill('room')
        modal.get_by_text('Room temperature', exact=True).click()
        expect(root.get_by_text('sensor.room', exact=True)).to_be_visible()
        assert installed[0]['values']['entity'] == 'sensor.room'
        root.get_by_role('button', name='Choose Home Assistant entity').click()
        page.locator('.modal-card').get_by_role('button', name='Clear', exact=True).click()
        expect(root.get_by_text('sensor.room', exact=True)).to_have_count(0)
        assert installed[0]['values']['entity'] == ''
        root.get_by_role('textbox', name='Greeting').fill('Changed on the subpage')
        root.get_by_role('textbox', name='Greeting').press('Tab')
        expect(root.get_by_role('button', name='Save settings')).to_have_count(0)
        expect(root.get_by_role('textbox', name='Greeting')).to_have_value('Changed on the subpage')
        assert page.url.endswith('#plugins/hello-world')
        page.locator('#pageTitle').get_by_role('button', name='Back').click()
        expect(row).to_be_visible()
        row.locator('label.switch').click()
        expect(row.get_by_role('checkbox')).to_be_checked()
        expect(root.get_by_role('button', name='Add plugin')).to_be_enabled()
        page.screenshot(path='/tmp/kiosk-plugins-restyled.png', full_page=True)
        expect(root.get_by_text('Refresh', exact=True)).to_have_count(0)
        expect(root.get_by_text('Developer Tools', exact=True)).to_be_visible()
        expect(root.get_by_role('button', name='Install from ZIP')).to_be_enabled()
        expect(root.locator('.hint-row.warn')).to_contain_text('expose private information')
        def choose_zip(content=b'development package'):
            with page.expect_file_chooser() as chooser:
                root.get_by_role('button', name='Install from ZIP', exact=True).click()
            chooser.value.set_files({'name': 'development.zip', 'mimeType': 'application/zip', 'buffer': content})
        zip_before = row.bounding_box()
        choose_zip()
        modal = page.locator('.modal-card')
        expect(modal.get_by_text('development.zip', exact=True)).to_be_visible()
        modal.get_by_role('button', name='Cancel').click()
        assert not any(name == 'installPlugin' for name, _ in requests)
        choose_zip(b'x' * (4 * 1024 * 1024 + 1))
        expect(page.get_by_text('Plugin ZIP must be at most 4 MB', exact=True)).to_be_visible()
        assert not any(name == 'installPlugin' for name, _ in requests)
        delay_zip = True
        choose_zip()
        modal.get_by_role('button', name='Trust and install').click()
        expect(root.get_by_role('button', name='Install from ZIP')).to_have_class('icon-btn plugin-busy')
        assert row.bounding_box() == zip_before, 'ZIP installation moved the installed plugin row'
        page.wait_for_timeout(100)
        assert held, 'ZIP upload was not made'
        route, response = held.pop()
        route.fulfill(json={'ok': True, 'data': response})
        delay_zip = False
        expect(row.get_by_role('checkbox')).not_to_be_checked()
        expect(root.get_by_role('button', name='Install from ZIP')).to_be_enabled()
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
        check = row.get_by_role('button', name='Check for updates for Hello World')
        check.click()
        expect(page.get_by_text('No updates available.', exact=True)).to_be_visible()
        assert page.url.endswith('#plugins')
        update_available = True
        installs_before = sum(name == 'installPluginRepository' for name, _ in requests)
        check.click()
        expect(modal.get_by_text('Installed version', exact=True)).to_be_visible()
        modal.get_by_role('button', name='Cancel', exact=True).click()
        assert sum(name == 'installPluginRepository' for name, _ in requests) == installs_before
        compatible = False
        check.click()
        expect(modal.get_by_role('button', name='Trust and update')).to_be_disabled()
        modal.get_by_role('button', name='Cancel', exact=True).click()
        compatible = True
        row.locator('label.switch').click()
        expect(row.get_by_role('checkbox')).to_be_checked()
        check.click()
        modal.get_by_role('button', name='Trust and update').click()
        expect(row.get_by_role('checkbox')).to_be_checked()
        assert sum(name == 'installPluginRepository' for name, _ in requests) == installs_before + 1
        assert row.locator(':scope > :first-child').get_attribute('class') == 'switch'
        row.get_by_role('button', name='About Hello World').click()
        expect(modal.get_by_role('heading', name='Reviewed README')).to_be_visible()
        assert page.url.endswith('#plugins'), 'Info opened the plugin settings'
        expect(modal.locator('script,[onerror]')).to_have_count(0)
        modal.get_by_role('button', name='Close', exact=True).click()
        row.get_by_text('Hello World', exact=True).click()
        expect(root.locator('.plugin-readme')).to_have_count(0)
        page.set_viewport_size({'width': 390, 'height': 844})
        assert page.evaluate('document.documentElement.scrollWidth <= innerWidth')
        page.locator('#pageTitle').get_by_role('button', name='Back').click()
        expect(row).to_be_visible()
        assert page.evaluate('document.documentElement.scrollWidth <= innerWidth')
        toggle_bounds = row.locator('label.switch').bounding_box()
        title_bounds = row.locator('.info').bounding_box()
        about_bounds = row.get_by_role('button', name='About Hello World').bounding_box()
        delete_bounds = row.get_by_role('button', name='Uninstall Hello World').bounding_box()
        assert toggle_bounds['x'] < title_bounds['x'] < about_bounds['x'] < delete_bounds['x']
        assert abs(toggle_bounds['y'] + toggle_bounds['height']/2 - delete_bounds['y'] - delete_bounds['height']/2) < 2
        page.screenshot(path='/tmp/kiosk-plugin-row-mobile.png', full_page=True)
        row.get_by_role('button', name='About Hello World').click()
        expect(modal.get_by_role('heading', name='Reviewed README')).to_be_visible()
        assert page.evaluate('document.documentElement.scrollWidth <= innerWidth')
        modal.get_by_role('button', name='Close', exact=True).click()
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
