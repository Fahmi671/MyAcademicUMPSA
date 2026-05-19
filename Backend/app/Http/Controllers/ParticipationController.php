<?php

namespace App\Http\Controllers;

use App\Models\Participation;
use App\Models\CoCurriculumActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ParticipationController extends Controller
{
    public function myParticipations(Request $request)
    {
        try {
            $user = $request->user();

            $participations = Participation::where('Student_ID', $user->User_ID)
                ->join('cocurriculum_activity', 'participation.Activity_ID', '=', 'cocurriculum_activity.Activity_ID')
                ->select(
                    'participation.*',
                    'cocurriculum_activity.Module_Code',
                    'cocurriculum_activity.Module_Name',
                    'cocurriculum_activity.Campus',
                    'cocurriculum_activity.Venue',
                    'cocurriculum_activity.Activity_Date',
                    'cocurriculum_activity.Activity_Time',
                    'cocurriculum_activity.Capacity',
                    'cocurriculum_activity.Available_Slots'
                )
                ->get();

            return response()->json([
                'success' => true,
                'data' => $participations
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch participations',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function store(Request $request)
    {
        try {
            $user = $request->user();

            $request->validate([
                'Activity_ID' => 'required|string',
            ]);

            return DB::transaction(function () use ($request, $user) {
                $activity = CoCurriculumActivity::where('Activity_ID', $request->Activity_ID)
                    ->lockForUpdate()
                    ->first();

                if (!$activity) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Activity not found'
                    ], 404);
                }

                if ($activity->Available_Slots <= 0) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Module has reached maximum capacity.'
                    ], 400);
                }

                $existing = Participation::where('Student_ID', $user->User_ID)
                    ->where('Activity_ID', $request->Activity_ID)
                    ->where('Registration_Status', 'Registered')
                    ->first();

                if ($existing) {
                    return response()->json([
                        'success' => false,
                        'message' => 'You have already registered for this module.'
                    ], 400);
                }

                $participation = Participation::create([
                    'Student_ID' => $user->User_ID,
                    'Activity_ID' => $request->Activity_ID,
                    'Registered_At' => now(),
                    'Registration_Status' => 'Registered',
                ]);

                $activity->Available_Slots = $activity->Available_Slots - 1;

                if ($activity->Available_Slots <= 0) {
                    $activity->Status = 'Full';
                }

                $activity->save();

                return response()->json([
                    'success' => true,
                    'message' => 'Registration Successful',
                    'data' => $participation
                ], 201);
            });
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Registration failed',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function destroy(Request $request, $participation_id)
    {
        try {
            return DB::transaction(function () use ($request, $participation_id) {
                $user = $request->user();

                $participation = Participation::where('Participation_ID', $participation_id)
                    ->where('Student_ID', $user->User_ID)
                    ->where('Registration_Status', 'Registered')
                    ->first();

                if (!$participation) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Registration record not found'
                    ], 404);
                }

                $activity = CoCurriculumActivity::where('Activity_ID', $participation->Activity_ID)
                    ->lockForUpdate()
                    ->first();

                $participation->Registration_Status = 'Withdrawn';
                $participation->save();

                if ($activity) {
                    $activity->Available_Slots = $activity->Available_Slots + 1;

                    if ($activity->Available_Slots > 0) {
                        $activity->Status = 'Open';
                    }

                    $activity->save();
                }

                return response()->json([
                    'success' => true,
                    'message' => 'Withdraw Successful'
                ], 200);
            });
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to withdraw activity',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}