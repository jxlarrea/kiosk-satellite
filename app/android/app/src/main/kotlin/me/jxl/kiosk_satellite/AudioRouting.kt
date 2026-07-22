package me.jxl.kiosk_satellite

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * User-selected capture and playback devices for Voice Satellite audio: the
 * wake-word/turn microphone (MicRecorder) and delegated sounds (SoundPlayer).
 * Deliberately NOT media playback (SendSpin, DLNA) - those are media players
 * and follow the system's own routing.
 *
 * Selections are stored as a stable selector string "type|address|name" rather
 * than an AudioDeviceInfo id: ids are transient (they change across replugs
 * and reboots), while type+address pins a Bluetooth or USB device and
 * type+name is a good fallback for everything else. Resolution is lazy - the
 * selector is re-matched against the live device list every time a stream
 * opens, so a speaker that is off tonight simply falls back to the system
 * default and wins again when it reappears.
 *
 * WebView audio (Voice Satellite TTS today) also cannot be routed here: it
 * follows the system's media routing, which Android offers no per-app
 * control over. It gains routing only as it is handed off to SoundPlayer.
 */
object AudioRouting {
    private const val TAG = "AudioRouting"

    @Volatile private var appContext: Context? = null
    @Volatile private var outputSelector: String? = null

    fun init(context: Context) {
        appContext = context.applicationContext
    }

    private fun audioManager(): AudioManager? =
        appContext?.getSystemService(Context.AUDIO_SERVICE) as? AudioManager

    /** Change the preferred output for Voice Satellite sounds. */
    fun setOutput(selector: String?) {
        outputSelector = selector?.takeIf { it.isNotBlank() }
        Log.i(TAG, "output selector = ${outputSelector ?: "automatic"}")
    }

    /** The selected output as a live device, or null for automatic. Resolved
     *  per play, so players pin themselves when a sound starts. */
    fun currentOutput(): AudioDeviceInfo? = resolve(outputSelector, source = false)

    /**
     * Match a selector against the live device list: type+address first (the
     * stable pin for BT/USB), then type+name, then the first device of the
     * type. Null (automatic, or nothing matches) leaves routing to Android.
     */
    fun resolve(selector: String?, source: Boolean): AudioDeviceInfo? {
        if (selector.isNullOrBlank()) return null
        val am = audioManager() ?: return null
        val parts = selector.split('|')
        val type = parts.getOrNull(0)?.toIntOrNull() ?: return null
        val address = parts.getOrNull(1) ?: ""
        val name = parts.getOrNull(2) ?: ""
        val devices = am.getDevices(
            if (source) AudioManager.GET_DEVICES_INPUTS else AudioManager.GET_DEVICES_OUTPUTS,
        )
        return devices.firstOrNull { it.type == type && address.isNotEmpty() && it.address == address }
            ?: devices.firstOrNull { it.type == type && name.isNotEmpty() && it.productName.toString() == name }
            ?: devices.firstOrNull { it.type == type }
    }

    /** The selectable devices of one direction, for the settings dropdowns. */
    fun list(source: Boolean): List<Map<String, Any>> {
        val am = audioManager() ?: return emptyList()
        val devices = am.getDevices(
            if (source) AudioManager.GET_DEVICES_INPUTS else AudioManager.GET_DEVICES_OUTPUTS,
        )
        val rows = devices
            .filter { selectable(it.type) }
            .map {
                Triple("${it.type}|${it.address}|${it.productName}", label(it), it)
            }
            // The same physical device can expose several profiles; keep one
            // row per selector so the dropdown stays readable.
            .distinctBy { it.first }
        // Twin devices of one kind (a tablet's bottom and back mics) would
        // read as identical rows; the address is what tells them apart.
        val dupes = rows.groupingBy { it.second }.eachCount()
        return rows.map { (selector, label, device) ->
            val name =
                if ((dupes[label] ?: 0) > 1 && device.address.isNotEmpty()) {
                    "$label (${device.address})"
                } else {
                    label
                }
            mapOf("selector" to selector, "label" to name, "type" to device.type)
        }
    }

    /** Internal/virtual routes nobody would pick from a settings dropdown. */
    private fun selectable(type: Int): Boolean = when (type) {
        AudioDeviceInfo.TYPE_TELEPHONY,
        AudioDeviceInfo.TYPE_FM_TUNER,
        AudioDeviceInfo.TYPE_TV_TUNER,
        AudioDeviceInfo.TYPE_REMOTE_SUBMIX,
        24, // TYPE_BUILTIN_SPEAKER_SAFE: the notification duck path, not a choice
        -> false
        else -> true
    }

    private fun label(device: AudioDeviceInfo): String {
        val product = device.productName.toString().trim()
        return when (device.type) {
            AudioDeviceInfo.TYPE_BUILTIN_MIC -> "Built-in microphone"
            AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "Built-in speaker"
            AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> "Earpiece"
            AudioDeviceInfo.TYPE_WIRED_HEADSET -> "Wired headset"
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "Wired headphones"
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO ->
                if (product.isEmpty()) "Bluetooth headset" else "$product (Bluetooth call audio)"
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ->
                if (product.isEmpty()) "Bluetooth audio" else "$product (Bluetooth)"
            AudioDeviceInfo.TYPE_USB_DEVICE, AudioDeviceInfo.TYPE_USB_HEADSET, AudioDeviceInfo.TYPE_USB_ACCESSORY ->
                if (product.isEmpty()) "USB audio" else "$product (USB)"
            AudioDeviceInfo.TYPE_HDMI, AudioDeviceInfo.TYPE_HDMI_ARC -> "HDMI"
            26, 27, 28, 30 -> // BLE headset/speaker/broadcast, BLE dock (API 31+/33+)
                if (product.isEmpty()) "Bluetooth LE audio" else "$product (Bluetooth LE)"
            else -> if (product.isEmpty()) "Audio device (type ${device.type})" else product
        }
    }
}

/**
 * MethodChannel face of [AudioRouting]: `list` for the settings dropdowns,
 * `setOutput` applied at startup and on every setting change. The microphone
 * selection travels with the mic stream itself (MicRecorder's onListen
 * arguments), so capture needs no call here.
 */
class AudioRoutingBridge(context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/audio_routing")

    init {
        AudioRouting.init(context)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "list" -> result.success(
                    mapOf(
                        "inputs" to AudioRouting.list(source = true),
                        "outputs" to AudioRouting.list(source = false),
                    ),
                )
                "setOutput" -> {
                    AudioRouting.setOutput(call.argument<String>("selector"))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
