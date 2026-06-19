<?php

namespace App\Http\Controllers;

use App\Models\WorkoutProgram;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WorkoutProgramController extends Controller
{
    public function index(): JsonResponse
    {
        $programs = WorkoutProgram::query()
            ->where('is_active', true)
            ->withCount('exercises')
            ->orderBy('id')
            ->get()
            ->map(function (WorkoutProgram $program) {
                $program->total_exercises = $program->exercises_count;
                return $program;
            });

        return response()->json([
            'data' => $programs,
        ]);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $difficulty = $request->query('difficulty');

        $program = WorkoutProgram::query()
            ->where('is_active', true)
            ->whereKey($id)
            ->with([
                'exercises' => function ($query) use ($difficulty) {
                    if (!empty($difficulty)) {
                        $query->where('difficulty', $difficulty);
                    }
                    $query->orderBy('order');
                },
            ])
            ->first();

        if (!$program) {
            return response()->json([
                'message' => 'Program latihan tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'data' => $program,
        ]);
    }
}
