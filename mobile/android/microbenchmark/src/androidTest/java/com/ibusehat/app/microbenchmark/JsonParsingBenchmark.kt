package com.ibusehat.app.microbenchmark

import androidx.benchmark.junit4.BenchmarkRule
import androidx.benchmark.junit4.measureRepeated
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Microbenchmark untuk fungsi parsing JSON yang sering dipanggil
 * oleh ActivityService, ProgressService, dan AuthService di layer Flutter/Dart.
 */
@RunWith(AndroidJUnit4::class)
class JsonParsingBenchmark {

    @get:Rule
    val benchmarkRule = BenchmarkRule()

    @Test
    fun parseActivitiesListResponse() {
        val payload = SampleApiPayloads.activitiesListJson
        benchmarkRule.measureRepeated {
            val result = ApiJsonParser.parseActivitiesListResponse(payload)
            check(result.size == 50)
        }
    }

    @Test
    fun parseActivitySummary() {
        val payload = SampleApiPayloads.activitySummaryJson
        benchmarkRule.measureRepeated {
            val (distance, steps) = ApiJsonParser.parseActivitySummary(payload)
            check(distance > 0 && steps > 0)
        }
    }

    @Test
    fun parseProgressSummary() {
        val payload = SampleApiPayloads.progressSummaryJson
        benchmarkRule.measureRepeated {
            val summary = ApiJsonParser.parseProgressSummary(payload)
            check(summary.steps > 0 && summary.sleepScore > 0)
        }
    }

    @Test
    fun parseAuthUser() {
        val payload = SampleApiPayloads.authUserJson
        benchmarkRule.measureRepeated {
            val user = ApiJsonParser.parseAuthUser(payload)
            check(user != null)
        }
    }
}
