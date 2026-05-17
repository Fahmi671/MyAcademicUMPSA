<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\AttendanceSession;
use App\Models\AttendanceRecord;
use App\Models\SubjectEnrollment;
use Illuminate\Support\Str;
use Carbon\Carbon;

class AttendanceController extends Controller
{
    // Lecturer/PusatAdab: Get sessions by subject or activity
    public function getSessions(Request $request)
    {
        $user = $request->user();

        if ($user->User_Role === 'lecturer') {
            $sessions = AttendanceSession::with('subject')
                ->where('session_type', 'class')
                ->whereHas('subject', function ($q) use ($user) {
                    $q->where('Lecturer_ID', $user->lecturer->Lecturer_ID);
                })->get();
        } else {
            $sessions = AttendanceSession::where('session_type', 'activity')->get();
        }

        return response()->json($sessions);
    }

    // Lecturer/PusatAdab: Generate attendance code and open session
    public function openSession(Request $request)
    {
        $request->validate([
            'subject_id'   => 'nullable|integer',
            'activity_id'  => 'nullable|integer',
            'session_type' => 'required|in:class,activity',
            'time_limit'   => 'required|integer|min:1',
        ]);

        $code = strtoupper(Str::random(6));

        $session = AttendanceSession::create([
            'subject_id'      => $request->subject_id,
            'activity_id'     => $request->activity_id,
            'session_type'    => $request->session_type,
            'attendance_code' => $code,
            'time_limit'      => $request->time_limit,
            'status'          => 'open',
            'opened_at'       => Carbon::now(),
        ]);

        return response()->json($session, 201);
    }

    // Lecturer/PusatAdab: Close session
    public function closeSession($session_id)
    {
        $session = AttendanceSession::findOrFail($session_id);
        $session->update(['status' => 'closed']);
        return response()->json(['message' => 'Session closed']);
    }

    // Lecturer/PusatAdab: View attendance list
    public function getAttendanceList($session_id)
    {
        $records = AttendanceRecord::with('student.user')
            ->where('session_id', $session_id)
            ->get();

        return response()->json($records);
    }

    // Student: Get registered classes with session status
    public function getStudentClasses(Request $request)
    {
        $user = $request->user();
        $student = $user->student;

        $enrollments = SubjectEnrollment::with(['subject', 'subject.attendanceSessions'])
            ->where('Student_ID', $student->Student_ID)
            ->get();

        return response()->json($enrollments);
    }

    // Student: Check in attendance
    public function checkIn(Request $request)
    {
        $request->validate([
            'attendance_code' => 'required|string',
            'subject_id'      => 'nullable|integer',
            'latitude'        => 'nullable|numeric',
            'longitude'       => 'nullable|numeric',
        ]);

        $user = $request->user();
        $student = $user->student;

        // Find open session by code
        $session = AttendanceSession::where('attendance_code', $request->attendance_code)
            ->where('status', 'open')
            ->first();

        if (!$session) {
            return response()->json(['message' => 'Invalid attendance code'], 422);
        }

        // Check time limit
        $expiry = Carbon::parse($session->opened_at)->addMinutes($session->time_limit);
        if (Carbon::now()->greaterThan($expiry)) {
            return response()->json(['message' => 'Attendance session has expired'], 422);
        }

        // Check duplicate
        $existing = AttendanceRecord::where('session_id', $session->id)
            ->where('student_id', $student->Student_ID)
            ->first();

        if ($existing) {
            return response()->json(['message' => 'Attendance already recorded'], 422);
        }

        // Save attendance
        $record = AttendanceRecord::create([
            'session_id'    => $session->id,
            'student_id'    => $student->Student_ID,
            'check_in_time' => Carbon::now(),
            'latitude'      => $request->latitude,
            'longitude'     => $request->longitude,
        ]);

        return response()->json(['message' => 'Attendance recorded successfully', 'record' => $record], 201);
    }
}