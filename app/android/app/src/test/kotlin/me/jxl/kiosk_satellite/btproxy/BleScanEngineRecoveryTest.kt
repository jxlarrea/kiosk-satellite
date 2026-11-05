package me.jxl.kiosk_satellite.btproxy

import android.app.Application
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.Intent
import android.os.Looper
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadow.api.Shadow
import org.robolectric.shadows.ShadowBluetoothLeScanner
import java.time.Duration

/** The real engine against Robolectric's scanner, on each side of the bug. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [27], manifest = Config.NONE, application = Application::class)
class BleScanEngineRecoveryTest {
    private val notes = mutableListOf<String>()
    private val states = mutableListOf<ScannerState>()
    private lateinit var app: Application
    private lateinit var adapter: BluetoothAdapter
    private lateinit var engine: BleScanEngine

    private val adapterRestarts get() = notes.count { "restarting the Bluetooth adapter" in it }
    private val scanRestarts get() = notes.count { it.endsWith("restarting scan") }
    private val sessionsEnded get() = states.count { it == ScannerState.STOPPING }

    @Before
    fun setUp() {
        app = RuntimeEnvironment.getApplication()
        adapter = (app.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
        shadowOf(adapter).setEnabled(true)
        engine = BleScanEngine(
            app,
            onAdvertisement = {},
            onStateChange = { state, _ -> states += state },
            onLog = { notes += it },
        )
        engine.requestStart(ScannerMode.PASSIVE)
        idle()
    }

    @After
    fun tearDown() {
        engine.shutdown()
        idle()
    }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    private fun advance(duration: Duration) =
        shadowOf(Looper.getMainLooper()).idleFor(duration)

    private fun callback(): ScanCallback {
        val scanner = Shadow.extract<ShadowBluetoothLeScanner>(adapter.bluetoothLeScanner)
        return scanner.scanCallbacks.first()
    }

    private fun registrationTimeout() {
        callback().onScanFailed(ScanCallback.SCAN_FAILED_APPLICATION_REGISTRATION_FAILED)
        idle()
    }

    private fun hear() {
        val device = adapter.getRemoteDevice("AA:BB:CC:DD:EE:FF")
        callback().onScanResult(
            ScanSettings.CALLBACK_TYPE_ALL_MATCHES, ScanResult(device, null, -50, 0))
        idle()
    }

    /** Hears something every 30 seconds, so the watchdog stays quiet. */
    private fun healthyFor(duration: Duration) {
        var left = duration
        while (!left.isNegative && !left.isZero) {
            hear()
            advance(Duration.ofSeconds(30))
            left = left.minusSeconds(30)
        }
    }

    private fun adapterBackOn() {
        shadowOf(adapter).setEnabled(true)
        app.sendBroadcast(
            Intent(BluetoothAdapter.ACTION_STATE_CHANGED)
                .putExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.STATE_ON))
        idle()
    }

    @Test
    fun silenceAfterATimeoutRestartsTheAdapter() {
        registrationTimeout()
        advance(Duration.ofSeconds(70))

        assertEquals(1, adapterRestarts)
        assertEquals(0, scanRestarts)
    }

    @Test
    fun silenceAfterAHealedTimeoutStillRestartsTheAdapter() {
        registrationTimeout()
        advance(Duration.ofSeconds(6))
        healthyFor(Duration.ofMinutes(10))
        assertEquals(0, adapterRestarts)

        advance(Duration.ofSeconds(70))
        assertEquals(1, adapterRestarts)
    }

    @Test
    fun silenceWithoutATimeoutOnlyRestartsTheScan() {
        advance(Duration.ofSeconds(70))

        assertEquals(0, adapterRestarts)
        assertTrue(scanRestarts >= 1)
    }

    @Test
    fun healthyDeviceRotatesEveryTwoMinutesOnTheBugReleases() {
        healthyFor(Duration.ofMinutes(10))

        assertEquals(5, sessionsEnded)
        assertEquals(0, adapterRestarts)
        assertEquals(0, scanRestarts)
    }

    @Test
    fun repeatedWedgeRestartsAgainAfterARecoveredRestart() {
        repeat(3) { registrationTimeout() }
        assertEquals(1, adapterRestarts)

        advance(Duration.ofSeconds(5))
        adapterBackOn()
        healthyFor(Duration.ofMinutes(31))

        repeat(3) { registrationTimeout() }
        assertEquals(2, adapterRestarts)
    }

    @Test
    @Config(sdk = [30])
    fun healthyDeviceRotatesEveryTwoMinutesOnFixedReleases() {
        healthyFor(Duration.ofMinutes(10))

        assertEquals(5, sessionsEnded)
        assertEquals(0, adapterRestarts)
    }

    @Test
    @Config(sdk = [30])
    fun silenceAfterATimeoutOnlyRestartsTheScanOnFixedReleases() {
        registrationTimeout()
        advance(Duration.ofSeconds(70))

        assertEquals(0, adapterRestarts)
        assertTrue(scanRestarts >= 1)
    }

    @Test
    @Config(sdk = [30])
    fun restartThatBroughtNothingBackStaysOneShotOnFixedReleases() {
        repeat(3) { registrationTimeout() }
        assertEquals(1, adapterRestarts)

        advance(Duration.ofSeconds(5))
        adapterBackOn()
        advance(Duration.ofHours(6))
        repeat(5) { registrationTimeout() }

        assertEquals(1, adapterRestarts)
    }
}
