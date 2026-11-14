package com.ibusehat.app.microbenchmark

import org.json.JSONArray
import org.json.JSONObject

/**
 * Kotlin mirror dari parsing JSON di Flutter:
 * - ActivityService.fetchActivities / fetchSummary
 * - ProgressService.getProgressSummary
 * - AuthService user payload
 */
object ApiJsonParser {

    data class ActivityCoordinate(val lat: Double, val lng: Double)

    data class ActivityModel(
        val id: Int,
        val type: String,
        val title: String,
        val distanceKm: Double,
        val durationSeconds: Int,
        val pace: String?,
        val calories: Int,
        val coordinates: List<ActivityCoordinate>,
    )

    data class ProgressSummary(
        val steps: Int,
        val waterMl: Int,
        val calories: Int,
        val sleepScore: Int,
    )

    fun parseActivitiesListResponse(json: String): List<ActivityModel> {
        val root = JSONObject(json)
        val data = root.optJSONArray("data") ?: JSONArray()
        val result = ArrayList<ActivityModel>(data.length())
        for (i in 0 until data.length()) {
            val item = data.getJSONObject(i)
            result.add(parseActivity(item))
        }
        return result
    }

    fun parseActivitySummary(json: String): Pair<Double, Int> {
        val root = JSONObject(json)
        val todayDistance = root.optDouble("today_distance_km", 0.0)
        val todaySteps = root.optInt("today_steps_estimate", 0)
        return todayDistance to todaySteps
    }

    fun parseProgressSummary(json: String): ProgressSummary {
        val root = JSONObject(json)
        val data = root.getJSONObject("data")
        return ProgressSummary(
            steps = data.optInt("steps", 0),
            waterMl = data.optInt("water_ml", 0),
            calories = data.optInt("calories", 0),
            sleepScore = data.optInt("sleep_score", 0),
        )
    }

    fun parseAuthUser(json: String): Pair<String, String>? {
        val root = JSONObject(json)
        val name = root.optString("name", "")
        val email = root.optString("email", "")
        if (name.isEmpty() || email.isEmpty()) return null
        return name to email
    }

    private fun parseActivity(json: JSONObject): ActivityModel {
        val coordsJson = json.optJSONArray("coordinates") ?: JSONArray()
        val coords = ArrayList<ActivityCoordinate>(coordsJson.length())
        for (i in 0 until coordsJson.length()) {
            val c = coordsJson.getJSONObject(i)
            coords.add(
                ActivityCoordinate(
                    lat = c.optDouble("lat", 0.0),
                    lng = c.optDouble("lng", 0.0),
                ),
            )
        }
        return ActivityModel(
            id = json.optInt("id", 0),
            type = json.optString("type", ""),
            title = json.optString("title", ""),
            distanceKm = json.optDouble("distance_km", 0.0),
            durationSeconds = json.optInt("duration_seconds", 0),
            pace = json.optString("pace").takeIf { it.isNotEmpty() },
            calories = json.optInt("calories", 0),
            coordinates = coords,
        )
    }
}
