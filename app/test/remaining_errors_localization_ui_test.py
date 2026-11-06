from pathlib import Path
from functools import partial
from http.server import SimpleHTTPRequestHandler,ThreadingHTTPServer
from threading import Thread
from playwright.sync_api import sync_playwright,expect
import json
app=Path(__file__).resolve().parents[1]
root=app/'remote-ui'
en={k:v for p in (app/'l10n/source').glob('*.arb') for k,v in json.loads(p.read_text()).items() if not k.startswith('@')}
es={k:v for p in (app.parents[1]/'kiosk-satellite-localization/translations/es').glob('*.arb') for k,v in json.loads(p.read_text()).items() if not k.startswith('@')}
calls=[]
class Handler(SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
server=ThreadingHTTPServer(('127.0.0.1',0),partial(Handler,directory=str(root)))
Thread(target=server.serve_forever,daemon=True).start();base=f'http://127.0.0.1:{server.server_port}'
html=(root/'index.html').read_text().replace('<script type="module" src="static/main.js?v=__KSV__"></script>','')
errors={'takeCameraSnapshot':'Camera permission not granted.','showCameraView':'view not found','installedApps':'could not list apps: PlatformException(E_TEST, original details, null, null)','previewPluginRepository':'Bad state: GitHub denied the request or its request limit was reached. Try again later.'}
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(headless=True,args=['--no-sandbox']);page=browser.new_page()
  page.route(base+'/',lambda r:r.fulfill(body=html,content_type='text/html'))
  page.route('**/static/catalogs.js',lambda r:r.fulfill(body='export const catalogs = '+json.dumps({'en':en,'es':es})+';',content_type='text/javascript'))
  def language(value):
   page.evaluate("async value=>(await import('/static/core.js')).cacheSettings([{key:'ui.language',value}])",value)
  def api(r):
   name=r.request.url.split('/api/')[-1].removeprefix('commands/')
   calls.append(name)
   if name in errors:return r.fulfill(json={'ok':False,'error':errors[name]})
   data={'cameraGetConfig':{'views':[{'id':'original','name':'Original view','cameraIds':['camera']}],'cameras':[{'id':'camera','name':'Original camera'}]},'getPluginState':{'enabled':True,'plugins':[]}}.get(name,{})
   r.fulfill(json={'ok':True,'data':data})
  page.route('**/api/**',api);page.goto(base+'/')
  page.evaluate("async()=>{const c=await import('/static/core.js');c.showView('app');c.cacheSettings([{key:'ui.language',value:'es'}]);await import('/static/overview.js');}")
  page.locator('#tileSnapshot').evaluate('(b)=>b.click()')
  expect(page.locator('.modal-body')).to_contain_text(es['cameraPermissionDenied'])
  assert page.locator('.modal-title').inner_text()!='Take snapshot'
  language('en')
  expect(page.locator('.modal-body')).to_contain_text(errors['takeCameraSnapshot'])
  language('es')
  assert calls.count('takeCameraSnapshot')==1
  page.locator('.modal-foot button').click()
  page.locator('#tileCameraView').evaluate('(b)=>b.click()')
  expect(page.locator('.modal-body')).to_contain_text(es['cameraStreamsViewNotFound'])
  page.locator('.modal-foot button').click()
  page.evaluate("async()=>{void(await import('/static/pickers.js')).openLauncherAppsPicker([]);}")
  expect(page.locator('.modal-body')).to_contain_text(es['launcherErrorListDetail'].replace('{error}','PlatformException(E_TEST, original details, null, null)'))
  language('en')
  expect(page.locator('.modal-body')).to_contain_text(errors['installedApps'])
  language('es')
  assert calls.count('installedApps')==1
  page.locator('.modal-foot button').first.click()
  page.evaluate("async()=>{(await import('/static/tabs.js')).showTab('plugins',{refresh:false});await(await import('/static/plugins.js')).loadPlugins();}")
  page.locator('[data-search-id="x:plugins:add"] button').click()
  page.locator('#plugin-repository-url').fill('https://github.com/example/example')
  page.locator('.modal-foot button').last.click()
  expect(page.locator('.toast-msg').last).to_have_text(es['pluginErrorGithubLimited'])
  assert calls.count('previewPluginRepository')==1
  page.route('**/api/commands/previewPluginRepository',lambda r:r.fulfill(json={'ok':True,'data':{'manifest':{'name':'Original <name>','description':'Author description','version':'1.2.3','author':'Original author','license':'MIT'},'compatible':False,'compatibilityError':'Plugin needs Android API 35','readme':'','previewId':'raw-preview'}}))
  page.locator('[data-search-id="x:plugins:add"] button').click()
  page.locator('#plugin-repository-url').fill('https://github.com/example/example')
  page.locator('.modal-foot button').last.click()
  expect(page.locator('.plugin-review-foot')).to_contain_text(es['pluginErrorAndroidApi'].replace('{version}','35'))
  expect(page.locator('.plugin-review-name')).to_have_text('Original <name>')
  expect(page.locator('.modal-foot button').last).to_be_disabled()
  language('en')
  expect(page.locator('.plugin-review-foot')).to_contain_text('Plugin needs Android API 35')
  language('es')
  expect(page.locator('.plugin-review-foot')).to_contain_text(es['pluginErrorAndroidApi'].replace('{version}','35'))
  expect(page.locator('.modal-foot button').last).to_be_disabled()
  page.locator('.modal-foot button').first.click()
  assert 'installPluginRepository' not in calls
  print('Snapshot, view, launcher and plugin failures localize without repeating operations.')
  browser.close()
finally:server.shutdown()
