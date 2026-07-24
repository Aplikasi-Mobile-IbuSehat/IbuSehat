package com.ibusehat.app.benchmark

import androidx.benchmark.macro.FrameTimingMetric
import androidx.benchmark.macro.StartupMode
import androidx.benchmark.macro.junit4.MacrobenchmarkRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import androidx.test.uiautomator.Direction
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Mengukur jank / frame drop saat scroll halaman Beranda (CustomScrollView / LazyColumn).
 */
@RunWith(AndroidJUnit4::class)
class BerandaScrollBenchmark {

    @get:Rule
    val benchmarkRule = MacrobenchmarkRule()

    @Test
    fun scrollBerandaHomeFrameTiming() {
        benchmarkRule.measureRepeated(
            packageName = BenchmarkConstants.PACKAGE_NAME,
            metrics = listOf(FrameTimingMetric()),
            iterations = BenchmarkConstants.ITERATIONS,
            startupMode = StartupMode.WARM,
            setupBlock = {
                pressHome()
                startActivityAndWait()
                waitForBerandaReady()
            },
            measureBlock = {
                val scrollable = device.findObject(By.scrollable(true))
                    ?: error("Scrollable view tidak ditemukan di halaman Beranda")

                repeat(3) {
                    scrollable.fling(Direction.DOWN)
                    device.waitForIdle()
                }
                repeat(3) {
                    scrollable.fling(Direction.UP)
                    device.waitForIdle()
                }
            },
        )
    }
}
