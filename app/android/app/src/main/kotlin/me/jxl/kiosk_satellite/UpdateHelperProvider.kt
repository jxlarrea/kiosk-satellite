package me.jxl.kiosk_satellite

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.Binder
import android.os.ParcelFileDescriptor

/** ADB can read the bootstrap script. Apps cannot read the helper secret. */
class UpdateHelperProvider : ContentProvider() {
    override fun onCreate() = true

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        val caller = Binder.getCallingUid()
        if (caller != 2000 && caller != 0) {
            throw SecurityException("Only ADB can start the update helper")
        }
        require(uri.path == "/start" && mode == "r") { "Unknown helper resource" }
        val ctx = requireNotNull(context)
        fun quoted(value: String) = "'" + value.replace("'", "'\"'\"'") + "'"
        val script = ctx.assets.open("start-update-helper.sh").bufferedReader().use { it.readText() }
            .replace("@APK@", quoted(ctx.applicationInfo.sourceDir))
            .replace("@UID@", ctx.applicationInfo.uid.toString())
            .replace("@TOKEN@", quoted(UpdateHelperClient.token(ctx)))
        val pipe = ParcelFileDescriptor.createPipe()
        Thread {
            try {
                ParcelFileDescriptor.AutoCloseOutputStream(pipe[1]).use {
                    it.write(script.toByteArray(Charsets.UTF_8))
                }
            } catch (_: java.io.IOException) { }
        }.start()
        return pipe[0]
    }

    override fun getType(uri: Uri) = "text/x-shellscript"
    override fun query(uri: Uri, projection: Array<out String>?, selection: String?,
        selectionArgs: Array<out String>?, sortOrder: String?): Cursor? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?) = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?,
        selectionArgs: Array<out String>?) = 0
}
