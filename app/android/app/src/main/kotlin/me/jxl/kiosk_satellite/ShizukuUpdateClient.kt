package me.jxl.kiosk_satellite

import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.ParcelFileDescriptor
import me.jxl.kiosk_satellite.updates.IShizukuInstaller
import rikka.shizuku.Shizuku
import java.io.File
import java.io.IOException
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/** Separate from plugin helpers: an accepted update must survive the app being replaced. */
class ShizukuUpdateClient(private val context: Context) {
    private val main = Handler(Looper.getMainLooper())
    fun ready(): Boolean = try {
        Shizuku.pingBinder() && !Shizuku.isPreV11() && Shizuku.getVersion() >= 13 &&
            Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
    } catch (_: Exception) { false }
    fun requireReady() {
        check(ready()) { "Shizuku updates are enabled. Start Shizuku and grant Kiosk Satellite access in Settings > Device > Shizuku, then try again." }
    }
    fun install(apk: File): String {
        requireReady()
        val args = Shizuku.UserServiceArgs(ComponentName(context, ShizukuUpdateService::class.java))
            .tag("kiosk-update-${UUID.randomUUID()}").daemon(true).version(1).processNameSuffix("shizuku_update")
        val connected = CountDownLatch(1)
        val stopped = java.util.concurrent.atomic.AtomicBoolean(false)
        val service = java.util.concurrent.atomic.AtomicReference<IShizukuInstaller>()
        val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName, binder: IBinder) {
                val target = IShizukuInstaller.Stub.asInterface(binder)
                if (stopped.get()) {
                    Thread { try { target.destroy() } catch (_: Exception) {} }.start()
                } else { service.set(target); connected.countDown() }
            }
            override fun onServiceDisconnected(name: ComponentName) { connected.countDown() }
        }
        var committed = false
        var completed = false
        main.post {
            if (!stopped.get()) try { Shizuku.bindUserService(args, connection) }
            catch (_: Exception) { connected.countDown() }
        }
        try {
            check(connected.await(10, TimeUnit.SECONDS)) { "Shizuku installer did not connect" }
            val target = service.get() ?: error("Shizuku installer is unavailable")
            ParcelFileDescriptor.open(apk, ParcelFileDescriptor.MODE_READ_ONLY).use { target.prepare(it, apk.length()) }
            requireReady()
            // Never fall back or retry after this point, even if the Binder reply is lost.
            committed = true
            val result = target.commit()
            completed = true
            check(result == "installed") { result }
            return "silent"
        } catch (error: Exception) {
            if (committed && !completed) throw IOException("Lost contact with Shizuku after committing the update. Check the installed version before trying again.", error)
            throw error
        } finally {
            stopped.set(true)
            main.post {
                try { Shizuku.unbindUserService(args, connection, !committed || completed) }
                catch (_: Exception) {}
            }
        }
    }
}
