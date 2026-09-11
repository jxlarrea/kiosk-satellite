package me.jxl.kiosk_satellite.plugins

import org.junit.Assert.*
import org.junit.Test

class PluginChartsTest {
    private fun chart(times: List<Any> = listOf(1000L, 2000L), values: List<Any?> = listOf(1.0, null)): Map<String, Any> =
        mapOf("title" to "CPU", "unit" to "%", "timestamps" to times, "series" to listOf(mapOf("name" to "Renderer", "color" to "#aabbcc", "values" to values)))
    private fun rejects(action: () -> Unit) {
        try { action(); fail("Expected chart rejection") } catch (_: IllegalArgumentException) {} catch (_: IllegalStateException) {}
    }
    @Test fun copiesSnapshotsAndSupportsGaps() {
        val values = mutableListOf<Any?>(1.0, null)
        val times = mutableListOf<Any>(1000L, 2000L)
        val store = PluginCharts()
        store.publish("cpu", chart(times, values))
        values[0] = 99; times[0] = 999
        val snapshot = store.snapshot().single()
        assertEquals(listOf(1000L, 2000L), snapshot["timestamps"])
        val series = (snapshot["series"] as List<*>).single() as Map<*, *>
        assertEquals(listOf(1.0, null), series["values"])
        assertEquals("#AABBCC", series["color"])
    }
    @Test fun validatesTimestampsValuesAndDimensionsAtomically() {
        val store = PluginCharts()
        store.publish("cpu", chart())
        for (times in listOf(listOf(2000L, 1000L), listOf(1000L, 1000L), listOf(-1L, 1L), listOf(1.5, 2.0), listOf(Double.NaN, 2), listOf(0L, 253402300800000L))) {
            rejects { store.publish("cpu", chart(times)) }
        }
        for (values in listOf(listOf(Double.NaN, 1), listOf(Double.POSITIVE_INFINITY, 1), listOf(1e13, 0), listOf("1", 0), listOf(1))) {
            rejects { store.publish("cpu", chart(values = values)) }
        }
        rejects { store.publish("cpu", chart(List(241) { it }, List(241) { 0 })) }
        rejects { store.publish("cpu", chart() + ("title" to "a".repeat(81))) }
        rejects { store.publish("cpu", chart() + ("unit" to "a".repeat(17))) }
        rejects { store.publish("cpu", chart() + ("unit" to 123)) }
        rejects { store.publish("cpu", chart() + ("html" to "<script>")) }
        rejects { store.publish("../bad", chart()) }
        val series = (chart()["series"] as List<*>).single() as Map<*, *>
        rejects { store.publish("cpu", chart() + ("series" to List(5) { series })) }
        rejects { store.publish("cpu", chart() + ("series" to listOf(series, series))) }
        rejects { store.publish("cpu", chart() + ("series" to listOf(series + ("color" to "red")))) }
        assertEquals(1, store.snapshot().size)
        assertEquals(listOf(1000L, 2000L), store.snapshot().single()["timestamps"])
    }
    @Test fun barTypesAreValidatedAndCanChangeAtTheSameKey() {
        val store = PluginCharts()
        store.publish("cpu", chart())
        assertEquals("line", store.snapshot().single()["type"])
        store.publish("cpu", chart(values = listOf(-5, 0)) + mapOf("type" to "bar", "compact" to true))
        val bars = store.snapshot().single()
        assertEquals("bar", bars["type"])
        assertEquals(true, bars["compact"])
        for (type in listOf("pie", "Bar", "", 1, false)) {
            rejects { store.publish("cpu", chart() + ("type" to type)) }
            assertEquals(bars, store.snapshot().single())
        }
        store.publish("cpu", chart() + ("type" to "line"))
        assertEquals("line", store.snapshot().single()["type"])
    }
    @Test fun boundsChartsAndUpdatesWithoutRetainingRemovedCharts() {
        var now = 0L
        val store = PluginCharts { now }
        repeat(4) { store.publish("chart_$it", chart()) }
        rejects { store.publish("fifth", chart()) }
        store.remove("chart_0")
        store.publish("replacement", chart())
        repeat(2) { store.publish("replacement", chart()) }
        rejects { store.remove("replacement") }
        now += 1_000_000_000L
        store.remove("replacement")
        assertEquals(3, store.snapshot().size)
        store.close()
        assertTrue(store.snapshot().isEmpty())
        rejects { store.publish("late", chart()) }
        rejects { store.remove("chart_1") }
    }
    @Test fun acceptsEmptySingleConstantNegativeAndMaximumHistory() {
        val store = PluginCharts()
        store.publish("empty", chart(emptyList(), emptyList()))
        store.publish("single", chart(listOf(1), listOf(-1e12)) + ("compact" to true))
        assertEquals(true, store.snapshot().last()["compact"])
        rejects { store.publish("single", chart() + ("compact" to "true")) }
        store.publish("constant", chart(List(240) { it }, List(240) { 1e12 }))
        assertEquals(3, store.snapshot().size)
    }
}
