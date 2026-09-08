package me.jxl.kiosk_satellite

import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class CameraDiagnosticJournalTest {
    @get:Rule val temporary = TemporaryFolder()

    @Test fun failureAndConfigurationSurviveRestartAndSuccessfulRecovery() {
        val file = File(temporary.root, "failure.txt")
        val journal = CameraDiagnosticJournal(file)
        journal.record("device", "environment", "tablet model, Android 16", false, null)
        journal.record("camera-1", "bound", "camera=1 video=640x480 fps=[5,30]", false, null)
        assertFalse(file.exists())
        journal.record("camera-1", "failure", "stream configuration rejected", true, "vendor cause: Broken pipe")
        val saved = file.readText()
        journal.record("camera-2", "recovered", "two outputs", false, null)
        assertEquals(saved, file.readText())
        val replay = CameraDiagnosticJournal(file).previousFailure
        assertTrue(replay.contains("camera=1 video=640x480"))
        assertTrue(replay.contains("vendor cause: Broken pipe"))
        assertTrue(replay.contains("Android 16"))
    }

    @Test fun boundedHistoryKeepsDeviceContextAndRedactsUrlCredentials() {
        val file = File(temporary.root, "failure.txt")
        val journal = CameraDiagnosticJournal(file)
        journal.record("device", "environment", "test tablet", false, null)
        repeat(100) { journal.record("camera-$it", "start", "x".repeat(3000), false, null) }
        journal.record("camera-100", "failure", "rtsp://viewer:secret@host/camera", true, "cause".repeat(5000))
        assertEquals(48, journal.entries().size)
        assertTrue(file.readText().length <= 32 * 1024)
        assertTrue(file.readText().contains("test tablet"))
        assertFalse(file.readText().contains("viewer:secret"))
        assertTrue(file.readText().contains("rtsp://[redacted]@host/camera"))
    }

    @Test fun failedPersistenceStillReturnsTheLiveFailure() {
        val journal = CameraDiagnosticJournal(File(temporary.root, "missing/failure.txt"))
        val entry = journal.record("camera-1", "failure", "camera disabled", true, null)
        assertEquals("warn", entry["level"])
        assertTrue((entry["message"] as String).contains("camera disabled"))
        assertNotNull(journal.persistenceError)
    }
}
