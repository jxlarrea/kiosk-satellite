package me.jxl.kiosk_satellite

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.app.role.RoleManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log

/**
 * The device's HOME role (issue #219): registering the kiosk as the home
 * app replaces the OEM launcher outright. The system then starts the kiosk
 * at boot itself (no stock-launcher flash), and every HOME press lands on
 * the kiosk with no screen pinning and no consent dialog.
 *
 * The registration rides a manifest activity-alias (HomeAlias, disabled by
 * default) that targets MainActivity. Disabled, the app has zero HOME
 * footprint: it appears in no chooser and no default-apps list. The alias
 * carries no LAUNCHER category, so getLaunchIntentForPackage keeps
 * resolving MainActivity and every recovery path (crash self-heal, boot
 * receiver, update relaunch, task-removed relaunch, bringToFront) is
 * untouched by the role.
 *
 * Undo is structural, never dependent on stored state: disabling the alias
 * removes the app from HOME resolution entirely and Android re-resolves to
 * the remaining launcher on its own (on API 29+ the role migrates to the
 * fallback holder; on older releases a preferred-activity entry for a
 * disabled component is void). The remembered previous launcher only makes
 * the landing immediate, it is not what the guarantee rests on. The same
 * property is what [HomeFuse] trips into when the kiosk crash-loops.
 */
object HomeRole {
    private const val TAG = "HomeRole"

    /** How long the "Set as default" dialog is deferred after enabling the
     *  alias: some OEM role controllers snapshot the candidate list lazily,
     *  and a request racing the component flip can come up empty. */
    private const val ROLE_REQUEST_DELAY_MS = 300L

    const val REQ_HOME_ROLE = 4501

    fun alias(context: Context): ComponentName =
        ComponentName(context.packageName, "${context.packageName}.HomeAlias")

    fun aliasEnabled(context: Context): Boolean =
        context.packageManager.getComponentEnabledSetting(alias(context)) ==
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED

    fun setAliasEnabled(context: Context, enabled: Boolean) {
        if (aliasEnabled(context) == enabled) return
        context.packageManager.setComponentEnabledSetting(
            alias(context),
            if (enabled) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            // Never restart the process over a component flip: the flip
            // happens from inside the running kiosk.
            PackageManager.DONT_KILL_APP,
        )
        Log.i(TAG, "home alias ${if (enabled) "enabled" else "disabled"}")
    }

