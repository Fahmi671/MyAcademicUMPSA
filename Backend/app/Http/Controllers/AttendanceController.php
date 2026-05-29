<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\AttendanceSession;
use App\Models\AttendanceRecord;
use App\Models\SubjectEnrollment;
use App\Models\Participation;
use Carbon\Carbon;
use Illuminate\Support\Str;

class AttendanceController extends Controller
{
    // Lecturer/Pusat Adab: Get attendance sessions
    public function getSessions(Request $request)
    {
        try {
            $user = $request->user();

            if ($user->User_Role === 'lecturer') {
                $lecturer = $user->lecturer;

                $sessions = AttendanceSession::with('subject')
                    ->where('session_type', 'class')
                    ->when($lecturer, function ($q) use ($lecturer) {
                        $q->whereHas('subject', function ($subjectQuery) use ($lecturer) {
                            $subjectQuery->where('Lecturer_ID', $lecturer->Lecturer_ID);
                        });
                    })
                    ->latest('opened_at')
                    ->get();
            } else {
                $sessions = AttendanceSession::where('session_type', 'activity')
                    ->latest('opened_at')
                    ->get();
            }

            return response()->json([
                'success' => true,
                'data' => $sessions,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch attendance sessions',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // Lecturer/Pusat Adab: Generate attendance code and open session
    public function openSession(Request $request)
    {
        try {
            $request->validate([
                'subject_id'   => 'nullable|integer|required_without:activity_id',
                'activity_id'  => 'nullable|string|required_without:subject_id',
                'session_type' => 'required|in:class,activity',
                'time_limit'   => 'required|integer|min:1',
            ]);

            // Close previous open session for the same class/activity so only the latest code is valid.
            AttendanceSession::where('session_type', $request->session_type)
                ->when($request->session_type === 'class', function ($q) use ($request) {
                    $q->where('subject_id', $request->subject_id);
                })
                ->when($request->session_type === 'activity', function ($q) use ($request) {
                    $q->where('activity_id', $request->activity_id);
                })
                ->where('status', 'open')
                ->update(['status' => 'closed']);

            $session = AttendanceSession::create([
                'subject_id'      => $request->subject_id,
                'activity_id'     => $request->activity_id,
                'session_type'    => $request->session_type,
                'attendance_code' => strtoupper(Str::random(6)),
                'time_limit'      => $request->time_limit,
                'status'          => 'open',
                'opened_at'       => Carbon::now(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Attendance session opened successfully',
                'data' => $session,
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to open attendance session',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function closeSession($session_id)
    {
        try {
            $session = AttendanceSession::findOrFail($session_id);
            $session->update(['status' => 'closed']);

            return response()->json([
                'success' => true,
                'message' => 'Session closed',
                'data' => $session,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to close session',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // Lecturer/Pusat Adab: View attendance list
    public function getAttendanceList($session_id)
    {
        try {
            $records = AttendanceRecord::with('student.user')
                ->where('session_id', $session_id)
                ->orderBy('check_in_time', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $records,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch attendance list',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // Student: Get registered classes and mark whether each class has an open attendance session.
    public function getStudentClasses(Request $request)
    {
        try {
            $student = $request->user()->student;

            if (!$student) {
                return response()->json([
                    'success' => false,
                    'message' => 'Student profile not found',
                ], 404);
            }

            $enrollments = SubjectEnrollment::with('subject')
                ->where('Student_ID', $student->Student_ID)
                ->get()
                ->map(function ($enrollment) {
                    $activeSession = null;

                    if ($enrollment->subject) {
                        $activeSession = AttendanceSession::where('session_type', 'class')
                            ->where('subject_id', $enrollment->subject->Subject_ID)
                            ->where('status', 'open')
                            ->latest('opened_at')
                            ->first();
                    }

                    $enrollment->has_active_session = $activeSession !== null;
                    $enrollment->session_status = $activeSession ? 'open' : 'closed';
                    $enrollment->active_session_id = $activeSession?->id;

                    return $enrollment;
                });

            return response()->json([
                'success' => true,
                'data' => $enrollments,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch registered classes',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    // Student: Check in attendance for class or activity
    public function checkIn(Request $request)
    {
        try {
            $request->validate([
                'attendance_code' => 'required|string',
                'subject_id'      => 'nullable|integer',
                'activity_id'     => 'nullable|string',
                'latitude'        => 'nullable|numeric',
                'longitude'       => 'nullable|numeric',
            ]);

            $user = $request->user();
            $student = $user->student;

            if (!$student) {
                return response()->json([
                    'success' => false,
                    'message' => 'Student profile not found',
                ], 404);
            }

            $session = AttendanceSession::where('attendance_code', strtoupper($request->attendance_code))
                ->where('status', 'open')
                ->first();

            if (!$session) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid attendance code',
                ], 422);
            }

            if ($session->subject_id && (int) $request->subject_id !== (int) $session->subject_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid attendance code for this class',
                ], 422);
            }

            if ($session->activity_id && (string) $request->activity_id !== (string) $session->activity_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid attendance code for this activity',
                ], 422);
            }

            $expiry = Carbon::parse($session->opened_at)->addMinutes($session->time_limit);
            if (Carbon::now()->greaterThan($expiry)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Attendance session has expired',
                ], 422);
            }

            if ($session->session_type === 'class') {
                $registered = SubjectEnrollment::where('Student_ID', $student->Student_ID)
                    ->where('Subject_ID', $session->subject_id)
                    ->exists();

                if (!$registered) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Student is not registered for this class',
                    ], 422);
                }
            }

            if ($session->session_type === 'activity') {
                // Some existing Module 2 code stores Student_ID using User_ID, so this accepts both to connect safely.
                $registered = Participation::whereIn('Student_ID', [$student->Student_ID, (string) $user->User_ID, $user->User_ID])
                    ->where('Activity_ID', (string) $session->activity_id)
                    ->where('Registration_Status', 'Registered')
                    ->exists();

                if (!$registered) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Student is not registered for this activity',
                    ], 422);
                }
            }

            $existing = AttendanceRecord::where('session_id', $session->id)
                ->where('student_id', $student->Student_ID)
                ->first();

            if ($existing) {
                return response()->json([
                    'success' => false,
                    'message' => 'Attendance already recorded',
                ], 422);
            }

            $record = AttendanceRecord::create([
                'session_id'    => $session->id,
                'student_id'    => $student->Student_ID,
                'check_in_time' => Carbon::now(),
                'latitude'      => $request->latitude,
                'longitude'     => $request->longitude,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Attendance recorded successfully',
                'data' => $record,
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Attendance submission failed',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
