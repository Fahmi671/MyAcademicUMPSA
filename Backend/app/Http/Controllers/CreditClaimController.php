<?php

namespace App\Http\Controllers;

use App\Models\CreditClaim;
use App\Models\Participation;
use App\Models\CoCurriculumActivity;
use Illuminate\Http\Request;

class CreditClaimController extends Controller
{
    public function store(Request $request)
    {
        try {
            $user = $request->user();

            $request->validate([
                'Participation_ID' => 'required|integer',
                'Attendance_Status' => 'required|string',
            ]);

            $participation = Participation::where('Participation_ID', $request->Participation_ID)
                ->where('Student_ID', $user->User_ID)
                ->where('Registration_Status', 'Registered')
                ->first();

            if (!$participation) {
                return response()->json([
                    'success' => false,
                    'message' => 'Participation record not found'
                ], 404);
            }

            $attendanceStatus = strtolower($request->Attendance_Status);

            if ($attendanceStatus !== 'present' && $attendanceStatus !== 'attended') {
                return response()->json([
                    'success' => false,
                    'message' => 'You can only claim credit after attendance is verified.'
                ], 400);
            }

            $existingClaim = CreditClaim::where('Participation_ID', $participation->Participation_ID)
                ->whereIn('Claim_Status', ['Pending', 'Approved'])
                ->first();

            if ($existingClaim) {
                return response()->json([
                    'success' => false,
                    'message' => 'You have already submitted a credit claim for this activity.'
                ], 400);
            }

            $activity = CoCurriculumActivity::where('Activity_ID', $participation->Activity_ID)->first();

            if (!$activity) {
                return response()->json([
                    'success' => false,
                    'message' => 'Activity not found'
                ], 404);
            }

            $claim = CreditClaim::create([
                'PusatAdab_ID' => $activity->PusatAdab_ID,
                'Participation_ID' => $participation->Participation_ID,
                'Attendance_Status' => $request->Attendance_Status,
                'Claim_Status' => 'Pending',
                'Remarks' => null,
                'Created_At' => now(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Credit Claim Submitted Successfully',
                'data' => $claim
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $e->errors()
            ], 422);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Claim Submission Failed',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function pendingClaims(Request $request)
    {
        try {
            $claims = CreditClaim::join(
                    'participation',
                    'credit_claim.Participation_ID',
                    '=',
                    'participation.Participation_ID'
                )
                ->join(
                    'cocurriculum_activity',
                    'participation.Activity_ID',
                    '=',
                    'cocurriculum_activity.Activity_ID'
                )
                ->join(
                    'user',
                    'participation.Student_ID',
                    '=',
                    'user.User_ID'
                )
                ->where('credit_claim.Claim_Status', 'Pending')
                ->select(
                    'credit_claim.*',
                    'user.User_FullName as Student_Name',
                    'cocurriculum_activity.Module_Code',
                    'cocurriculum_activity.Module_Name',
                    'cocurriculum_activity.Campus',
                    'cocurriculum_activity.Venue',
                    'cocurriculum_activity.Activity_Date',
                    'cocurriculum_activity.Activity_Time'
                )
                ->get();

            return response()->json([
                'success' => true,
                'data' => $claims
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch pending claims',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function review(Request $request, $claim_id)
    {
        try {
            $request->validate([
                'Claim_Status' => 'required|string|in:Approved,Rejected',
                'Remarks' => 'nullable|string',
            ]);

            $claim = CreditClaim::where('Claim_ID', $claim_id)->first();

            if (!$claim) {
                return response()->json([
                    'success' => false,
                    'message' => 'Claim not found'
                ], 404);
            }

            $claim->Claim_Status = $request->Claim_Status;
            $claim->Remarks = $request->Remarks;
            $claim->save();

            return response()->json([
                'success' => true,
                'message' => $request->Claim_Status === 'Approved'
                    ? 'Claim Approved Successfully'
                    : 'Claim Rejected Successfully',
                'data' => $claim
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $e->errors()
            ], 422);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to review claim',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}