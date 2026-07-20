package me.jxl.kiosk_satellite.sendspin

import android.media.AudioAttributes
import android.media.AudioFormat
import android.os.Build
import android.media.AudioTrack
import android.os.Handler
import android.os.HandlerThread
import android.os.Process
import android.util.Log
import me.jxl.kiosk_satellite.sendspin.audio.AudioSink
import me.jxl.kiosk_satellite.sendspin.audio.AudioTrackSink
import me.jxl.kiosk_satellite.sendspin.protocol.SendSpinProtocol
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.android.asCoroutineDispatcher
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock
import kotlin.math.abs


/**
 * Minimal shim replacing SendspinDroid's AppLog with android.util.Log under
 * the shared "sendspin" tag, preserving the AppLog.Audio / AppLog.Sync call
 * sites in the ported code below.
 */
private object AppLog {
    private const val TAG = "sendspin"

    object Audio {
        fun v(msg: String) { Log.v(TAG, msg) }
        fun d(msg: String) { Log.d(TAG, msg) }
        fun i(msg: String) { Log.i(TAG, msg) }
        fun w(msg: String, tr: Throwable? = null) { Log.w(TAG, msg, tr) }
        fun e(msg: String, tr: Throwable? = null) { Log.e(TAG, msg, tr) }
    }

    object Sync {
        fun v(msg: String) { Log.v(TAG, msg) }
        fun d(msg: String) { Log.d(TAG, msg) }
        fun i(msg: String) { Log.i(TAG, msg) }
        fun w(msg: String, tr: Throwable? = null) { Log.w(TAG, msg, tr) }
        fun e(msg: String, tr: Throwable? = null) { Log.e(TAG, msg, tr) }
    }
}

/**
 * Playback state machine for synchronized audio.
 *
 * Follows the Python reference implementation pattern for start gating and reanchoring.
 * This state machine ensures synchronized playback by controlling when audio starts
 * and handling sync errors gracefully.
 *
 * ## State Diagram
 * ```
 *                              ┌─────────────────────────────────────────────────┐
 *                              │                                                 │
 *                              ▼                                                 │
 *                      ┌──────────────┐                                          │
 *          ┌──────────►│ INITIALIZING │◄──────────────────────────────┐          │
 *          │           └──────┬───────┘                               │          │
 *          │                  │ first chunk received                  │          │
 *          │                  │ (queueChunk)                          │          │
 *          │                  ▼                                       │          │
 *          │      ┌───────────────────────┐                           │          │
 *          │      │  WAITING_FOR_START    │◄──────┐                   │          │
 *          │      │  (buffer filling)     │       │                   │          │
 *          │      └───────────┬───────────┘       │                   │          │
 *          │                  │ buffer >= 200ms   │                   │          │
 *          │                  │ AND scheduled     │ reanchor chunk    │          │
 *          │                  │ start time        │ received          │          │
 *          │                  │ reached           │                   │          │
 *          │                  ▼                   │                   │          │
 *          │           ┌──────────────┐     ┌─────┴──────┐            │          │
 *          │           │   PLAYING    │────►│ REANCHORING│────────────┘          │
 *          │           │              │     └────────────┘                       │
 *          │           └──────┬───────┘      large sync error                    │
 *          │                  │              (> 500ms)                           │
 *          │                  │                                                  │
 *          │                  │ connection lost                                  │
 *          │                  │ (enterDraining)                                  │
 *          │                  ▼                                                  │
 *          │           ┌──────────────┐                                          │
 *          │           │   DRAINING   │──────────────────────────────────────────┘
 *          │           │              │  buffer exhausted
 *          │           └──────┬───────┘
 *          │                  │ reconnected (exitDraining)
 *          │                  │ OR new chunks arrive
 *          │                  ▼
 *          │           ┌──────────────┐
 *          └───────────┤   PLAYING    │
 *            stop()    └──────────────┘
 *            clearBuffer()
 * ```
 *
 * ## State Transition Table
 * ```
 * ┌─────────────────────┬─────────────────────┬─────────────────────────────────────────────────┐
 * │ From State          │ To State            │ Trigger / Condition                             │
 * ├─────────────────────┼─────────────────────┼─────────────────────────────────────────────────┤
 * │ INITIALIZING        │ WAITING_FOR_START   │ First audio chunk received in queueChunk()     │
 * │ WAITING_FOR_START   │ PLAYING             │ Buffer >= 200ms AND scheduled start time       │
 * │                     │                     │ reached (handleStartGating)                    │
 * │ PLAYING             │ REANCHORING         │ Sync error > 500ms (triggerReanchor)           │
 * │ PLAYING             │ DRAINING            │ Connection lost (enterDraining called)         │
 * │ REANCHORING         │ INITIALIZING        │ After clearing buffers (triggerReanchor)       │
 * │ REANCHORING         │ WAITING_FOR_START   │ New chunk received during reanchor             │
 * │ DRAINING            │ PLAYING             │ Reconnected (exitDraining called)              │
 * │ DRAINING            │ INITIALIZING        │ Buffer exhausted during drain                  │
 * │ Any State           │ INITIALIZING        │ stop() or clearBuffer() called                 │
 * └─────────────────────┴─────────────────────┴─────────────────────────────────────────────────┘
 * ```
 *
 * ## State Descriptions
 *
 * ### INITIALIZING
 * Initial state. Waiting for the first audio chunk and time synchronization.
 * No audio output occurs. Transitions to WAITING_FOR_START when first chunk arrives.
 *
 * ### WAITING_FOR_START
 * Buffer is being filled with audio chunks. A scheduled start time has been computed
 * based on the first chunk's server timestamp. Waits until:
 * - Buffer has at least 200ms of audio (MIN_BUFFER_BEFORE_START_MS)
 * - Scheduled start time is reached or passed
 * During this state, the scheduled start time is continuously updated as time sync improves.
 *
 * ### PLAYING
 * Active synchronized playback with sample insert/drop corrections.
 * Audio is written to AudioTrack with:
 * - Sync error monitoring (Kalman filtered)
 * - Sample insertion (slow down) or dropping (speed up) to maintain sync
 * - 500ms startup grace period before corrections begin
 *
 * ### REANCHORING
 * Transient state triggered by large sync error (> 500ms).
 * Clears all buffers and resets timing state to recover from severe desync.
 * Has a 5-second cooldown to prevent thrashing. Transitions to INITIALIZING
 * immediately, then to WAITING_FOR_START when new chunk arrives.
 *
 * ### DRAINING
 * Connection lost but buffer contains audio. Continues playing from buffer while
 * reconnection is attempted. Monitors buffer level and notifies via callback:
 * - onBufferLow() when < 1 second remains
 * - onBufferExhausted() when buffer runs out
 * New chunks can still be queued (seamlessly spliced via gap/overlap handling).
 */
/**
 * Default production [AudioSink] factory for [SyncAudioPlayer].
 *
 * Builds an [AudioTrack] with the same configuration that SyncAudioPlayer previously
 * constructed inline (USAGE_MEDIA / CONTENT_TYPE_MUSIC, MODE_STREAM,
 * PERFORMANCE_MODE_LOW_LATENCY) and wraps it in an [AudioTrackSink]. The
 * [bufferSize] is precomputed by the caller; this factory does not query
 * [AudioTrack.getMinBufferSize].
 *
 * Tests inject a FakeAudioSink instead via SyncAudioPlayer's `sinkFactory`
 * constructor parameter, allowing the player to run off-device without a real
 * AudioTrack.
 */
private fun defaultSinkFactory(
    sampleRate: Int,
    channels: Int,
    bitDepth: Int,
    bufferSize: Int,
): AudioSink {
    val channelConfig = when (channels) {
        1 -> AudioFormat.CHANNEL_OUT_MONO
        2 -> AudioFormat.CHANNEL_OUT_STEREO
        else -> throw IllegalArgumentException("Unsupported channel count: $channels")
    }
    val encoding = when (bitDepth) {
        16 -> AudioFormat.ENCODING_PCM_16BIT
        24 -> if (Build.VERSION.SDK_INT >= 31) {
            AudioFormat.ENCODING_PCM_24BIT_PACKED
        } else {
            throw IllegalStateException("24-bit PCM requires API 31+, device is API ${Build.VERSION.SDK_INT}")
        }
        32 -> if (Build.VERSION.SDK_INT >= 31) {
            AudioFormat.ENCODING_PCM_32BIT
        } else {
            throw IllegalStateException("32-bit PCM requires API 31+, device is API ${Build.VERSION.SDK_INT}")
        }
        else -> throw IllegalArgumentException("Unsupported bit depth: $bitDepth")
    }
    val bytesPerFrame = channels * (bitDepth / 8)
    val builder = AudioTrack.Builder()
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
        )
        .setAudioFormat(
            AudioFormat.Builder()
                .setSampleRate(sampleRate)
                .setChannelMask(channelConfig)
                .setEncoding(encoding)
                .build()
        )
        .setBufferSizeInBytes(bufferSize)
        .setTransferMode(AudioTrack.MODE_STREAM)
    if (Build.VERSION.SDK_INT >= 26) {
        builder.setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)
    }
    return AudioTrackSink(builder.build(), bytesPerFrame)
}

enum class PlaybackState {
    /** Waiting for first audio chunk and time sync to be ready. */
    INITIALIZING,

    /** Buffer filling, scheduled start time computed. Waiting for enough buffer and start time. */
    WAITING_FOR_START,

    /** Active synchronized playback with sample insert/drop corrections. */
    PLAYING,

    /** Large sync error exceeded threshold. Resetting timing state to recover. */
    REANCHORING,

    /** Connection lost. Playing from buffer only while reconnecting. */
    DRAINING
}

/**
 * Callback interface for SyncAudioPlayer state changes.
 */
interface SyncAudioPlayerCallback {
    /**
     * Called when the playback state changes.
     */
    fun onPlaybackStateChanged(state: PlaybackState)

    /**
     * Called when buffer is running low during DRAINING state.
     * This is a warning that playback may stop soon if reconnection doesn't succeed.
     *
     * @param remainingMs Remaining buffer duration in milliseconds
     */
    fun onBufferLow(remainingMs: Long) {}

    /**
     * Called when buffer has been exhausted during DRAINING state.
     * Playback will stop - the connection was lost and buffer ran out.
     */
    fun onBufferExhausted() {}
}

/**
 * Synchronized audio player for Sendspin protocol.
 *
 * Receives PCM audio chunks with server timestamps and plays them at the correct
 * client time using the Kalman-filtered time offset. Uses imperceptible sample
 * insert/drop for sync correction (no pitch changes).
 *
 * ## Sync Correction Strategy
 * Instead of rate adjustment (which causes audible pitch changes), we use sample
 * insert/drop which is completely imperceptible:
 * - Behind schedule: Drop frames to catch up (skip input samples)
 * - Ahead of schedule: Insert duplicate frames to slow down
 * - At 48kHz with 2ms error: ~48 corrections/sec = 1 frame every 1000 frames
 *
 * ## Architecture
 * ```
 * SendSpin ──┬── Audio chunks (timestamped) ──► SyncAudioPlayer
 *                  │                                        │
 *                  └── TimeFilter ◄─────────────────────────┘
 *                         │
 *                    serverToClient()
 * ```
 */
