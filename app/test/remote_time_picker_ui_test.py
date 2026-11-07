"""The remote time picker counts 1 to 12 beside AM and PM when the alarms
use a 12-hour clock, and still answers "HH:mm"."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
from threading import Thread
from playwright.sync_api import sync_playwright, expect
APP = Path(__file__).resolve().parents[1]
ROOT = APP / 'remote-ui'
english = {k: v for p in (APP / 'l10n/source').glob('*_en.arb')
           for k, v in json.loads(p.read_text()).items() if not k.startswith('@')}
class Handler(SimpleHTTPRequestHandler):
 def log_message(self,*_):pass
server=ThreadingHTTPServer(('127.0.0.1',0),partial(Handler,directory=str(ROOT)))
Thread(target=server.serve_forever,daemon=True).start()
base=f'http://127.0.0.1:{server.server_port}'
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(headless=True,args=['--no-sandbox'])
  page=browser.new_page(viewport={'width':1200,'height':900})
  errors=[];page.on('pageerror',lambda error:errors.append(str(error)))
  html=(ROOT/'index.html').read_text().replace('<script type="module" src="static/main.js?v=__KSV__"></script>','')
  page.route(base+'/',lambda route:route.fulfill(body=html,content_type='text/html'))
  page.route('**/static/catalogs.js',lambda route:route.fulfill(body='export const catalogs = '+json.dumps({'en':english,'zh-CN':{}})+';',content_type='text/javascript'))
  page.route('**/api/**',lambda route:route.fulfill(json={'ok':True,'data':{}}))
  page.goto(base+'/')

  def pick(value,h12,language='en'):
   """Opens the picker on `value` and leaves it open; the answer lands in
   window.picked."""
   page.evaluate("""async ([value, h12, language]) => {
     (await import('/static/localization.js')).setLanguagePreference(language);
     const { pickTime } = await import('/static/widgets.js');
     window.picked = undefined;
     pickTime({ title: 'Time', value, h12 }).then((v) => { window.picked = v; });
   }""",[value,h12,language])
   expect(page.locator('.time-pick')).to_be_visible()

  def answer():
   page.wait_for_function('window.picked !== undefined')
   return page.evaluate('window.picked')

  digits=page.locator('.time-digits')
  period=page.locator('.time-period button')

  # 23:50 on a 12-hour clock reads 11, 50 and PM.
  pick('23:50',True)
  expect(digits.nth(0)).to_have_value('11')
  expect(digits.nth(1)).to_have_value('50')
  expect(period.filter(has_text='PM')).to_have_class('active')
  page.get_by_role('button',name='Set',exact=True).click()
  assert answer()=='23:50'

  # AM moves it to the morning; 12 AM is midnight and 12 PM is noon.
  pick('23:50',True)
  period.filter(has_text='AM').click()
  digits.nth(0).fill('12')
  page.get_by_role('button',name='Set',exact=True).click()
  assert answer()=='00:50'
  pick('00:15',True)
  expect(digits.nth(0)).to_have_value('12')
  expect(period.filter(has_text='AM')).to_have_class('active')
  period.filter(has_text='PM').click()
  page.get_by_role('button',name='Set',exact=True).click()
  assert answer()=='12:15'

  # 0 and 13 are not hours on a 12-hour clock.
  pick('07:00',True)
  digits.nth(0).fill('0')
  expect(page.get_by_role('button',name='Set',exact=True)).to_be_disabled()
  digits.nth(0).fill('13')
  expect(page.get_by_role('button',name='Set',exact=True)).to_be_disabled()
  # The chevrons wrap from 12 to 1.
  digits.nth(0).fill('12')
  page.locator('.time-col').nth(0).get_by_role('button',name='Up').click()
  expect(digits.nth(0)).to_have_value('1')
  page.get_by_role('button',name='Cancel',exact=True).click()
  assert answer() is None

  # Chinese puts the period before the hour.
  pick('16:05',True,'zh-CN')
  first=page.locator('.time-pick > *').first
  expect(first).to_have_class('time-period')
  expect(period.nth(1)).to_have_class('active')
  page.get_by_role('button',name='Set',exact=True).click()
  assert answer()=='16:05'

  # The 24-hour picker is as it was: two boxes, 0 to 23.
  pick('23:50',False)
  expect(page.locator('.time-period')).to_have_count(0)
  expect(digits.nth(0)).to_have_value('23')
  page.get_by_role('button',name='Set',exact=True).click()
  assert answer()=='23:50'

  # The box writes the value the way `format` says and keeps "HH:mm".
  shown=page.evaluate("""async () => {
    const { timeBox } = await import('/static/widgets.js');
    const box = timeBox({ title: 'Time', value: '23:50', onPick() {},
      format: (v) => v === '23:50' ? '11:50 PM' : v });
    return [box.el.textContent, box.value];
  }""")
  assert shown==['11:50 PM','23:50'],shown

  assert not errors,errors
  browser.close()
finally:
 server.shutdown()
print('remote time picker ok')
