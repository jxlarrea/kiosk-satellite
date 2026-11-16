package com.pichillilorenzo.flutter_inappwebview_android;

import android.app.Activity;
import android.content.Context;
import android.content.MutableContextWrapper;

import java.util.Collections;
import java.util.Set;
import java.util.WeakHashMap;

/**
 * Kiosk Satellite change. A WebView keeps the context it was built with for
 * its whole life, and Chromium builds its dialogs (the color, date and time
 * pickers) on that context. The app's FlutterEngine outlives its Activity,
 * so when a new Activity takes over the engine the dashboard WebView still
 * held the old one, and the next picker crashed the app with
 * BadTokenException. Each WebView built on an Activity now gets a
 * MutableContextWrapper, and every attach moves the wrappers to the
 * Activity that attached.
 */
public final class WebViewContexts {
  private static final Set<MutableContextWrapper> wrappers =
      Collections.newSetFromMap(new WeakHashMap<MutableContextWrapper, Boolean>());

  private WebViewContexts() {}

  /** [context] in a wrapper that follows the attached Activity when it is an Activity. */
  public static Context wrap(Context context) {
    if (!(context instanceof Activity)) return context;
    MutableContextWrapper wrapper = new MutableContextWrapper(context);
    synchronized (wrappers) {
      wrappers.add(wrapper);
    }
    return wrapper;
  }

  /** Points every live wrapper at [activity]. */
  public static void moveTo(Activity activity) {
    if (activity == null) return;
    synchronized (wrappers) {
      for (MutableContextWrapper wrapper : wrappers) {
        if (wrapper.getBaseContext() != activity) wrapper.setBaseContext(activity);
      }
    }
  }
}
