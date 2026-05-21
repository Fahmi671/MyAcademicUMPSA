<?php

namespace App\Http\Controllers;

use App\Models\RegistrationSchedule;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class RegistrationScheduleController extends Controller
{
    // Return all schedules for logged-in faculty registrar.
    public function index()
    {
        try {
            $user = Auth::user();
            $facultyRegistrar = $user->facultyRegistrar;

            if (!$facultyRegistrar) {
                return response()->json([
                    'success' => false,
                    'message' => 'Faculty registrar not found',
                ], 404);
            }

            // Automatically clean up expired schedules (End_Date in the past, or End_Date is today but End_Time is in the past)
            $today = now()->toDateString();
            $currentTime = now()->format('H:i:s');

            RegistrationSchedule::where('End_Date', '<', $today)
                ->orWhere(function ($query) use ($today, $currentTime) {
                    $query->where('End_Date', $today)
                          ->where('End_Time', '<', $currentTime);
                })
                ->delete();

            $schedules = RegistrationSchedule::where(
                'FacultyRegistrar_ID',
                $facultyRegistrar->FacultyRegistrar_ID
            )->get();

            return response()->json([
                'success' => true,
                'data' => $schedules,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch schedules: ' . $e->getMessage(),
            ], 500);
        }
    }

    // Create registration schedule for logged-in faculty registrar.
    public function store(Request $request)
    {
        try {
            $user = Auth::user();
            $facultyRegistrar = $user->facultyRegistrar;

            $validator = Validator::make($request->all(), [
                'Year_of_Study'  => 'required|integer|min:1|max:4',
                'Start_Date'     => 'required|date',
                'End_Date'       => 'required|date|after:Start_Date',
                'Start_Time'     => 'required|date_format:H:i',
                'End_Time'       => 'required|date_format:H:i',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation error',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $schedule = RegistrationSchedule::create([
                'FacultyRegistrar_ID' => $facultyRegistrar->FacultyRegistrar_ID,
                'Year_of_Study' => $request->Year_of_Study,
                'Start_Date' => $request->Start_Date,
                'End_Date' => $request->End_Date,
                'Start_Time' => $request->Start_Time,
                'End_Time' => $request->End_Time,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Schedule created successfully',
                'data' => $schedule,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create schedule: ' . $e->getMessage(),
            ], 500);
        }
    }

    // Update a registration schedule by ID.
    public function update(Request $request, $scheduleId)
    {
        try {
            $schedule = RegistrationSchedule::findOrFail($scheduleId);

            $validator = Validator::make($request->all(), [
                'Year_of_Study'  => 'sometimes|integer|min:1|max:4',
                'Start_Date'     => 'sometimes|date',
                'End_Date'       => 'sometimes|date',
                'Start_Time'     => 'sometimes|date_format:H:i',
                'End_Time'       => 'sometimes|date_format:H:i',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation error',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $schedule->update($request->all());

            return response()->json([
                'success' => true,
                'message' => 'Schedule updated successfully',
                'data' => $schedule,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update schedule: ' . $e->getMessage(),
            ], 500);
        }
    }

    // Delete a registration schedule by ID.
    public function destroy($scheduleId)
    {
        try {
            $schedule = RegistrationSchedule::findOrFail($scheduleId);
            $schedule->delete();

            return response()->json([
                'success' => true,
                'message' => 'Schedule deleted successfully',
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete schedule: ' . $e->getMessage(),
            ], 500);
        }
    }
}