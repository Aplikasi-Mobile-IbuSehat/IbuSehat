package com.ibusehat.app.benchmark

import androidx.benchmark.macro.StartupMode
import androidx.benchmark.macro.StartupTimingMetric
import androidx.benchmark.macro.junit4.MacrobenchmarkRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Mengukur cold / warm / hot startup untuk host Android Flutter app IbuSehat.
 */
@RunWith(AndroidJUnit4::class)
class StartupBenchmark {

    @get:Rule
    val benchmarkRule = MacrobenchmarkRule()

    @Test
    fun startupCold() = measureStartup(StartupMode.COLD)

    @Test
    fun startupWarm() = measureStartup(StartupMode.WARM)

    @Test
    fun startupHot() = measureStartup(StartupMode.HOT)

    private fun measureStartup(startupMode: StartupMode) {
        benchmarkRule.measureRepeated(
            packageName = BenchmarkConstants.PACKAGE_NAME,
            metrics = listOf(StartupTimingMetric()),
            iterations = BenchmarkConstants.ITERATIONS,
            startupMode = startupMode,
            setupBlock = {
                pressHome()
            },
            measureBlock = {
                startActivityAndWait()
            },
        )
    }
}
