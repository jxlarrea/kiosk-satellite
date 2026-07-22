package me.jxl.kiosk_satellite.sendspin.discovery

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.concurrent.Executors

/**
 * Manages mDNS service discovery using Android's native NsdManager.
 *
 * Why NsdManager instead of Go's hashicorp/mdns?
 * - NsdManager is Android's native implementation and works reliably with Android's network stack
 * - hashicorp/mdns has issues selecting the correct network interface on Android
 * - NsdManager properly handles WiFi multicast lock integration
 * - NsdManager respects Android's network permissions and restrictions
 *
 * Service type: _sendspin-server._tcp (same as Python CLI's zeroconf browser)
 */
class NsdDiscoveryManager(
    private val context: Context,
    private val listener: DiscoveryListener
) {
    companion object {
        private const val TAG = "NsdDiscoveryManager"
        // SendSpin mDNS service type (must match server advertisement)
        private const val SERVICE_TYPE = "_sendspin-server._tcp."
    }

    /**
     * Callback interface for discovery events.
     */
    interface DiscoveryListener {
        /**
         * Called when a server is discovered.
         * @param name Service name (mDNS service name, typically hostname)
         * @param host Resolved host address (IPv4 or IPv6 literal, no brackets)
         * @param port Resolved port
         * @param path WebSocket path from TXT records (default: /sendspin)
         * @param friendlyName User-friendly server name from TXT "name" record (defaults to [name])
         */
        fun onServerDiscovered(
            name: String,
            host: String,
            port: Int,
            path: String = "/sendspin",
            friendlyName: String = name
        )
        fun onServerLost(name: String)
        fun onDiscoveryStarted()
        fun onDiscoveryStopped()
        fun onDiscoveryError(error: String)
    }

    private var nsdManager: NsdManager? = null
    private var discoveryListener: NsdManager.DiscoveryListener? = null
    private var multicastLock: WifiManager.MulticastLock? = null

    // Shared executor for API 34+ ServiceInfoCallback dispatch. One executor
    // per manager instead of one per resolve; lazy so browse sessions that
    // never resolve don't spin up a thread. Shut down in cleanup().
    private val resolveExecutorDelegate = lazy { Executors.newSingleThreadExecutor() }

    // Rejection-safe view handed to NsdManager: after cleanup() shuts the
    // executor down, late dispatches (e.g. unregistered confirmations) are
    // dropped instead of throwing inside NsdManager's handler thread.
    private val resolveExecutor = java.util.concurrent.Executor { task ->
        try {
            resolveExecutorDelegate.value.execute(task)
        } catch (e: java.util.concurrent.RejectedExecutionException) {
            Log.d(TAG, "Resolve executor rejected task after shutdown")
        }
    }

    // Outstanding API 34+ callbacks so onServiceLost and cleanup() can
    // unregister them. NsdManager retains a registered callback (and its
    // executor) until unregistration, leaking otherwise.
    private val activeServiceInfoCallbacks = mutableSetOf<NsdManager.ServiceInfoCallback>()

    // These flags are accessed from both the main thread (start/stop calls) and the
    // NSD binder thread (callbacks). @Volatile ensures cross-thread visibility (C-15).
    @Volatile private var isDiscovering = false
    @Volatile private var pendingRestart = false

    // Track services we're currently resolving to avoid duplicate resolutions
    private val resolvingServices = mutableSetOf<String>()

    /**
     * Starts mDNS discovery for SendSpin servers.
     *
     * Must be called from main thread (NsdManager callbacks require Looper).
     */
    fun startDiscovery() {
        if (isDiscovering) {
            Log.d(TAG, "Discovery already running, scheduling restart")
            pendingRestart = true
            return
        }

        // Acquire multicast lock first (required for mDNS)
        acquireMulticastLock()

        // Initialize NsdManager
        nsdManager = context.getSystemService(Context.NSD_SERVICE) as NsdManager

        // Create discovery listener
        discoveryListener = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(serviceType: String) {
                Log.d(TAG, "Discovery started for $serviceType")
                isDiscovering = true
                listener.onDiscoveryStarted()
            }

            override fun onServiceFound(serviceInfo: NsdServiceInfo) {
                Log.d(TAG, "Service found: ${serviceInfo.serviceName}")
                // Resolve to get IP address and port
                resolveService(serviceInfo)
            }

            override fun onServiceLost(serviceInfo: NsdServiceInfo) {
                Log.d(TAG, "Service lost: ${serviceInfo.serviceName}")
                listener.onServerLost(serviceInfo.serviceName)
            }

            override fun onDiscoveryStopped(serviceType: String) {
                Log.d(TAG, "Discovery stopped for $serviceType")
                isDiscovering = false

                // Clear resolving services tracking set to avoid stale entries
                // persisting across discovery sessions (M-09).
                synchronized(resolvingServices) {
                    resolvingServices.clear()
                }

                // Release multicast lock here (not in stopDiscovery()) so it stays
                // held until discovery actually stops on the NSD binder thread (C-15).
                releaseMulticastLock()

                listener.onDiscoveryStopped()

                // Check if we need to restart discovery
                if (pendingRestart) {
                    Log.d(TAG, "Pending restart detected, restarting discovery")
                    pendingRestart = false
                    // Post to handler to avoid potential recursion issues
                    Handler(Looper.getMainLooper()).post {
                        startDiscovery()
                    }
                }
            }

            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                val errorMsg = nsdErrorToString(errorCode)
                Log.e(TAG, "Start discovery failed: $errorMsg (code: $errorCode)")
                isDiscovering = false
                // onDiscoveryStopped won't fire, so release the lock acquired in
                // startDiscovery() here to avoid leaking it.
                releaseMulticastLock()
                listener.onDiscoveryError("Failed to start discovery: $errorMsg")
            }

            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
                val errorMsg = nsdErrorToString(errorCode)
                Log.e(TAG, "Stop discovery failed: $errorMsg (code: $errorCode)")
            }
        }

        // Start discovery
        Log.d(TAG, "Starting NSD discovery for $SERVICE_TYPE")
        try {
            nsdManager?.discoverServices(
                SERVICE_TYPE,
                NsdManager.PROTOCOL_DNS_SD,
                discoveryListener
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start discovery", e)
            listener.onDiscoveryError("Failed to start discovery: ${e.message}")
            releaseMulticastLock()
        }
    }

    /**
     * Resolves a discovered service to get its IP address and port.
     *
     * Note: NsdManager can only resolve one service at a time on older Android versions.
     * We use a tracking set to avoid duplicate resolution attempts.
     *
     * On API 34+ (Android 14), uses registerServiceInfoCallback which replaces the
     * deprecated resolveService/ResolveListener API.
     */
    private fun resolveService(serviceInfo: NsdServiceInfo) {
        val serviceName = serviceInfo.serviceName

        // Avoid duplicate resolutions
        synchronized(resolvingServices) {
            if (resolvingServices.contains(serviceName)) {
                Log.d(TAG, "Already resolving $serviceName, skipping")
                return
            }
            resolvingServices.add(serviceName)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            resolveServiceApi34(serviceInfo, serviceName)
        } else {
            resolveServiceLegacy(serviceInfo, serviceName)
        }
    }

    /**
     * Resolves a service using the API 34+ registerServiceInfoCallback approach.
     */
    @android.annotation.TargetApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun resolveServiceApi34(serviceInfo: NsdServiceInfo, serviceName: String) {
        val callback = object : NsdManager.ServiceInfoCallback {
            override fun onServiceInfoCallbackRegistrationFailed(errorCode: Int) {
                val errorMsg = nsdErrorToString(errorCode)
                Log.e(TAG, "ServiceInfoCallback registration failed for $serviceName: $errorMsg")
                synchronized(resolvingServices) {
                    resolvingServices.remove(serviceName)
                }
                // Registration failed: onServiceInfoCallbackUnregistered will
                // never fire, so drop the tracking entry here.
                synchronized(activeServiceInfoCallbacks) {
                    activeServiceInfoCallbacks.remove(this)
                }
            }

            override fun onServiceUpdated(resolvedInfo: NsdServiceInfo) {
                synchronized(resolvingServices) {
                    resolvingServices.remove(serviceName)
                }

                // Unregister after first successful resolution -- we only need one result
                unregisterServiceInfoCallbackQuietly(this)

                val host = resolvedInfo.hostAddresses.firstOrNull()?.hostAddress
                val port = resolvedInfo.port
                handleResolvedService(resolvedInfo, host, port)
            }

            override fun onServiceLost() {
                Log.d(TAG, "Service lost during resolution: $serviceName")
                synchronized(resolvingServices) {
                    resolvingServices.remove(serviceName)
                }
                // Must unregister here too: NsdManager keeps a lost-service
                // callback registered forever, leaking it (and the executor)
                // on every AP flap or server restart.
                unregisterServiceInfoCallbackQuietly(this)
            }

            override fun onServiceInfoCallbackUnregistered() {
                synchronized(activeServiceInfoCallbacks) {
                    activeServiceInfoCallbacks.remove(this)
                }
            }
        }

        synchronized(activeServiceInfoCallbacks) {
            activeServiceInfoCallbacks.add(callback)
        }
        try {
            // Force-create the shared executor before registering so cleanup()
            // sees it as initialized even if no dispatch ever runs.
            resolveExecutorDelegate.value
            nsdManager?.registerServiceInfoCallback(serviceInfo, resolveExecutor, callback)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register ServiceInfoCallback", e)
            synchronized(resolvingServices) {
                resolvingServices.remove(serviceName)
            }
            synchronized(activeServiceInfoCallbacks) {
                activeServiceInfoCallbacks.remove(callback)
            }
        }
    }

    /**
     * Unregisters a ServiceInfoCallback, tolerating double unregistration.
     * NsdManager throws IllegalArgumentException when the callback is not
     * (or no longer) registered.
     */
    @android.annotation.TargetApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun unregisterServiceInfoCallbackQuietly(callback: NsdManager.ServiceInfoCallback) {
        try {
            nsdManager?.unregisterServiceInfoCallback(callback)
        } catch (e: IllegalArgumentException) {
            // Already unregistered
        } catch (e: Exception) {
            Log.w(TAG, "Failed to unregister ServiceInfoCallback", e)
        }
    }

    /**
     * Resolves a service using the legacy resolveService API (pre-API 34).
     */
    @Suppress("DEPRECATION")
    private fun resolveServiceLegacy(serviceInfo: NsdServiceInfo, serviceName: String) {
        val resolveListener = object : NsdManager.ResolveListener {
            override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                val errorMsg = nsdErrorToString(errorCode)
                Log.e(TAG, "Resolve failed for ${serviceInfo.serviceName}: $errorMsg")
                synchronized(resolvingServices) {
                    resolvingServices.remove(serviceName)
                }
            }

            override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
                synchronized(resolvingServices) {
                    resolvingServices.remove(serviceName)
                }

                val host = serviceInfo.host?.hostAddress
                val port = serviceInfo.port
                handleResolvedService(serviceInfo, host, port)
            }
        }

        try {
            nsdManager?.resolveService(serviceInfo, resolveListener)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to resolve service", e)
            synchronized(resolvingServices) {
                resolvingServices.remove(serviceName)
            }
        }
    }

    /**
     * Processes a resolved service, extracting TXT records and notifying the listener.
     */
    private fun handleResolvedService(serviceInfo: NsdServiceInfo, host: String?, port: Int) {
        if (host != null && port > 0) {
            val address = "$host:$port"

            // Extract path from TXT records (key: "path")
            // Android API 21+ has getAttributes() for TXT records
            val attributes = try {
                serviceInfo.attributes
            } catch (e: Exception) {
                emptyMap<String, ByteArray>()
            }

            // Log all TXT records for debugging
            Log.d(TAG, "TXT records for ${serviceInfo.serviceName}:")
            attributes.forEach { (key, value) ->
                val valueStr = value?.let { String(it, Charsets.UTF_8) } ?: "(null)"
                Log.d(TAG, "  $key = $valueStr")
            }

            // Get path with default
            var path = attributes["path"]?.let { String(it, Charsets.UTF_8) } ?: "/sendspin"
            if (!path.startsWith("/")) {
                path = "/$path"
            }

            // Extract friendly name from TXT "name" record, falling back to service name
            val friendlyName = attributes["name"]?.let { String(it, Charsets.UTF_8) }
                ?: serviceInfo.serviceName

            Log.d(TAG, "Service resolved: ${serviceInfo.serviceName} at $address path=$path friendlyName=$friendlyName")
            listener.onServerDiscovered(serviceInfo.serviceName, host, port, path, friendlyName)
        } else {
            Log.w(TAG, "Service resolved but missing host/port: ${serviceInfo.serviceName}")
        }
    }

    /**
     * Stops mDNS discovery.
     * Note: The actual stop is asynchronous - isDiscovering will be set to false
     * in the onDiscoveryStopped callback.
     */
    fun stopDiscovery() {
        if (!isDiscovering) {
            Log.d(TAG, "Discovery not running")
            return
        }

        // Clear any pending restart when explicitly stopping
        pendingRestart = false

        try {
            discoveryListener?.let { listener ->
                nsdManager?.stopServiceDiscovery(listener)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping discovery", e)
            // On error, mark as not discovering so we can try again
            isDiscovering = false
            // Release lock here since onDiscoveryStopped won't fire on error
            releaseMulticastLock()
        }
        // Note: Don't set isDiscovering = false here - wait for onDiscoveryStopped callback.
        // Multicast lock is released in onDiscoveryStopped to ensure it stays held
        // until discovery actually stops on the NSD binder thread (C-15).
    }

    /**
     * Acquires multicast lock for mDNS discovery.
     *
     * Why needed: Android filters multicast packets by default to save battery.
     * mDNS requires receiving multicast packets on 224.0.0.251.
     */
    private fun acquireMulticastLock() {
        if (multicastLock == null) {
            val wifiManager = context.applicationContext
                .getSystemService(Context.WIFI_SERVICE) as WifiManager
            multicastLock = wifiManager.createMulticastLock("KioskSatellite_NSD").apply {
                setReferenceCounted(true)
                acquire()
            }
            Log.d(TAG, "Multicast lock acquired")
        }
    }

    private fun releaseMulticastLock() {
        multicastLock?.let {
            if (it.isHeld) {
                it.release()
                Log.d(TAG, "Multicast lock released")
            }
            multicastLock = null
        }
    }

    /**
     * Re-acquires the multicast lock if discovery is currently active. Intended
     * to be called from a network link-properties-changed callback (DHCP renewal
     * on the same AP, IPv4/IPv6 stack swap, etc.) where the existing lock may
     * have been silently invalidated by the interface flapping.
     *
     * Safe no-op when discovery is not running. Issue #130.
     */
    fun refreshMulticastLockIfActive() {
        if (!isDiscovering) return
        Log.i(TAG, "Refreshing multicast lock after network link change")
        releaseMulticastLock()
        acquireMulticastLock()
    }

    /**
     * Converts NSD error codes to human-readable strings.
     */
    private fun nsdErrorToString(errorCode: Int): String = when (errorCode) {
        NsdManager.FAILURE_ALREADY_ACTIVE -> "Already active"
        NsdManager.FAILURE_INTERNAL_ERROR -> "Internal error"
        NsdManager.FAILURE_MAX_LIMIT -> "Max limit reached"
        else -> "Unknown error"
    }

    /**
     * Returns whether discovery is currently running.
     */
    fun isDiscovering(): Boolean = isDiscovering

    /**
     * Cleanup resources. Unlike [stopDiscovery], this tears down even when
     * [onDiscoveryStarted] never fired (bounded/one-shot use, or a start failure):
     * it stops the registered discovery and releases the multicast lock
     * unconditionally, so neither the lock nor the NSD registration leaks.
     */
    fun cleanup() {
        pendingRestart = false
        try {
            discoveryListener?.let { nsdManager?.stopServiceDiscovery(it) }
        } catch (e: Exception) {
            Log.d(TAG, "cleanup: stopServiceDiscovery ignored (likely not started): ${e.message}")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Unregister any resolves still in flight so NsdManager releases
            // the callbacks and our executor.
            val outstanding = synchronized(activeServiceInfoCallbacks) {
                val snapshot = activeServiceInfoCallbacks.toList()
                activeServiceInfoCallbacks.clear()
                snapshot
            }
            for (callback in outstanding) {
                unregisterServiceInfoCallbackQuietly(callback)
            }
        }
        if (resolveExecutorDelegate.isInitialized()) {
            resolveExecutorDelegate.value.shutdown()
        }
        isDiscovering = false
        releaseMulticastLock()
        nsdManager = null
        discoveryListener = null
    }
}
