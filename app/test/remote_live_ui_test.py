"""Browser checks against the server started by remote_browser_test.dart."""
import json
import hashlib
import ssl
from pathlib import Path
import sys
from playwright.sync_api import sync_playwright, expect

base = sys.argv[1]
with sync_playwright() as playwright:
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context(viewport={"width": 1400, "height": 1000}, locale='en-US', ignore_https_errors=True)
    response = context.request.post(base + '/api/login', data=json.dumps({'password': 'secret'}))
    token = response.json()['token']
    context.add_init_script('localStorage.setItem("ks_token", ' + json.dumps(token) + ')')
    page = context.new_page()
    errors = []
    page.on('pageerror', lambda error: errors.append(str(error)))
    frames = []
    page.on('websocket', lambda socket: socket.on('framesent', lambda frame: frames.append(json.loads(frame))))
    boot_requests = []
    page.on('request', lambda request: boot_requests.append(request.url))
    page.goto(base + '/#camera/RTSP%20&%20ONVIF%20Streaming')
    expect(page.locator('#app')).to_be_visible(timeout=30000)
    # The boot reads everything through the socket: the only HTTP calls
    # are the public setup probe, the page and its static files and the
    # one-shot screenshot.
    polled = [url for url in boot_requests if any(part in url for part in
        ('/api/info', '/api/settings', '/api/commands/', '/api/console', '/api/logs'))]
    assert not polled, polled
    assert [frame for frame in frames if frame.get('type') == 'get' and frame.get('name') == 'info'], frames
    assert not [frame for frame in frames if frame.get('type') == 'get' and frame.get('name') == 'settings'], frames
    expect(page).to_have_url(base + '/#camera/rtsp-onvif-streaming')
    expect(page.locator('#pageTitle')).to_have_text('RTSP & ONVIF Streaming')
    expect(page.locator('#connDot')).to_have_class('dot on')
    requests = []
    page.on('request', lambda request: requests.append(request.url))

    def change(key, value):
        result = context.request.post(base + '/api/commands/testSetSetting',
            headers={'Authorization': 'Bearer ' + token},
            data=json.dumps({'key': key, 'value': value}))
        assert result.json()['ok'] and result.json()['data'] is True, result.text()

    # A device language change repaints the open admin without a page reload.
    page.locator('#tabs button[data-tab="device"]').click()
    name = page.locator('[data-key="device.name"] .name')
    language = page.locator('[data-key="ui.language"] select')
    expect(name).to_have_text('Device name')
    page.evaluate('window.languageTestMarker = true')
    change('ui.language', 'es')
    expect(name).to_have_text('Nombre del dispositivo')
    expect(language).to_have_value('es')
    assert page.evaluate('window.languageTestMarker') is True
    # The saved choice also wins over an English browser on a fresh load.
    page.reload()
    expect(name).to_have_text('Nombre del dispositivo')
    # Camera Streams must keep translated text after its settings read and live refresh.
    page.evaluate("""async () => {
      const url = performance.getEntriesByType('resource').find(r => r.name.includes('/catalogs.js')).name;
      const {catalogs} = await import(url);
      catalogs.es.cameraStreamsServers = 'TEST servidores';
      catalogs.es.settingCameraAllowH265Title = 'TEST codec';
    }""")
    page.locator('#tabs button[data-tab="cameras"]').click()
    camera_servers = page.locator('#tab-cameras .card-title').filter(has_text='TEST servidores')
    expect(camera_servers).to_be_visible()
    camera_codec = page.locator('#tab-cameras [data-key="camera.allow_h265"] .name')
    expect(camera_codec).to_have_text('TEST codec')
    change('camera.allow_h265', True)
    expect(page.locator('#tab-cameras [data-key="camera.allow_h265"] input')).to_be_checked()
    change('camera.allow_h265', False)
    expect(page.locator('#tab-cameras [data-key="camera.allow_h265"] input')).not_to_be_checked()
    page.wait_for_timeout(500)
    expect(camera_servers).to_be_visible()
    expect(camera_codec).to_have_text('TEST codec')
    change('ui.language', 'en')
    expect(page.locator('#tab-cameras .card-title').filter(has_text='Go2RTC servers')).to_be_visible()
    change('ui.language', 'es')
    expect(camera_servers).to_be_visible()
    expect(camera_codec).to_have_text('TEST codec')
    # Gestures renders from the subscription cache, including language and edits.
    page.evaluate("""async () => {
      const url = performance.getEntriesByType('resource').find(r => r.name.includes('/catalogs.js')).name;
      const {catalogs} = await import(url);
      catalogs.es.gestureEmpty = 'TEST sin gestos';
      catalogs.es.settingClapStrictnessTitle = 'TEST palmadas';
      catalogs.es.gestureOpenApp = 'TEST abrir {package}';
    }""")
    reads_before = len([f for f in frames if f.get('type') == 'get' and f.get('name') == 'settings'])
    page.locator('#tabs button[data-tab="gestures"]').click()
    gestures = page.locator('#tab-gestures')
    expect(gestures.get_by_text('TEST sin gestos', exact=True)).to_be_visible()
    gesture_detection = gestures.locator('[data-key="gestures.clap_strictness"] .name')
    expect(gesture_detection).to_have_text('TEST palmadas')
    change('gestures.clap_strictness', 'strict')
    expect(gestures.locator('select')).to_have_value('strict')
    mapped = [{'id':'original', 'trigger':{'type':'claps','claps':2},
               'action':{'type':'launch_app','package':'com.example.KeepCase'}}]
    change('gestures.mappings', json.dumps(mapped))
    expect(gestures.get_by_text('TEST abrir com.example.KeepCase', exact=True)).to_be_visible()
    for locale, text in [('en','Open app com.example.KeepCase'), ('es','TEST abrir com.example.KeepCase')]:
        change('ui.language', locale)
        expect(gestures.get_by_text(text, exact=True)).to_be_visible()
        page.locator('#tabs button[data-tab="launcher"]').click()
        page.locator('#tabs button[data-tab="gestures"]').click()
        expect(gestures.get_by_text(text, exact=True)).to_be_visible()
    page.wait_for_timeout(500)
    expect(gesture_detection).to_have_text('TEST palmadas')
    assert len([f for f in frames if f.get('type') == 'get' and f.get('name') == 'settings']) == reads_before
    change('gestures.mappings', '[]')
    expect(gestures.get_by_text('TEST sin gestos', exact=True)).to_be_visible()
    page.locator('#tabs button[data-tab="device"]').click()
    # Changing the dropdown in this browser applies the new language too.
    language.select_option('en')
    expect(name).to_have_text('Device name')
    language.select_option('es')
    expect(name).to_have_text('Nombre del dispositivo')
    expect(language.locator('option[value="system"]')).to_have_count(0)
    language.select_option('en')
    expect(name).to_have_text('Device name')

    page.locator('#tabs button[data-tab="screensaver"]').click()
    mode = page.locator('[data-key="screensaver.mode"] select')
    expect(mode).to_be_visible()
    change('screensaver.mode', 'black')
    expect(mode).to_have_value('black')
    change('screensaver.mode', 'clock')
    expect(mode).to_have_value('clock')
    expect(page.locator('[data-subpage-entry="Clock screensaver"]')).to_be_visible()

    # Visiting a page that reads settings must not disconnect existing sliders.
    page.locator('#tabs button[data-tab="gestures"]').click()
    expect(page.locator('[data-key="gestures.clap_strictness"]')).to_be_visible()
    page.locator('#tabs button[data-tab="sendspin"]').click()
    duck_row = page.locator('[data-key="sendspin.duck_percent"]')
    duck = duck_row.locator('input[type="range"]')
    expect(duck).to_have_value('10')
    duck_row.evaluate('row => row.dataset.preserved = "yes"')
    change('sendspin.duck_percent', 0)
    expect(duck).to_have_value('0')
    expect(duck_row.locator('.slider-value')).to_have_text('0%')
    expect(duck).to_have_css('--pct', '0.00%')
    expect(duck_row).to_have_attribute('data-preserved', 'yes')
    page.locator('#tabs button[data-tab="cameras"]').click()
    expect(page.locator('#tab-cameras').get_by_text('Import cameras from Home Assistant', exact=True)).to_be_visible()
    page.locator('#tabs button[data-tab="sendspin"]').click()
    frames.clear()
    change('sendspin.duck_percent', 5)
    expect(duck).to_have_value('5')
    expect(duck_row.locator('.slider-value')).to_have_text('5%')
    expect(duck).to_have_css('--pct', '50.00%')
    expect(duck_row).to_have_attribute('data-preserved', 'yes')
    assert not [frame for frame in frames if frame.get('type') == 'settings'], frames

    # The player field must follow both the chosen ID and source.
    page.locator('#tabs button[data-tab="sendspin"]').click()
    player = page.locator('[data-key="sendspin.player"] .ep-field .dp-field-text')
    expect(player).to_have_text('First speaker')
    change('sendspin.player', 'ha:media_player.second')
    expect(player).to_have_text('Second speaker')
    # A player the source no longer lists keeps the name it was saved with.
    change('sendspin.player_name', 'Unlisted speaker')
    change('sendspin.player', 'ha:media_player.unlisted')
    expect(player).to_have_text('Unlisted speaker')
    change('sendspin.player_name', 'Second speaker renamed')
    expect(page.locator('.player-warn')).to_contain_text('Second speaker renamed')
    # A source change swaps pages in place: the rest of the page stays.
    page.locator('[data-key="sendspin.duck_percent"]').evaluate('el => el.dataset.sourceKept = "yes"')
    change('sendspin.player_source', '')
    expect(page.locator('#tab-sendspin [data-subpage-entry="Sendspin Player"]')).to_have_count(1)
    expect(page.locator('[data-key="sendspin.duck_percent"]')).to_have_attribute('data-source-kept', 'yes')
    change('sendspin.player_source', 'ma')
    expect(page.locator('[data-key="sendspin.player_source"] select')).to_have_value('ma')
    expect(page.locator('#tab-sendspin [data-subpage-entry="Sendspin Player"]')).to_have_count(0)
    expect(page.locator('[data-key="sendspin.duck_percent"]')).to_have_attribute('data-source-kept', 'yes')
    change('sendspin.player', 'ma:media_player.second')
    expect(player).to_have_text('Second speaker')

    # Other sections stay in place.
    page.locator('[data-key="sendspin.duck_percent"]').evaluate('el => el.dataset.kept = "yes"')
    change('sendspin.player_name', 'Office')
    expect(page.locator('.player-warn')).to_contain_text('Office')
    expect(page.locator('[data-key="sendspin.duck_percent"]')).to_have_attribute('data-kept', 'yes')
    # A followed group this device is in keeps the Sendspin player on, so
    # the warning leaves without the page rebuilding (issue #1334).
    change('sendspin.kept_for', 'ma:media_player.second')
    expect(page.locator('.player-warn')).to_have_count(0)
    expect(page.locator('[data-key="sendspin.duck_percent"]')).to_have_attribute('data-kept', 'yes')
    change('sendspin.kept_for', 'ma:another')
    expect(page.locator('.player-warn')).to_contain_text('Office')
    change('sendspin.kept_for', '')

    def route(path):
        page.evaluate('(path) => { location.hash = path; }', path)

    # Every Media Player subpage, including dependent controls.
    for path, key, value, kind in [
        ('sendspin/floating-player', 'sendspin.show_player', True, 'checkbox'),
        ('sendspin/floating-player', 'sendspin.player_size', 'large', 'select'),
        ('sendspin/now-playing', 'sendspin.fullscreen', True, 'checkbox'),
        ('sendspin/now-playing', 'sendspin.fullscreen_text_scale', 120, 'range'),
        ('sendspin/now-playing', 'sendspin.audio_quality', True, 'checkbox'),
        ('sendspin/music-assistant', 'sendspin.ma_open_fullscreen', True, 'checkbox'),
        ('sendspin/music-assistant', 'sendspin.ma_inputs', True, 'checkbox'),
        ('sendspin/lyrics', 'sendspin.lyrics_enabled', True, 'checkbox'),
        ('sendspin/lyrics', 'sendspin.lyrics_source', 'ma', 'select'),
        ('sendspin/sonos', 'sendspin.sonos_inputs', True, 'checkbox'),
    ]:
        change(key, value)
        route(path)
        control = page.locator(f'[data-key="{key}"] ' + ('select' if kind == 'select' else f'input[type="{kind}"]'))
        expect(page.locator(f'[data-key="{key}"]')).to_be_visible()
        if kind == 'checkbox': expect(control).to_be_checked()
        else: expect(control).to_have_value(str(value))

    # Writes from another admin use the same socket path and update peers.
    peer = context.new_page()
    peer.goto(base + '/#sendspin/lyrics')
    expect(peer.locator('[data-key="sendspin.lyrics_source"] select')).to_have_value('ma')
    route('sendspin/lyrics')
    page.locator('[data-key="sendspin.lyrics_source"] select').select_option('lrclib')
    expect(peer.locator('[data-key="sendspin.lyrics_source"] select')).to_have_value('lrclib')
    expect(peer.locator('[data-key="sendspin.lyrics_fallback_ma"]')).to_be_visible()
    expect(page.locator('[data-key="sendspin.lyrics_fallback_ma"]')).to_be_visible()
    peer.close()
    route('sendspin/sonos')

    change('sendspin.sonos_hosts', json.dumps({'room': {'name': 'Kitchen Sonos', 'host': '192.0.2.3'}}))
    expect(page.locator('.sonos-speakers')).to_contain_text('Kitchen Sonos')
    change('sendspin.sonos_hosts', '{}')
    expect(page.locator('.sonos-speakers')).to_contain_text('No speakers yet')

    # Hand-built summaries, color pickers and dependent sections elsewhere.
    change('screensaver.mode', 'clock')
    route('screensaver/clock-screensaver')
    change('screensaver.clock_color', '10,20,30')
    expect(page.locator('[data-key="screensaver.clock_color"] .swatch')).to_have_css('background-color', 'rgb(10, 20, 30)')
    change('launcher.enabled', True)
    route('launcher')
    change('launcher.apps', json.dumps([{'package': 'example.app', 'label': 'Example app'}]))
    expect(page.locator('[data-key="launcher.apps"]')).to_contain_text('Example app')
    change('launcher.auto_return', True)
    expect(page.locator('#tab-launcher').get_by_text('Required system permissions', exact=True)).to_be_visible()
    change('launcher.auto_return', False)
    expect(page.locator('#tab-launcher').get_by_text('Required system permissions', exact=True)).to_be_hidden()
    route('screenaudio')
    context.request.post(base + '/api/commands/testAudioConnected', headers={'Authorization': 'Bearer ' + token}, data='{}')
    expect(page.locator('[data-key="audio.speaker_device"] option[value="usb|1|USB Speaker"]')).to_have_count(1)
    change('audio.speaker_device', 'usb|1|USB Speaker')
    expect(page.locator('[data-key="audio.speaker_device"] select')).to_have_value('usb|1|USB Speaker')
    change('dlna.enabled', True)
    route('dlna')
    change('dlna.audio_background', True)
    expect(page.locator('[data-key="dlna.audio_background"] input')).to_be_checked()
    route('browser')
    change('browser.zoom', 1.25)
    expect(page.locator('[data-key="browser.zoom"] input')).to_have_value('1.25')

    # A device update must not throw away an unfinished text edit.
    page.locator('#tabs button[data-tab="browser"]').click()
    field = page.locator('[data-key="browser.inject_js"] textarea')
    expect(field).to_be_visible()
    field.fill('window.unfinishedDraft = true;')
    change('screensaver.mode', 'black')
    expect(field).to_have_value('window.unfinishedDraft = true;')
    expect(field).to_be_focused()

    # Reconnect reads changes made while this browser had no event feed.
    context.set_offline(True)
    page.evaluate("""async () => {
      const url = performance.getEntriesByType('resource')
        .find(entry => new URL(entry.name).pathname === '/static/core.js').name;
      (await import(url)).state.ws.close();
    }""")
    expect(page.locator('#connDot')).to_have_class('dot off')
    # A dropped connection covers the page until the socket is back.
    expect(page.locator('.reconnect-back')).to_be_visible()
    expect(page.locator('.reconnect-back .modal-title')).to_have_text(page.evaluate("async () => (await import(performance.getEntriesByType('resource').find(r => new URL(r.name).pathname === '/static/localization.js').name)).t('remoteReconnecting')"))
    expect(page.locator('.reconnect-back')).to_contain_text('Test kiosk')
    # Browser contexts also take their request client offline, so use a
    # separate client while this one has no network.
    import urllib.request
    req = urllib.request.Request(base + '/api/commands/testSetSetting',
        data=json.dumps({'key': 'screensaver.mode', 'value': 'clock'}).encode(),
        headers={'Authorization': 'Bearer ' + token})
    with urllib.request.urlopen(req) as response:
        assert json.load(response)['ok']
    context.set_offline(False)
    expect(page.locator('#connDot')).to_have_class('dot on', timeout=30000)
    expect(page.locator('.reconnect-back')).to_have_count(0)
    page.locator('#tabs button[data-tab="screensaver"]').click()
    expect(page.locator('[data-key="screensaver.mode"] select')).to_have_value('clock')
    page.wait_for_timeout(1000)
    requests.clear()
    frames.clear()
    page.wait_for_timeout(6000)
    assert not [frame for frame in frames if frame.get('type') in ('command', 'settings')], frames
    assert not [url for url in requests if '/api/commands/' in url or '/api/settings' in url], requests

    # A settings flip repaints the Overview's tiles from the cache. Only a
    # setting a status command reads (the HA link) re-reads, and only that
    # one source.
    page.locator('#tabs button[data-tab="dashboard"]').click()
    expect(page.locator('#statusGrid [data-status="ha"]')).to_be_visible()
    page.wait_for_timeout(1500)
    frames.clear()
    change('screen.keep_on', True)
    change('browser.zoom', 1.1)
    page.wait_for_timeout(1500)
    assert not [f for f in frames if f.get('type') == 'command'], frames
    change('ha.url', 'http://ha.example/')
    page.wait_for_timeout(1500)
    assert [f.get('name') for f in frames if f.get('type') == 'command'] == ['haStatus'], frames

    # TLS has its own Device page and uses the shared copy control and dialog.
    page.locator('#tabs button[data-tab="device"]').click()
    entries = page.locator('#device-pages [data-subpage-entry]').evaluate_all(
        '(nodes) => nodes.map(node => node.dataset.subpageEntry)')
    assert entries[entries.index('Remote Administration') + 1] == 'TLS', entries
    page.locator('#device-pages [data-subpage-entry="TLS"]').click()
    expect(page).to_have_url(base + '/#device/tls')
    tls = page.locator('#tab-device .subpage[data-subpage="TLS"]')
    fingerprint = hashlib.sha256(ssl.PEM_cert_to_DER_cert(Path('test/fixtures/tls/cert.pem').read_text())).hexdigest()
    expect(tls.locator('.copy-box .copy-value')).to_have_text(fingerprint)
    assert '[object Object]' not in tls.inner_text()
    assert 'Trusted kiosks' not in tls.inner_text()
    assert 'Use HTTPS' not in tls.inner_text()
    assert 'Encrypt camera stream' not in tls.inner_text()
    assert 'HTTPS and encrypted RTSP share this certificate.' not in tls.inner_text()
    expect(tls.get_by_role('button', name='Import', exact=True)).to_be_disabled()
    tls.get_by_role('button', name='Replace', exact=True).click()
    confirm = page.locator('.modal-card')
    expect(confirm.locator('.modal-title')).to_have_text('Replace certificate')
    expect(confirm.locator('.btn-primary')).to_have_text('Replace')
    confirm.get_by_role('button', name='Cancel', exact=True).click()

    # The app restarted on a new build: the reconnect's snapshot names it,
    # the page says so and reloads itself onto the new bundle.
    context.request.post(base + '/api/commands/testSetVersion',
        headers={'Authorization': 'Bearer ' + token}, data=json.dumps({'version': '2026.9.59'}))
    page.evaluate("""async () => {
      const url = performance.getEntriesByType('resource')
        .find(entry => new URL(entry.name).pathname === '/static/core.js').name;
      (await import(url)).state.ws.close();
    }""")
    notice = page.locator('.modal-card')
    expect(notice).to_contain_text('2026.9.59', timeout=15000)
    expect(notice.locator('.modal-title')).to_have_text(page.evaluate("async () => (await import(performance.getEntriesByType('resource').find(r => new URL(r.name).pathname === '/static/localization.js').name)).t('remoteUpdated')"))
    expect(notice).to_have_count(0, timeout=15000)
    expect(page.locator('#app')).to_be_visible(timeout=30000)
    page.wait_for_timeout(2500)
    expect(page.locator('.modal-card')).to_have_count(0)
    assert page.evaluate("""async () => {
      const url = performance.getEntriesByType('resource')
        .find(entry => new URL(entry.name).pathname === '/static/core.js').name;
      return (await import(url)).state.appVersion;
    }""") == '2026.9.59+259'
    # Protocol changes wait for confirmation, then navigate both directions.
    peer.close()
    route('device/remote-administration')
    https_toggle = page.locator('[data-key="remote.tls"] input')
    page.locator('[data-key="remote.tls"] .switch').click()
    dialog = page.locator('.modal-card')
    secure_url = base.replace('http:', 'https:') + '/#device/remote-administration'
    expect(dialog.locator('.copy-value')).to_have_text(secure_url)
    assert dialog.locator('.copy-value').evaluate('(n) => n.scrollWidth <= n.clientWidth'), 'Destination address is clipped'
    expect(dialog.get_by_role('button', name='Confirm', exact=True)).to_be_visible()
    dialog.get_by_role('button', name='Cancel', exact=True).click()
    expect(https_toggle).not_to_be_checked()
    expect(page).to_have_url(base + '/#device/remote-administration')
    page.evaluate("""() => {
      const url = performance.getEntriesByType('resource')
        .find(entry => new URL(entry.name).pathname === '/static/core.js').name;
      import(url).then(module => module.cmd('testSlowCommand'));
    }""")
    page.wait_for_timeout(100)
    page.locator('[data-key="remote.tls"] .switch').click()
    page.locator('.modal-card').get_by_role('button', name='Confirm', exact=True).click()
    expect(page).to_have_url(secure_url, timeout=15000)
    expect(page.locator('#app')).to_be_visible(timeout=30000)
    expect(page.locator('[data-key="remote.tls"] input')).to_be_checked()
    page.wait_for_timeout(1000)
    # Exercise protocol changes over the HTTP fallback as well as WebSocket.
    page.evaluate("""async () => {
      const resource = name => performance.getEntriesByType('resource')
        .find(entry => new URL(entry.name).pathname === '/static/' + name + '.js').name;
      (await import(resource('transport'))).detachSocket();
      (await import(resource('core'))).state.ws = null;
    }""")
    page.locator('[data-key="remote.tls"] .switch').click()
    dialog = page.locator('.modal-card')
    expect(dialog.locator('.copy-value')).to_have_text(base + '/#device/remote-administration')
    dialog.get_by_role('button', name='Confirm', exact=True).click()
    expect(page).to_have_url(base + '/#device/remote-administration', timeout=15000)
    expect(page.locator('#app')).to_be_visible(timeout=30000)
    expect(page.locator('[data-key="remote.tls"] input')).not_to_be_checked()
    assert not errors, errors
    browser.close()
    print('Live settings across Media Player and other sections, peer writes, audio events, drafts, reconnects and idle traffic passed')
