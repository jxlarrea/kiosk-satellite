# The native SendSpin engine resolves these from JNI by name (GetMethodID in
# sendspin_jni.cpp); R8 renaming them aborts the runtime with a pending
# NoSuchMethodError at session start.
-keep class me.jxl.kiosk_satellite.sendspin.NativeSendspin { *; }
-keep interface me.jxl.kiosk_satellite.sendspin.NativeSendspinCallbacks { *; }
-keep class * implements me.jxl.kiosk_satellite.sendspin.NativeSendspinCallbacks { *; }
