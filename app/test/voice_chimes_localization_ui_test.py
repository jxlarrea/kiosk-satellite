"""Exercise localized chime selection, upload and preview in Remote Admin."""
import json
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread
from playwright.sync_api import sync_playwright, expect

APP = Path(__file__).resolve().parents[1]
ROOT = APP / 'remote-ui'
english = json.loads((APP / 'l10n/effective/ui_en.arb').read_text())
spanish = json.loads((APP / 'l10n/effective/ui_es.arb').read_text())
mapping = json.loads((APP / 'l10n/settings.json').read_text())
settings = [dict(key='ui.language', value='es', type='string', category='Device', hidden=True),
            dict(key='ha.url', value='http://ha.test', type='string', category='Home Assistant', title='Home Assistant URL', description='')]
for kind in ['wake', 'done', 'error', 'alert', 'announce']:
    key = 'voice_chimes.' + kind
    ids = mapping[key]
    settings.append(dict(key=key, value='', type='string', category='Voice Satellite', subpage='Chimes',
                         title=english[ids['title']], description=english[ids['description']],
                         titleMessageId=ids['title'], descriptionMessageId=ids['description']))
    ids = mapping[key + '_volume']
    settings.append(dict(key=key + '_volume', value=100, type='number', category='Voice Satellite', subpage='Chimes',
                         min=0, max=100, step=5, unit='%', default=100,
                         title=english[ids['title']], description=english[ids['description']],
                         titleMessageId=ids['title'], descriptionMessageId=ids['description']))
commands, writes, uploads = [], [], []
sounds = ['siren.mp3']


def api(route):
    path = route.request.url.split('/api/', 1)[1]
    if path == 'settings':
        if route.request.method == 'GET':
            return route.fulfill(json=dict(settings=settings, subpageHints={'Chimes': english['voiceChimesSoundsHint']}))
        values = route.request.post_data_json
        writes.append(values)
        for key, value in values.items():
            next(s for s in settings if s['key'] == key)['value'] = value
        return route.fulfill(json=dict(ok=True))
    if path.startswith('files/upload?'):
        uploads.append(path)
        sounds.append('new.mp3')
        return route.fulfill(json=dict(ok=True))
    name = path.removeprefix('commands/')
    params = route.request.post_data_json or {}
    commands.append((name, params))
    data = {
        'haStatus': dict(connected=True), 'haDetectVoiceSatellite': True,
        'vsControls': dict(satellite='', satellites=[], entities={}, browser=None),
        'getSystemPermissions': {}, 'getAudioDevices': dict(inputs=[], outputs=[]),
        'listNotificationSounds': dict(sounds=sounds), 'hasDeviceCamera': False,
    }.get(name, {})
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
        page = browser.new_page(viewport=dict(width=390, height=1000))
        errors = []
        page.on('pageerror', lambda error: errors.append(str(error)))
        html = (ROOT / 'index.html').read_text().replace('<script type="module" src="static/main.js?v=__KSV__"></script>', '')
        page.route(base + '/', lambda route: route.fulfill(body=html, content_type='text/html'))
        page.route('**/api/**', api)
        page.goto(base + '/')
        for language, catalog in [('es', spanish), ('en', english)]:
            settings[0]['value'] = language
            page.evaluate("""async () => {
                (await import('/static/core.js')).showView('app');
                await (await import('/static/settings.js')).loadSettings();
                (await import('/static/tabs.js')).showTab('voicesatellite/Chimes', {refresh:false});
            }""")
            panel = page.locator('#tab-voicesatellite .subpage[data-subpage="Chimes"]')
            expect(panel).to_be_visible()
            expect(page.locator('#pageTitle')).to_contain_text(catalog['voiceChimesPage'])
            expect(panel).not_to_contain_text(catalog['voiceChimesHelp'])
            expect(panel.locator(':scope > .hint-row')).to_have_count(0)
            expect(panel.locator('.row')).to_have_count(10)
            keys = panel.locator('.row[data-key]').evaluate_all('(rows) => rows.map((row) => row.dataset.key)')
            assert keys == [k for kind in ['wake', 'done', 'error', 'alert', 'announce']
                            for k in ('voice_chimes.' + kind, f'voice_chimes.{kind}_volume')], keys
            entries = page.locator('#tab-voicesatellite [data-subpage-entry]').evaluate_all(
                '(rows) => rows.map((row) => row.dataset.subpageEntry)')
            assert entries.index('Appearance') < entries.index('Chimes'), entries
            for kind in ['wake', 'done', 'error', 'alert', 'announce']:
                row = panel.locator(f'[data-key="voice_chimes.{kind}"]')
                expect(row).to_contain_text(catalog[mapping['voice_chimes.' + kind]['title']])
                expect(row).to_contain_text(catalog[mapping['voice_chimes.' + kind]['description']])
                volume = panel.locator(f'[data-key="voice_chimes.{kind}_volume"]')
                expect(volume).to_contain_text(catalog[mapping[f'voice_chimes.{kind}_volume']['title']])
                expect(volume).to_contain_text(catalog['voiceChimeVolumeDescription'])
                expect(volume.locator('input[type=range]')).to_have_count(1)
            expect(panel.get_by_role('button', name=catalog['voiceChimesPreview'], exact=True)).to_have_count(5)
            panel.get_by_role('button', name=catalog['voiceChimesPreview'], exact=True).first.click()
            page.wait_for_timeout(50)
            assert ('previewVoiceChime', {'kind': 'wake'}) in commands
            expect(panel.locator('.chime-controls')).to_have_count(5)
            panel.locator('.chime-controls > button').first.click()
            page.wait_for_timeout(50)
            assert commands[-1] == ('stopSound', {'id': 'voice-preview'})
            expect(panel.get_by_role('button', name=catalog['voiceChimesPreview'], exact=True)).to_have_count(5)
            panel.get_by_role('button', name=catalog['voiceChimesPreview'], exact=True).first.click()
            page.wait_for_timeout(50)
            page.evaluate("document.dispatchEvent(new CustomEvent('ks-event', {detail: {event: 'sound-ended', data: {id: 'voice-preview'}}}))")
            expect(panel.get_by_role('button', name=catalog['voiceChimesPreview'], exact=True)).to_have_count(5)
            page.screenshot(path=f'/tmp/chimes-remote-{language}-phone.png', full_page=True)
            page.set_viewport_size(dict(width=1440, height=1000))
            page.screenshot(path=f'/tmp/chimes-remote-{language}-desktop.png', full_page=True)
            page.set_viewport_size(dict(width=390, height=1000))
            assert page.evaluate('document.documentElement.scrollWidth <= innerWidth')
        row = panel.locator('[data-key="voice_chimes.alert"]')
        row.locator('select').select_option('siren.mp3')
        page.wait_for_timeout(50)
        assert writes[-1] == {'voice_chimes.alert': 'siren.mp3'}
        panel.locator('input[type=file]').nth(3).set_input_files(dict(name='new.mp3', mimeType='audio/mpeg', buffer=b'test'))
        expect(row.locator('select')).to_have_value('new.mp3')
        assert uploads and 'sounds%2Fnew.mp3' in uploads[-1]
        for select in panel.locator('select').all():
            expect(select.locator('option[value="new.mp3"]')).to_have_count(1)
        assert ('getVoiceChimeDurations', {}) in commands
        assert not errors, errors
        browser.close()
    print('Chime localization, selection, upload and preview browser checks passed')
finally:
    server.shutdown()