    private fun homeIntent(): Intent =
        Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)

    /** Whether this device lets an app take the HOME role at all, and if
     *  not, why. Fire OS is unsupported outright: its role service claims
     *  ROLE_HOME is available and even accepts a holder over adb, but the
     *  request dialog is denied silently, the home-settings screen closes
     *  itself the moment it opens and HOME keeps landing on the Fire
     *  launcher with the role held (verified on Fire OS 8). The one
     *  escape is a build where HOME actually resolves to us, which
     *  [isHeld] would report. */
    fun isSupported(context: Context): Pair<Boolean, String> {
        val amazon = Build.MANUFACTURER.equals("Amazon", ignoreCase = true)
        if (amazon && !isHeld(context)) return false to "fireos"
        if (Build.VERSION.SDK_INT >= 29) {
            val role = context.getSystemService(RoleManager::class.java)
            val available = role?.isRoleAvailable(RoleManager.ROLE_HOME) == true
            if (available) return true to ""
            return false to "unavailable"
        }
        // Pre-role releases: supported when the system offers a way to pick
        // a home app, or another home app exists to fall back to.
        val pm = context.packageManager
        val settingsResolves = Intent(Settings.ACTION_HOME_SETTINGS)
            .resolveActivity(pm) != null
        val others = pm.queryIntentActivities(homeIntent(), 0)
            .any { it.activityInfo?.packageName != context.packageName }
        if (settingsResolves || others) return true to ""
        return false to "unavailable"
    }

    /** Whether the kiosk is the device's home app right now. What HOME
     *  actually resolves to is the ground truth; the role only breaks the
     *  tie while no launcher owns the resolution (right after a crash the
     *  preferred entry can transiently read as a chooser while the role
     *  stands). A concrete rival resolution outranks a nominally held
     *  role: Fire OS grants the role over adb yet keeps sending HOME to
     *  its own launcher, and claiming "held" there would be a lie. */
    fun isHeld(context: Context): Boolean {
        val current = currentDefaultHome(context)
        if (current == context.packageName) return true
        if (current != null) return false
        if (Build.VERSION.SDK_INT >= 29) {
            val role = context.getSystemService(RoleManager::class.java)
            if (role?.isRoleHeld(RoleManager.ROLE_HOME) == true) return true
        }
        return false
    }

    /** The package HOME resolves to today, or null while a chooser would
     *  show. The system's resolver activity does not count as a home. */
    fun currentDefaultHome(context: Context): String? {
        val info = context.packageManager.resolveActivity(
            homeIntent(), PackageManager.MATCH_DEFAULT_ONLY) ?: return null
        val pkg = info.activityInfo?.packageName ?: return null
        return if (pkg == "android") null else pkg
    }

    fun isDeviceOwner(context: Context): Boolean = try {
        context.getSystemService(DevicePolicyManager::class.java)
            ?.isDeviceOwnerApp(context.packageName) == true
    } catch (_: Exception) {
        false
    }

    /**
     * The device-owner acquisition: no dialog, no person at the screen,
     * works from the application context (a remote flip completes with no
     * Activity alive). Returns whether the role landed.
     */
    fun acquireSilent(context: Context): Boolean {
        if (!isDeviceOwner(context)) return false
        return try {
            setAliasEnabled(context, true)
            val dpm = context.getSystemService(DevicePolicyManager::class.java)
            val admin = ComponentName(context, KioskAdminReceiver::class.java)
            val filter = IntentFilter(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addCategory(Intent.CATEGORY_DEFAULT)
            }
            dpm.addPersistentPreferredActivity(admin, filter, alias(context))
            Log.i(TAG, "home role acquired as device owner")
            true
        } catch (e: Exception) {
            Log.w(TAG, "device-owner home acquire failed: ${e.message}")
            false
        }
    }

    /**
     * The one-tap system dialog on API 29+. The result lands in
     * MainActivity.onActivityResult under [REQ_HOME_ROLE]. Android quietly
     * auto-denies the dialog after about two refusals, which is why the
     * caller falls back to [openHomeSettings] once denials pile up.
     */
    fun requestRole(activity: Activity) {
        setAliasEnabled(activity, true)
        if (Build.VERSION.SDK_INT < 29) {
            openHomeSettings(activity)
            return
        }
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                val role = activity.getSystemService(RoleManager::class.java)
                activity.startActivityForResult(
                    role.createRequestRoleIntent(RoleManager.ROLE_HOME),
                    REQ_HOME_ROLE,
                )
            } catch (e: Exception) {
                Log.w(TAG, "role request failed: ${e.message}")
                openHomeSettings(activity)
            }
        }, ROLE_REQUEST_DELAY_MS)
    }

    /** The system's own home picker, in order of directness. Also the
     *  acquisition path on API 24-28. The alias must be enabled first or
     *  the kiosk is not on the list. */
    fun openHomeSettings(activity: Activity) {
        setAliasEnabled(activity, true)
        for (intent in listOf(
            Intent(Settings.ACTION_HOME_SETTINGS),
            Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS),
            // Last resort: a bare HOME launch surfaces the chooser itself.
            homeIntent(),
        )) {
            try {
                activity.startActivity(intent)
                return
            } catch (_: Exception) {
                // Try the next one.
            }
        }
        Log.w(TAG, "no home settings surface resolved")
    }

    /**
     * Give the role back. Structural (see the class doc); the [previous]
     * package, when it still resolves for HOME, is launched so the person
     * lands somewhere immediately instead of on the next HOME press.
     */
    fun release(context: Context, previous: String?) {
        // Releasing a role that was never engaged must be a silent no-op:
        // the manager reverts a stored-but-unsupported enable through this
        // path, and launching the landing intent there would yank the
        // kiosk behind the OEM launcher for nothing.
        val hadAlias = aliasEnabled(context)
        try {
            if (isDeviceOwner(context)) {
                val dpm = context.getSystemService(DevicePolicyManager::class.java)
                val admin = ComponentName(context, KioskAdminReceiver::class.java)
                dpm.clearPackagePersistentPreferredActivities(
                    admin, context.packageName)
            }
        } catch (e: Exception) {
            Log.w(TAG, "clearing preferred home failed: ${e.message}")
        }
        setAliasEnabled(context, false)
        if (!hadAlias) return
        // Cosmetic landing only. Not getLaunchIntentForPackage: a home app
        // does not necessarily have a LAUNCHER entry.
        try {
            val pm = context.packageManager
            val landing = previous
                ?.let { homeIntent().setPackage(it) }
                ?.takeIf { pm.resolveActivity(it, 0) != null }
                ?: homeIntent()
            landing.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(landing)
        } catch (e: Exception) {
            Log.w(TAG, "landing launch after release failed: ${e.message}")
        }
        Log.i(TAG, "home role released")
    }

    /** Everything the Dart side needs to render the status row. */
    fun status(context: Context): Map<String, Any?> {
        val (supported, reason) = isSupported(context)
        return mapOf(
            "supported" to supported,
            "reason" to reason,
            "held" to isHeld(context),
            "defaultHome" to currentDefaultHome(context),
            "aliasEnabled" to aliasEnabled(context),
            "deviceOwner" to isDeviceOwner(context),
            "fuseTripped" to HomeFuse.tripped(context),
            "fuseReason" to HomeFuse.reason(context),
            "roleDenials" to HomeFuse.roleDenials(context),
            "sdk" to Build.VERSION.SDK_INT,
        )
    }
}
