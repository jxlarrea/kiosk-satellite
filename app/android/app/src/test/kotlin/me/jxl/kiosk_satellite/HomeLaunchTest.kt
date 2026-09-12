package me.jxl.kiosk_satellite

import android.app.AlarmManager
import android.app.ActivityManager
import android.app.Application
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.ResolveInfo
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowAppTask

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28, 33], manifest = Config.NONE, application = Application::class)
class HomeLaunchTest {
    private lateinit var context: Application

    @Before
    fun setUp() {
        context = RuntimeEnvironment.getApplication()
        val appInfo = ApplicationInfo().apply { packageName = context.packageName }
        val main = ActivityInfo().apply {
            packageName = context.packageName
            name = "${context.packageName}.MainActivity"
            applicationInfo = appInfo
        }
        val home = ActivityInfo().apply {
            packageName = context.packageName
            name = HomeRole.alias(context).className
            applicationInfo = appInfo
        }
        shadowOf(context.packageManager).installPackage(PackageInfo().apply {
            packageName = context.packageName
            applicationInfo = appInfo
            activities = arrayOf(main, home)
        })
        shadowOf(context.packageManager).setResolveInfosForIntent(
            Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                .setPackage(context.packageName),
            listOf(ResolveInfo().apply { activityInfo = main }),
        )
        setDefaultHome("com.example.launcher")
    }

    private fun setDefaultHome(pkg: String) {
        shadowOf(context.packageManager).setResolveInfosForIntent(
            Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME),
            listOf(ResolveInfo().apply {
                isDefault = true
                activityInfo = ActivityInfo().apply {
                    packageName = pkg
                    name = "$pkg.HomeAlias"
                    applicationInfo = ApplicationInfo().apply { packageName = pkg }
                }
            }),
        )
    }

    private fun relaunch(): Intent {
        UpdateRelaunchReceiver().onReceive(context, Intent(Intent.ACTION_MY_PACKAGE_REPLACED))
        return checkNotNull(shadowOf(context).nextStartedActivity)
    }

    @Test
    fun updateReturnsToHomeWithoutAnExplicitComponentOrExtraCategories() {
        HomeRole.setAliasEnabled(context, true)
        setDefaultHome(context.packageName)
        val launch = relaunch()
        assertEquals(Intent.ACTION_MAIN, launch.action)
        assertEquals(setOf(Intent.CATEGORY_HOME), launch.categories)
        assertEquals(context.packageName, launch.`package`)
        assertNull(launch.component)
        assertNull(launch.data)
        assertNull(launch.type)
        assertTrue(launch.flags and Intent.FLAG_ACTIVITY_NEW_TASK != 0)
        assertEquals(0, launch.flags and Intent.FLAG_ACTIVITY_CLEAR_TASK)
        assertFalse(HomeRole.isHomePress(launch))
    }

    @Test
    fun physicalHomePressStillReturnsToDashboard() {
        assertTrue(HomeRole.isHomePress(
            Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
                .setComponent(HomeRole.alias(context)),
        ))
    }

    @Test
    fun updateUsesRegularAppWhenAnotherLauncherIsDefault() {
        HomeRole.setAliasEnabled(context, true)
        val launch = relaunch()
        assertTrue(launch.hasCategory(Intent.CATEGORY_LAUNCHER))
        assertFalse(launch.hasCategory(Intent.CATEGORY_HOME))
        assertEquals("${context.packageName}.MainActivity", launch.component?.className)
    }

    @Test
    fun disabledAliasCannotBeUsedEvenWhileDefaultHomeResolutionIsStale() {
        HomeRole.setAliasEnabled(context, true)
        HomeRole.setAliasEnabled(context, false)
        setDefaultHome(context.packageName)
        assertTrue(relaunch().hasCategory(Intent.CATEGORY_LAUNCHER))
    }

    @Test
    fun unrelatedBroadcastDoesNotLaunch() {
        UpdateRelaunchReceiver().onReceive(context, Intent(Intent.ACTION_BOOT_COMPLETED))
        assertNull(shadowOf(context).nextStartedActivity)
    }

    private fun task(base: Intent): ActivityManager.AppTask =
        ShadowAppTask.newInstance().also {
            shadowOf(it).setTaskInfo(ActivityManager.RecentTaskInfo().apply {
                baseIntent = base
            })
        }

    @Test
    fun homeUpdateRemovesOldAppTasksButPreservesHomeAndOtherActivities() {
        HomeRole.setAliasEnabled(context, true)
        setDefaultHome(context.packageName)
        val main = ComponentName(context, MainActivity::class.java)
        val regular = task(Intent(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_LAUNCHER).setComponent(main))
        val notification = task(Intent().setComponent(main))
        val home = task(Intent(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_HOME).setComponent(main))
        val alias = task(Intent(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_HOME).setComponent(HomeRole.alias(context)))
        val other = task(Intent(context, WakeActivity::class.java))
        shadowOf(context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager)
            .setAppTasks(listOf(regular, notification, home, alias, other))
        relaunch()
        assertTrue(shadowOf(regular).isFinishedAndRemoved)
        assertTrue(shadowOf(notification).isFinishedAndRemoved)
        assertFalse(shadowOf(home).isFinishedAndRemoved)
        assertFalse(shadowOf(alias).isFinishedAndRemoved)
        assertFalse(shadowOf(other).isFinishedAndRemoved)
    }

    @Test
    fun regularAppUpdateKeepsItsExistingTask() {
        val regular = task(Intent(context, MainActivity::class.java))
        shadowOf(context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager)
            .setAppTasks(listOf(regular))
        relaunch()
        assertFalse(shadowOf(regular).isFinishedAndRemoved)
    }

    @Test
    fun restartAlarmIsCancelledAfterLosingHomeRole() {
        HomeRole.setAliasEnabled(context, true)
        setDefaultHome(context.packageName)
        assertAlarmCancelledAfterRoleChange(false)
    }

    @Test
    fun restartAlarmIsCancelledAfterGainingHomeRole() {
        assertAlarmCancelledAfterRoleChange(true)
    }

    private fun assertAlarmCancelledAfterRoleChange(held: Boolean) {
        val alarms = shadowOf(context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
        assertEquals(!held, HomeRole.isHeld(context))
        BackgroundBridge.scheduleRestartAlarm(context)
        assertEquals(1, alarms.scheduledAlarms.size)
        HomeRole.setAliasEnabled(context, held)
        setDefaultHome(if (held) context.packageName else "com.example.launcher")
        assertEquals(held, HomeRole.isHeld(context))
        BackgroundBridge.cancelRestartAlarm(context)
        assertTrue(alarms.scheduledAlarms.isEmpty())
    }
}
