<?php

namespace App\Http\Controllers;

use App\Models\Activity;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ActivityController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $activities = $request->user()
            ->activities()
            ->orderByDesc('ended_at')
            ->paginate(20);

        return response()->json($activities);
    }

    public function show(Request $request, Activity $activity): JsonResponse
    {
        if ($activity->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        return response()->json($activity);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'type' => 'required|string|in:running,walking,cycling',
            'title' => 'required|string|max:255',
            'distance_km' => 'required|numeric|min:0',
            'duration_seconds' => 'required|integer|min:0',
            'pace' => 'nullable|string|max:16',
            'calories' => 'nullable|integer|min:0',
            'coordinates' => 'required|array',
            'coordinates.*.lat' => 'required|numeric',
            'coordinates.*.lng' => 'required|numeric',
            'started_at' => 'required|date',
            'ended_at' => 'required|date|after_or_equal:started_at',
        ]);

        $activity = $request->user()->activities()->create([
            'type' => $validated['type'],
            'title' => $validated['title'],
            'distance_km' => $validated['distance_km'],
            'duration_seconds' => $validated['duration_seconds'],
            'pace' => $validated['pace'] ?? null,
            'calories' => $validated['calories'] ?? 0,
            'coordinates' => $validated['coordinates'],
            'started_at' => $validated['started_at'],
            'ended_at' => $validated['ended_at'],
        ]);

        return response()->json([
            'success' => true,
            'data' => $activity,
        ], 201);
    }

    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();
        $today = Carbon::today();

        $todayDistance = (float) $user->activities()
            ->whereDate('started_at', $today)
            ->sum('distance_km');

        $todaySteps = (int) round($todayDistance * 1300);

        $latest = $user->activities()
            ->orderByDesc('ended_at')
            ->first();

        $startWeek = $today->copy()->startOfWeek(Carbon::MONDAY);
        $dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        $weeklyData = [];

        for ($i = 0; $i < 7; $i++) {
            $day = $startWeek->copy()->addDays($i);
            $km = (float) $user->activities()
                ->whereDate('started_at', $day->toDateString())
                ->sum('distance_km');
            $labelIndex = $day->isoWeekday() - 1;
            $weeklyData[] = [
                'day' => $dayLabels[$labelIndex] ?? '?',
                'distance_km' => round($km, 2),
            ];
        }

        $monthDistance = (float) $user->activities()
            ->whereYear('started_at', $today->year)
            ->whereMonth('started_at', $today->month)
            ->sum('distance_km');

        return response()->json([
            'today_distance_km' => round($todayDistance, 2),
            'today_steps' => $todaySteps,
            'month_distance_km' => round($monthDistance, 2),
            'weekly_data' => $weeklyData,
            'latest_activity' => $latest,
        ]);
    }
}
