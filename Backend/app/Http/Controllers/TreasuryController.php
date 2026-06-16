<?php

namespace App\Http\Controllers;

use App\Models\TuitionFee;
use Illuminate\Http\Request;

class TreasuryController extends Controller
{
    // Returns all student tuition fee and payment records for the Treasury ledger view.
    public function ledger()
    {
        try {
            $records = TuitionFee::with('student.user')->orderBy('Created_At', 'desc')->get();
            return response()->json(['success' => true, 'data' => $records], 200);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to load student ledger: ' . $e->getMessage()], 500);
        }
    }

    // Searches the ledger for a specific student by Student ID or name.
    public function search(Request $request)
    {
        try {
            $query = $request->query('student_id');
            if (empty($query)) {
                return response()->json(['success' => false, 'message' => 'Search query is required'], 422);
            }

            // To avoid MySQL collation mismatch errors between tables (utf8mb4_unicode_ci vs utf8mb4_general_ci),
            // we find matching student IDs in a separate query instead of using whereHas.
            $userIds = \App\Models\User::where('User_FullName', 'like', '%' . $query . '%')->pluck('User_ID');
            $studentIds = \App\Models\Student::whereIn('User_ID', $userIds)->pluck('Student_ID');

            $results = TuitionFee::with('student.user')
                ->where('Student_ID', 'like', '%' . $query . '%')
                ->orWhereIn('Student_ID', $studentIds)
                ->get();

            if ($results->isEmpty()) {
                return response()->json(['success' => false, 'message' => 'No record found for this Student ID'], 404);
            }

            return response()->json(['success' => true, 'data' => $results], 200);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Search failed: ' . $e->getMessage()], 500);
        }
    }

    // Filters the ledger by payment status: All Students, Paid, or Blocked.
    public function filter(Request $request)
    {
        try {
            $status = $request->query('status');

            $query = TuitionFee::with('student.user');

            if ($status === 'Paid') {
                $query->where('Payment_Status', 'Paid');
            } elseif ($status === 'Blocked') {
                $query->where('Academic_Access', 'Blocked');
            } elseif ($status !== 'All Students' && !empty($status)) {
                return response()->json(['success' => false, 'message' => 'Invalid filter status'], 422);
            }

            $results = $query->get();

            return response()->json(['success' => true, 'data' => $results], 200);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Filter failed: ' . $e->getMessage()], 500);
        }
    }
}
