<?php

namespace App\Http\Controllers;

use App\Models\Lecturer;
use App\Models\Subject;
use App\Models\SubjectEnrollment;
use Illuminate\Support\Facades\Auth;

class LecturerController extends Controller
{
    // Return all lecturers for dropdown/list usage.
    public function index()
    {
        try {
            $lecturers = Lecturer::query()
                ->join('user', 'lecturer.User_ID', '=', 'user.User_ID')
                ->select('lecturer.Lecturer_ID', 'user.User_FullName')
                ->orderBy('user.User_FullName')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $lecturers,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch lecturers: '.$e->getMessage(),
            ], 500);
        }
    }

    // Return subjects assigned to logged-in lecturer.
    public function assignedSubjects()
    {
        try {
            $user = Auth::user();
            $lecturer = Lecturer::where('User_ID', $user->User_ID)->first();
            if (!$lecturer) {
                return response()->json([
                    'success' => false,
                    'message' => 'Lecturer profile not found',
                ], 404);
            }

            $subjects = Subject::where('Lecturer_ID', $lecturer->Lecturer_ID)
                ->orderBy('Subject_Code')
                ->orderBy('Section')
                ->orderBy('Lab')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $subjects,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch assigned subjects: ' . $e->getMessage(),
            ], 500);
        }
    }

    // Return subject detail and enrolled students for logged-in lecturer.
    public function subjectDetail($subjectCode)
    {
        try {
            $user = Auth::user();
            $lecturer = Lecturer::where('User_ID', $user->User_ID)->first();
            if (!$lecturer) {
                return response()->json([
                    'success' => false,
                    'message' => 'Lecturer profile not found',
                ], 404);
            }

            $subjects = Subject::where('Lecturer_ID', $lecturer->Lecturer_ID)
                ->where('Subject_Code', $subjectCode)
                ->orderBy('Section')
                ->orderBy('Lab')
                ->get();

            $subjectIds = $subjects->pluck('Subject_ID')->all();
            $enrollments = SubjectEnrollment::with(['student.user'])
                ->whereIn('Subject_ID', $subjectIds)
                ->get()
                ->groupBy('Subject_ID');

            $subjectsWithEnrollments = $subjects->map(function ($subject) use ($enrollments) {
                $subjectData = $subject->toArray();
                $subjectData['enrollments'] = ($enrollments[$subject->Subject_ID] ?? collect())->values();
                return $subjectData;
            });

            return response()->json([
                'success' => true,
                'data' => $subjectsWithEnrollments,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch subject detail: ' . $e->getMessage(),
            ], 500);
        }
    }
}
