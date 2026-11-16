# Android WebView plugin used by Kiosk Satellite

This is the runtime source of `flutter_inappwebview_android` 1.2.0-beta.3,
copied from the pub.dev package with its Apache 2.0 license. Its Dart API
is unchanged. The app selects this copy through `dependency_overrides` in
`app/pubspec.yaml`.

The local changes:

- `WebViewContexts.java` (new), `FlutterWebView.java` and
  `InAppWebViewFlutterPlugin.java`. The app's FlutterEngine outlives its
  Activity. A WebView keeps the context it was built with, and Chromium
  builds its color, date and time pickers on it. After a new Activity took
  over the engine, the dashboard WebView still held the old Activity and the
  next picker crashed the app with `BadTokenException`. A WebView built on an
  Activity now gets a `MutableContextWrapper`, and each attach points the
  wrappers at the new Activity.
- `InAppWebView.java`. `takeScreenshot` catches `OutOfMemoryError` and
  answers null instead of ending the app.

To check the picker change, load a page with `<input type="color">`, replace
the Activity with `adb shell am start -f 0x10008000 -n
me.jxl.kiosk_satellite/.HomeAlias -a android.intent.action.MAIN -c
android.intent.category.HOME` and tap the input. Logcat shows `evicted by
another attaching activity` and the picker opens.

When updating this package, carry these changes over. Remove the override
when an upstream release handles both.
