package me.jxl.kiosk_satellite.plugins

import android.content.Context
import android.os.Binder
import android.os.Bundle
import android.os.Process
import android.system.Os
import android.system.OsConstants
import java.util.concurrent.atomic.AtomicBoolean
import java.io.File

/** Loaded by Shizuku, never by Android's normal service machinery. */
class PluginShizukuService(context: Context) : IPluginShizukuService.Stub() {
    private val ownerUid = context.applicationInfo.uid
    private val closed = AtomicBoolean(false)
    private val running = AtomicBoolean(false)
    init {
        // Own the process group so stopping the helper also stops ordinary child commands.
        val group = File("/proc/self/stat").readText().substringAfterLast(") ").split(" ")[2].toInt()
        if (group != Process.myPid()) check(Os.setsid() == Process.myPid()) { "Cannot isolate Shizuku helper" }
    }

    override fun execute(command: Array<String>, timeoutMs: Int): Bundle {
        check(Binder.getCallingUid() == ownerUid) { "Caller is not Kiosk Satellite" }
        check(!closed.get() && running.compareAndSet(false, true)) { "Shizuku helper is busy or stopped" }
        try {
            val values = PluginShizukuCommand.run(command, timeoutMs, closed)
            return Bundle().apply {
                putInt("exitCode", values["exitCode"] as Int)
                putString("stdout", values["stdout"] as String)
                putString("stderr", values["stderr"] as String)
                putBoolean("timedOut", values["timedOut"] as Boolean)
                putBoolean("truncated", values["truncated"] as Boolean)
            }
        } finally { running.set(false) }
    }

    override fun destroy() {
        check(Binder.getCallingUid() in setOf(ownerUid, 0, 2000)) { "Caller cannot stop this helper" }
        closed.set(true)
        Os.kill(-Process.myPid(), OsConstants.SIGKILL)
    }
}
