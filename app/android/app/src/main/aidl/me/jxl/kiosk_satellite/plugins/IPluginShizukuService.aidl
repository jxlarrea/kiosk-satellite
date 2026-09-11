package me.jxl.kiosk_satellite.plugins;
import android.os.Bundle;

interface IPluginShizukuService {
    Bundle execute(in String[] command, int timeoutMs) = 0;
    void destroy() = 16777114;
}
