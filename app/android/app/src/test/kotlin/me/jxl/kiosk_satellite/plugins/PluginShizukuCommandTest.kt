package me.jxl.kiosk_satellite.plugins

import org.junit.Assert.*
import org.junit.Test
import java.util.concurrent.atomic.AtomicBoolean

class PluginShizukuCommandTest {
    @Test fun literalArgumentsAndSeparateOutput() {
        val result = PluginShizukuCommand.run(arrayOf("/bin/sh", "-c", "printf '%s' \"\$1\"; printf error >&2; exit 7", "test", "literal; \$(id)"), 2000, AtomicBoolean(false))
        assertEquals("literal; \$(id)", result["stdout"])
        assertEquals("error", result["stderr"])
        assertEquals(7, result["exitCode"])
        assertEquals(false, result["timedOut"])
    }
    @Test fun boundedOutputDrainsBothPipes() {
        val result = PluginShizukuCommand.run(arrayOf("/bin/sh", "-c", "head -c 80000 /dev/zero; head -c 80000 /dev/zero >&2"), 3000, AtomicBoolean(false))
        assertEquals(PluginShizukuCommand.OUTPUT_LIMIT, (result["stdout"] as String).length)
        assertEquals(PluginShizukuCommand.OUTPUT_LIMIT, (result["stderr"] as String).length)
        assertEquals(true, result["truncated"])
        assertEquals(0, result["exitCode"])
    }
    @Test fun timeoutAndCancellation() {
        val start = System.nanoTime()
        val result = PluginShizukuCommand.run(arrayOf("/bin/sleep", "10"), 100, AtomicBoolean(false))
        assertEquals(true, result["timedOut"])
        assertTrue(System.nanoTime() - start < 2_000_000_000L)
        assertThrows(IllegalStateException::class.java) {
            PluginShizukuCommand.run(arrayOf("/bin/echo", "never"), 1000, AtomicBoolean(true))
        }
    }
    @Test fun rejectsMalformedAndUnboundedCommands() {
        for (args in listOf(emptyArray(), arrayOf("echo"), arrayOf("/bin/echo", "bad\u0000argument"), Array(33) { "/bin/echo" }, arrayOf("/bin/echo", "x".repeat(4097)))) {
            assertThrows(IllegalArgumentException::class.java) { PluginShizukuCommand.validate(args, 1000) }
        }
        for (timeout in listOf(0, 99, 30001)) {
            assertThrows(IllegalArgumentException::class.java) { PluginShizukuCommand.validate(arrayOf("/bin/echo"), timeout) }
        }
    }
}