class SyncAudioPlayer(
    private val timeFilter: SendspinTimeFilter,
    private val sampleRate: Int = SendSpinProtocol.AudioFormat.SAMPLE_RATE,
    private val channels: Int = SendSpinProtocol.AudioFormat.CHANNELS,
    private val bitDepth: Int = SendSpinProtocol.AudioFormat.BIT_DEPTH,
    private val maxQueueSamples: Long = 0,  // 0 = unlimited; >0 caps queue to this many samples
    private val requestClientStateSnapshot: () -> Unit = {},
    // Injectable monotonic clock for testability; production default is System.nanoTime().
    private val nowNs: () -> Long = { System.nanoTime() },
    // Injectable audio sink factory for testability; production default wraps AudioTrack.
    // The bufferSize parameter is precomputed (via AudioTrack.getMinBufferSize + multiplier)
    // and passed in rather than queried inside the factory.
    private val sinkFactory: (sampleRate: Int, channels: Int, bitDepth: Int, bufferSize: Int) -> AudioSink =
        ::defaultSinkFactory,
) {
    companion object {
        // Sync correction thresholds (microseconds)
        private const val DEADBAND_THRESHOLD_US = 10_000L       // 10ms - no correction needed
        private const val HARD_RESYNC_THRESHOLD_US = 200_000L   // 200ms - hard resync (drop/skip chunks)

        // Sample insert/drop correction constants (matching Windows SDK for stability)
        private const val MAX_SPEED_CORRECTION = 0.02           // +/-2% max correction rate (was 4%)
        private const val CORRECTION_TARGET_SECONDS = 3.0       // Fix error over 3 seconds (was 2)

        // Startup grace period - no corrections until timing stabilizes (Windows SDK: 500ms)
        private const val STARTUP_GRACE_PERIOD_US = 500_000L    // 500ms grace period

        // Reconnect stabilization period - no corrections after reconnect while Kalman re-converges
        private const val RECONNECT_STABILIZATION_US = 2_000_000L  // 2 seconds

        // Buffer configuration
        private const val BUFFER_SIZE_MULTIPLIER = 4  // Multiplier for minimum buffer size

        // Sync error Kalman filter parameters
        // Expected measurement noise in microseconds (5ms jitter)
        private const val SYNC_ERROR_MEASUREMENT_NOISE_US = 5_000L

        // DAC calibration parameters
        private const val MAX_DAC_CALIBRATIONS = 50  // Keep last N calibration pairs
        private const val MIN_CALIBRATION_INTERVAL_US = 10_000L  // Don't calibrate more often than 10ms

        // Sync error update interval
        private const val SYNC_ERROR_UPDATE_INTERVAL = 5  // Update every N chunks

        // Start gating configuration (from Python reference)
        private const val MIN_BUFFER_BEFORE_START_MS = 200  // Wait for 200ms buffer before scheduling
        private const val REANCHOR_THRESHOLD_US = 500_000L  // 500ms error triggers reanchor

        // DAC-position-aware startup alignment
        private const val TARGET_PENDING_US = 250_000L      // 250ms target write-to-DAC distance
        private const val PENDING_TOL_US = 50_000L           // 50ms pacing tolerance
        private const val START_ALIGN_TOL_US = 50_000L       // 50ms start alignment tolerance
        private const val TIMESTAMP_STABLE_READS = 3         // consecutive valid getTimestamp() reads
        private const val REANCHOR_COOLDOWN_US = 5_000_000L // 5 second cooldown between reanchors

        // Buffer exhaustion thresholds for DRAINING state
        private const val BUFFER_WARNING_MS = 1000L   // Warn when buffer drops below 1 second
        private const val BUFFER_CRITICAL_MS = 200L   // Critical warning at 200ms
        private const val BUFFER_WARNING_INTERVAL_US = 500_000L  // Rate limit warnings to 500ms

        // Silence keepalive: write silence when pending-to-DAC drops below this threshold
        private const val SILENCE_KEEPALIVE_THRESHOLD_US = 200_000L  // 200ms

        // Playback loop timing (milliseconds)
        private const val STATE_POLL_DELAY_MS = 10L   // Polling interval during state transitions
        private const val BUFFER_EMPTY_DELAY_MS = 5L  // Short delay when buffer is empty/draining

        // Gap/overlap detection
        private const val GAP_THRESHOLD_US = 10_000L  // 10ms minimum gap before filling with silence
        private const val DISCONTINUITY_THRESHOLD_US = 100_000L  // 100ms gap indicates discontinuity (for logging)

        // Symmetric crossfade window around each correction (frames before + after)
        private const val CROSSFADE_FRAMES = 4  // 4 frames each side = 83µs at 48kHz

        // 3-point interpolation weights
        private const val BLEND_OUTER = 0.25   // weight for lastOutput and secondary
        private const val BLEND_CENTER = 0.50  // weight for primary frame

        // Baseline refresh interval -- how often to re-derive the server-time baseline
        // from the Kalman filter so early convergence error doesn't stick forever.
        // Python does this on every callback; we do it every 5 seconds for efficiency.
        private const val BASELINE_REFRESH_INTERVAL_US = 5_000_000L  // 5 seconds
        // Minimum Kalman measurements before trusting a refresh (filter must have converged)
        private const val BASELINE_REFRESH_MIN_MEASUREMENTS = 10

        // Logging and diagnostics
        private const val CHUNK_DROP_LOG_INTERVAL = 100  // Log every Nth dropped chunk when time sync not ready
        private const val DAC_PACING_LOG_INTERVAL_US = 10_000_000L  // Log DAC pacing stats every 10 seconds

        // Stuck-state watchdog: detects when the state machine wedges in a
        // non-PLAYING state while chunks are arriving (diagnostic only).
        private const val STUCK_STATE_WARNING_US = 5_000_000L         // 5s
        private const val STUCK_STATE_WARNING_INTERVAL_US = 10_000_000L  // 10s between warnings

        // Pre-sync buffering - buffer chunks while waiting for time sync to be ready
        private const val MAX_PENDING_CHUNKS = 500  // ~10 seconds at 48kHz/20ms chunks

        // Coroutine cancellation. Best-effort wait after scope.cancel(); the
        // worst case is bounded by a single AudioTrack.write() duration (one
        // chunk, ~20 ms at 48 kHz), so 250 ms is comfortably above the typical
        // exit latency and well below Android's 5 s ANR threshold for main.
        private const val PLAYBACK_LOOP_CANCEL_TIMEOUT_MS = 250L
    }

    /**
     * Timestamped audio chunk waiting to be played.
     */
    private data class AudioChunk(
        val serverTimeMicros: Long,
        val pcmData: ByteArray,
        val sampleCount: Int
    )

    // Dedicated audio thread for the playback write loop.
    //
    // The write loop owns every blocking AudioTrack.write() call, the
    // System.nanoTime()-based sync error computation, and the sample
    // insert/drop corrector. Running it on a shared pool (Dispatchers.Default)
    // at normal priority leaves it vulnerable to background CPU throttling:
    // display-pipeline suspend / big.LITTLE migration / thermal DVFS can delay
    // the coroutine past AudioTrack's DAC deadline, causing underruns and
    // phantom sync drift that the corrector then chases with ±4% rate
    // adjustments (audible pitch warble).
    //
    // A HandlerThread constructed with THREAD_PRIORITY_URGENT_AUDIO stays on
    // the audio-class cpuset across foreground/background transitions, which
    // is exactly what AudioTrack MODE_STREAM push-model playback needs.
    //
    // Thread-level lifecycle: created once per SyncAudioPlayer instance, quit
    // in release() after the final coroutine drains. Safe because only one
    // coroutine is ever launched into the scope (the main playback loop), so
    // serializing through a single Looper cannot starve siblings.
    private val audioThread: HandlerThread =
        HandlerThread("SendSpinAudio", Process.THREAD_PRIORITY_URGENT_AUDIO).apply { start() }
    private val audioDispatcher: CoroutineDispatcher =
        Handler(audioThread.looper).asCoroutineDispatcher("SendSpinAudioDispatcher")

    // Coroutine scope for playback - recreated for each playback session
    private var scope: CoroutineScope? = null
    private var playbackJob: Job? = null

    // Lock for thread-safe state transitions
    private val stateLock = ReentrantLock()

    // Flag to track if release() has been called
    private val isReleased = AtomicBoolean(false)

    // Output latency estimator: measures hardware write-to-DAC delay during
    // the pre-playback window and writes the result to timeFilter before PLAYING.
    private val latencyEstimator = me.jxl.kiosk_satellite.sendspin.latency.OutputLatencyEstimator(
        nowNs = nowNs,
    )

    // Audio output
    private var audioSink: AudioSink? = null
    private val isPlaying = AtomicBoolean(false)
    private val isPaused = AtomicBoolean(false)

    // Flush coordination: set by clearBuffer()/enterIdle() on the main thread,
    // checked and cleared by the playback loop before writes.  This avoids
    // flushing AudioTrack while the playback loop is mid-write, which causes
    // clicks/pops and incorrect frame accounting.
    private val isFlushPending = AtomicBoolean(false)
    @Volatile private var pausedAtUs: Long = 0L  // Timestamp when pause() was called, for long-pause detection

    // Playback state machine (from Python reference)
    @Volatile private var playbackState = PlaybackState.INITIALIZING
    @Volatile private var stateCallback: SyncAudioPlayerCallback? = null
    private var scheduledStartLoopTimeUs: Long? = null   // When to start in loop time
    private var firstServerTimestampUs: Long? = null     // First chunk's server timestamp
    private var lastReanchorTimeUs: Long = 0             // Cooldown tracking for reanchor

    // DAC timestamp stability tracking for start gating
    private var consecutiveValidTimestamps = 0       // counts consecutive valid getTimestamp() reads
    private var dacTimestampsStable = false           // true once TIMESTAMP_STABLE_READS reached

    // DAC-aware alignment wait: rate-limit the per-iteration "waiting for alignment"
    // log so a 2-12s wait emits ~3-13 lines instead of 200-1200. Entry log fires once
    // when we first enter alignment wait; progress logs fire at 1s intervals while
    // still waiting; exit log fires when alignment completes. Both fields reset to 0L
    // on successful transition to PLAYING so the next alignment wait emits fresh logs.
    @Volatile private var alignmentWaitStartedAtUs: Long = 0L
    @Volatile private var alignmentWaitLastLoggedUs: Long = 0L

    // DRAINING state tracking - for seamless reconnection
    private var drainingStartTimeUs: Long = 0            // When we entered DRAINING state
    private var lastBufferWarningTimeUs: Long = 0        // Rate limiting for buffer warnings
    private var lastDacPacingLogTimeUs: Long = 0         // Rate limiting for DAC pacing diagnostics
    private var stateBeforeDraining: PlaybackState? = null  // State to restore if exitDraining during non-PLAYING
    private var reconnectedAtUs: Long = 0L               // When exitDraining() was called (for stabilization)

    // Chunk queue
    private val chunkQueue = ConcurrentLinkedQueue<AudioChunk>()
    private val totalQueuedSamples = AtomicLong(0)
    private var queueCapDrops = 0  // Counter for capacity-based drops (diagnostics)

    // Sync tracking
    private var lastChunkServerTime = 0L
    @Volatile private var streamGeneration = 0  // Incremented on stream/clear to invalidate old chunks

    // Sync error tracking
    private var syncUpdateCounter = 0  // Counter for update interval
    private val totalFramesWritten = AtomicLong(0)  // Total frames written to AudioTrack

    // Playback position tracking (in server timeline)
    // Tracks where we've written up to in the server timeline (input side).
    // Advanced in playChunkWithCorrection based on input frames consumed.
    // Used for stats/UI display only; NOT used in sync error calculation.
    @Volatile private var serverTimelineCursor = 0L
    private var serverTimelineCursorRemainder = 0L  // Sub-microsecond accumulator for precision

    // ========================================================================
    // Sync Error Tracking
    // ========================================================================
    //
    // Sync error = actualPlaybackServerTimeUs - expectedPlaybackServerTimeUs
    //   - actual: baseline + DAC frame delta (advances at DAC hardware clock rate)
    //   - expected: fresh Kalman conversion at DAC time (advances at server clock rate)
    // At calibration these are identical; divergence = DAC-vs-server clock drift.
    //
    // Sign convention:
    //   Positive = DAC ahead of expected (playing fast) -> need DROP
    //   Negative = DAC behind expected (playing slow) -> need INSERT
    //
    private var playbackStartTimeUs = 0L          // When playback started (for stats display)
    private var startTimeCalibrated = false       // Has playback start been calibrated from AudioTimestamp?

    // Server-time baseline tracking for absolute sync error calculation
    // At calibration, we capture the relationship between DAC frame position and server time.
    // The baseline is periodically refreshed as the Kalman filter converges (see BASELINE_REFRESH_INTERVAL_US).
    private var baselineFramePosition = 0L        // DAC frame position at calibration
    private var baselineServerTimeUs = 0L         // Corresponding server time at calibration
    private var lastBaselineRefreshUs = 0L        // When baseline was last refreshed
    private var samplesReadSinceStart = 0L        // Total samples consumed since playback started
    @Volatile private var syncErrorUs = 0L        // Current sync error (for display)

    @Volatile private var syncMuted: Boolean = false

    /// Multiplier applied to outgoing samples while a voice interaction
    /// needs the music quiet; 1.0 = normal.
    @Volatile var duckFactor: Float = 1f

    // 2D Kalman filter for sync error smoothing (tracks offset + drift)
    // Based on Python reference implementation for optimal noise filtering
    private val syncErrorFilter = SyncErrorFilter(
        measurementNoiseUs = SYNC_ERROR_MEASUREMENT_NOISE_US
    )

    // DAC calibration state - tracks (dacTimeUs, loopTimeUs) pairs for time conversion
    // Used to convert DAC hardware time to loop/system time
    private data class DacCalibration(val dacTimeUs: Long, val loopTimeUs: Long)
    private val dacLoopCalibrations = ArrayDeque<DacCalibration>()
    private var lastDacCalibrationTimeUs = 0L

    // Frame position wrap detection for pre-API-28 hardware.
    // Some HAL implementations use 32-bit counters internally, causing framePosition
    // to wrap around ~4.29 billion frames (~24.8 hours at 48kHz). Track the last valid
    // frame position so we can detect and reject wrapped values.
    private var lastValidFramePosition = 0L

    // Sample insert/drop correction state (from Python reference)
    private var insertEveryNFrames: Int = 0      // Insert duplicate frame every N frames (slow down)
    private var dropEveryNFrames: Int = 0        // Drop frame every N frames (speed up)
    private var framesUntilNextInsert: Int = 0   // Countdown to next insert
    private var framesUntilNextDrop: Int = 0     // Countdown to next drop
    private var lastOutputFrame: ByteArray = ByteArray(0)  // Last frame written (for duplication)

    // Crossfade and interpolation state for smooth sync corrections
    private var secondLastOutputFrame = ByteArray(0)  // For 3-point INSERT interpolation
    private var crossfadeState = CrossfadeState.IDLE
    private var crossfadeProgress = 0
    private var crossfadeTargetFrame = ByteArray(0)   // Blended frame to crossfade toward/from

    private enum class CrossfadeState { IDLE, FADING_IN, FADING_OUT }

    // Startup grace period tracking (Windows SDK style)
    // No corrections applied until STARTUP_GRACE_PERIOD_US after entering PLAYING state
    private var playingStateEnteredAtUs = 0L     // When we transitioned to PLAYING state

    // Statistics - @Volatile because written from playback loop / WebSocket thread
    // and read from main thread via getStats()
    @Volatile private var chunksReceived = 0L
    @Volatile private var chunksPlayed = 0L
    @Volatile private var chunksDropped = 0L
    @Volatile private var syncCorrections = 0L
    @Volatile private var framesInserted = 0L
    @Volatile private var framesDropped = 0L
    @Volatile private var reanchorCount = 0L        // Count of reanchor events
    @Volatile private var bufferUnderrunCount = 0L  // Count of times queue was empty during playback

    // Stuck-state watchdog: tracks when a non-PLAYING state was first entered.
    // Used by the stats logger to surface state-machine deadlocks.
    private var stuckStateEnteredAtUs: Long = 0L
    private var lastObservedState: PlaybackState = PlaybackState.INITIALIZING
    private var lastStuckWarningAtUs: Long = 0L

    // Pre-sync chunk buffer - holds chunks received before time sync is ready.
    // These will be processed once time sync completes. Mutations require the
    // `synchronized(pendingChunks)` monitor; see [hasPendingChunks] for the
    // lock-free reader hint.
    private val pendingChunks = mutableListOf<Pair<Long, ByteArray>>()

    // Lock-free fast-path hint for [processPendingChunks]. Writes happen under
    // `synchronized(pendingChunks)`, reads are lock-free. A stale-true read is
    // benign (one wasted lock acquisition); a stale-false read is prevented
    // because every add sets this before releasing the monitor, and @Volatile
    // gives the subsequent reader the correct visibility.
    @Volatile private var hasPendingChunks = false

    // Gap/overlap handling (from Python reference)
    private var expectedNextTimestampUs: Long? = null  // Expected server timestamp of next chunk
    private var gapsFilled = 0L           // Count of gaps filled with silence
    private var gapSilenceMs = 0L         // Total milliseconds of silence inserted
    private var overlapsTrimmed = 0L      // Count of overlaps trimmed
    private var overlapTrimmedMs = 0L     // Total milliseconds of audio trimmed

    // Bytes per sample (e.g., 2 channels * 2 bytes = 4 bytes per sample frame)
    private val bytesPerFrame = channels * (bitDepth / 8)

    // Pre-allocated silence buffer for DAC pre-calibration and keepalive (10ms at sample rate).
    // Avoids allocating a new ByteArray on every iteration of the hot audio loop (~100 alloc/sec).
    private val silenceFrameCount = sampleRate / 100  // 10ms of silence
    private val silenceBuffer = ByteArray(silenceFrameCount * bytesPerFrame)

    // Microseconds per sample frame
    private val microsPerSample = 1_000_000.0 / sampleRate

    /**
     * Initialize the audio player with the specified format.
     */
    fun initialize() {
        if (isReleased.get()) {
            AppLog.Audio.e("Cannot initialize - player has been released")
            return
        }

        stateLock.withLock {
            if (audioSink != null) {
                AppLog.Audio.w("Already initialized")
                return
            }
        }

        val channelConfig = when (channels) {
            1 -> AudioFormat.CHANNEL_OUT_MONO
            2 -> AudioFormat.CHANNEL_OUT_STEREO
            else -> {
                AppLog.Audio.e("Unsupported channel count: $channels")
                return
            }
        }

        val encoding = when (bitDepth) {
            16 -> AudioFormat.ENCODING_PCM_16BIT
            24 -> if (Build.VERSION.SDK_INT >= 31) {
                AudioFormat.ENCODING_PCM_24BIT_PACKED
            } else {
                AppLog.Audio.e("24-bit PCM requires API 31+, device is API ${Build.VERSION.SDK_INT}")
                return
            }
            32 -> if (Build.VERSION.SDK_INT >= 31) {
                AudioFormat.ENCODING_PCM_32BIT
            } else {
                AppLog.Audio.e("32-bit PCM requires API 31+, device is API ${Build.VERSION.SDK_INT}")
                return
            }
            else -> {
                AppLog.Audio.e("Unsupported bit depth: $bitDepth")
                return
            }
        }

        // Calculate minimum buffer size
        val minBufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfig, encoding)
        // Use larger buffer for scheduling headroom
        val bufferSize = maxOf(minBufferSize * BUFFER_SIZE_MULTIPLIER, sampleRate * bytesPerFrame) // ~1 second

        try {
            audioSink = sinkFactory(sampleRate, channels, bitDepth, bufferSize)

            // Pre-allocate frame buffers for sync correction (avoids GC in audio callback)
            lastOutputFrame = ByteArray(bytesPerFrame)
            secondLastOutputFrame = ByteArray(bytesPerFrame)
            crossfadeTargetFrame = ByteArray(bytesPerFrame)
            crossfadeScratchBuf = ByteArray(bytesPerFrame)

            AppLog.Audio.i("AudioTrack initialized: ${sampleRate}Hz, ${channels}ch, ${bitDepth}bit, buffer=${bufferSize}bytes")

            // Start latency measurement. The estimator collects write/DAC-timestamp
            // pairs during the pre-playback window and fires the callback once it
            // converges (20 samples) or times out (2 s). The WAITING_FOR_START gate
            // (Task 13) holds until the result arrives.
            latencyEstimator.start { result ->
                when (result) {
                    is me.jxl.kiosk_satellite.sendspin.latency.OutputLatencyEstimator.Result.Converged -> {
                        timeFilter.setAutoMeasuredDelayMicros(
                            result.latencyMicros,
                            me.jxl.kiosk_satellite.sendspin.latency.StaticDelaySource.AUTO,
                        )
                        AppLog.Audio.i("[delay-cal] converged: ${result.latencyMicros}us from ${result.sampleCount} samples")
                    }
                    is me.jxl.kiosk_satellite.sendspin.latency.OutputLatencyEstimator.Result.TimedOut -> {
                        timeFilter.setAutoMeasuredDelayMicros(
                            0L,
                            me.jxl.kiosk_satellite.sendspin.latency.StaticDelaySource.NONE,
                        )
                        AppLog.Audio.w("[delay-cal] timed out with ${result.sampleCount} samples; falling back to 0")
                    }
                }
                requestClientStateSnapshot()
            }
        } catch (e: Exception) {
            AppLog.Audio.e("Failed to create AudioTrack", e)
        }
    }

    /**
     * Start playback.
     *
     * This method is thread-safe and handles rapid start/stop cycles by ensuring
     * any existing coroutine scope is fully cancelled before creating a new one.
     */
    fun start() {
        if (isReleased.get()) {
            AppLog.Audio.e("Cannot start - player has been released")
            return
        }

        // Phase 1: Under lock, capture old playback loop refs and check preconditions
        val captured = stateLock.withLock {
            if (isPlaying.get()) {
                AppLog.Audio.w("Already playing")
                return
            }

            if (audioSink == null) {
                AppLog.Audio.e("AudioTrack not initialized")
                return
            }

            // Capture and clear old playback loop references while holding the lock.
            // The actual cancellation/join happens outside the lock to avoid deadlock.
            captureAndClearPlaybackLoop()
        }

        // Phase 2: Outside lock - cancel old scope and wait for coroutine to finish.
        // Safe because references were already nulled under the lock, so no other
        // thread can see or interact with the old scope/job.
        awaitPlaybackLoopCancellation(captured)

        // Phase 3: Re-acquire lock to set up new playback state
        stateLock.withLock {
            // Re-check preconditions after re-acquiring lock - another thread may
            // have called start() or release() while we were awaiting cancellation
            if (isPlaying.get() || isReleased.get()) {
                AppLog.Audio.w("State changed during playback loop cancellation - aborting start")
                return
            }

            val track = audioSink
            if (track == null) {
                AppLog.Audio.e("AudioTrack was released during playback loop cancellation")
                return
            }

            // Defensive check: scope should be null after capture+await
            if (scope != null) {
                AppLog.Audio.e("BUG: Scope was not null after cancellation - forcing cleanup")
                scope?.cancel()
                scope = null
            }

            // Create a new scope for this playback session
            // Using SupervisorJob so child failures don't cancel the scope.
            // Dispatcher is backed by a dedicated HandlerThread running at
            // THREAD_PRIORITY_URGENT_AUDIO so the write loop keeps its audio
            // deadline even when the app is backgrounded.
            scope = CoroutineScope(SupervisorJob() + audioDispatcher)

            isPlaying.set(true)
            isPaused.set(false)
            track.play()

            // Start the playback loop
            startPlaybackLoop()

            AppLog.Audio.i("Playback started")
        }
    }

    /**
     * Pause playback.
     *
     * Flushes the AudioTrack hardware buffer so audio stops immediately.
     * The chunk-level queue is preserved for seamless resume.
     */
    fun pause() {
        stateLock.withLock {
            isPaused.set(true)
            pausedAtUs = nowNs() / 1000
            audioSink?.pause()
            audioSink?.flush()
            AppLog.Audio.d("Playback paused")
        }
    }

    /**
     * Resume playback.
     *
     * Resets sync state that becomes stale during pause:
     * - DAC calibrations (System.nanoTime() continues advancing during pause)
     * - Sync error filter (pre-pause error is no longer relevant)
     * - Correction schedule (start fresh)
     * - Grace period (allow sync to stabilize after resume)
     *
     * For long pauses (>5 seconds), clears the buffer and reinitializes
     * since buffered chunks will be too stale.
     */
    fun resume() {
        stateLock.withLock {
            if (!isPaused.get()) {
                // Even if our flag says not paused, the AudioTrack hardware might still be paused
                // (e.g., after clearBuffer() was called while paused)
                if (audioSink?.playState != AudioTrack.PLAYSTATE_PLAYING) {
                    AppLog.Audio.i("resume() - isPaused is false but AudioTrack is not playing, forcing play")
                    audioSink?.play()
                } else {
                    AppLog.Audio.d("resume() called but not paused - ignoring")
                }
                return@withLock
            }

            val nowUs = nowNs() / 1000
            val pauseDurationUs = nowUs - pausedAtUs
            val LONG_PAUSE_THRESHOLD_US = 5_000_000L  // 5 seconds

            if (pauseDurationUs > LONG_PAUSE_THRESHOLD_US) {
                AppLog.Audio.d("Long pause detected (${pauseDurationUs / 1000}ms) - clearing stale buffer")
                // Clear buffer and let it refill from server
                chunkQueue.clear()
                totalQueuedSamples.set(0)
                setPlaybackState(PlaybackState.INITIALIZING)
                expectedNextTimestampUs = null
            }

            // Clear stale DAC calibrations - they become invalid during pause
            // because System.nanoTime() continues advancing
            clearDacCalibrations()

            // Reset DAC timestamp stability -- must re-establish after resume
            consecutiveValidTimestamps = 0
            dacTimestampsStable = false

            // Reset sync error filter and server-time baseline - pre-pause state is no longer relevant
            syncErrorFilter.reset()
            syncErrorUs = 0L
            startTimeCalibrated = false        // Force recalibration after resume
            baselineFramePosition = 0L
            baselineServerTimeUs = 0L

            // Reset correction schedule - start fresh
            insertEveryNFrames = 0
            dropEveryNFrames = 0
            framesUntilNextInsert = 0
            framesUntilNextDrop = 0
            crossfadeState = CrossfadeState.IDLE
            crossfadeProgress = 0

            // Reset grace period to allow sync to stabilize after resume
            playingStateEnteredAtUs = nowUs

            isPaused.set(false)
            audioSink?.play()
            AppLog.Audio.d("Playback resumed after ${pauseDurationUs / 1000}ms pause - sync state reset")
        }
    }

    /**
     * Set the playback volume.
     *
     * Note: Volume is now controlled via device STREAM_MUSIC (AudioManager),
     * not per-AudioTrack gain. This method is kept for API compatibility but
     * AudioTrack always plays at full volume. Device volume handles attenuation.
     *
     * @param volume Volume level from 0.0 (mute) to 1.0 (full volume) - ignored
     */
    @Suppress("UNUSED_PARAMETER")
    fun setVolume(volume: Float) {
        // Volume is now controlled via device STREAM_MUSIC, not AudioTrack gain.
        // AudioTrack plays at full volume; device media stream handles attenuation.
        // This follows Spotify/Plexamp best practices for hardware volume button support.
        AppLog.Audio.d("setVolume called (ignored - using device volume): $volume")
    }

    /**
     * Silence audio output without disturbing buffer drain rate or DAC
     * timing. Used by the protocol layer when reporting `state="error"`
     * to the server: per Sendspin spec, the client must mute its output
     * and continue buffering until it can resume synchronized playback.
     *
     * Calling with `false` resumes pass-through audio on the next chunk.
     * Idempotent.
     */
    fun setSyncMuted(muted: Boolean) {
        if (syncMuted == muted) return
        syncMuted = muted
        AppLog.Audio.i("Sync mute=$muted")
    }

    /**
     * Stop playback and clear buffers.
     *
     * This method is thread-safe and can be called from any thread.
     * It will wait for the playback loop to finish before returning.
     */
    fun stop() {
        // Phase 1: Under lock, signal stop and capture playback loop references
        val captured = stateLock.withLock {
            // Signal the playback loop to stop
            isPlaying.set(false)
            isPaused.set(false)

            // Capture and clear playback loop references while holding the lock
            captureAndClearPlaybackLoop()
        }

        // Phase 2: Outside lock - cancel scope and wait for coroutine to finish.
        // The isPlaying=false signal causes the loop's while condition to exit,
        // and scope.cancel() ensures prompt cancellation of any suspend points.
        awaitPlaybackLoopCancellation(captured)

        // Phase 3: Re-acquire lock for AudioTrack and state cleanup
        stateLock.withLock {
            // Now safe to manipulate AudioTrack - playback loop has stopped
            isFlushPending.set(false)  // Clear any pending flush since we flush directly below
            audioSink?.stop()
            audioSink?.flush()
            chunkQueue.clear()
            totalQueuedSamples.set(0)

            // Clear pending chunks buffer
            synchronized(pendingChunks) {
                pendingChunks.clear()
                hasPendingChunks = false
            }

            // Reset playback state machine
            setPlaybackState(PlaybackState.INITIALIZING)
            scheduledStartLoopTimeUs = null
            firstServerTimestampUs = null

            // Reset DAC timestamp stability tracking
            consecutiveValidTimestamps = 0
            dacTimestampsStable = false

            AppLog.Audio.i("Playback stopped")
        }
    }

    /**
     * Enter idle mode: reset sync state but keep AudioTrack alive and writing silence.
     *
     * Used when the stream ends but the server is still connected. The playback loop
     * continues in INITIALIZING state, writing silence to keep DAC timestamps warm
     * for the next stream start.
     *
     * This method is thread-safe and can be called from any thread.
     */
    fun enterIdle() {
        stateLock.withLock {
            // Mirrors clearBuffer(): invalidate any queueChunk() invocations
            // that are still in flight on the WebSocket IO thread. Without
            // this, a chunk whose queueChunk() captured the pre-idle
            // generation can re-populate the queue after the clears below
            // run, leaving stale audio in the pipeline after stream/end.
            streamGeneration++

            AppLog.Audio.i("[cmd-trace] T4 enterIdle ts=${nowNs() / 1_000_000} thread=${Thread.currentThread().name} gen=$streamGeneration")

            // Clear all audio buffers
            chunkQueue.clear()
            totalQueuedSamples.set(0)
            synchronized(pendingChunks) {
                pendingChunks.clear()
                hasPendingChunks = false
            }

            lastChunkServerTime = 0L

            // Reset playback state machine to INITIALIZING (silence-writing state)
            setPlaybackState(PlaybackState.INITIALIZING)
            scheduledStartLoopTimeUs = null
            firstServerTimestampUs = null

            // Reset sync error tracking
            syncUpdateCounter = 0
            totalFramesWritten.set(0)
            serverTimelineCursor = 0L
            serverTimelineCursorRemainder = 0L
            playbackStartTimeUs = 0L
            startTimeCalibrated = false
            baselineFramePosition = 0L
            baselineServerTimeUs = 0L
            lastBaselineRefreshUs = 0L
            samplesReadSinceStart = 0L
            syncErrorUs = 0L
            syncErrorFilter.reset()
            clearDacCalibrations()
            playingStateEnteredAtUs = 0L

            // Reset DAC timestamp stability tracking so it re-warms
            consecutiveValidTimestamps = 0
            dacTimestampsStable = false
            lastDacPacingLogTimeUs = 0L

            // Reset sample insert/drop correction state
            insertEveryNFrames = 0
            dropEveryNFrames = 0
            framesUntilNextInsert = 0
            framesUntilNextDrop = 0
            lastOutputFrame.fill(0)
            secondLastOutputFrame.fill(0)
            crossfadeTargetFrame.fill(0)
            crossfadeScratchBuf.fill(0)
            crossfadeState = CrossfadeState.IDLE
            crossfadeProgress = 0

            // Reset gap/overlap tracking
            expectedNextTimestampUs = null

            // Signal the playback loop to flush AudioTrack before its next write.
            // We must NOT flush here because the playback loop may be mid-write()
            // on the coroutine thread (H-11).
            if (audioSink != null && isPlaying.get()) {
                isFlushPending.set(true)
            } else {
                val track = audioSink
                if (track != null) {
                    try {
                        track.flush()
                    } catch (e: IllegalStateException) {
                        AppLog.Audio.w("Failed to flush AudioTrack during enterIdle", e)
                    }
                }
            }

            // NOTE: Do NOT stop AudioTrack or cancel playback loop.
            // The loop will continue in INITIALIZING state, writing silence
            // to keep DAC timestamps warm.

            AppLog.Audio.i("Entered idle mode - continuing silence for DAC keepalive")
        }
    }

    /**
     * Check if this player's format matches the given parameters.
     *
     * Used to determine if the player can be reused for a new stream
     * without tearing down the AudioTrack (preserving DAC timestamp warmth).
     */
    fun matchesFormat(sr: Int, ch: Int, bd: Int): Boolean =
        sr == sampleRate && ch == channels && bd == bitDepth

    /**
     * Capture playback loop references and clear them atomically.
     *
     * Must be called while holding stateLock. Returns a pair of (scope, job) that
     * the caller must pass to [awaitPlaybackLoopCancellation] OUTSIDE the lock.
     *
     * Splitting capture (under lock) from await (outside lock) prevents deadlock:
     * the playback loop may call setPlaybackState() which acquires stateLock, so
     * we must not hold stateLock while waiting for the loop to finish.
     */
    private fun captureAndClearPlaybackLoop(): Pair<CoroutineScope?, Job?> {
        val currentScope = scope
        val job = playbackJob

        // Clear references immediately to prevent race conditions where a new
        // start() call could see stale references
        playbackJob = null
        scope = null

        return Pair(currentScope, job)
    }

    /**
     * Cancel the playback scope and wait for the job to complete.
     *
     * MUST be called OUTSIDE stateLock to avoid deadlock. The playback loop
     * coroutine may be blocked on stateLock (e.g. inside setPlaybackState()),
     * so holding the lock here would create a deadlock cycle:
     *   main thread holds stateLock -> wait for coroutine
     *   coroutine waits for stateLock -> deadlock
     *
     * Uses a [CountDownLatch] + [Job.invokeOnCompletion] instead of
     * `runBlocking { job.join() }`. The scope cancel is the actual cleanup
     * mechanism; this wait only exists so subsequent phases of stop()/release()
     * can touch the AudioTrack without racing the loop's final write. A bare
     * JVM latch avoids spinning up a new coroutine event loop on the caller
     * thread for a single await.
     */
    private fun awaitPlaybackLoopCancellation(scopeAndJob: Pair<CoroutineScope?, Job?>) {
        val (currentScope, job) = scopeAndJob

        if (currentScope == null) {
            return
        }

        // Cancel the scope first - this cancels ALL coroutines in the scope,
        // not just the playback job. This is safer than cancelling individual jobs.
        currentScope.cancel()

        // Wait for the job to complete if it was active
        if (job != null && job.isActive) {
            val latch = CountDownLatch(1)
            job.invokeOnCompletion { latch.countDown() }
            try {
                if (!latch.await(PLAYBACK_LOOP_CANCEL_TIMEOUT_MS, TimeUnit.MILLISECONDS)) {
                    AppLog.Audio.w("Playback loop did not stop within timeout - scope was cancelled, coroutines will be cleaned up")
                }
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
                AppLog.Audio.w("Interrupted while waiting for playback loop to stop", e)
            }
        }

        AppLog.Audio.v("Playback loop cancelled and cleaned up")
    }

    /**
     * Release all resources.
     *
     * After calling this method, the player cannot be reused.
     * This method is idempotent and thread-safe.
     */
    fun release() {
        if (isReleased.getAndSet(true)) {
            AppLog.Audio.w("Already released")
            return
        }

        // Phase 1: Under lock, signal stop and capture playback loop references
        val captured = stateLock.withLock {
            isPlaying.set(false)
            isPaused.set(false)

            // Capture and clear playback loop references while holding the lock
            captureAndClearPlaybackLoop()
        }

        // Phase 2: Outside lock - cancel scope and wait for coroutine to finish
        awaitPlaybackLoopCancellation(captured)

        // Quit the audio HandlerThread only after the playback coroutine has
        // drained off its Looper. Quitting earlier would orphan pending
        // messages and risk IllegalStateException on subsequent post().
        audioThread.quitSafely()

        // Phase 3: Re-acquire lock for final resource cleanup
        stateLock.withLock {
            isFlushPending.set(false)  // Clear any pending flush since we're releasing
            // Cancel any in-flight latency measurement before releasing the track.
            latencyEstimator.cancel()

            // Release AudioTrack
            try {
                audioSink?.stop()
            } catch (e: IllegalStateException) {
                // AudioTrack may already be stopped
                AppLog.Audio.v("AudioTrack already stopped during release")
            }
            audioSink?.release()
            audioSink = null

            // Clear all buffers and state
            chunkQueue.clear()
            totalQueuedSamples.set(0)
            synchronized(pendingChunks) {
                pendingChunks.clear()
                hasPendingChunks = false
            }
            stateCallback = null

            AppLog.Audio.i("Released")
        }
    }

    /**
     * Clear the audio buffer (called on stream/clear or seek).
     *
     * This method is thread-safe. It pauses the playback loop during the clear
     * to prevent concurrent access issues.
     */
    fun clearBuffer() {
        if (isReleased.get()) {
            AppLog.Audio.w("Cannot clear buffer - player has been released")
            return
        }

        stateLock.withLock {
            streamGeneration++

            AppLog.Audio.i("[cmd-trace] T4 clearBuffer ts=${nowNs() / 1_000_000} thread=${Thread.currentThread().name} gen=$streamGeneration")

            // Reset paused state - we're starting a fresh stream (e.g., after seek)
            // This ensures playback loop will process new chunks even if we were paused
            val wasPaused = isPaused.getAndSet(false)

            // Clear the chunk queue (thread-safe operation)
            chunkQueue.clear()
            totalQueuedSamples.set(0)

            // Clear pending chunks buffer
            synchronized(pendingChunks) {
                pendingChunks.clear()
                hasPendingChunks = false
            }

            // Signal the playback loop to flush AudioTrack before its next write.
            // We must NOT flush here because the playback loop may be mid-write()
            // on the coroutine thread -- concurrent pause()/flush() causes clicks/pops
            // and incorrect frame accounting (H-11).
            if (audioSink != null && isPlaying.get()) {
                isFlushPending.set(true)
            } else {
                // Not playing -- safe to flush directly (no concurrent writes)
                val track = audioSink
                if (track != null) {
                    try {
                        track.flush()
                    } catch (e: IllegalStateException) {
                        AppLog.Audio.w("Failed to flush AudioTrack during clearBuffer", e)
                    }
                }
            }

            // Ensure AudioTrack hardware matches software state after clearing pause flag
            if (wasPaused) {
                audioSink?.play()
            }

            lastChunkServerTime = 0L

            // Reset playback state machine
            setPlaybackState(PlaybackState.INITIALIZING)
            scheduledStartLoopTimeUs = null
            firstServerTimestampUs = null
            // Note: lastReanchorTimeUs is NOT reset to maintain cooldown across clears

            // Reset sync error tracking (decoupled architecture)
            syncUpdateCounter = 0
            totalFramesWritten.set(0)
            serverTimelineCursor = 0L
            serverTimelineCursorRemainder = 0L
            playbackStartTimeUs = 0L
            startTimeCalibrated = false
            baselineFramePosition = 0L       // Reset server-time baseline
            baselineServerTimeUs = 0L
            lastBaselineRefreshUs = 0L
            samplesReadSinceStart = 0L
            syncErrorUs = 0L
            syncErrorFilter.reset()
            clearDacCalibrations()  // Clear DAC calibration history
            playingStateEnteredAtUs = 0L  // Reset grace period

            // Reset DAC timestamp stability tracking
            consecutiveValidTimestamps = 0
            dacTimestampsStable = false
            lastDacPacingLogTimeUs = 0L
            lastValidFramePosition = 0L  // Reset frame position wrap detection

            // Reset sample insert/drop correction state
            insertEveryNFrames = 0
            dropEveryNFrames = 0
            framesUntilNextInsert = 0
            framesUntilNextDrop = 0
            // Clear frame buffers but keep the pre-allocated arrays
            lastOutputFrame.fill(0)
            secondLastOutputFrame.fill(0)
            crossfadeTargetFrame.fill(0)
            crossfadeScratchBuf.fill(0)
            crossfadeState = CrossfadeState.IDLE
            crossfadeProgress = 0

            // Reset gap/overlap tracking
            expectedNextTimestampUs = null

            AppLog.Audio.d("Buffer cleared, generation=$streamGeneration, state=$playbackState")
        }
    }

    /**
     * Evict oldest chunks from the queue if adding [newSamples] would exceed the
     * capacity limit. Only active when [maxQueueSamples] > 0.
     */
    private fun evictIfOverCapacity(newSamples: Long) {
        if (maxQueueSamples <= 0) return
        while (totalQueuedSamples.get() + newSamples > maxQueueSamples) {
            val evicted = chunkQueue.poll() ?: break
            totalQueuedSamples.addAndGet(-evicted.sampleCount.toLong())
            queueCapDrops++
            if (queueCapDrops % 100 == 1) {
                AppLog.Audio.w("Queue capacity limit reached ($maxQueueSamples samples), " +
                    "dropping oldest chunks (total drops: $queueCapDrops)")
            }
        }
    }

    /**
     * Queue an audio chunk for playback.
     *
     * Handles gaps and overlaps in the audio stream following the Python reference:
     * - Gaps: Insert silence to fill gaps larger than GAP_THRESHOLD_US
     * - Overlaps: Trim the start of chunks that overlap with already-queued audio
     *
     * @param serverTimeMicros Server timestamp when this audio should play
     * @param pcmData Raw PCM audio data
     */
    fun queueChunk(serverTimeMicros: Long, pcmData: ByteArray) {
        if (isReleased.get()) return
        chunksReceived++

        // Buffer chunks until time sync has CONVERGED, not merely produced
        // a first estimate. Starting on an early estimate cost a fresh
        // process ~1.5s of clock error, which the sync corrector then
        // "fixed" with a reanchor seconds into playback — the estimate is
        // cheap to wait out (about a second) and the reanchor is not.
        if (!timeFilter.isConverged) {
            synchronized(pendingChunks) {
                if (pendingChunks.size < MAX_PENDING_CHUNKS) {
                    pendingChunks.add(Pair(serverTimeMicros, pcmData))
                    hasPendingChunks = true
                    if (pendingChunks.size == 1) {
                        AppLog.Audio.d("Buffering chunks while waiting for time sync...")
                    }
                } else {
                    chunksDropped++  // Only drop if buffer is full
                    if (chunksDropped % CHUNK_DROP_LOG_INTERVAL == 1L) {
                        AppLog.Audio.w("Pending buffer full, dropping chunk (dropped: $chunksDropped)")
                    }
                }
            }
            return
        }

        // Process any pending chunks first (once time sync is ready)
        processPendingChunks()

        // Now process the current chunk
        processChunk(serverTimeMicros, pcmData)
    }

    /**
     * Process pending chunks that were buffered while waiting for time sync.
     * Called when time sync becomes ready.
     *
     * Drains `pendingChunks` under its monitor and then processes the drained
     * snapshot OUTSIDE the monitor. This is required because [processChunk]
     * acquires `stateLock`, while `stop()`, `clearBuffer()`, `enterIdle()`,
     * and `release()` acquire `stateLock` BEFORE `synchronized(pendingChunks)`.
     * Holding `pendingChunks` across a `stateLock` acquisition would create a
     * lock-order inversion and a potential deadlock.
     */
    private fun processPendingChunks() {
        // Lock-free fast path: the overwhelming steady-state case (sync ready,
        // buffer already drained) avoids the monitor entirely.
        if (!hasPendingChunks) return

        val drained: List<Pair<Long, ByteArray>>
        synchronized(pendingChunks) {
            if (pendingChunks.isEmpty()) {
                hasPendingChunks = false
                return
            }
            AppLog.Audio.i("Time sync ready, processing ${pendingChunks.size} buffered chunks")
            drained = pendingChunks.toList()
            pendingChunks.clear()
            hasPendingChunks = false
        }

        // processChunk() acquires stateLock - MUST be called outside the
        // synchronized(pendingChunks) block above.
        for ((timestamp, data) in drained) {
            processChunk(timestamp, data)
        }
    }

    /**
     * Process a single audio chunk (internal implementation).
     * Handles gap/overlap detection and state machine transitions.
     *
     * Called from the WebSocket thread. Captures streamGeneration at entry
     * and rechecks before state transitions to avoid racing with clearBuffer()/stop().
     */
    private fun processChunk(serverTimeMicros: Long, pcmData: ByteArray) {
        // Snapshot generation to detect concurrent clearBuffer()/stop() calls.
        // If generation changes mid-processing, this chunk belongs to a stale stream.
        val gen = streamGeneration

        // Working copies that may be modified by gap/overlap handling
        var workingServerTimeMicros = serverTimeMicros
        var workingPcmData = pcmData

        // Initialize expected next timestamp on first chunk
        val expectedNext = expectedNextTimestampUs
        if (expectedNext == null) {
            expectedNextTimestampUs = serverTimeMicros
        } else {
            // Handle gap: insert silence to fill the gap
            if (serverTimeMicros > expectedNext) {
                val gapUs = serverTimeMicros - expectedNext

                // Only fill gaps larger than threshold (small gaps are normal network jitter)
                if (gapUs > GAP_THRESHOLD_US) {
                    val gapFrames = ((gapUs * sampleRate) / 1_000_000).toInt()
                    val silenceBytes = gapFrames * bytesPerFrame
                    val silenceData = ByteArray(silenceBytes)  // Zeros = silence

                    val silenceChunk = AudioChunk(
                        serverTimeMicros = expectedNext,
                        pcmData = silenceData,
                        sampleCount = gapFrames
                    )
                    evictIfOverCapacity(gapFrames.toLong())
                    chunkQueue.add(silenceChunk)
                    totalQueuedSamples.addAndGet(gapFrames.toLong())

                    // Update statistics
                    gapsFilled++
                    val gapMs = gapUs / 1000
                    gapSilenceMs += gapMs

                    // Update expected next timestamp to account for inserted silence
                    val silenceDurationUs = (gapFrames * 1_000_000L) / sampleRate
                    expectedNextTimestampUs = expectedNext + silenceDurationUs
                }
            }
            // Handle overlap: trim the start of the chunk
            else if (serverTimeMicros < expectedNext) {
                val overlapUs = expectedNext - serverTimeMicros
                val overlapFrames = ((overlapUs * sampleRate) / 1_000_000).toInt()
                val trimBytes = overlapFrames * bytesPerFrame

                if (trimBytes < workingPcmData.size) {
                    // Trim the overlapping portion from the start
                    workingPcmData = workingPcmData.copyOfRange(trimBytes, workingPcmData.size)
                    workingServerTimeMicros = expectedNext

                    // Update statistics
                    overlapsTrimmed++
                    val overlapMs = overlapUs / 1000
                    overlapTrimmedMs += overlapMs
                } else {
                    // Entire chunk is overlap - skip it entirely
                    overlapsTrimmed++
                    overlapTrimmedMs += overlapUs / 1000
                    return
                }
            }
        }

        // Check for large discontinuity (new stream or seek) - for logging only
        if (lastChunkServerTime > 0) {
            val serverGap = serverTimeMicros - lastChunkServerTime
            val expectedGapUs = (pcmData.size.toLong() / bytesPerFrame) * microsPerSample.toLong()

            // If gap is more than threshold different from expected, log it
            if (abs(serverGap - expectedGapUs) > DISCONTINUITY_THRESHOLD_US) {
                AppLog.Audio.w("Discontinuity detected: gap=${serverGap}us, expected=${expectedGapUs}us")
            }
        }
        lastChunkServerTime = serverTimeMicros

        // Calculate sample count for the (possibly trimmed) chunk
        val sampleCount = workingPcmData.size / bytesPerFrame

        // Skip empty chunks (can happen after trimming)
        if (sampleCount == 0 || workingPcmData.isEmpty()) {
            return
        }

        val clientPlayTime = timeFilter.serverToClient(workingServerTimeMicros)

        val chunk = AudioChunk(
            serverTimeMicros = workingServerTimeMicros,
            pcmData = workingPcmData,
            sampleCount = sampleCount
        )
        evictIfOverCapacity(sampleCount.toLong())
        chunkQueue.add(chunk)
        totalQueuedSamples.addAndGet(sampleCount.toLong())

        // Update expected next timestamp based on this chunk's duration
        val chunkDurationUs = (sampleCount * 1_000_000L) / sampleRate
        expectedNextTimestampUs = workingServerTimeMicros + chunkDurationUs

        // ====================================================================
        // State Machine Transitions in queueChunk()
        // ====================================================================
        // This is where incoming audio chunks trigger state transitions.
        // The key transitions here are:
        //   INITIALIZING -> WAITING_FOR_START (first chunk establishes timing)
        //   REANCHORING  -> WAITING_FOR_START (recovery from large sync error)
        //
        // Held under stateLock to avoid racing with clearBuffer()/stop() which
        // reset the state machine on the main thread. The generation check
        // ensures we don't apply stale chunk timing after a stream reset.
        //
        // See PlaybackState enum for the complete state diagram.
        // ====================================================================
        stateLock.withLock {
            // If clearBuffer()/stop() ran since we entered processChunk(),
            // this chunk belongs to a stale stream -- skip the transition.
            if (streamGeneration != gen) return

            when (playbackState) {
                PlaybackState.INITIALIZING -> {
                    // TRANSITION: INITIALIZING -> WAITING_FOR_START
                    // Trigger: First audio chunk received while time sync is ready
                    // Action: Record the first chunk's server timestamp as anchor point,
                    //         compute scheduled client-time start, begin buffer filling
                    firstServerTimestampUs = workingServerTimeMicros
                    scheduledStartLoopTimeUs = clientPlayTime
                    setPlaybackState(PlaybackState.WAITING_FOR_START)
                    AppLog.Audio.i("First chunk received: serverTime=${workingServerTimeMicros/1000}ms, " +
                            "scheduled start at ${clientPlayTime/1000}ms, transitioning to WAITING_FOR_START")
                }
                PlaybackState.WAITING_FOR_START -> {
                    // NO TRANSITION - Still in WAITING_FOR_START
                    // Action: Update scheduled start time as time sync improves.
                    // The time filter's offset estimate improves with more samples,
                    // so we recompute the client play time using the original server timestamp.
                    // This ensures the scheduled start aligns with the corrected time sync.
                    val firstTs = firstServerTimestampUs
                    if (firstTs != null) {
                        scheduledStartLoopTimeUs = timeFilter.serverToClient(firstTs)
                    }
                    // Actual transition to PLAYING happens in playback loop's handleStartGating()
                    // when buffer >= 200ms AND scheduled start time is reached.
                }
                PlaybackState.REANCHORING -> {
                    // TRANSITION: REANCHORING -> WAITING_FOR_START
                    // Trigger: New chunk arrives after reanchor cleared all buffers
                    // Action: Treat this as the new "first" chunk, establish new timing anchor.
                    // This completes the reanchor recovery - we have fresh timing reference.
                    firstServerTimestampUs = workingServerTimeMicros
                    scheduledStartLoopTimeUs = clientPlayTime
                    setPlaybackState(PlaybackState.WAITING_FOR_START)
                    AppLog.Sync.i("Reanchoring: new first chunk at serverTime=${workingServerTimeMicros/1000}ms")
                }
                PlaybackState.PLAYING,
                PlaybackState.DRAINING -> {
                    // NO TRANSITION - Normal chunk processing
                    // PLAYING: Standard operation, chunks added to queue for playback.
                    // DRAINING: Reconnected! New chunks arrive and are seamlessly spliced
                    //           into the existing buffer via gap/overlap handling above.
                    //           The exitDraining() call (from SendSpin) will
                    //           transition back to PLAYING once stream is stable.
                }
            }
        }

    }

    // ========================================================================
    // Start Gating and Reanchoring (from Python reference)
    // ========================================================================

    /**
     * Reset sync baselines for a fresh playback start.
     *
     * Called when transitioning to PLAYING from handleStartGating() to set up
     * clean timing anchors. Deduplicates the reset code that was previously
     * repeated in the "late" and "on-time" start gating paths.
     *
     * @param nowMicros Current system time in microseconds (System.nanoTime() / 1000)
     */
    private fun resetSyncBaselines(nowMicros: Long) {
        playbackStartTimeUs = nowMicros
        startTimeCalibrated = false
        baselineFramePosition = 0L
        baselineServerTimeUs = 0L
        samplesReadSinceStart = 0L
        syncErrorUs = 0L
        syncErrorFilter.reset()
    }

    /**
     * Handle start gating - decide when and where to begin playback.
     *
     * Two paths:
     * 1. **DAC-aware** (preferred): If AudioTrack timestamps are stable, use the
     *    hardware DAC position to align the queue head. The key insight is that
     *    `startErr = headChunkServerTime - desiredDacHeadServerTime` cancels
     *    Kalman offset error because both sides go through the same linear
     *    transform (`clientToServer(x) = x + offset - staticDelay`).
     * 2. **Kalman fallback**: If timestamps are not yet stable, use the existing
     *    Kalman-predicted `scheduledStartLoopTimeUs` approach.
     *
     * @return true if we should continue waiting, false if ready to play
     */
    private fun handleStartGating(): Boolean {
        val track = audioSink
        if (track != null && dacTimestampsStable) {
            return handleStartGatingDacAware(track)
        }
        return handleStartGatingKalman()
    }

    /**
     * DAC-position-aware start gating.
     *
     * Uses AudioTrack.getTimestamp() to determine what the DAC is currently
     * outputting, then aligns the chunk queue head to TARGET_PENDING_US ahead
     * of the DAC position. This is resilient to Kalman filter offset error at
     * startup because both `headChunkServerTime` and `desiredDacHeadServerTime`
     * go through the same linear offset transform -- the error cancels in the
     * difference.
     *
     * @return true if we should continue waiting, false if ready to play
     */
    private fun handleStartGatingDacAware(track: AudioSink): Boolean {
        // Wind the estimator's timeout clock before checking its status. Once
        // dacTimestampsStable flips to true, the WAITING_FOR_START branch of
        // the main loop stops calling preCalibrateDacTiming() -- which was the
        // only other path that ticked the estimator. Without this call, an
        // estimator that hasn't accepted 20 samples before DAC stabilises
        // stays in Measuring indefinitely, and the status check below holds
        // us in WAITING_FOR_START forever. On-device that surfaces as
        // MediaSession BUFFERING with a growing chunk queue and no audio.
        latencyEstimator.tick()


        // Measurement-complete clause: don't transition to PLAYING until
        // the latency estimator has converged or timed out. If we don't
        // wait here, an unusually-early server-scheduled start could make
        // us enter PLAYING with staticDelay=0, then change it mid-stream
        // once measurement finishes -- causing a one-time sync jump / click.
        if (latencyEstimator.status == me.jxl.kiosk_satellite.sendspin.latency.OutputLatencyEstimator.Status.Measuring) {
            return true  // keep waiting
        }

        val nowMicros = nowNs() / 1000
        val pendingToDacUs = getPendingToDacUs(track)

        if (pendingToDacUs <= 0) {
            // Timestamp read failed despite being "stable" -- fall back to Kalman
            AppLog.Sync.w("DAC-aware start: getPendingToDacUs returned $pendingToDacUs, falling back to Kalman")
            return handleStartGatingKalman()
        }

        // What server time is the DAC currently outputting?
        val dacNowServerUs = timeFilter.clientToServer(nowMicros - pendingToDacUs)

        // Where should the queue head be in server time?
        // The first real chunk goes at the write cursor, which is pendingToDacUs
        // ahead of the DAC output. Use the actual measured pending (not the
        // steady-state TARGET_PENDING_US constant) so the chunk exits the DAC
        // at the correct wall-clock moment regardless of how much silence
        // accumulated during pre-calibration.
        val desiredHeadServerUs = dacNowServerUs + pendingToDacUs

        val headChunk = chunkQueue.peek() ?: return true  // No chunks yet, keep waiting

        // How far is the actual queue head from where we want it?
        // Positive = head chunk is AHEAD of desired (normal buffer), Negative = head chunk BEHIND (stale)
        val startErrUs = headChunk.serverTimeMicros - desiredHeadServerUs

        if (startErrUs > START_ALIGN_TOL_US) {
            // Queue head is too far ahead of where the DAC needs it -- wait for
            // the DAC to catch up by playing through existing silence. Without
            // this gate, starting with startErr=200ms bakes in a permanent offset.
            //
            // This branch runs every playback-loop iteration (~10ms) while we wait.
            // Rate-limit the log: first-time entry, then once per second progress,
            // then an exit log on transition to PLAYING. See alignmentWait* fields.
            if (alignmentWaitStartedAtUs == 0L) {
                alignmentWaitStartedAtUs = nowMicros
                alignmentWaitLastLoggedUs = nowMicros
                AppLog.Sync.d("DAC-aware start: waiting for alignment, startErr=${startErrUs/1000}ms > ${START_ALIGN_TOL_US/1000}ms")
            } else if (nowMicros - alignmentWaitLastLoggedUs > 1_000_000L) {
                alignmentWaitLastLoggedUs = nowMicros
                val elapsedMs = (nowMicros - alignmentWaitStartedAtUs) / 1000
                AppLog.Sync.d("DAC-aware start: still waiting, startErr=${startErrUs/1000}ms, elapsed=${elapsedMs}ms")
            }
            return true
        }

        if (startErrUs < -START_ALIGN_TOL_US) {
            // Head chunk is behind the DAC -- drop stale chunks until aligned
            var droppedFrames = 0
            var droppedChunks = 0

            while (true) {
                val chunk = chunkQueue.peek() ?: break
                val err = chunk.serverTimeMicros - desiredHeadServerUs
                if (err >= -START_ALIGN_TOL_US) break  // This chunk is close enough

                chunkQueue.poll()
                totalQueuedSamples.addAndGet(-chunk.sampleCount.toLong())
                droppedFrames += chunk.sampleCount
                droppedChunks++
                chunksDropped++
            }

            framesDropped += droppedFrames.toLong()
            AppLog.Sync.d("DAC-aware start: dropped $droppedChunks stale chunks ($droppedFrames frames)")
        }

        // Update timing anchor to actual queue head
        val alignedHead = chunkQueue.peek()
        if (alignedHead == null) {
            // Dropped everything -- wait for more chunks
            AppLog.Sync.w("DAC-aware start: all chunks were stale, waiting for more")
            return true
        }

        firstServerTimestampUs = alignedHead.serverTimeMicros
        scheduledStartLoopTimeUs = timeFilter.serverToClient(alignedHead.serverTimeMicros)

        resetSyncBaselines(nowMicros)

        // Diagnostic logging
        val bufferedMs = (totalQueuedSamples.get() * 1000) / sampleRate
        val finalErr = alignedHead.serverTimeMicros - desiredHeadServerUs
        AppLog.Sync.i("DAC-aware start gating transition: " +
            "startErr=${startErrUs/1000}ms, finalErr=${finalErr/1000}ms, " +
            "pendingToDac=${pendingToDacUs/1000}ms, " +
            "firstServerTs=${firstServerTimestampUs}us, " +
            "kalmanOffset=${timeFilter.offsetMicros/1000}ms, " +
            "kalmanMeasurements=${timeFilter.measurementCountValue}, " +
            "bufferedChunks=${chunkQueue.size}, bufferedMs=$bufferedMs")

        // Exit log for the rate-limited alignment-wait path: emit total elapsed
        // so ops can see how long the DAC took to catch up. Reset both fields
        // so the next alignment cycle (e.g. after a track change) starts fresh.
        if (alignmentWaitStartedAtUs != 0L) {
            val waitElapsedMs = (nowMicros - alignmentWaitStartedAtUs) / 1000
            AppLog.Sync.i("DAC-aware start: alignment complete after ${waitElapsedMs}ms wait")
            alignmentWaitStartedAtUs = 0L
            alignmentWaitLastLoggedUs = 0L
        }

        setPlaybackState(PlaybackState.PLAYING)
        AppLog.Sync.i("DAC-aware start gating complete: now PLAYING")
        return false
    }

    /**
     * Kalman-based start gating (original behavior, used as fallback).
     *
     * Waits for `scheduledStartLoopTimeUs` (computed from Kalman filter) before
     * transitioning to PLAYING. If we're late, drops frames to catch up.
     *
     * @return true if we should continue waiting, false if ready to play
     */
    private fun handleStartGatingKalman(): Boolean {
        val scheduledStart = scheduledStartLoopTimeUs ?: return false
        val nowMicros = nowNs() / 1000
        val deltaUs = scheduledStart - nowMicros

        when {
            deltaUs > 0 -> {
                // Not yet time to start - AudioTrack is already playing silence
                return true  // Keep waiting
            }
            deltaUs < -HARD_RESYNC_THRESHOLD_US -> {
                // We're very late - need to drop frames to catch up
                val framesToDrop = ((-deltaUs * sampleRate) / 1_000_000).toInt()
                var droppedFrames = 0

                AppLog.Sync.w("Kalman start gating: late by ${-deltaUs/1000}ms, dropping $framesToDrop frames")

                // Drop chunks until we've caught up
                while (droppedFrames < framesToDrop) {
                    val chunk = chunkQueue.peek() ?: break
                    val chunkFrames = chunk.sampleCount

                    if (droppedFrames + chunkFrames <= framesToDrop) {
                        chunkQueue.poll()
                        totalQueuedSamples.addAndGet(-chunk.sampleCount.toLong())
                        droppedFrames += chunkFrames
                        chunksDropped++
                    } else {
                        break
                    }
                }

                // Update timing anchors to match what we're actually playing
                val firstPlayableChunk = chunkQueue.peek()
                if (firstPlayableChunk != null) {
                    firstServerTimestampUs = firstPlayableChunk.serverTimeMicros
                    scheduledStartLoopTimeUs = timeFilter.serverToClient(firstPlayableChunk.serverTimeMicros)
                }

                resetSyncBaselines(nowNs() / 1000)

                framesDropped += droppedFrames.toLong()

                // Diagnostic logging
                val bufferedMs = (totalQueuedSamples.get() * 1000) / sampleRate
                AppLog.Sync.i("Kalman start gating transition (late): " +
                    "scheduledStart=${scheduledStartLoopTimeUs}us, now=${nowMicros}us, " +
                    "delta=${deltaUs/1000}ms, " +
                    "firstServerTs=${firstServerTimestampUs}us, " +
                    "kalmanOffset=${timeFilter.offsetMicros/1000}ms, " +
                    "kalmanMeasurements=${timeFilter.measurementCountValue}, " +
                    "bufferedChunks=${chunkQueue.size}, bufferedMs=$bufferedMs")

                setPlaybackState(PlaybackState.PLAYING)
                AppLog.Sync.i("Kalman start gating complete: dropped $droppedFrames frames, now PLAYING")
                return false
            }
            else -> {
                // Within tolerance - start playing
                val firstChunk = chunkQueue.peek()
                if (firstChunk != null && firstServerTimestampUs != firstChunk.serverTimeMicros) {
                    val oldServerTs = firstServerTimestampUs
                    firstServerTimestampUs = firstChunk.serverTimeMicros
                    scheduledStartLoopTimeUs = timeFilter.serverToClient(firstChunk.serverTimeMicros)
                    AppLog.Sync.d("Realigned timing anchor: serverTs ${oldServerTs}->${firstServerTimestampUs}")
                }

                resetSyncBaselines(nowNs() / 1000)

                // Diagnostic logging
                val bufferedMs = (totalQueuedSamples.get() * 1000) / sampleRate
                AppLog.Sync.i("Kalman start gating transition: " +
                    "scheduledStart=${scheduledStartLoopTimeUs}us, now=${nowMicros}us, " +
                    "delta=${deltaUs/1000}ms, " +
                    "firstServerTs=${firstServerTimestampUs}us, " +
                    "kalmanOffset=${timeFilter.offsetMicros/1000}ms, " +
                    "kalmanMeasurements=${timeFilter.measurementCountValue}, " +
                    "bufferedChunks=${chunkQueue.size}, bufferedMs=$bufferedMs")

                setPlaybackState(PlaybackState.PLAYING)
                AppLog.Sync.i("Kalman start gating complete: delta=${deltaUs/1000}ms, now PLAYING")
                return false
            }
        }
    }

    /**
     * Pre-calibrate DAC timing by writing silence during WAITING_FOR_START.
     *
     * This allows us to gather DAC calibration pairs before real audio arrives,
     * making sync error calculations reliable from the first measurement.
     *
     * Android's AudioTimestamp API requires ~21k frames (~443ms at 48kHz) to be
     * played before returning valid data. By actively writing silence during
     * the wait period, we can establish DAC calibration BEFORE real playback
     * begins, avoiding the large initial sync error (~848ms) that would otherwise
     * occur while waiting for calibration.
     */
    private fun preCalibrateDacTiming() {
        val track = audioSink ?: return

        // Write pre-allocated silence (10ms = 480 frames at 48kHz)
        val silenceBytes = silenceBuffer.size
        val silenceWriteTimeNs = nowNs()
        val written = track.write(silenceBuffer, 0, silenceBytes)
        if (written <= 0) return

        // CRITICAL: Track silence frames so sync error calculation is accurate
        // Without this, totalFramesWritten excludes pre-cal silence but framePosition
        // includes it, causing a mismatch that shows up as ~200ms initial sync error
        val framesWritten = written / bytesPerFrame
        totalFramesWritten.addAndGet(framesWritten.toLong())

        // Record the silence write so the latency estimator can pair it with
        // the subsequent getTimestamp() report for this same batch of frames.
        latencyEstimator.recordWrite(totalFramesWritten.get(), silenceWriteTimeNs)

        // Try to get DAC timestamp for calibration and stability tracking
        val ts = track.getTimestamp()
        if (ts != null) {
            val dacTimeUs = ts.nanoTime / 1000
            val loopTimeUs = nowNs() / 1000

            // Sanity check - only store valid timestamps (framePosition > 0 means DAC has started)
            if (ts.framePosition > 0) {
                storeDacCalibration(dacTimeUs, loopTimeUs)
                latencyEstimator.recordDacTimestamp(ts.framePosition, ts.nanoTime)

                // Track consecutive valid reads for DAC-aware start gating
                consecutiveValidTimestamps++
                if (consecutiveValidTimestamps >= TIMESTAMP_STABLE_READS && !dacTimestampsStable) {
                    dacTimestampsStable = true
                    AppLog.Sync.i("DAC timestamps stable after $consecutiveValidTimestamps consecutive reads")
                }
            } else {
                // Invalid framePosition resets stability counter
                consecutiveValidTimestamps = 0
            }
        } else {
            // getTimestamp() failed - reset stability counter
            consecutiveValidTimestamps = 0
        }
        latencyEstimator.tick()
    }

    /**
     * Reduced-rate silence writer for keeping DAC timestamps warm once stable.
     *
     * Unlike preCalibrateDacTiming() which writes every loop iteration (10ms),
     * this only writes when the pending-to-DAC buffer drops below a threshold.
     * This saves CPU during long idle periods while keeping AudioTimestamp valid.
     */
    private fun writeSilenceKeepAlive() {
        val track = audioSink ?: return

        val pendingUs = getPendingToDacUs(track)
        if (pendingUs > SILENCE_KEEPALIVE_THRESHOLD_US) return

        // Write pre-allocated silence (10ms) to top up the buffer
        val keepAliveWriteTimeNs = nowNs()
        val written = track.write(silenceBuffer, 0, silenceBuffer.size)
        if (written > 0) {
            totalFramesWritten.addAndGet((written / bytesPerFrame).toLong())
            latencyEstimator.recordWrite(totalFramesWritten.get(), keepAliveWriteTimeNs)
        }
    }

    /**
     * Trigger a reanchor - reset sync state due to large error.
     *
     * Called when sync error exceeds REANCHOR_THRESHOLD_US.
     * Respects cooldown to avoid thrashing.
     *
     * Note: This is called from the playback loop, so we use tryLock to avoid
     * blocking if another thread holds the lock.
     *
     * @return true if reanchor was triggered, false if still in cooldown or lock unavailable
     */
    private fun triggerReanchor(): Boolean {
        val nowMicros = nowNs() / 1000
        val timeSinceLastReanchor = nowMicros - lastReanchorTimeUs

        if (timeSinceLastReanchor < REANCHOR_COOLDOWN_US) {
            return false
        }

        // Try to acquire the lock without blocking - if we can't, skip this reanchor attempt
        if (!stateLock.tryLock()) {
            return false
        }

        try {
            AppLog.Sync.w("Triggering reanchor: resetting timing, keeping the queue")

            lastReanchorTimeUs = nowMicros
            setPlaybackState(PlaybackState.REANCHORING)

            // Keep the buffered queue: those chunks are the NEXT ~30s of
            // music (the server sends far ahead), and clearing them left a
            // silence hole until the server's send-cursor caught up — the
            // classic restart-mid-song death. Drop only chunks whose
            // deadline has already passed under the corrected clock; the
            // start gate re-aligns against the queue head.
            val nowServerUs = timeFilter.clientToServer(nowMicros)
            var dropped = 0
            while (true) {
                val head = chunkQueue.peek() ?: break
                if (head.serverTimeMicros >= nowServerUs) break
                chunkQueue.poll()
                totalQueuedSamples.addAndGet(-head.sampleCount.toLong())
                dropped++
            }
            if (dropped > 0) {
                AppLog.Sync.i("Reanchor dropped $dropped stale chunks")
            }

            // Safely flush the AudioTrack
            val track = audioSink
            if (track != null) {
                try {
                    track.pause()
                    track.flush()
                    track.play()
                } catch (e: IllegalStateException) {
                    AppLog.Sync.w("Failed to flush AudioTrack during reanchor", e)
                }
            }

            // Reset start gating state
            scheduledStartLoopTimeUs = null
            firstServerTimestampUs = null

            // Reset sync tracking (simplified)
            lastChunkServerTime = 0L
            insertEveryNFrames = 0
            dropEveryNFrames = 0
            crossfadeState = CrossfadeState.IDLE
            crossfadeProgress = 0

            // Reset sync error state (decoupled architecture)
            syncUpdateCounter = 0
            totalFramesWritten.set(0)
            serverTimelineCursor = 0L
            serverTimelineCursorRemainder = 0L
            playbackStartTimeUs = 0L
            startTimeCalibrated = false
            baselineFramePosition = 0L       // Reset server-time baseline
            baselineServerTimeUs = 0L
            lastBaselineRefreshUs = 0L
            samplesReadSinceStart = 0L
            syncErrorUs = 0L
            syncErrorFilter.reset()
            clearDacCalibrations()  // Clear DAC calibration history
            playingStateEnteredAtUs = 0L  // Reset grace period

            // Reset DAC timestamp stability tracking
            consecutiveValidTimestamps = 0
            dacTimestampsStable = false
            lastValidFramePosition = 0L  // Reset frame position wrap detection

            // Transition to INITIALIZING to wait for new chunks
            setPlaybackState(PlaybackState.INITIALIZING)
            syncCorrections++
            reanchorCount++

            return true
        } finally {
            stateLock.unlock()
        }
    }

    /**
     * Main playback loop that writes audio to AudioTrack at the correct time.
     *
     * Uses a state machine for start gating and sample insert/drop for sync correction.
     * This is imperceptible to the listener (no pitch/tempo changes).
     */
    private fun startPlaybackLoop() {
        val currentScope = scope ?: run {
            AppLog.Audio.e("Cannot start playback loop - scope is null")
            return
        }

        playbackJob = currentScope.launch {
            // Confirms per-device whether THREAD_PRIORITY_URGENT_AUDIO was
            // actually honored. Some OEMs clamp audio priorities for non-system
            // apps; logging the effective tid/priority makes field triage
            // deterministic. On a healthy device we expect priority = -19.
            val tid = Process.myTid()
            AppLog.Audio.i(
                "Playback loop thread: name=${Thread.currentThread().name} " +
                    "tid=$tid priority=${Process.getThreadPriority(tid)}"
            )
            AppLog.Audio.d("Playback loop started, initial state=$playbackState")

            while (isActive && isPlaying.get()) {
                if (isPaused.get()) {
                    delay(STATE_POLL_DELAY_MS)
                    continue
                }

                // Handle deferred flush from clearBuffer()/enterIdle().
                // Performed here (on the playback thread) rather than on the
                // main thread to avoid flushing mid-write (H-11).
                if (isFlushPending.compareAndSet(true, false)) {
                    val track = audioSink
                    if (track != null) {
                        try {
                            track.pause()
                            track.flush()
                            track.play()
                        } catch (e: IllegalStateException) {
                            AppLog.Audio.w("Failed to flush AudioTrack (deferred)", e)
                        }
                    }
                }

                // State machine for synchronized playback
                when (playbackState) {
                    PlaybackState.INITIALIZING -> {
                        // Write silence to keep DAC timestamps warm while waiting
                        // for first chunk. Once stable, reduced-rate keepalive.
                        if (!dacTimestampsStable) {
                            preCalibrateDacTiming()
                        } else {
                            writeSilenceKeepAlive()
                        }
                        delay(STATE_POLL_DELAY_MS)
                        continue
                    }

                    PlaybackState.WAITING_FOR_START -> {
                        // Check if we have enough buffer before starting
                        // Duration check alone is sufficient -- the old chunk count gate
                        // (MIN_CHUNKS_BEFORE_START=16) added unnecessary delay and is now
                        // replaced by DAC timestamp stability tracking in preCalibrateDacTiming()
                        val bufferedMs = (totalQueuedSamples.get() * 1000) / sampleRate
                        if (bufferedMs < MIN_BUFFER_BEFORE_START_MS) {
                            // Pre-calibrate DAC timing while waiting for buffer to fill
                            // This establishes timing calibration BEFORE real audio arrives.
                            // Once stable, stop writing silence -- further writes just inflate
                            // totalFramesWritten and increase the DAC-to-first-chunk gap.
                            if (!dacTimestampsStable) {
                                preCalibrateDacTiming()
                            }
                            delay(STATE_POLL_DELAY_MS)
                            continue
                        }

                        // Handle start gating logic
                        if (handleStartGating()) {
                            // Still waiting for scheduled start - continue pre-calibration
                            // only if timestamps aren't stable yet
                            if (!dacTimestampsStable) {
                                preCalibrateDacTiming()
                            }
                            delay(STATE_POLL_DELAY_MS)  // Still waiting for scheduled start
                            continue
                        }
                        // handleStartGating() transitioned us to PLAYING
                    }

                    PlaybackState.REANCHORING -> {
                        // Write silence to keep DAC timestamps warm while waiting
                        // for new chunks after reanchor
                        if (!dacTimestampsStable) {
                            preCalibrateDacTiming()
                        } else {
                            writeSilenceKeepAlive()
                        }
                        delay(STATE_POLL_DELAY_MS)
                        continue
                    }

                    PlaybackState.DRAINING -> {
                        // Connection lost - playing from buffer only
                        // Monitor buffer level and notify if running low
                        val bufferedMs = getBufferedDurationMs()

                        if (bufferedMs <= 0) {
                            // Buffer exhausted - notify and stop
                            AppLog.Audio.e("Buffer exhausted during DRAINING - stopping playback")
                            stateCallback?.onBufferExhausted()
                            setPlaybackState(PlaybackState.INITIALIZING)
                            delay(STATE_POLL_DELAY_MS)
                            continue
                        }

                        // Rate-limited buffer warnings
                        if (bufferedMs < BUFFER_WARNING_MS) {
                            val nowUs = nowNs() / 1000
                            if (nowUs - lastBufferWarningTimeUs > BUFFER_WARNING_INTERVAL_US) {
                                lastBufferWarningTimeUs = nowUs
                                stateCallback?.onBufferLow(bufferedMs)
                                AppLog.Audio.w("Buffer low during DRAINING: ${bufferedMs}ms remaining")
                            }
                        }

                        // Continue playing from buffer (fall through to chunk processing)
                    }

                    PlaybackState.PLAYING -> {
                        // Normal playback - handled below
                    }
                }

                // PLAYING/DRAINING state: process chunks with sync correction
                val chunk = chunkQueue.peek()
                if (chunk == null) {
                    // No chunks available - buffer underrun
                    if (playbackState == PlaybackState.DRAINING) {
                        // In DRAINING, empty queue means we're exhausted (already handled above)
                        delay(BUFFER_EMPTY_DELAY_MS)
                        continue
                    }
                    bufferUnderrunCount++
                    delay(BUFFER_EMPTY_DELAY_MS)
                    continue
                }

                // Pending-to-DAC pacing: only mechanism needed for write timing.
                // The Python CLI uses a pull/callback model (audio system requests
                // frames); on Android we push, so we pace writes by keeping the
                // AudioTrack ring buffer at a target depth. This replaces the old
                // effectiveLead scheduling which drifted due to Kalman offset changes
                // between chunk-queue time and chunk-play time.
                val pendingToDacUs = if (audioSink != null && dacTimestampsStable)
                    getPendingToDacUs(audioSink!!) else 0L

                // Rate-limited DAC pacing diagnostics. The watchdog shares this
                // cadence so stuck-state warnings come out on the same log tick.
                val nowMicros = nowNs() / 1000
                checkStuckState()
                if (dacTimestampsStable && nowMicros - lastDacPacingLogTimeUs > DAC_PACING_LOG_INTERVAL_US) {
                    lastDacPacingLogTimeUs = nowMicros
                    AppLog.Sync.d("DAC pacing: pending=${pendingToDacUs/1000}ms, syncErr=${syncErrorUs/1000}ms")
                }

                // Pause writing when the AudioTrack buffer is sufficiently full
                if (dacTimestampsStable && pendingToDacUs > TARGET_PENDING_US + PENDING_TOL_US) {
                    delay(STATE_POLL_DELAY_MS)
                    continue
                }

                // Reanchor if sync error is extremely large (e.g. after long pause/seek)
                if (startTimeCalibrated && abs(syncErrorUs) > REANCHOR_THRESHOLD_US) {
                    AppLog.Sync.w("Large sync error: ${syncErrorUs/1000}ms, considering reanchor")
                    if (triggerReanchor()) {
                        continue
                    }
                }

                // Normal playback: update correction schedule and write chunk
                updateCorrectionSchedule(0)  // param unused, reads syncErrorFilter
                playChunkWithCorrection(chunk)
            }

            AppLog.Audio.d("Playback loop ended")
        }
    }

    /**
     * Watchdog invoked once per stats-log cycle. Warns if the state machine
     * has been in a non-PLAYING state for more than STUCK_STATE_WARNING_US
     * while chunks are arriving (indicating the pipeline is wedged, not
     * just idle).
     *
     * Diagnostic only -- no recovery action.
     */
    private fun checkStuckState() {
        val nowUs = nowNs() / 1000
        val state = playbackState

        if (state != lastObservedState) {
            lastObservedState = state
            stuckStateEnteredAtUs = nowUs
            return
        }

        if (state == PlaybackState.PLAYING) return

        val stuckUs = nowUs - stuckStateEnteredAtUs
        if (stuckUs < STUCK_STATE_WARNING_US) return

        // Don't spam when there's no audio backlog -- that's a genuinely
        // idle state (e.g. user paused), not a deadlock.
        if (totalQueuedSamples.get() == 0L) return

        // Rate-limit: once warned, stay quiet for STUCK_STATE_WARNING_INTERVAL_US.
        // The `lastStuckWarningAtUs != 0L` guard ensures the first warning always
        // fires -- otherwise `nowUs - 0` is trivially small and the watchdog
        // would silently suppress its very first report.
        if (lastStuckWarningAtUs != 0L &&
            nowUs - lastStuckWarningAtUs < STUCK_STATE_WARNING_INTERVAL_US
        ) return
        lastStuckWarningAtUs = nowUs

        val bufferedMs = (totalQueuedSamples.get() * 1000) / sampleRate
        AppLog.Audio.w(
            "WATCHDOG: state=$state stuck for ${stuckUs / 1000}ms, " +
                "buffered=${bufferedMs}ms, chunks=${chunkQueue.size}, " +
                "estimatorStatus=${latencyEstimator.status}, " +
                "dacTimestampsStable=$dacTimestampsStable"
        )
    }

    /**
     * Update the sample insert/drop correction schedule based on sync error.
     *
     * ## Design Overview
     *
     * This implements **proportional control** for imperceptible audio sync correction.
     * Instead of changing playback rate (which causes audible pitch/tempo changes), we
     * insert or drop individual sample frames. At 48kHz, a single frame is ~21 microseconds
     * - far below the ~10ms threshold of human perception for audio discontinuities.
     *
     * ## Why Proportional Control?
     *
     * A simple on/off correction (always correct at max rate when error exists) would:
     * - Overshoot the target, causing oscillation around zero
     * - Create more audible artifacts due to rapid insert/drop transitions
     *
     * Proportional control provides:
     * - Gentle corrections for small errors (most common case)
     * - Aggressive corrections only when truly needed
     * - Smooth convergence to zero error without oscillation
     *
     * ## The Math: Sync Error to Correction Interval
     *
     * Given a sync error in microseconds, we calculate how often to insert/drop frames:
     *
     * ```
     * 1. Convert error to frames:
     *    framesError = |errorUs| * sampleRate / 1,000,000
     *    Example: 2ms error at 48kHz = 2000 * 48000 / 1000000 = 96 frames
     *
     * 2. Calculate desired corrections per second:
     *    correctionsPerSec = framesError / CORRECTION_TARGET_SECONDS
     *    Example: 96 frames / 3 seconds = 32 corrections/sec
     *
     * 3. Cap at maximum correction rate:
     *    maxCorrectionsPerSec = sampleRate * MAX_SPEED_CORRECTION
     *    Example: 48000 * 0.02 = 960 corrections/sec max
     *
     * 4. Calculate interval between corrections:
     *    intervalFrames = sampleRate / correctionsPerSec
     *    Example: 48000 / 32 = 1500 frames between corrections
     *    (drop/insert 1 frame every 1500 frames = 31ms)
     * ```
     *
     * ## Why MAX_SPEED_CORRECTION = 2% (0.02)?
     *
     * The 2% limit balances correction speed against audibility:
     * - Below ~4%: Sample insert/drop is completely imperceptible
     * - At 2%: Very conservative - even sensitive listeners won't notice
     * - Correction of 2% at 48kHz = 960 samples/sec = 1 frame every ~1ms
     * - This can correct up to 960 * 21us = ~20ms of error per second
     *
     * Note: The Python reference uses 4%, but 2% provides extra safety margin.
     *
     * ## Why CORRECTION_TARGET_SECONDS = 3 seconds?
     *
     * This controls the responsiveness vs smoothness tradeoff:
     * - Shorter (1-2s): More responsive but more aggressive corrections
     * - Longer (5-10s): Smoother but slow to converge
     * - 3 seconds: Good balance - corrects typical drift within acceptable time
     *   while keeping correction rate low for normal operation
     *
     * With 3 second target:
     * - 20ms error -> ~320 corrections/sec -> 1 frame every ~150 frames (3ms)
     * - 10ms error -> ~160 corrections/sec -> 1 frame every ~300 frames (6ms)
     * - Below 10ms: deadband, no corrections applied
     *
     * ## Deadband: Why 10ms Threshold?
     *
     * The DEADBAND_THRESHOLD_US (10ms / 10000us) creates a "good enough" zone:
     * - Errors below 10ms don't trigger any correction
     * - This prevents constant tiny corrections during normal playback
     * - 10ms is well within acceptable sync tolerance (human perception ~20-80ms)
     * - When corrections do activate (>10ms error), the proportional controller
     *   converges quickly: 10ms error → ~160 corrections/sec → fixed in ~3s
     *
     * Without a deadband, noise in the sync error measurement would cause
     * continuous small corrections even when perfectly synced.
     *
     * ## Correction Direction
     *
     * Uses Kalman-filtered sync error from [updateSyncError]:
     * - **Positive error** = behind schedule (DAC ahead of read cursor)
     *   -> DROP frames to catch up (skip input samples, output less)
     * - **Negative error** = ahead of schedule (DAC behind read cursor)
     *   -> INSERT duplicate frames to slow down (output more, effective slowdown)
     *
     * @param processingTimeErrorUs Unused - kept for API compatibility.
     *        Sync error is obtained from [syncErrorFilter] (Kalman-filtered).
     */
    private fun updateCorrectionSchedule(@Suppress("UNUSED_PARAMETER") processingTimeErrorUs: Long) {
        // Guard: Skip corrections until DAC calibration provides reliable sync error
        if (!startTimeCalibrated) {
            insertEveryNFrames = 0
            dropEveryNFrames = 0
            return
        }

        // Guard: Skip corrections during startup grace period (500ms)
        // AudioTimestamp needs time to stabilize after playback starts
        if (playingStateEnteredAtUs > 0) {
            val nowUs = nowNs() / 1000
            val timeSincePlayingUs = nowUs - playingStateEnteredAtUs
            if (timeSincePlayingUs < STARTUP_GRACE_PERIOD_US) {
                insertEveryNFrames = 0
                dropEveryNFrames = 0
                return
            }
        }

        // Guard: Skip corrections during reconnection stabilization period (2s)
        // After reconnection, the Kalman filter needs time to re-converge with new measurements
        if (reconnectedAtUs > 0) {
            val nowUs = nowNs() / 1000
            val timeSinceReconnectUs = nowUs - reconnectedAtUs
            if (timeSinceReconnectUs < RECONNECT_STABILIZATION_US) {
                insertEveryNFrames = 0
                dropEveryNFrames = 0
                return
            }
        }

        // Get Kalman-filtered sync error (smooths measurement noise and tracks drift)
        val effectiveErrorUs = syncErrorFilter.offsetMicros.toDouble()
        val absErr = abs(effectiveErrorUs)

        // Deadband check: errors below 2ms are "good enough" - no correction needed
        // This prevents oscillation and unnecessary CPU usage for imperceptible errors
        if (absErr <= DEADBAND_THRESHOLD_US) {
            insertEveryNFrames = 0
            dropEveryNFrames = 0
            return
        }

        // Step 1: Convert error from microseconds to sample frames
        // Example: 2000us * 48000Hz / 1,000,000 = 96 frames
        val framesError = absErr * sampleRate / 1_000_000.0

        // Step 2: Calculate desired corrections per second using proportional control
        // We aim to eliminate the error over CORRECTION_TARGET_SECONDS (3 seconds)
        // Example: 96 frames / 3 seconds = 32 corrections/sec
        val desiredCorrectionsPerSec = framesError / CORRECTION_TARGET_SECONDS

        // Step 3: Cap at maximum correction rate (2% of sample rate)
        // Example: 48000 * 0.02 = 960 corrections/sec max
        // This ensures corrections remain imperceptible even for large errors
        val maxCorrectionsPerSec = sampleRate * MAX_SPEED_CORRECTION
        val correctionsPerSec = minOf(desiredCorrectionsPerSec, maxCorrectionsPerSec)

        // Step 4: Calculate interval between corrections (in frames)
        // Example: 48000 / 32 = 1500 frames between corrections (~31ms at 48kHz)
        val intervalFrames = if (correctionsPerSec > 0) {
            (sampleRate / correctionsPerSec).toInt().coerceAtLeast(1)
        } else {
            0
        }

        // Apply correction in the appropriate direction
        if (effectiveErrorUs > 0) {
            // Positive error: DAC is ahead of where we've read to
            // DROP frames to catch up (skip input samples, effectively speeding up)
            dropEveryNFrames = intervalFrames
            insertEveryNFrames = 0
            if (framesUntilNextDrop == 0) {
                framesUntilNextDrop = intervalFrames
            }
        } else {
            // Negative error: DAC is behind where we've read to
            // INSERT duplicate frames to slow down (output more samples per input)
            insertEveryNFrames = intervalFrames
            dropEveryNFrames = 0
            if (framesUntilNextInsert == 0) {
                framesUntilNextInsert = intervalFrames
            }
        }
    }

    /**
     * Write a chunk to AudioTrack with sample insert/drop corrections.
     *
     * When corrections are active, processes frame-by-frame to insert duplicates
     * or skip frames. When no corrections are needed, writes in bulk for efficiency.
     */
    private fun playChunkWithCorrection(chunk: AudioChunk) {
        chunkQueue.poll() // Remove from queue
        totalQueuedSamples.addAndGet(-chunk.sampleCount.toLong())

        val track = audioSink ?: return

        if (syncMuted && chunk.pcmData.isNotEmpty()) {
            chunk.pcmData.fill(0)
        } else if (duckFactor < 1f && chunk.pcmData.isNotEmpty()) {
            // Voice-interaction ducking: scale the samples themselves so the
            // drain rate, DAC timing and stream volume are all untouched.
            // 16-bit little-endian interleaved, same layout the corrector
            // assumes.
            val factor = duckFactor
            var i = 0
            while (i + 1 < chunk.pcmData.size) {
                val sample = ((chunk.pcmData[i + 1].toInt() shl 8) or
                        (chunk.pcmData[i].toInt() and 0xFF)).toShort()
                val ducked = (sample * factor).toInt()
                    .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
                chunk.pcmData[i] = (ducked and 0xFF).toByte()
                chunk.pcmData[i + 1] = ((ducked shr 8) and 0xFF).toByte()
                i += 2
            }
        }

        // Track samples consumed for sync error calculation
        samplesReadSinceStart += chunk.sampleCount

        // Decide if we need frame-by-frame processing or can use fast path
        // Include crossfade state to ensure fade tail completes even when corrections stop
        val needsCorrection = insertEveryNFrames > 0 || dropEveryNFrames > 0
                || crossfadeState != CrossfadeState.IDLE

        val writeTimeNs = nowNs()
        val written = if (needsCorrection) {
            writeWithCorrection(track, chunk.pcmData)
        } else {
            // Fast path: write entire chunk at once
            val result = track.write(chunk.pcmData, 0, chunk.pcmData.size)
            // Store last two frames for potential future interpolation
            if (chunk.pcmData.size >= bytesPerFrame) {
                // Update secondLastOutputFrame from the previous lastOutputFrame
                System.arraycopy(lastOutputFrame, 0, secondLastOutputFrame, 0, bytesPerFrame)
                // Store the last frame of this chunk
                System.arraycopy(
                    chunk.pcmData, chunk.pcmData.size - bytesPerFrame,
                    lastOutputFrame, 0, bytesPerFrame
                )
            }
            result
        }

        if (written < 0) {
            AppLog.Audio.e("AudioTrack write error: $written")
        }

        // Update frame tracking
        val framesWritten = written / bytesPerFrame
        totalFramesWritten.addAndGet(framesWritten.toLong())

        // Feed the latency estimator with the cumulative write position and wall time.
        if (written > 0) {
            latencyEstimator.recordWrite(totalFramesWritten.get(), writeTimeNs)
        }

        // Update server timeline cursor - tracks input frames CONSUMED (read side).
        // Initialize from chunk's server timestamp on first chunk, then advance
        // by input frames consumed. This matches Python CLI's _server_ts_cursor_us.
        if (serverTimelineCursor == 0L) {
            serverTimelineCursor = chunk.serverTimeMicros
        }
        // Input frames consumed = chunk sample count (all input frames are read).
        // Drops consume extra input without outputting (already counted in sampleCount).
        // Inserts output extra without consuming input (don't affect sampleCount).
        advanceServerCursorFrames(chunk.sampleCount)

        chunksPlayed++

        // Update sync error periodically
        syncUpdateCounter++
        if (syncUpdateCounter >= SYNC_ERROR_UPDATE_INTERVAL) {
            syncUpdateCounter = 0
            updateSyncError()
        }
    }

    // ========================================================================
    // PCM Blending Helpers - Zero-allocation weighted interpolation
    // ========================================================================

    /** Extract a 16-bit little-endian sample as a signed Int. */
    private fun readInt16LE(data: ByteArray, offset: Int): Int {
        return (data[offset].toInt() and 0xFF) or (data[offset + 1].toInt() shl 8)
    }

    /** Write a 16-bit little-endian sample, clamping to Int16 range. */
    private fun writeInt16LE(data: ByteArray, offset: Int, value: Int) {
        val clamped = value.coerceIn(-32768, 32767)
        data[offset] = (clamped and 0xFF).toByte()
        data[offset + 1] = (clamped shr 8).toByte()
    }

    /**
     * Weighted blend of two stereo frames into output buffer.
     * Processes each channel independently with Int16 clamping.
     */
    private fun blendFrames(
        frameA: ByteArray, offA: Int,
        frameB: ByteArray, offB: Int,
        wA: Double, wB: Double,
        output: ByteArray, outOff: Int
    ) {
        for (ch in 0 until channels) {
            val byteOff = ch * 2
            val sampleA = readInt16LE(frameA, offA + byteOff)
            val sampleB = readInt16LE(frameB, offB + byteOff)
            val blended = (sampleA * wA + sampleB * wB).toInt()
            writeInt16LE(output, outOff + byteOff, blended)
        }
    }

    /**
     * 3-point weighted interpolation: 0.25*A + 0.50*B + 0.25*C per channel.
     * Creates a smooth waveform transition at correction points.
     */
    private fun interpolate3Point(
        frameA: ByteArray, offA: Int,
        frameB: ByteArray, offB: Int,
        frameC: ByteArray, offC: Int,
        output: ByteArray, outOff: Int
    ) {
        for (ch in 0 until channels) {
            val byteOff = ch * 2
            val sA = readInt16LE(frameA, offA + byteOff)
            val sB = readInt16LE(frameB, offB + byteOff)
            val sC = readInt16LE(frameC, offC + byteOff)
            val blended = (sA * BLEND_OUTER + sB * BLEND_CENTER + sC * BLEND_OUTER).toInt()
            writeInt16LE(output, outOff + byteOff, blended)
        }
    }

    // ========================================================================
    // Crossfade State Machine - Smooth transitions around corrections
    // ========================================================================

    /** Begin fading toward targetFrame over CROSSFADE_FRAMES. */
    private fun startFadeIn(targetFrame: ByteArray, targetOff: Int = 0) {
        System.arraycopy(targetFrame, targetOff, crossfadeTargetFrame, 0, bytesPerFrame)
        crossfadeState = CrossfadeState.FADING_IN
        crossfadeProgress = 0
    }

    /** Begin fading back from targetFrame to normal over CROSSFADE_FRAMES. */
    private fun startFadeOut(targetFrame: ByteArray, targetOff: Int = 0) {
        System.arraycopy(targetFrame, targetOff, crossfadeTargetFrame, 0, bytesPerFrame)
        crossfadeState = CrossfadeState.FADING_OUT
        crossfadeProgress = 0
    }

    /**
     * Apply crossfade blending and write a frame to AudioTrack.
     * During IDLE, writes normalFrame directly.
     * During FADING_IN, blends from normalFrame toward crossfadeTargetFrame.
     * During FADING_OUT, blends from crossfadeTargetFrame back to normalFrame.
     *
     * Uses crossfadeScratchBuf as a pre-allocated scratch buffer for blended output.
     */
    private var crossfadeScratchBuf = ByteArray(0)

    private fun applyCrossfadeAndWrite(track: AudioSink, normalFrame: ByteArray, normalOff: Int = 0): Int {
        when (crossfadeState) {
            CrossfadeState.FADING_IN -> {
                crossfadeProgress++
                val alpha = crossfadeProgress.toDouble() / CROSSFADE_FRAMES
                if (alpha >= 1.0) {
                    // Fade complete - write the target frame
                    crossfadeState = CrossfadeState.IDLE
                    return track.write(crossfadeTargetFrame, 0, bytesPerFrame)
                }
                // Blend: normalFrame*(1-alpha) + targetFrame*alpha
                blendFrames(
                    normalFrame, normalOff,
                    crossfadeTargetFrame, 0,
                    1.0 - alpha, alpha,
                    crossfadeScratchBuf, 0
                )
                return track.write(crossfadeScratchBuf, 0, bytesPerFrame)
            }
            CrossfadeState.FADING_OUT -> {
                crossfadeProgress++
                val alpha = 1.0 - (crossfadeProgress.toDouble() / CROSSFADE_FRAMES)
                if (alpha <= 0.0) {
                    // Fade complete - write normal frame
                    crossfadeState = CrossfadeState.IDLE
                    return track.write(normalFrame, normalOff, bytesPerFrame)
                }
                // Blend: targetFrame*alpha + normalFrame*(1-alpha)
                blendFrames(
                    crossfadeTargetFrame, 0,
                    normalFrame, normalOff,
                    alpha, 1.0 - alpha,
                    crossfadeScratchBuf, 0
                )
                return track.write(crossfadeScratchBuf, 0, bytesPerFrame)
            }
            CrossfadeState.IDLE -> {
                return track.write(normalFrame, normalOff, bytesPerFrame)
            }
        }
    }

    /**
     * Write PCM data with sample insert/drop corrections applied.
     *
     * For 16-bit PCM, uses 3-point weighted interpolation and symmetric crossfade
     * windows for smooth waveform transitions at correction points.
     *
     * For 24-bit and 32-bit PCM, sample-level crossfade is skipped because the
     * blending helpers operate on 16-bit samples. Insert/drop corrections still
     * work at the frame level (duplicate or skip whole frames).
     *
     * @param track The AudioTrack to write to
     * @param pcmData The raw PCM data
     * @return Total bytes written to AudioTrack
     */
    private fun writeWithCorrection(track: AudioSink, pcmData: ByteArray): Int {
        // For non-16-bit formats, use simplified insert/drop without sample-level crossfade
        if (bitDepth != 16) {
            return writeWithCorrectionSimple(track, pcmData)
        }

        val inputFrameCount = pcmData.size / bytesPerFrame
        var totalWritten = 0
        var inputOffset = 0

        for (i in 0 until inputFrameCount) {
            // --- Pre-correction fade-in: anticipate upcoming corrections ---
            if (crossfadeState == CrossfadeState.IDLE) {
                if (dropEveryNFrames > 0 && framesUntilNextDrop <= CROSSFADE_FRAMES && framesUntilNextDrop > 1) {
                    // Approaching a DROP - compute the blended frame we'll transition through
                    // Use lastOutputFrame blended with current as approach target
                    blendFrames(lastOutputFrame, 0, pcmData, inputOffset, 0.5, 0.5, crossfadeScratchBuf, 0)
                    startFadeIn(crossfadeScratchBuf)
                } else if (insertEveryNFrames > 0 && framesUntilNextInsert <= CROSSFADE_FRAMES && framesUntilNextInsert > 1) {
                    // Approaching an INSERT - blend lastOutput with current as approach target
                    blendFrames(lastOutputFrame, 0, pcmData, inputOffset, 0.5, 0.5, crossfadeScratchBuf, 0)
                    startFadeIn(crossfadeScratchBuf)
                }
            }

            // --- DROP: 3-point interpolation + fade-out ---
            if (dropEveryNFrames > 0) {
                framesUntilNextDrop--
                if (framesUntilNextDrop <= 0) {
                    framesUntilNextDrop = dropEveryNFrames
                    framesDropped++

                    // 3-point interpolation: 0.25*lastOutput + 0.50*dropped + 0.25*next
                    val hasNext = (i + 1 < inputFrameCount)
                    if (hasNext) {
                        interpolate3Point(
                            lastOutputFrame, 0,
                            pcmData, inputOffset,
                            pcmData, inputOffset + bytesPerFrame,
                            crossfadeScratchBuf, 0
                        )
                    } else {
                        // Edge case: no next frame - fall back to 2-point blend
                        blendFrames(
                            lastOutputFrame, 0,
                            pcmData, inputOffset,
                            0.5, 0.5,
                            crossfadeScratchBuf, 0
                        )
                    }
                    // Start fade-out from the interpolated frame back to normal
                    startFadeOut(crossfadeScratchBuf)

                    // Skip this input frame (the actual drop)
                    inputOffset += bytesPerFrame
                    continue
                }
            }

            // --- INSERT: 3-point interpolation + fade-out ---
            if (insertEveryNFrames > 0) {
                framesUntilNextInsert--
                if (framesUntilNextInsert <= 0 && lastOutputFrame.isNotEmpty()) {
                    framesUntilNextInsert = insertEveryNFrames
                    framesInserted++

                    // 3-point interpolation: 0.25*secondLast + 0.50*lastOutput + 0.25*current
                    val hasSecondLast = secondLastOutputFrame.size == bytesPerFrame &&
                            !secondLastOutputFrame.all { it == 0.toByte() }
                    if (hasSecondLast) {
                        interpolate3Point(
                            secondLastOutputFrame, 0,
                            lastOutputFrame, 0,
                            pcmData, inputOffset,
                            crossfadeScratchBuf, 0
                        )
                    } else {
                        // Fallback: 2-point blend between lastOutput and current
                        blendFrames(
                            lastOutputFrame, 0,
                            pcmData, inputOffset,
                            0.5, 0.5,
                            crossfadeScratchBuf, 0
                        )
                    }

                    // Write the interpolated inserted frame
                    val insertWritten = applyCrossfadeAndWrite(track, crossfadeScratchBuf, 0)
                    if (insertWritten > 0) totalWritten += insertWritten

                    // Start fade-out from the inserted frame back to normal
                    startFadeOut(crossfadeScratchBuf)
                }
            }

            // --- Normal frame output with crossfade applied ---
            val written = applyCrossfadeAndWrite(track, pcmData, inputOffset)
            if (written > 0) {
                totalWritten += written
                // Update frame history
                System.arraycopy(lastOutputFrame, 0, secondLastOutputFrame, 0, bytesPerFrame)
                System.arraycopy(pcmData, inputOffset, lastOutputFrame, 0, bytesPerFrame)
            }
            inputOffset += bytesPerFrame
        }

        return totalWritten
    }

    /**
     * Simplified write with insert/drop corrections for non-16-bit PCM formats.
     *
     * Performs frame-level insert (duplicate last frame) and drop (skip frame) without
     * sample-level crossfade or interpolation. This avoids needing format-specific
     * sample blending code for 24-bit packed and 32-bit integer encodings.
     */
    private fun writeWithCorrectionSimple(track: AudioSink, pcmData: ByteArray): Int {
        val inputFrameCount = pcmData.size / bytesPerFrame
        var totalWritten = 0
        var inputOffset = 0

        for (i in 0 until inputFrameCount) {
            // --- DROP: skip this frame ---
            if (dropEveryNFrames > 0) {
                framesUntilNextDrop--
                if (framesUntilNextDrop <= 0) {
                    framesUntilNextDrop = dropEveryNFrames
                    framesDropped++
                    // Skip this input frame
                    inputOffset += bytesPerFrame
                    continue
                }
            }

            // --- INSERT: duplicate last output frame ---
            if (insertEveryNFrames > 0) {
                framesUntilNextInsert--
                if (framesUntilNextInsert <= 0 && lastOutputFrame.isNotEmpty()) {
                    framesUntilNextInsert = insertEveryNFrames
                    framesInserted++
                    // Write a duplicate of the last output frame
                    val insertWritten = track.write(lastOutputFrame, 0, bytesPerFrame)
                    if (insertWritten > 0) totalWritten += insertWritten
                }
            }

            // --- Normal frame output ---
            val written = track.write(pcmData, inputOffset, bytesPerFrame)
            if (written > 0) {
                totalWritten += written
                System.arraycopy(lastOutputFrame, 0, secondLastOutputFrame, 0, bytesPerFrame)
                System.arraycopy(pcmData, inputOffset, lastOutputFrame, 0, bytesPerFrame)
            }
            inputOffset += bytesPerFrame
        }

        return totalWritten
    }

    // ========================================================================
    // Sync Error Calculation
    // ========================================================================

    /**
     * Update sync error by comparing DAC playback position to Kalman-expected position.
     *
     * Both terms are evaluated at the DAC output point in server time:
     *   - actualPlaybackServerTimeUs: baseline + DAC frame delta (advances at DAC clock rate)
     *   - expectedPlaybackServerTimeUs: fresh Kalman conversion (advances at server clock rate)
     *
     * At calibration these are identical. Over time they diverge by DAC-vs-server
     * clock drift, which is exactly what insert/drop corrections fix.
     *
     * This avoids comparing the write cursor to the DAC position, sidestepping
     * the Android push-model problem where the write cursor is ~300ms ahead of
     * the DAC output and totalFramesWritten/framePosition can mismatch after flush.
     *
     * Sign convention (matching Python CLI):
     *   Positive = DAC is ahead of expected (playing fast) -> need DROP
     *   Negative = DAC is behind expected (playing slow) -> need INSERT
     */
    private fun updateSyncError() {
        val track = audioSink ?: return
        if (playbackState != PlaybackState.PLAYING) return

        try {
            // Query AudioTimestamp on every update
            val ts = track.getTimestamp()
            if (ts != null) {
                latencyEstimator.recordDacTimestamp(ts.framePosition, ts.nanoTime)
            }
            latencyEstimator.tick()
            if (ts == null) {
                return
            }

            val dacTimeMicros = ts.nanoTime / 1000
            val framePosition = ts.framePosition
            val loopTimeUs = nowNs() / 1000

            // Sanity check - framePosition should be reasonable
            if (framePosition <= 0 || framePosition > totalFramesWritten.get() + sampleRate) {
                return
            }

            // Detect 32-bit frame counter wrap on pre-API-28 HAL implementations.
            // A backward jump of more than 1 second of frames indicates the counter
            // wrapped rather than a genuine regression. Skip this reading.
            if (lastValidFramePosition > 0 && framePosition < lastValidFramePosition - sampleRate) {
                AppLog.Sync.w("Frame position wrap detected: last=$lastValidFramePosition, " +
                    "current=$framePosition, totalWritten=${totalFramesWritten.get()}")
                return
            }
            lastValidFramePosition = framePosition

            // Store DAC calibration pair for time conversion
            storeDacCalibration(dacTimeMicros, loopTimeUs)

            // ================================================================
            // INITIAL BASELINE: Capture on first valid AudioTimestamp
            // ================================================================
            // Use Kalman conversion (same as periodic refresh) so that the
            // baseline reflects what the DAC is actually playing, not the
            // first queued chunk's server time which may be seconds ahead.
            if (!startTimeCalibrated) {
                if (firstServerTimestampUs == null) {
                    return
                }

                val loopAtDac = estimateLoopTimeForDacTime(dacTimeMicros)
                if (loopAtDac <= 0) {
                    return  // Need calibration pairs first
                }
                val kalmanServerTimeUs = computeServerTime(loopAtDac)

                startTimeCalibrated = true
                baselineFramePosition = framePosition
                baselineServerTimeUs = kalmanServerTimeUs
                lastBaselineRefreshUs = loopTimeUs

                // Reconcile totalFramesWritten and serverTimelineCursor so the
                // sync error equation starts from a consistent baseline.
                //
                // Problem: by this point, pre-calibration silence has inflated
                // totalFramesWritten, and several real audio chunks have already
                // advanced serverTimelineCursor. Snapping totalFramesWritten alone
                // would erase real-audio frames from the accounting while leaving
                // the cursor ahead, producing a large false sync error.
                //
                // Solution: compute the current pending depth and set the cursor
                // so that cursorAtDac = kalmanServerTimeUs (the Kalman-derived
                // server time at the DAC output right now). This is the same
                // reference point the DAC-aware start gating uses.
                val pendingFrames = (totalFramesWritten.get() - framePosition).coerceAtLeast(0)
                val currentPendingUs = (pendingFrames * 1_000_000L) / sampleRate
                serverTimelineCursor = kalmanServerTimeUs + currentPendingUs
                serverTimelineCursorRemainder = 0L

                AppLog.Sync.i("Sync baseline calibrated: " +
                    "framePos=$framePosition, totalWritten=${totalFramesWritten.get()}, " +
                    "pending=${currentPendingUs/1000}ms, " +
                    "baselineServerTime=${baselineServerTimeUs}us")
            }

            // ================================================================
            // PERIODIC BASELINE REFRESH (matching Python's continuous Kalman use)
            // ================================================================
            // The Python CLI converts DAC->server on every callback via _compute_server_time().
            // We periodically refresh the baseline so that early Kalman convergence error
            // doesn't stay baked in for the entire session.
            //
            if (loopTimeUs - lastBaselineRefreshUs > BASELINE_REFRESH_INTERVAL_US
                && timeFilter.isReady
                && timeFilter.measurementCountValue >= BASELINE_REFRESH_MIN_MEASUREMENTS) {

                // Convert current DAC loop time to server time via Kalman
                val loopAtDac = estimateLoopTimeForDacTime(dacTimeMicros)
                if (loopAtDac > 0) {
                    val kalmanServerTimeUs = computeServerTime(loopAtDac)
                    val oldBaselineServerUs = baselineServerTimeUs
                    val oldBaselineFramePos = baselineFramePosition

                    // Update baseline to current position
                    baselineFramePosition = framePosition
                    baselineServerTimeUs = kalmanServerTimeUs
                    lastBaselineRefreshUs = loopTimeUs

                    val expectedServerUs = oldBaselineServerUs +
                        ((framePosition - oldBaselineFramePos) * 1_000_000L) / sampleRate
                    val shiftUs = kalmanServerTimeUs - expectedServerUs
                    if (abs(shiftUs) > 1000) {  // Only log shifts > 1ms
                        AppLog.Sync.d("Baseline refreshed via Kalman: shift=${shiftUs/1000}ms, " +
                            "newServerTime=${kalmanServerTimeUs}us, framePos=$framePosition")
                    }
                }
            }

            // ================================================================
            // SYNC ERROR: Cursor-based measurement (matching Python CLI)
            // ================================================================
            // Ground-truth cursor: serverTimelineCursor tracks the server time
            // of audio written to the AudioTrack. Subtract pending frames to get
            // the server time at the DAC output point ("where the DAC SHOULD be").
            //
            // Kalman DAC position: convert the hardware DAC timestamp to server
            // time via Kalman ("where the DAC IS in server time").
            //
            // The old baseline approach had both sides Kalman-derived, causing
            // real offsets to cancel. This cursor approach uses one ground-truth
            // side, so actual offsets are visible to the correction loop.

            val pendingFrames = (totalFramesWritten.get() - framePosition).coerceAtLeast(0)
            val pendingUs = (pendingFrames * 1_000_000L) / sampleRate
            val cursorAtDacUs = serverTimelineCursor - pendingUs
            if (serverTimelineCursor == 0L || cursorAtDacUs <= 0) return

            // Kalman-derived DAC position: where the DAC IS in server time
            val loopAtDac = estimateLoopTimeForDacTime(dacTimeMicros)
            if (loopAtDac <= 0) return
            val dacPlaybackServerTimeUs = computeServerTime(loopAtDac)

            // Sync error = actual - expected (matching Python CLI sign convention)
            // Positive = DAC ahead (fast) -> DROP, Negative = DAC behind (slow) -> INSERT
            val rawSyncError = dacPlaybackServerTimeUs - cursorAtDacUs
            syncErrorUs = rawSyncError

            // Apply 2D Kalman filter smoothing for display stability
            syncErrorFilter.update(rawSyncError, loopTimeUs)

            // Periodic log to confirm cursor-based measurement is working
            if (chunksPlayed % 100 == 0L) {
                AppLog.Sync.d("Sync: err=${rawSyncError / 1000}ms, " +
                    "pending=${pendingUs / 1000}ms, " +
                    "cursor=${serverTimelineCursor}us, " +
                    "dacServer=${dacPlaybackServerTimeUs}us")
            }

        } catch (e: Exception) {
            AppLog.Sync.w("Failed to update sync error", e)
        }
    }

    // ========================================================================
    // DAC Calibration - Maps DAC hardware time to loop/system time
    // ========================================================================

    /**
     * Store a DAC calibration pair for time conversion.
     *
     * Captures the relationship between DAC hardware time (from AudioTimestamp)
     * and system monotonic time (from System.nanoTime). This allows us to
     * convert DAC times to loop times and then to server times.
     *
     * @param dacTimeUs DAC hardware time in microseconds
     * @param loopTimeUs System monotonic time in microseconds
     */
    /**
     * Compute microseconds between AudioTrack write cursor and DAC output position.
     * Returns 0 if AudioTimestamp is unavailable or invalid.
     */
    private fun getPendingToDacUs(track: AudioSink): Long {
        val ts = track.getTimestamp() ?: return 0L
        if (ts.framePosition <= 0) return 0L
        val pendingFrames = (totalFramesWritten.get() - ts.framePosition).coerceAtLeast(0)
        return (pendingFrames * 1_000_000L) / sampleRate
    }

    private fun storeDacCalibration(dacTimeUs: Long, loopTimeUs: Long) {
        // Don't store calibrations too frequently
        if (loopTimeUs - lastDacCalibrationTimeUs < MIN_CALIBRATION_INTERVAL_US) {
            return
        }

        dacLoopCalibrations.addLast(DacCalibration(dacTimeUs, loopTimeUs))
        lastDacCalibrationTimeUs = loopTimeUs

        // Keep only the most recent calibrations
        while (dacLoopCalibrations.size > MAX_DAC_CALIBRATIONS) {
            dacLoopCalibrations.removeFirst()
        }
    }

    /**
     * Estimate the loop time that corresponds to a given DAC time.
     *
     * Uses linear interpolation between calibration pairs to estimate
     * what system time corresponds to a DAC hardware timestamp.
     *
     * @param dacTimeUs DAC hardware time in microseconds
     * @return Estimated loop (system) time in microseconds
     */
    private fun estimateLoopTimeForDacTime(dacTimeUs: Long): Long {
        if (dacLoopCalibrations.isEmpty()) {
            // No calibrations yet - can't estimate
            return 0L
        }

        if (dacLoopCalibrations.size == 1) {
            // Single calibration - use simple offset
            val cal = dacLoopCalibrations.first()
            val dacOffset = dacTimeUs - cal.dacTimeUs
            return cal.loopTimeUs + dacOffset
        }

        // Find the two calibrations that bracket the target DAC time
        // or use the nearest pair for extrapolation.
        // The deque is already time-ordered (addLast with monotonic timestamps),
        // so we scan directly without sorting.
        var lower = dacLoopCalibrations.first()
        var upper = dacLoopCalibrations.last()

        for (i in 0 until dacLoopCalibrations.size - 1) {
            if (dacLoopCalibrations[i].dacTimeUs <= dacTimeUs && dacLoopCalibrations[i + 1].dacTimeUs >= dacTimeUs) {
                lower = dacLoopCalibrations[i]
                upper = dacLoopCalibrations[i + 1]
                break
            }
        }

        // Linear interpolation between the two calibration points
        val dacDelta = upper.dacTimeUs - lower.dacTimeUs
        if (dacDelta == 0L) {
            return lower.loopTimeUs
        }

        val fraction = (dacTimeUs - lower.dacTimeUs).toDouble() / dacDelta
        val loopDelta = upper.loopTimeUs - lower.loopTimeUs
        return lower.loopTimeUs + (fraction * loopDelta).toLong()
    }

    /**
     * Convert a loop (system) time to server time using the time filter.
     *
     * @param loopTimeUs System monotonic time in microseconds
     * @return Server time in microseconds
     */
    private fun computeServerTime(loopTimeUs: Long): Long {
        return timeFilter.clientToServer(loopTimeUs)
    }

    /**
     * Advance the server timeline cursor by a number of input frames consumed.
     *
     * Matches Python CLI's _advance_server_cursor_frames: uses integer accumulator
     * to avoid floating-point drift over long playback sessions.
     *
     * @param frames Number of input frames consumed (read from queue)
     */
    private fun advanceServerCursorFrames(frames: Int) {
        if (frames <= 0) return
        serverTimelineCursorRemainder += frames.toLong() * 1_000_000L
        if (serverTimelineCursorRemainder >= sampleRate) {
            val incUs = serverTimelineCursorRemainder / sampleRate
            serverTimelineCursorRemainder %= sampleRate
            serverTimelineCursor += incUs
        }
    }

    /**
     * Clear DAC calibrations (called on buffer clear/reanchor).
     */
    private fun clearDacCalibrations() {
        dacLoopCalibrations.clear()
        lastDacCalibrationTimeUs = 0L
    }

    /**
     * Get the server timeline cursor (where we've READ/CONSUMED audio up to).
     *
     * @return Server time in microseconds of input audio consumed from the queue
     */
    fun getServerTimelineCursorUs(): Long = serverTimelineCursor

    /**
     * Get the current sync error.
     *
     * Positive = behind (haven't read enough) → need to DROP
     * Negative = ahead (read too much) → need to INSERT
     *
     * @return Sync error in microseconds
     */
    fun getSyncErrorUs(): Long = syncErrorUs

    /**
     * Check if start time has been calibrated from AudioTimestamp.
     */
    fun isStartTimeCalibrated(): Boolean = startTimeCalibrated

    /**
     * Get the number of DAC calibration pairs stored.
     */
    fun getDacCalibrationCount(): Int = dacLoopCalibrations.size

    /**
     * Get the sync error filter's drift value.
     */
    fun getSyncErrorDrift(): Double = syncErrorFilter.driftValue

    /**
     * Get the remaining grace period time in microseconds.
     * Returns -1 if grace period is not active.
     */
    fun getGracePeriodRemainingUs(): Long {
        if (playingStateEnteredAtUs <= 0) return -1
        val nowUs = nowNs() / 1000
        val elapsed = nowUs - playingStateEnteredAtUs
        val remaining = STARTUP_GRACE_PERIOD_US - elapsed
        return if (remaining > 0) remaining else -1
    }

    /**
     * Get current playback state.
     */
    fun getPlaybackState(): PlaybackState = playbackState

    /**
     * Get current buffered duration in milliseconds.
     * Useful for monitoring buffer status during DRAINING state.
     */
    fun getBufferedDurationMs(): Long {
        return (totalQueuedSamples.get() * 1000) / sampleRate
    }

    /**
     * Get the expected next timestamp in server time.
     * This is where the next audio chunk should start to maintain continuity.
     * Used for seamless stream handoff during reconnection.
     *
     * @return Expected next server timestamp in microseconds, or null if not set
     */
    fun getExpectedNextTimestampUs(): Long? = expectedNextTimestampUs

    /**
     * Enter draining mode - continue playing from buffer while disconnected.
     * Called when connection is lost but reconnection is being attempted.
     *
     * In DRAINING state:
     * - Playback continues from existing buffer
     * - Buffer exhaustion is monitored and reported
     * - No new chunks are expected until exitDraining() is called
     *
     * @return true if successfully entered draining, false if not applicable
     */
    fun enterDraining(): Boolean {
        if (isReleased.get()) {
            AppLog.Audio.w("Cannot enter DRAINING - player has been released")
            return false
        }
        stateLock.withLock {
            // Only enter draining if we're currently playing or have buffer
            if (playbackState != PlaybackState.PLAYING && playbackState != PlaybackState.WAITING_FOR_START) {
                AppLog.Audio.w("Cannot enter DRAINING from state $playbackState")
                return false
            }

            stateBeforeDraining = playbackState
            drainingStartTimeUs = nowNs() / 1000
            lastBufferWarningTimeUs = 0L
            setPlaybackState(PlaybackState.DRAINING)

            val bufferedMs = getBufferedDurationMs()
            AppLog.Audio.i("Entering DRAINING state - buffer: ${bufferedMs}ms")
            return true
        }
    }

    /**
     * Exit draining mode - new stream is available.
     * Called after successful reconnection when new audio stream starts.
     *
     * The existing buffer will continue to be played, and new chunks will be
     * appended. The gap/overlap handling in queueChunk() will handle any
     * discontinuity at the splice point.
     *
     * @return true if successfully exited draining, false if not in draining state
     */
    fun exitDraining(): Boolean {
        stateLock.withLock {
            if (playbackState != PlaybackState.DRAINING) {
                AppLog.Audio.w("Cannot exit DRAINING - current state is $playbackState")
                return false
            }

            val drainingDurationMs = (nowNs() / 1000 - drainingStartTimeUs) / 1000
            AppLog.Audio.i("Exiting DRAINING state after ${drainingDurationMs}ms - resuming normal playback")

            // Mark reconnection time for stabilization period (skip sync corrections while Kalman re-converges)
            reconnectedAtUs = nowNs() / 1000

            // Transition back to PLAYING (the normal state for active playback)
            setPlaybackState(PlaybackState.PLAYING)
            stateBeforeDraining = null
            return true
        }
    }

    /**
     * Set the callback for playback state changes.
     */
    fun setStateCallback(callback: SyncAudioPlayerCallback?) {
        stateCallback = callback
    }

    /**
     * Update playback state and notify callback if changed.
     * Thread-safe via stateLock (ReentrantLock allows re-entry from callers already holding lock).
     */
    private fun setPlaybackState(newState: PlaybackState) {
        stateLock.withLock {
            if (playbackState != newState) {
                // Track when we enter PLAYING state for grace period calculation
                if (newState == PlaybackState.PLAYING && playbackState != PlaybackState.PLAYING) {
                    playingStateEnteredAtUs = nowNs() / 1000
                    AppLog.Audio.d("Entered PLAYING state - grace period starts (${STARTUP_GRACE_PERIOD_US/1000}ms)")
                }
                playbackState = newState
                stateCallback?.onPlaybackStateChanged(newState)
            }
        }
    }

    /**
     * Get current sync statistics.
     */
    fun getStats(): SyncStats {
        return SyncStats(
            chunksReceived = chunksReceived,
            chunksPlayed = chunksPlayed,
            chunksDropped = chunksDropped,
            syncCorrections = syncCorrections,
            queuedSamples = totalQueuedSamples.get(),
            isPlaying = isPlaying.get(),
            // Playback state machine
            playbackState = playbackState,
            scheduledStartLoopTimeUs = scheduledStartLoopTimeUs,
            firstServerTimestampUs = firstServerTimestampUs,
            // Sync error (simplified Windows SDK style)
            syncErrorUs = syncErrorUs,
            smoothedSyncErrorUs = syncErrorFilter.offsetMicros,
            startTimeCalibrated = startTimeCalibrated,
            samplesReadSinceStart = samplesReadSinceStart,
            serverTimelineCursorUs = serverTimelineCursor,
            totalFramesWritten = totalFramesWritten.get(),
            // Sample insert/drop correction stats
            framesInserted = framesInserted,
            framesDropped = framesDropped,
            insertEveryNFrames = insertEveryNFrames,
            dropEveryNFrames = dropEveryNFrames,
            // Gap/overlap handling stats
            gapsFilled = gapsFilled,
            gapSilenceMs = gapSilenceMs,
            overlapsTrimmed = overlapsTrimmed,
            overlapTrimmedMs = overlapTrimmedMs,
            // New stats for comprehensive debugging
            reanchorCount = reanchorCount,
            bufferUnderrunCount = bufferUnderrunCount,
            dacCalibrationCount = dacLoopCalibrations.size,
            syncErrorDrift = syncErrorFilter.driftValue,
            gracePeriodRemainingUs = getGracePeriodRemainingUs(),
            dacTimestampsStable = dacTimestampsStable
        )
    }

    data class SyncStats(
        val chunksReceived: Long,
        val chunksPlayed: Long,
        val chunksDropped: Long,
        val syncCorrections: Long,
        val queuedSamples: Long,
        val isPlaying: Boolean,
        // Playback state machine stats
        val playbackState: PlaybackState = PlaybackState.INITIALIZING,
        val scheduledStartLoopTimeUs: Long? = null,
        val firstServerTimestampUs: Long? = null,
        // Sync error stats (simplified Windows SDK style)
        val syncErrorUs: Long = 0,
        val smoothedSyncErrorUs: Long = 0,
        val startTimeCalibrated: Boolean = false,
        val samplesReadSinceStart: Long = 0,
        val serverTimelineCursorUs: Long = 0,
        val totalFramesWritten: Long = 0,
        // Sample insert/drop correction stats
        val framesInserted: Long = 0,
        val framesDropped: Long = 0,
        val insertEveryNFrames: Int = 0,
        val dropEveryNFrames: Int = 0,
        // Gap/overlap handling stats
        val gapsFilled: Long = 0,
        val gapSilenceMs: Long = 0,
        val overlapsTrimmed: Long = 0,
        val overlapTrimmedMs: Long = 0,
        // New stats for comprehensive debugging
        val reanchorCount: Long = 0,
        val bufferUnderrunCount: Long = 0,
        val dacCalibrationCount: Int = 0,
        val syncErrorDrift: Double = 0.0,
        val gracePeriodRemainingUs: Long = -1,
        val dacTimestampsStable: Boolean = false
    )
}
