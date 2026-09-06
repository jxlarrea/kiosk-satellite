# The native SendSpin engine resolves these from JNI by name (GetMethodID in
# sendspin_jni.cpp); R8 renaming them aborts the runtime with a pending
# NoSuchMethodError at session start.
-keep class me.jxl.kiosk_satellite.sendspin.NativeSendspin { *; }
-keep interface me.jxl.kiosk_satellite.sendspin.NativeSendspinCallbacks { *; }
-keep class * implements me.jxl.kiosk_satellite.sendspin.NativeSendspinCallbacks { *; }

# MediaPipe Tasks (the hand landmarker behind the Show fingers gesture)
# reads its option and result protos by reflection; minified, it fails at
# load with "Field platform_ for ... not found".
-keep class com.google.mediapipe.** { *; }
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.mediapipe.**
# ... and its logger (flogger) finds its caller by walking the stack for a
# class by name, which renaming breaks in Graph's static init.
-keep class com.google.common.flogger.** { *; }
-keep class com.google.common.** { *; }
-dontwarn com.google.common.**

# ADB starts this entry point directly from the installed APK.
-keep class me.jxl.kiosk_satellite.updates.UpdateHelper { public static void main(java.lang.String[]); }
