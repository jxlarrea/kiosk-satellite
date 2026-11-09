"""Exercise plugin list settings and the picker setting types in a local browser fixture.

Run with Python 3 and Playwright's Chromium installed. No device is contacted.
"""
import copy
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread

from playwright.sync_api import sync_playwright, expect

ROOT = Path(__file__).resolve().parents[1] / 'remote-ui'


class Handler(SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass


server = ThreadingHTTPServer(('127.0.0.1', 0), partial(Handler, directory=str(ROOT)))
Thread(target=server.serve_forever, daemon=True).start()
base = f'http://127.0.0.1:{server.server_port}'
entries = {
    'key': 'entries', 'title': 'Entries', 'type': 'list', 'addTitle': 'Add entry', 'minItems': 1,
    'visibleWhen': {'key': 'opens', 'equals': 'Menu'},
    'fields': [
        {'key': 'label', 'title': 'Label', 'type': 'string', 'required': True},
        {'key': 'url', 'title': 'Address', 'type': 'string'},
    ],
}
plugin = {
    'id': 'navbar', 'name': 'Navbar', 'version': '1.0.0', 'description': 'A navigation bar',
    'capabilities': ['overlay'], 'enabled': True, 'running': True, 'commands': [],
    'groups': [{'title': 'Behavior'}, {'title': 'Items'}],
    'settings': [
        {'key': 'collapse', 'title': 'Collapse', 'type': 'select', 'options': ['Off', 'On'], 'default': 'Off', 'group': 'Behavior'},
        {'key': 'after', 'title': 'Collapse after', 'type': 'number', 'min': 0, 'max': 60, 'default': 0, 'group': 'Behavior',
         'visibleWhen': {'key': 'collapse', 'notEquals': 'Off'}},
        {'key': 'tabIcon', 'title': 'Tab icon', 'type': 'icon', 'default': '', 'group': 'Behavior'},
        {'key': 'items', 'title': 'Items', 'type': 'list', 'group': 'Items', 'addTitle': 'Add item', 'default': [],
         'row': {'title': 'label', 'subtitle': ['url', 'camera', 'opens'], 'icon': 'icon'},
         'fields': [
             {'key': 'label', 'title': 'Label', 'type': 'string', 'required': True},
             {'key': 'icon', 'title': 'Icon', 'type': 'icon'},
             {'key': 'opens', 'title': 'Opens', 'type': 'select', 'options': ['Web address', 'Camera view', 'Menu']},
             {'key': 'url', 'title': 'Address', 'type': 'string', 'required': True,
              'visibleWhen': {'key': 'opens', 'equals': 'Web address'}},
             {'key': 'camera', 'title': 'Camera view', 'type': 'cameraView', 'required': True,
              'visibleWhen': {'key': 'opens', 'equals': 'Camera view'}},
             entries,
         ]},
    ],
    'values': {
        'collapse': 'Off', 'after': 0, 'tabIcon': '',
        'items': [{'label': 'Home', 'icon': 'mdi:home', 'opens': 'Web address', 'url': 'https://example.com', 'camera': '', 'entries': []}],
    },
}
sensors = {
    'id': 'sensors', 'name': 'Sensors', 'version': '1.0.0', 'description': 'Entity lists',
    'capabilities': [], 'enabled': True, 'running': True, 'commands': [], 'groups': [],
    'settings': [
        {'key': 'sensors', 'title': 'Sensors', 'type': 'list', 'default': [], 'row': {'title': 'entity'},
         'fields': [{'key': 'entity', 'title': 'Entity', 'type': 'entity'}]},
        {'key': 'buttons', 'title': 'Buttons', 'type': 'list', 'default': [], 'row': {'title': 'label', 'subtitle': 'target'},
         'fields': [{'key': 'label', 'title': 'Label', 'type': 'string'}, {'key': 'target', 'title': 'Target', 'type': 'entity'}]},
    ],
    'values': {
        'sensors': [{'entity': 'sensor.room'}, {'entity': 'sensor.gone'}],
        'buttons': [{'label': 'Porch', 'target': 'light.porch'}],
    },
}
entities = [
    {'entity_id': 'sensor.room', 'name': 'Room temperature', 'state': '21 °C', 'domain': 'sensor', 'icon_path': 'M15,13V5A3,3 0 0,0 9,5V13A5,5 0 1,0 15,13M12,4A1,1 0 0,1 13,5V8H11V5A1,1 0 0,1 12,4Z'},
    {'entity_id': 'light.porch', 'name': 'Porch light', 'state': 'On', 'domain': 'light'},
]
monitor = {
    'id': 'monitor', 'name': 'Monitor', 'version': '1.0.0', 'description': 'Hardware panels',
    'capabilities': [], 'enabled': True, 'running': True, 'commands': [], 'groups': [],
    'settings': [
        {'key': 'panels', 'title': 'Panels', 'type': 'list', 'default': [], 'row': {'title': 'sensor', 'subtitle': 'label'},
         'fields': [
             {'key': 'label', 'title': 'Label', 'type': 'string'},
             {'key': 'sensor', 'title': 'Sensor', 'type': 'string', 'choices': 'plugin', 'required': True},
             {'key': 'tiles', 'title': 'Tiles', 'type': 'list',
              'fields': [{'key': 'sensor', 'title': 'Tile sensor', 'type': 'string', 'choices': 'plugin'}]},
         ]},
    ],
    'values': {'panels': [{'label': 'Main', 'sensor': 'cpu.temp', 'tiles': [{'sensor': 'gpu.temp'}, {'sensor': 'board.temp'}]}]},
}
thresholds = {
    'id': 'thresholds', 'name': 'Thresholds', 'version': '1.0.0', 'description': 'Typed numbers',
    'capabilities': [], 'enabled': True, 'running': True, 'commands': [], 'groups': [],
    'settings': [
        {'key': 'hot', 'title': 'Hot above', 'type': 'number', 'input': 'field', 'min': -50, 'max': 150, 'step': 0.5,
         'default': 85, 'unit': '°C'},
        {'key': 'alerts', 'title': 'Alerts', 'type': 'list', 'addTitle': 'Add alert', 'default': [], 'row': {'title': 'name', 'subtitle': 'above'},
         'fields': [
             {'key': 'name', 'title': 'Name', 'type': 'string', 'required': True},
             {'key': 'watch', 'title': 'Watch', 'type': 'boolean', 'default': True},
             {'key': 'above', 'title': 'Above', 'type': 'number', 'input': 'field', 'min': 0, 'max': 100000, 'unit': 'fps',
              'visibleWhen': {'key': 'watch', 'equals': True}},
         ]},
    ],
    'values': {'hot': 85, 'alerts': []},
}
# A switch that reveals color rows, one in a group of its own with a
# button and a summary the plugin writes itself on every save.
clock = {
    'id': 'clock', 'name': 'Clock', 'version': '1.0.0', 'description': 'Custom colors',
    'capabilities': [], 'enabled': True, 'running': True, 'commands': [], 'groups': [{'title': 'Look'}],
    'settings': [
        {'key': 'label', 'title': 'Label', 'type': 'string', 'default': '', 'group': 'Look'},
        {'key': 'custom', 'title': 'Custom colors', 'type': 'boolean', 'default': False, 'group': 'Look'},
        {'key': 'face', 'title': 'Face color', 'type': 'color', 'default': '#112233', 'group': 'Look',
         'visibleWhen': {'key': 'custom', 'equals': True}},
        {'key': 'hands', 'title': 'Hands color', 'type': 'color', 'default': '#445566', 'group': 'Look',
         'visibleWhen': {'key': 'custom', 'equals': True}},
        {'key': 'size', 'title': 'Size', 'type': 'number', 'min': 1, 'max': 10, 'default': 5, 'group': 'Look'},
        {'key': 'summary', 'title': 'Summary', 'type': 'string', 'default': '', 'group': 'Look'},
        {'key': 'accent', 'title': 'Accent color', 'type': 'color', 'default': '#778899', 'group': 'Accents',
         'visibleWhen': {'key': 'custom', 'equals': True}},
    ],
    'buttons': [{'id': 'preview', 'title': 'Preview colors', 'label': 'Preview', 'group': 'Accents',
                 'visibleWhen': {'key': 'custom', 'equals': True}}],
    'values': {'label': 'Kitchen', 'custom': False, 'size': 5, 'summary': 'Plain'},
    'status': 'Plain colors',
}
# A list that offers Duplicate, with a tap action and a nested list.
commutes = {
    'id': 'commutes', 'name': 'Commutes', 'version': '1.0.0', 'description': 'Row copies',
    'capabilities': [], 'enabled': True, 'running': True, 'commands': [], 'groups': [],
    'settings': [
        {'key': 'trips', 'title': 'Trips', 'type': 'list', 'addTitle': 'Add trip', 'maxItems': 3, 'duplicate': True,
         'default': [], 'row': {'title': 'label'},
         'fields': [
             {'key': 'label', 'title': 'Label', 'type': 'string', 'required': True},
             {'key': 'tap', 'title': 'Tap action', 'type': 'action'},
             {'key': 'stops', 'title': 'Stops', 'type': 'list', 'addTitle': 'Add stop', 'maxItems': 2, 'duplicate': True,
              'fields': [{'key': 'name', 'title': 'Name', 'type': 'string'}]},
         ]},
    ],
    'values': {'trips': [{'label': 'Home', 'tap': {'type': 'refresh'}, 'stops': [{'name': 'Main St'}]}]},
}
installed = [copy.deepcopy(plugin), sensors, monitor, thresholds, clock, commutes]
setup = {'runs': {}, 'choices': {}, 'choiceRevisions': {}}
setup_runs = []
icons = {'mdi:home': 'M10,20V14H14V20H19V12H22L12,3L2,12H5V20H10Z', 'mdi:garage': 'M19,20H17V11H7V20H5V9L12,5L19,9V20Z',
         'mdi:garage-open': 'M19,20H17V11H7V20H5V9L12,5L19,9V20M8,12H16V14H8Z', 'mdi:cctv': 'M18.15,4.94L4,6Z'}
saved = []


def api(route):
    name = route.request.url.rsplit('/', 1)[-1]
    params = route.request.post_data_json or {}
    if name == 'getPluginState':
        result = {'enabled': True, 'plugins': installed}
    elif name == 'configurePlugin':
        # A patch writes over the saved values, like the host.
        target = next(p for p in installed if p['id'] == params['id'])
        target['values'] = {**(target['values'] if params.get('patch') else {}), **copy.deepcopy(params['values'])}
        saved.append(copy.deepcopy(params['values']))
        if target['id'] == 'clock':
            target['values']['summary'] = 'Custom' if target['values'].get('custom') else 'Plain'
            target['status'] = f"{target['values']['summary']} colors"
        result = installed
    elif name == 'searchIcons':
        if 'names' in params:
            result = [{'name': n, 'path': icons[n]} for n in params['names'] if n in icons]
        else:
            words = params.get('query', '').split()
            result = [{'name': n, 'path': p} for n, p in icons.items() if all(w in n for w in words)]
    elif name == 'haListEntities':
        result = entities
    elif name == 'cameraGetConfig':
        result = {'cameras': [], 'views': [{'id': 'a1b2c3d4e5f60718293a4b5c6d7e8f90', 'name': 'Front door', 'cameraIds': ['c1']},
                                           {'id': 'default', 'name': 'Default', 'cameraIds': []}]}
    elif name == 'getPluginSetup':
        held = params.get('choiceRevisions')
        result = {'runs': setup['runs'], 'choiceRevisions': setup['choiceRevisions'],
                  'choices': {k: v for k, v in setup['choices'].items()
                              if held is None or held.get(k) != setup['choiceRevisions'][k]}}
    elif name == 'runPluginSetup':
        setup_runs.append(params)
        setup['runs'][f"{params['target']}:{params['key']}"] = {
            'run': f'run-{len(setup_runs)}', 'state': 'running', 'message': '', 'code': '', 'origin': 'remote', 'confirm': None}
        result = {'run': f'run-{len(setup_runs)}'}
    elif name in ('getPluginCharts', 'getPluginReadings', 'getPluginStatusTiles'):
        result = []
    else:
        result = installed
    route.fulfill(json={'ok': True, 'data': result})


try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, args=['--no-sandbox'])
        page = browser.new_page(viewport={'width': 1280, 'height': 1000})
        errors = []
        page.on('pageerror', lambda error: errors.append(str(error)))
        html = (ROOT / 'index.html').read_text().replace('<script type="module" src="static/main.js?v=__KSV__"></script>', '')
        page.route(base + '/', lambda route: route.fulfill(body=html, content_type='text/html'))
        page.route('**/api/commands/*', api)
        page.goto(base + '/')
        page.evaluate("""async () => {
          (await import('/static/core.js')).showView('app');
          await (await import('/static/plugins.js')).loadPlugins();
          (await import('/static/tabs.js')).showTab('plugins/navbar', {refresh: false});
        }""")
        root = page.locator('#tab-plugins > .subpage[data-subpage="navbar"]')
        expect(page.locator('#pageTitle')).to_contain_text('Navbar')
        # A setting whose condition fails stays off the page. The list,
        # alone in its group, has no title row of its own.
        expect(root.get_by_text('Collapse after', exact=True)).to_have_count(0)
        expect(root.locator('.plugin-list > .row:not(.plugin-list-row)')).to_have_count(0)
        rows = root.locator('.plugin-list-row')
        expect(rows).to_have_count(1)
        expect(rows.first).to_contain_text('Home')
        expect(rows.first).to_contain_text('https://example.com')
        expect(rows.first.locator('.camera-row-icon svg path')).to_have_attribute('d', icons['mdi:home'])

        # Editing a row saves the whole list.
        rows.first.click()
        modal = page.locator('.modal-card')
        expect(modal.locator('.modal-title')).to_have_text('Home')
        modal.locator('.form-field:has-text("Label") input').fill('House')
        modal.get_by_role('button', name='Save', exact=True).click()
        expect(modal).to_have_count(0)
        assert saved[-1]['items'][0]['label'] == 'House', saved[-1]
        expect(rows.first).to_contain_text('House')

        # A new row waits for its required fields, a nested row included.
        root.get_by_text('Add item', exact=True).click()
        save = modal.get_by_role('button', name='Save', exact=True)
        expect(save).to_be_disabled()
        expect(modal.get_by_role('button', name='Delete', exact=True)).to_have_count(0)
        modal.locator('.form-field:has-text("Label") input').fill('Cameras')
        modal.locator('.form-field:has-text("Opens") select').select_option('Menu')
        expect(modal.get_by_text('Address', exact=True)).to_have_count(0)
        expect(modal.locator('.form-field:has-text("Entries") .plugin-required')).to_be_visible()
        expect(save).to_be_disabled()
        modal.get_by_text('Add entry', exact=True).click()
        expect(modal.locator('.modal-title')).to_contain_text('Add entry')
        expect(modal.get_by_role('button', name='Back', exact=True)).to_be_visible()
        modal.locator('.form-field:has-text("Label") input').fill('Front door')
        modal.get_by_role('button', name='Done', exact=True).click()
        expect(modal.locator('.modal-title')).to_have_text('Add item')
        expect(modal.locator('.plugin-list-box')).to_contain_text('Front door')
        # The icon picker searches the kiosk's icons as you type.
        modal.locator('.form-field:has-text("Icon") .dp-field').click()
        picker = page.locator('.modal-card').last
        picker.get_by_role('searchbox').fill('garage open')
        expect(picker.locator('.plugin-icon-cell')).to_have_count(1)
        picker.locator('.plugin-icon-cell').click()
        expect(modal.locator('.form-field:has-text("Icon") .dp-field')).to_contain_text('mdi:garage-open')
        expect(save).to_be_enabled()
        save.click()
        expect(modal).to_have_count(0)
        assert saved[-1]['items'][1] == {'label': 'Cameras', 'icon': 'mdi:garage-open', 'opens': 'Menu', 'url': '', 'camera': '',
                                         'entries': [{'label': 'Front door', 'url': ''}]}, saved[-1]

        # Arrows move a row for screens without drag.
        rows.nth(1).get_by_role('button', name='Move up', exact=True).click()
        expect(rows.first).to_contain_text('Cameras')
        assert [i['label'] for i in saved[-1]['items']] == ['Cameras', 'House']

        # A camera view row shows the view's name.
        rows.nth(1).click()
        modal.locator('.form-field:has-text("Opens") select').select_option('Camera view')
        modal.locator('.form-field:has-text("Camera view") .ep-field').click()
        page.locator('.dash-picker-card').get_by_text('Front door', exact=True).click()
        save.click()
        assert saved[-1]['items'][1]['camera'] == 'a1b2c3d4e5f60718293a4b5c6d7e8f90'
        expect(rows.nth(1)).to_contain_text('Front door')

        # Duplicate waits for the plugin to offer it.
        rows.nth(1).click()
        expect(modal.get_by_role('button', name='Duplicate', exact=True)).to_have_count(0)

        # Delete takes the row out.
        modal.get_by_role('button', name='Delete', exact=True).click()
        expect(rows).to_have_count(1)
        assert [i['label'] for i in saved[-1]['items']] == ['Cameras']

        # A top-level icon setting saves on pick.
        root.locator('.row:has-text("Tab icon") .dp-field').click()
        page.locator('.modal-card').get_by_role('searchbox').fill('garage')
        page.locator('.plugin-icon-cell[title="mdi:garage"]').click()
        expect(root.locator('.row:has-text("Tab icon") .dp-field')).to_contain_text('mdi:garage')
        assert saved[-1]['tabIcon'] == 'mdi:garage'

        # Turning the condition's setting on brings its dependent back.
        root.locator('.row:has-text("Collapse") select').first.select_option('On')
        expect(root.get_by_text('Collapse after', exact=True)).to_be_visible()
        page.screenshot(path='/tmp/kiosk-plugin-list-settings.png', full_page=True)

        # Entity fields show the entity's name, icon and state, and an
        # entity Home Assistant lacks keeps its id with a warning.
        page.evaluate("(async () => (await import('/static/tabs.js')).showTab('plugins/sensors', {refresh: false}))()")
        expect(page.locator('#pageTitle')).to_contain_text('Sensors')
        rows = page.locator('#tab-plugins > .subpage[data-subpage="sensors"] .plugin-list-row')
        expect(rows).to_have_count(3)
        expect(rows.nth(0).locator('.name')).to_have_text('Room temperature')
        expect(rows.nth(0).locator('.desc')).to_have_text('21 °C · sensor.room')
        expect(rows.nth(0).locator('.camera-row-main .camera-row-icon svg path')).to_have_attribute('d', entities[0]['icon_path'])
        expect(rows.nth(1).locator('.name')).to_have_text('sensor.gone')
        expect(rows.nth(1).locator('.desc')).to_have_count(0)
        expect(rows.nth(1).locator('.plugin-row-missing')).to_have_count(1)
        expect(rows.nth(2).locator('.name')).to_have_text('Porch')
        expect(rows.nth(2).locator('.desc')).to_have_text('Porch light · On')
        expect(rows.nth(2).locator('.camera-row-main .camera-row-icon')).to_have_count(0)
        page.screenshot(path='/tmp/kiosk-plugin-list-entities.png', full_page=True)

        # A row field with plugin choices shows its ID until the plugin
        # lists the choices, then the label.
        page.evaluate("(async () => (await import('/static/tabs.js')).showTab('plugins/monitor', {refresh: false}))()")
        expect(page.locator('#pageTitle')).to_contain_text('Monitor')
        rows = page.locator('#tab-plugins > .subpage[data-subpage="monitor"] .plugin-list-row')
        expect(rows.first.locator('.name')).to_have_text('cpu.temp')
        expect(rows.first.locator('.desc')).to_have_text('Main')
        setup['choices'] = {
            'panels.sensor': [
                {'id': 'cpu.temp', 'label': 'CPU temperature', 'group': 'Processor', 'detail': '54 °C'},
                {'id': 'gpu.temp', 'label': 'GPU temperature', 'group': 'Graphics', 'detail': '61 °C'},
            ],
            'panels.tiles.sensor': [{'id': 'gpu.temp', 'label': 'Graphics heat'}],
        }
        setup['choiceRevisions'] = {'panels.sensor': 1, 'panels.tiles.sensor': 1}
        page.evaluate("async () => (await import('/static/plugin_setup.js')).refreshPluginSetup('monitor')")
        expect(rows.first.locator('.name')).to_have_text('CPU temperature')

        # The row editor picks from the same choices, with Refresh beside them.
        rows.first.click()
        modal = page.locator('.modal-card')
        expect(modal.locator('.modal-title')).to_have_text('CPU temperature')
        sensor = modal.locator('.form-field:has-text("Sensor")').first
        expect(sensor.locator('.dp-field')).to_contain_text('CPU temperature')
        sensor.get_by_role('button', name='Refresh').click()
        assert setup_runs[-1] == {'id': 'monitor', 'target': 'choices', 'key': 'panels.sensor'}, setup_runs
        expect(sensor.locator('.plugin-setup-spinning')).to_have_count(1)
        sensor.locator('.dp-field').click()
        picker = page.locator('.dash-picker-card')
        expect(picker.locator('.ep-heading')).to_have_count(2)
        expect(picker).to_contain_text('61 °C')
        picker.get_by_text('GPU temperature', exact=True).click()
        expect(sensor.locator('.dp-field')).to_contain_text('GPU temperature')

        # Nested rows show their own field's labels, or an ID it lacks with
        # the warning.
        tiles = modal.locator('.plugin-list-box .plugin-list-row')
        expect(tiles.nth(0).locator('.name')).to_have_text('Graphics heat')
        expect(tiles.nth(1).locator('.name')).to_have_text('board.temp')
        tiles.nth(1).click()
        expect(modal.locator('.modal-title')).to_contain_text('board.temp')
        expect(modal.locator('.dp-missing')).to_be_visible()
        modal.get_by_role('button', name='Refresh').click()
        assert setup_runs[-1] == {'id': 'monitor', 'target': 'choices', 'key': 'panels.tiles.sensor'}, setup_runs
        modal.get_by_role('button', name='Cancel', exact=True).click()
        modal.get_by_role('button', name='Save', exact=True).click()
        expect(modal).to_have_count(0)
        assert saved[-1]['panels'][0]['sensor'] == 'gpu.temp', saved[-1]
        expect(rows.first.locator('.name')).to_have_text('GPU temperature')
        page.screenshot(path='/tmp/kiosk-plugin-list-choices.png', full_page=True)

        # A typed number saves on change, only a value the setting takes,
        # and shows why it does not take the rest.
        page.evaluate("(async () => (await import('/static/tabs.js')).showTab('plugins/thresholds', {refresh: false}))()")
        expect(page.locator('#pageTitle')).to_contain_text('Thresholds')
        root = page.locator('#tab-plugins > .subpage[data-subpage="thresholds"]')
        hot = root.locator('.row:has-text("Hot above")')
        number = hot.locator('input[type=number]')
        expect(hot.locator('input[type=range]')).to_have_count(0)
        expect(number).to_have_value('85')
        expect(hot.locator('.plugin-number')).to_contain_text('°C')
        error = hot.locator('.plugin-number-error')
        expect(error).to_be_hidden()
        count = len(saved)
        for text, reason in [('151', 'Numeric setting is outside its range'), ('90.25', 'Numeric setting does not match its step'),
                             ('', 'Expected a numeric setting')]:
            number.fill(text)
            expect(error).to_have_text(reason)
            number.press('Enter')
            assert len(saved) == count, saved[-1]
        number.fill('-12.5')
        expect(error).to_be_hidden()
        number.press('Enter')
        expect(number).to_have_value('-12.5')
        assert saved[-1] == {'hot': -12.5}, saved[-1]

        # In the row editor Save waits while the number is not valid, and
        # the row shows it with its unit.
        root.get_by_text('Add alert', exact=True).click()
        modal = page.locator('.modal-card')
        save = modal.get_by_role('button', name='Save', exact=True)
        modal.locator('.form-field:has-text("Name") input').fill('Frame rate')
        above = modal.locator('.form-field:has-text("Above") input[type=number]')
        expect(above).to_have_value('0')
        expect(save).to_be_enabled()
        above.fill('100001')
        expect(modal.locator('.plugin-number-error')).to_have_text('Numeric setting is outside its range')
        expect(modal.locator('.form-field:has-text("Above") .plugin-required')).to_be_hidden()
        expect(save).to_be_disabled()
        # A hidden field keeps its last valid number and does not hold Save.
        modal.locator('.row:has-text("Watch") .switch').click()
        expect(above).to_have_count(0)
        expect(save).to_be_enabled()
        modal.locator('.row:has-text("Watch") .switch').click()
        expect(above).to_have_value('100001')
        expect(save).to_be_disabled()
        above.fill('60.5')
        expect(modal.locator('.plugin-number-error')).to_have_text('Numeric setting does not match its step')
        expect(save).to_be_disabled()
        above.fill('60')
        expect(modal.locator('.plugin-number-error')).to_be_hidden()
        expect(save).to_be_enabled()
        save.click()
        expect(modal).to_have_count(0)
        assert saved[-1] == {'alerts': [{'name': 'Frame rate', 'watch': True, 'above': 60}]}, saved[-1]
        expect(root.locator('.plugin-list-row .desc')).to_have_text('60 fps')
        page.screenshot(path='/tmp/kiosk-plugin-list-numbers.png', full_page=True)

        # A switch that reveals rows updates the page in place: the other
        # rows keep their nodes, the scroll stays and the values the plugin
        # saved itself show.
        page.set_viewport_size({'width': 1280, 'height': 420})
        page.evaluate("(async () => (await import('/static/tabs.js')).showTab('plugins/clock', {refresh: false}))()")
        expect(page.locator('#pageTitle')).to_contain_text('Clock')
        root = page.locator('#tab-plugins > .subpage[data-subpage="clock"]')
        summary = root.get_by_role('textbox', name='Summary')
        expect(summary).to_have_value('Plain')
        expect(root.get_by_text('Face color', exact=True)).to_have_count(0)
        expect(root.get_by_text('Accents', exact=True)).to_have_count(0)
        tag = '''(tag) => {
          const page = [...document.querySelectorAll('#tab-plugins > .subpage')].find((el) => el.dataset.subpage === 'clock');
          const rows = [page, ...['label', 'size'].map((key) => page.querySelector(`[data-setting-key="${key}"]`))];
          if (tag) rows.forEach((row) => { row.kept = true; });
          return rows.every((row) => row && row.kept === true);
        }'''
        assert page.evaluate(tag, True)
        root.locator('.row:has-text("Custom colors") .switch').scroll_into_view_if_needed()
        page.evaluate('document.scrollingElement.scrollTop = document.scrollingElement.scrollTop + 60')
        scroll = page.evaluate('document.scrollingElement.scrollTop')
        assert scroll > 0, scroll
        root.locator('.row:has-text("Custom colors") .switch').click()
        expect(root.get_by_text('Face color', exact=True)).to_be_visible()
        expect(summary).to_have_value('Custom')
        expect(root.locator('.plugin-runtime-status')).to_have_text('Custom colors')
        assert saved[-1] == {'custom': True}, saved[-1]
        assert page.evaluate(tag, False), 'Saving a setting drew its page again'
        assert page.evaluate('document.scrollingElement.scrollTop') == scroll
        order = root.locator('.card:has([data-setting-key="label"]) > [data-setting-key]').evaluate_all('(rows) => rows.map((row) => row.dataset.settingKey)')
        assert order == ['label', 'custom', 'face', 'hands', 'size', 'summary'], order
        # The group a revealed row brings shows after the declared ones,
        # with its button closing it.
        titles = root.locator('.card-title').all_text_contents()
        assert titles == ['Look', 'Accents'], titles
        accents = root.locator('.card:has([data-setting-key="accent"]) > .row')
        expect(accents).to_have_count(2)
        expect(accents.last).to_contain_text('Preview colors')
        page.screenshot(path='/tmp/kiosk-plugin-in-place.png', full_page=True)

        # Turning it off takes the rows and their group out again.
        root.locator('.row:has-text("Custom colors") .switch').click()
        expect(root.get_by_text('Face color', exact=True)).to_have_count(0)
        expect(root.get_by_text('Accents', exact=True)).to_have_count(0)
        expect(root.get_by_text('Preview colors', exact=True)).to_have_count(0)
        expect(summary).to_have_value('Plain')
        assert page.evaluate(tag, False), 'Saving a setting drew its page again'
        assert page.evaluate('document.scrollingElement.scrollTop') == scroll

        # A value the plugin saves on its own shows in place too. A field
        # being typed in keeps its text.
        root.get_by_role('textbox', name='Label').fill('Typing')
        clock['values']['summary'] = 'Built'
        clock['values']['size'] = 7
        page.evaluate("async () => (await import('/static/live.js')).receiveUpdate('plugin-settings')")
        expect(summary).to_have_value('Built')
        expect(root.locator('.row:has-text("Size") input[type=range]')).to_have_value('7')
        expect(root.get_by_role('textbox', name='Label')).to_have_value('Typing')
        expect(root.get_by_role('textbox', name='Label')).to_be_focused()
        assert page.evaluate(tag, False) is False, 'The changed rows kept their old nodes'
        assert page.evaluate('''() => {
          const page = [...document.querySelectorAll('#tab-plugins > .subpage')].find((el) => el.dataset.subpage === 'clock');
          return page.kept === true && page.querySelector('[data-setting-key="label"]').kept === true;
        }''')

        # Duplicate turns the open row into a new one holding what the
        # editor shows, action included. Cancel then adds nothing, and Save
        # adds it after the others while the source row stays as saved.
        page.evaluate("(async () => (await import('/static/tabs.js')).showTab('plugins/commutes', {refresh: false}))()")
        expect(page.locator('#pageTitle')).to_contain_text('Commutes')
        rows = page.locator('#tab-plugins > .subpage[data-subpage="commutes"] .plugin-list-row')
        modal = page.locator('.modal-card')
        duplicate = modal.get_by_role('button', name='Duplicate', exact=True)
        before = len(saved)
        rows.first.click()
        duplicate.click()
        expect(modal.locator('.modal-title')).to_have_text('Add trip')
        modal.get_by_role('button', name='Cancel', exact=True).click()
        expect(modal).to_have_count(0)
        assert len(saved) == before, saved[-1]
        home = copy.deepcopy(commutes['values']['trips'][0])
        rows.first.click()
        # Duplicate sits beside Delete, ahead of Cancel and Save.
        names = modal.locator('.modal-foot button').all_inner_texts()
        assert names == ['Delete', 'Duplicate', 'Cancel', 'Save'], names
        modal.locator('.form-field:has-text("Label") input').fill('Away')
        duplicate.click()
        expect(modal.get_by_role('button', name='Delete', exact=True)).to_have_count(0)
        expect(duplicate).to_have_count(0)
        modal.get_by_role('button', name='Save', exact=True).click()
        expect(modal).to_have_count(0)
        assert saved[-1]['trips'] == [home, {**home, 'label': 'Away'}], saved[-1]

        # A nested row copies inside the editor, and Duplicate leaves once
        # the nested list is full.
        rows.nth(1).click()
        modal.locator('.plugin-list-box').get_by_text('Main St', exact=True).click()
        duplicate.click()
        expect(modal.locator('.modal-title')).to_contain_text('Add stop')
        modal.locator('.form-field:has-text("Name") input').fill('Oak Ave')
        modal.get_by_role('button', name='Done', exact=True).click()
        modal.locator('.plugin-list-box').get_by_text('Main St', exact=True).click()
        expect(modal.get_by_role('button', name='Delete', exact=True)).to_be_visible()
        expect(duplicate).to_have_count(0)
        modal.get_by_role('button', name='Back', exact=True).click()
        modal.get_by_role('button', name='Save', exact=True).click()
        assert saved[-1]['trips'][1]['stops'] == [{'name': 'Main St'}, {'name': 'Oak Ave'}], saved[-1]

        # A full list has no room for a copy.
        rows.first.click()
        duplicate.click()
        modal.get_by_role('button', name='Save', exact=True).click()
        expect(rows).to_have_count(3)
        rows.nth(1).click()
        expect(modal.get_by_role('button', name='Delete', exact=True)).to_be_visible()
        expect(duplicate).to_have_count(0)
        modal.get_by_role('button', name='Delete', exact=True).click()
        expect(rows).to_have_count(2)

        # A phone's footer keeps all four buttons inside the card.
        page.set_viewport_size({'width': 360, 'height': 740})
        rows.first.click()
        expect(duplicate).to_be_visible()
        assert page.evaluate('''() => {
          const foot = document.querySelector('.modal-card .modal-foot');
          const box = foot.getBoundingClientRect();
          return [...foot.querySelectorAll('button')].every((b) => {
            const r = b.getBoundingClientRect();
            return r.left >= box.left - 0.5 && r.right <= box.right + 0.5;
          });
        }''')
        page.screenshot(path='/tmp/kiosk-plugin-list-duplicate-phone.png')
        modal.get_by_role('button', name='Cancel', exact=True).click()
        assert not errors, errors
        browser.close()
finally:
    server.shutdown()
print('plugin list remote UI test passed')
