"""Onboarding language changes preserve drafts and use only the setup endpoint."""
import json
from pathlib import Path
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from threading import Thread
from playwright.sync_api import sync_playwright, expect
APP=Path(__file__).resolve().parents[1]
ROOT=APP/'remote-ui'
catalogs={p.stem.removeprefix('ui_').replace('_','-'):{k:v for k,v in json.loads(p.read_text()).items() if not k.startswith('@')} for p in (APP/'l10n/effective').glob('ui_*.arb')}
names=json.loads((APP/'l10n/vendor/metadata/languages.json').read_text())
# A regional language such as zh-CN also has a base catalog (zh) for
# gen-l10n. It has no name and is not a choice in the picker.
languages=[{'value':tag,'label':names[tag]} for tag in sorted(catalogs) if tag in names]
en=catalogs['en'];es=catalogs['es']
requests=[];saved='en';failure=False
class Handler(SimpleHTTPRequestHandler):
    def log_message(self,*_):pass
server=ThreadingHTTPServer(('127.0.0.1',0),partial(Handler,directory=str(ROOT)))
Thread(target=server.serve_forever,daemon=True).start();base=f'http://127.0.0.1:{server.server_port}'
def api(route):
    global saved
    path=route.request.url.split('/api/',1)[1]
    data=route.request.post_data_json or {}
    requests.append((path,data,route.request.headers.get('authorization')))
    if path=='setup/status':return route.fulfill(json={'setupNeeded':True,'passwordNeeded':True,'language':saved,'deviceName':'Original device','languages':languages})
    if path=='setup/language':
        assert data.keys()=={'language'}
        if failure:return route.fulfill(status=500,json={'error':'internal error'})
        saved=data['language'];return route.fulfill(json={'language':saved})
    if path=='setup/grants':return route.fulfill(json={'permissions':{},'grants':{}})
    return route.fulfill(json={'ok':True,'data':{'grants':{}}})
try:
    with sync_playwright() as p:
        browser=p.chromium.launch(headless=True,args=['--no-sandbox'])
        page=browser.new_page(viewport={'width':390,'height':1000})
        errors=[];page.on('pageerror',lambda e:errors.append(str(e)))
        html=(ROOT/'index.html').read_text().replace('<script type="module" src="static/main.js?v=__KSV__"></script>','')
        page.route(base+'/',lambda r:r.fulfill(body=html,content_type='text/html'))
        page.route('**/api/**',api)
        page.goto(base+'/')
        page.evaluate("async()=>await (await import('/static/wizard.js')).startWizard({needPassword:true})")
        select=page.locator('#wzLanguage')
        expect(select).to_have_value('en')
        assert select.locator('option').all_text_contents()==[language['label'] for language in languages]
        assert select.bounding_box()['y']<page.locator('#wzDeviceName').bounding_box()['y']
        page.locator('#wzDeviceName').fill('Unsaved <device>')
        page.locator('#wzPassword').fill('Unsaved-password')
        for tag in ['de','fr','it','nl','uk']:
            select.select_option(tag)
            expect(page.locator('#wizardTitle')).to_have_text(catalogs[tag]['remoteWelcomeTitle'])
            assert page.locator('#wizardBrandTitle').inner_html()==catalogs[tag]['setupTitle'].replace('\n','<br>')
            expect(select).to_have_value(tag)
            expect(page.locator('#wzDeviceName')).to_have_value('Unsaved <device>')
            expect(page.locator('#wzPassword')).to_have_value('Unsaved-password')
            assert ('setup/language',{'language':tag},None) in requests
            assert page.evaluate('document.documentElement.scrollWidth<=innerWidth')
        select.select_option('es')
        expect(page.locator('#wizardTitle')).to_have_text(es['remoteWelcomeTitle'])
        expect(select).to_have_value('es')
        expect(page.locator('#wzDeviceName')).to_have_value('Unsaved <device>')
        expect(page.locator('#wzPassword')).to_have_value('Unsaved-password')
        assert ('setup/language',{'language':'es'},None) in requests
        assert not any(path in ('settings','setup/password') for path,_,_ in requests)
        assert page.evaluate('document.documentElement.scrollWidth<=innerWidth')
        failure=True
        select.select_option('en')
        expect(page.locator('#wizardError')).to_contain_text(es['commonSaveFailed'])
        expect(select).to_have_value('es')
        expect(page.locator('#wzDeviceName')).to_have_value('Unsaved <device>')
        expect(page.locator('#wzPassword')).to_have_value('Unsaved-password')
        expect(page.locator('#wizardNext')).to_be_enabled()
        failure=False
        page.evaluate("async()=>{(await import('/static/core.js')).state.token='fixture-token';await (await import('/static/wizard.js')).startWizard({needPassword:false});}")
        expect(select).to_have_value('es')
        select.select_option('en')
        expect(page.locator('#wizardTitle')).to_have_text(en['remoteWelcomeTitle'])
        assert ('setup/language',{'language':'en'},'Bearer fixture-token') in requests
        assert not errors,errors
        browser.close()
finally:server.shutdown()
print('Onboarding language browser checks passed')
