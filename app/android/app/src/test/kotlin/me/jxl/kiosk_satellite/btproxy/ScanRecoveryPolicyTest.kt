package me.jxl.kiosk_satellite.btproxy

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ScanRecoveryPolicyTest {
    private val minute = 60_000L
    private val hour = 60 * minute

    @Test
    fun firstRestartNeedsThreeFailuresUpToAndroid12L() {
        for (sdk in listOf(26, 28, 29, 30, 32)) {
            val policy = ScanRecoveryPolicy(sdk)
            assertFalse(policy.shouldRestartAfterFailures(2, 0))
            assertTrue(policy.shouldRestartAfterFailures(3, 0))
        }
    }

    @Test
    fun androidBlocksAdapterRestartsAfter12L() {
        val policy = ScanRecoveryPolicy(33)
        policy.recordRegistrationFailure()
        assertFalse(policy.shouldRestartAfterFailures(50, 0))
        assertFalse(policy.shouldRestartOnSilence(0))
    }

    @Test
    fun restartThatWorkedCanRepeatAfterTheCooldown() {
        for (sdk in listOf(27, 30)) {
            val policy = ScanRecoveryPolicy(sdk)
            policy.recordAdapterRestart(0)
            policy.recordResults()
            assertFalse(policy.shouldRestartAfterFailures(3, 29 * minute))
            assertTrue(policy.shouldRestartAfterFailures(3, 30 * minute))
        }
    }

    @Test
    fun unprovenRestartStaysOneShotOutsideTheBug() {
        for (sdk in listOf(25, 29, 30, 32)) {
            val policy = ScanRecoveryPolicy(sdk)
            policy.recordAdapterRestart(0)
            assertFalse(policy.shouldRestartAfterFailures(3, 1000 * hour))
        }
    }

    @Test
    fun unprovenRestartGetsTheLongCooldownOnTheBug() {
        val policy = ScanRecoveryPolicy(27)
        policy.recordAdapterRestart(0)
        assertFalse(policy.shouldRestartAfterFailures(3, 2 * hour - 1))
        assertTrue(policy.shouldRestartAfterFailures(3, 2 * hour))
    }

    @Test
    fun resultsAreAwaitedOnlyAfterARestart() {
        val policy = ScanRecoveryPolicy(27)
        assertFalse(policy.awaitingResults)
        policy.recordAdapterRestart(0)
        assertTrue(policy.awaitingResults)
        policy.recordResults()
        assertFalse(policy.awaitingResults)
    }

    @Test
    fun silenceRestartsOnlyAfterARegistrationFailureOnTheBug() {
        for (sdk in listOf(26, 27, 28)) {
            val policy = ScanRecoveryPolicy(sdk)
            assertFalse(policy.shouldRestartOnSilence(0))
            policy.recordRegistrationFailure()
            assertTrue(policy.shouldRestartOnSilence(0))
        }
    }

    @Test
    fun silenceNeverRestartsOutsideTheBug() {
        for (sdk in listOf(25, 29, 30, 32, 36)) {
            val policy = ScanRecoveryPolicy(sdk)
            policy.recordRegistrationFailure()
            assertFalse(policy.shouldRestartOnSilence(0))
        }
    }

    @Test
    fun staleEntryOutlivesResultsUntilTheAdapterRestarts() {
        val policy = ScanRecoveryPolicy(27)
        policy.recordRegistrationFailure()
        policy.recordResults()
        assertTrue(policy.shouldRestartOnSilence(0))
        policy.recordAdapterOn()
        assertFalse(policy.shouldRestartOnSilence(0))
    }

    @Test
    fun oneSlowStartKeepsTheNormalRotation() {
        val policy = ScanRecoveryPolicy(27)
        assertFalse(policy.recordStart(1_900, 0))
        assertFalse(policy.registrationSlow)
        assertTrue(policy.shouldRotate(2 * minute))
    }

    @Test
    fun twoSlowStartsStretchRotationUntilAFastStart() {
        val policy = ScanRecoveryPolicy(27)
        policy.recordStart(1_000, 0)
        assertTrue(policy.recordStart(1_500, 2 * minute))
        assertTrue(policy.registrationSlow)
        assertFalse(policy.shouldRotate(4 * minute))
        assertFalse(policy.shouldRotate(31 * minute))
        assertTrue(policy.shouldRotate(32 * minute))

        assertTrue(policy.recordStart(3, 32 * minute))
        assertFalse(policy.registrationSlow)
        assertTrue(policy.shouldRotate(34 * minute))
    }

    @Test
    fun slowStartsInterruptedByAFastOneDoNotCount() {
        val policy = ScanRecoveryPolicy(27)
        policy.recordStart(1_500, 0)
        policy.recordStart(2, 1)
        policy.recordStart(1_500, 2)
        assertFalse(policy.registrationSlow)
    }

    @Test
    fun slowStartsNeverChangeRotationOutsideTheBug() {
        for (sdk in listOf(25, 29, 30, 36)) {
            val policy = ScanRecoveryPolicy(sdk)
            repeat(10) { assertFalse(policy.recordStart(5_000, it * minute)) }
            assertFalse(policy.registrationSlow)
            assertTrue(policy.shouldRotate(10 * minute))
        }
    }
}
