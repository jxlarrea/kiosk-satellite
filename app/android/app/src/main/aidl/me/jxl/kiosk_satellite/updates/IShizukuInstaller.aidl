package me.jxl.kiosk_satellite.updates;
import android.os.ParcelFileDescriptor;
interface IShizukuInstaller {
    void prepare(in ParcelFileDescriptor apk, long size) = 0;
    String commit() = 1;
    void destroy() = 16777114;
}
