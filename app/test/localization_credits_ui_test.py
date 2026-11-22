"""Exercise credits navigation and live language changes in Remote Admin."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread
import os

from playwright.sync_api import expect, sync_playwright

APP = Path(__file__).resolve().parents[1]
ROOT = APP / "remote-ui"


class Handler(SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass


server = ThreadingHTTPServer(("127.0.0.1", 0), partial(Handler, directory=str(ROOT)))
Thread(target=server.serve_forever, daemon=True).start()
base = f"http://127.0.0.1:{server.server_port}"
try:
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True, args=["--no-sandbox"])
        page = browser.new_page(viewport={"width": 390, "height": 1000})
        errors = []
        page.on("pageerror", lambda error: errors.append(str(error)))
        html = (ROOT / "index.html").read_text().replace(
            '<script type="module" src="static/main.js?v=__KSV__"></script>', "")
        page.route(base + "/", lambda route: route.fulfill(body=html, content_type="text/html"))

        def api(route):
            if route.request.url.endswith("/api/info"):
                return route.fulfill(json={"appVersion": "PREVIEW", "buildNumber": 263,
                                           "package": "me.jxl.kiosk_satellite", "buildMode": "release"})
            return route.fulfill(json={"ok": True, "data": {}})

        page.route("**/api/**", api)
        page.goto(base + "/#about/localization-credits")
        page.evaluate("""async () => {
          const core = await import('/static/core.js');
          core.showView('app');
          core.cacheSettings([{key:'ui.language',value:'fr'}]);
          const tabs = await import('/static/tabs.js');
          tabs.showTab('about/Localization Credits', {push:false});
        }""")
        credits = page.locator("#localization-credits")
        expect(credits).to_be_visible()
        german = page.evaluate("async () => 'de' in (await import('/static/catalogs.js')).catalogs")
        languages = [("English", "jxlarrea"), ("Español", "jxlarrea"), ("Français", "Limoniak")]
        if german:
            languages.insert(0, ("Deutsch", "Dee-san"))
        languages.append(("Nederlands", "rononline"))
        languages.append(("Polski", "ThePnx"))
        languages.append(("Русский", "MrYadro"))
        languages.append(("Українська", "kdinya"))
        languages.append(("简体中文", "panda-star357"))
        # Contributors credited under a name other than their login.
        credit_names = {"jxlarrea": "Xavier Larrea", "MrYadro": "Iaroslav Iadryshnikov"}
        expect(credits.locator("h2")).to_have_text([name for name, _ in languages])
        for index, (_, login) in enumerate(languages):
            names = [credit_names.get(login, login)]
            expect(credits.locator(".card").nth(index).locator(".name")).to_have_text(names)
            profile = credits.locator(".card").nth(index).get_by_role("link", name=login, exact=True)
            expect(profile).to_have_attribute("href", f"https://github.com/{login}")
            expect(profile).to_have_attribute("target", "_blank")
            expect(profile).to_have_attribute("rel", "noreferrer")
            expect(profile.locator("svg")).to_have_count(1)
        locales = [("fr", "Crédits de traduction"), ("en", "Localization Credits")]
        if not os.environ.get("KS_FRENCH_PREVIEW"):
            locales.append(("es", "Créditos de traducción"))
        if german:
            locales.append(("de", "Mitwirkende an der Übersetzung"))
        locales.append(("nl", "Vertalers"))
        locales.append(("pl", "Autorzy tłumaczeń"))
        locales.append(("ru", "Авторы локализации"))
        locales.append(("uk", "Автори перекладу"))
        locales.append(("zh-CN", "翻译贡献者"))
        locales.append(("fr", "Crédits de traduction"))
        for locale, title in locales:
            page.evaluate("""async locale => {
              (await import('/static/core.js')).cacheSettings([{key:'ui.language',value:locale}]);
              (await import('/static/tabs.js')).refreshNavigationText();
            }""", locale)
            expect(page.locator("#pageTitle")).to_have_text(title)
            page.locator("#pageTitle .title-back").click()
            entry = page.locator('#about-info [data-subpage-entry="Localization Credits"]')
            expect(entry.locator(".name")).to_have_text(title)
            expect(entry.locator(".desc")).to_have_count(0)
            assert page.locator("#about-info").evaluate("""root => {
              const entry = root.querySelector('[data-subpage-entry="Localization Credits"]');
              return root.lastElementChild.tagName === 'P'
                && !!(entry.compareDocumentPosition(root.lastElementChild) & Node.DOCUMENT_POSITION_FOLLOWING);
            }""")
            entry.click()
            expect(credits).to_be_visible()
            expect(page.locator("#pageTitle")).to_have_text(title)
            page.wait_for_timeout(350)
            expect(page.locator("#pageTitle")).to_have_text(title)
        layout_locales = [("nl", "Vertalers"), ("uk", "Автори перекладу")]
        if german:
            layout_locales.insert(0, ("de", "Mitwirkende an der Übersetzung"))
        for locale, title in layout_locales:
            for width in (320, 390, 768, 1200):
                page.set_viewport_size({"width": width, "height": 1000})
                page.evaluate("""async locale => {
                  (await import('/static/core.js')).cacheSettings([{key:'ui.language',value:locale}]);
                  (await import('/static/tabs.js')).refreshNavigationText();
                }""", locale)
                expect(page.locator("#pageTitle")).to_have_text(title)
                assert credits.evaluate("el => el.scrollWidth <= el.clientWidth"), width
                for row in credits.locator(".row").all():
                    name = row.locator(".name").bounding_box()
                    link = row.locator("a").bounding_box()
                    assert link["x"] >= name["x"] + name["width"], width
                    assert abs((name["y"] + name["height"] / 2) - (link["y"] + link["height"] / 2)) < 2, width
        output = os.environ.get("KS_CREDITS_SCREENSHOT")
        if output:
            page.set_viewport_size({"width": 390, "height": 1000})
            page.wait_for_timeout(400)
            page.screenshot(path=output, full_page=True)
        assert not errors, errors
        browser.close()
        print("Credits: language groups, contributors, navigation, live locale changes and layout passed")
finally:
    server.shutdown()
