package com.ibusehat.app.microbenchmark

object SampleApiPayloads {
    val activitiesListJson: String = buildString {
        append("""{"data":[""")
        repeat(50) { index ->
            if (index > 0) append(',')
            append(
                """
                {
                  "id": $index,
                  "type": "run",
                  "title": "Lari Pagi $index",
                  "distance_km": ${3.5 + index * 0.1},
                  "duration_seconds": ${1800 + index * 30},
                  "pace": "6:30",
                  "calories": ${250 + index},
                  "coordinates": [
                    {"lat": -6.2, "lng": 106.8},
                    {"lat": -6.21, "lng": 106.81},
                    {"lat": -6.22, "lng": 106.82}
                  ],
                  "started_at": "2026-07-24T06:00:00Z",
                  "ended_at": "2026-07-24T06:30:00Z"
                }
                """.trimIndent(),
            )
        }
        append("""]}""")
    }

    const val activitySummaryJson = """
        {
          "today_distance_km": 4.2,
          "today_steps_estimate": 6200,
          "month_distance_km": 42.5,
          "weekly_chart": [
            {"day": "Mon", "distance_km": 1.2},
            {"day": "Tue", "distance_km": 2.1}
          ]
        }
    """

    const val progressSummaryJson = """
        {
          "status": "success",
          "data": {
            "steps": 8500,
            "water_ml": 1800,
            "calories": 1650,
            "sleep_score": 82
          }
        }
    """

    const val authUserJson = """
        {
          "name": "Ibu Sehat",
          "email": "ibu@example.com",
          "avatar": "https://cdn.example.com/avatar.png",
          "is_onboarding_done": true,
          "is_premium": true,
          "premium_until": "2026-12-31T23:59:59Z"
        }
    """
}
