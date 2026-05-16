<?php

namespace App\Http\Controllers;

use App\Models\CoCurriculumActivity;
use Illuminate\Http\Request;

class CoCurriculumActivityController extends Controller
{
    public function index()
    {
        try {
            $activities = CoCurriculumActivity::all();

            return response()->json([
                'success' => true,
                'data' => $activities
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch activities',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function show($activity_id)
    {
        try {
            $activity = CoCurriculumActivity::find($activity_id);

            if (!$activity) {
                return response()->json([
                    'success' => false,
                    'message' => 'Activity not found'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $activity
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch activity',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function store(Request $request)
    {
        try {
            $request->validate([
                'Activity_ID' => 'required|string',
                'PusatAdab_ID' => 'nullable|string',
                'Module_Code' => 'required|string',
                'Module_Name' => 'required|string',
                'Campus' => 'required|string',
                'Venue' => 'required|string',
                'Activity_Date' => 'required',
                'Activity_Time' => 'required|string',
                'Capacity' => 'required|integer',
                'Available_Slots' => 'required|integer',
                'Status' => 'nullable|string',
                'Description' => 'nullable|string',
            ]);

            $activity = CoCurriculumActivity::create([
                'Activity_ID' => $request->Activity_ID,
                'PusatAdab_ID' => $request->PusatAdab_ID,
                'Module_Code' => $request->Module_Code,
                'Module_Name' => $request->Module_Name,
                'Campus' => $request->Campus,
                'Venue' => $request->Venue,
                'Activity_Date' => $request->Activity_Date,
                'Activity_Time' => $request->Activity_Time,
                'Capacity' => $request->Capacity,
                'Available_Slots' => $request->Available_Slots,
                'Status' => $request->Status ?? 'Open',
                'Description' => $request->Description,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Activity added successfully',
                'data' => $activity
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to add activity',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function update(Request $request, $activity_id)
    {
        try {
            $activity = CoCurriculumActivity::find($activity_id);

            if (!$activity) {
                return response()->json([
                    'success' => false,
                    'message' => 'Activity not found'
                ], 404);
            }

            $activity->update($request->only([
                'PusatAdab_ID',
                'Module_Code',
                'Module_Name',
                'Campus',
                'Venue',
                'Activity_Date',
                'Activity_Time',
                'Capacity',
                'Available_Slots',
                'Status',
                'Description',
            ]));

            return response()->json([
                'success' => true,
                'message' => 'Activity updated successfully',
                'data' => $activity
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update activity',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function destroy($activity_id)
    {
        try {
            $activity = CoCurriculumActivity::find($activity_id);

            if (!$activity) {
                return response()->json([
                    'success' => false,
                    'message' => 'Activity not found'
                ], 404);
            }

            $activity->delete();

            return response()->json([
                'success' => true,
                'message' => 'Activity deleted successfully'
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete activity',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}