package me.jxl.kiosk_satellite

import android.content.Context
import android.os.Binder
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.Process
import android.system.Os
import me.jxl.kiosk_satellite.updates.HelperProtocol
import me.jxl.kiosk_satellite.updates.IShizukuInstaller
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.atomic.AtomicBoolean

/** A single self-update. Survives the KS process swap and exits after finishing. */
class ShizukuUpdateService(private val context: Context) : IShizukuInstaller.Stub() {
    private val ownerUid = context.applicationInfo.uid
    private val committed = AtomicBoolean(false)
    @Volatile private var apk: File? = null
    @Volatile private var process: java.lang.Process? = null
    init {
        // Also bounds an abandoned upload or a client lost before commit.
        Thread({ Thread.sleep(180_000); finish() }, "shizuku-update-deadline").apply { isDaemon = true; start() }
    }
    private fun checkCaller() { check(Binder.getCallingUid() == ownerUid) { "Caller is not Kiosk Satellite" } }
    @Synchronized override fun prepare(descriptor: ParcelFileDescriptor, size: Long) {
        checkCaller()
        check(apk == null && !committed.get()) { "An APK is already prepared" }
        require(size in 1..HelperProtocol.MAX_APK_BYTES) { "Invalid APK size" }
        val directory = File("/data/local/tmp/ks-shizuku-update-$ownerUid")
        check(directory.isDirectory || directory.mkdir()) { "Cannot create update staging directory" }
        Os.chmod(directory.path, 0x1c0)
        val file = File.createTempFile("update-", ".apk", directory)
        apk = file
        try {
            ParcelFileDescriptor.AutoCloseInputStream(descriptor).use { input ->
                FileOutputStream(file).use { output ->
                    val buffer = ByteArray(65536)
                    var left = size
                    while (left > 0) {
                        val count = input.read(buffer, 0, minOf(left, buffer.size.toLong()).toInt())
                        check(count > 0) { "Incomplete APK upload" }
                        output.write(buffer, 0, count)
                        left -= count
                    }
                    check(input.read() == -1) { "APK size changed during upload" }
                    output.fd.sync()
                }
            }
            val packages = context.packageManager
            val candidate = packages.getPackageArchiveInfo(file.path, 0) ?: error("Invalid APK")
            val installed = packages.getPackageInfo(context.packageName, 0)
            fun version(info: android.content.pm.PackageInfo): Long = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
            HelperProtocol.validateCandidate(candidate.packageName, version(candidate), version(installed))
        } catch (error: Exception) { file.delete(); apk = null; throw error }
    }
    @Synchronized override fun commit(): String {
        checkCaller()
        val file = apk ?: error("No APK was prepared")
        check(committed.compareAndSet(false, true)) { "Update already committed" }
        try {
            // Android verifies the signing certificate. No shell interpolation or permission grants.
            val child = ProcessBuilder("/system/bin/pm", "install", "-r", "--user",
                (ownerUid / 100000).toString(), "-i", context.packageName, file.path)
                .redirectErrorStream(true).start()
            process = child
            val output = StringBuilder()
            child.inputStream.bufferedReader().use { reader ->
                val buffer = CharArray(4096)
                while (true) {
                    val count = reader.read(buffer)
                    if (count < 0) break
                    if (output.length < 8000) output.append(buffer, 0, minOf(count, 8000 - output.length))
                }
            }
            val success = child.waitFor() == 0 && output.toString().trim() == "Success"
            return if (success) "installed" else "Install failed: ${output.toString().trim()}"
        } finally {
            file.delete()
            Thread({ Thread.sleep(1000); finish() }, "shizuku-update-stop").apply { isDaemon = true; start() }
        }
    }
    override fun destroy() {
        check(Binder.getCallingUid() in setOf(ownerUid, 0, 2000)) { "Caller cannot stop this installer" }
        // A lost client must not interrupt a package replacement already in progress.
        if (!committed.get()) finish()
    }
    private fun finish() {
        try { process?.destroy() } catch (_: Exception) {}
        apk?.delete()
        Process.killProcess(Process.myPid())
    }
}
