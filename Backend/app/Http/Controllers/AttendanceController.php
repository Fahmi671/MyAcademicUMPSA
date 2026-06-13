<?php

namespace App\Http\Controllers;

use App\Models\AttendanceRecord;
use App\Models\AttendanceSession;
use App\Models\CoCurriculumActivity;
use App\Models\Participation;
use App\Models\Student;
use App\Models\Subject;
use App\Models\SubjectEnrollment;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class AttendanceController extends Controller
{
    private function success($data = null, string $message = 'Success', int $status = 200)
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data,
        ], $status);
    }

    private function fail(string $message, int $status = 400, $errors = null)
    {
        $payload = [
            'success' => false,
            'message' => $message,
        ];

        if ($errors !== null) {
            $payload['errors'] = $errors;
        }

        return response()->json($payload, $status);
    }

    private function currentStudent(Request $request): ?Student
    {
        $user = $request->user();
        if (!$user) {
            return null;
        }

        if (method_exists($user, 'student') && $user->student) {
            return $user->student;
        }

        return Student::where('User_ID', $user->User_ID)->first();
    }


    private function closeExpiredSessions(): void
    {
        AttendanceSession::where('status', 'open')
            ->whereNotNull('opened_at')
            ->get()
            ->each(function ($session) {
                $expiry = Carbon::parse($session->opened_at)->addMinutes((int) $session->time_limit);
                if (Carbon::now()->greaterThanOrEqualTo($expiry)) {
                    $session->update(['status' => 'closed']);
                }
            });
    }

    private function isSessionStillActive(?AttendanceSession $session): bool
    {
        if (!$session || $session->status !== 'open' || !$session->opened_at) {
            return false;
        }

        $expiry = Carbon::parse($session->opened_at)->addMinutes((int) $session->time_limit);
        return Carbon::now()->lessThan($expiry);
    }

    /**
     * Lecturer / Pusat Adab: list existing attendance sessions.
     * Main UI uses assigned subjects and activities directly, but this endpoint is kept for compatibility.
     */
    public function getSessions(Request $request)
    {
        try {
            $this->closeExpiredSessions();
            $user = $request->user();

            if ($user && $user->User_Role === 'lecturer') {
                $lecturer = $user->lecturer;
                $sessions = AttendanceSession::with(['subject', 'records.student.user'])
                    ->where('session_type', 'class')
                    ->when($lecturer, function ($query) use ($lecturer) {
                        $query->whereHas('subject', function ($q) use ($lecturer) {
                            $q->where('Lecturer_ID', $lecturer->Lecturer_ID);
                        });
                    })
                    ->latest('opened_at')
                    ->get();
            } else {
                $sessions = AttendanceSession::with(['activity', 'records.student.user'])
                    ->where('session_type', 'activity')
                    ->latest('opened_at')
                    ->get();
            }

            return $this->success($sessions, 'Attendance sessions fetched');
        } catch (\Exception $e) {
            return $this->fail('Failed to fetch attendance sessions', 500, $e->getMessage());
        }
    }

    /**
     * Lecturer / Pusat Adab: generate code and open attendance session.
     * For this prototype, code generation opens the session immediately, which matches the current Flutter flow.
     */
    public function openSession(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'subject_id'   => 'nullable|integer',
            'activity_id'  => 'nullable|string|max:20',
            'session_type' => 'required|in:class,activity',
            'time_limit'   => 'nullable|integer|min:1|max:240',
        ]);

        if ($validator->fails()) {
            return $this->fail('Validation error', 422, $validator->errors());
        }

        try {
            return DB::transaction(function () use ($request) {
                $this->closeExpiredSessions();

                $sessionType = $request->session_type;
                $timeLimit = (int) ($request->time_limit ?? 15);

                if ($sessionType === 'class') {
                    if (!$request->subject_id) {
                        return $this->fail('Subject ID is required for class attendance', 422);
                    }

                    $subject = Subject::find($request->subject_id);
                    if (!$subject) {
                        return $this->fail('Subject not found', 404);
                    }

                    $existingOpen = AttendanceSession::where('session_type', 'class')
                        ->where('subject_id', $subject->Subject_ID)
                        ->where('status', 'open')
                        ->latest('opened_at')
                        ->first();

                    if ($this->isSessionStillActive($existingOpen)) {
                        $existingOpen->load('subject');
                        return $this->success($existingOpen, 'Attendance session already open');
                    }

                    AttendanceSession::where('session_type', 'class')
                        ->where('subject_id', $subject->Subject_ID)
                        ->where('status', 'open')
                        ->update(['status' => 'closed']);

                    $session = AttendanceSession::create([
                        'subject_id'      => $subject->Subject_ID,
                        'activity_id'     => null,
                        'session_type'    => 'class',
                        'attendance_code' => Str::random(6),
                        'time_limit'      => $timeLimit,
                        'status'          => 'open',
                        'opened_at'       => Carbon::now(),
                    ]);

                    $session->load('subject');
                    return $this->success($session, 'Attendance session opened', 201);
                }

                if (!$request->activity_id) {
                    return $this->fail('Activity ID is required for activity attendance', 422);
                }

                $activity = CoCurriculumActivity::where('Activity_ID', $request->activity_id)->first();
                if (!$activity) {
                    return $this->fail('Activity not found', 404);
                }

                $existingOpen = AttendanceSession::where('session_type', 'activity')
                    ->where('activity_id', $activity->Activity_ID)
                    ->where('status', 'open')
                    ->latest('opened_at')
                    ->first();

                if ($this->isSessionStillActive($existingOpen)) {
                    $existingOpen->load('activity');
                    return $this->success($existingOpen, 'Attendance session already open');
                }

                AttendanceSession::where('session_type', 'activity')
                    ->where('activity_id', $activity->Activity_ID)
                    ->where('status', 'open')
                    ->update(['status' => 'closed']);

                $session = AttendanceSession::create([
                    'subject_id'      => null,
                    'activity_id'     => $activity->Activity_ID,
                    'session_type'    => 'activity',
                    'attendance_code' => Str::random(6),
                    'time_limit'      => $timeLimit,
                    'status'          => 'open',
                    'opened_at'       => Carbon::now(),
                ]);

                $session->load('activity');
                return $this->success($session, 'Attendance session opened', 201);
            });
        } catch (\Exception $e) {
            return $this->fail('Failed to open attendance session', 500, $e->getMessage());
        }
    }

    public function closeSession($session_id)
    {
        try {
            $session = AttendanceSession::find($session_id);
            if (!$session) {
                return $this->fail('Attendance session not found', 404);
            }

            $session->update(['status' => 'closed']);
            return $this->success($session, 'Session closed');
        } catch (\Exception $e) {
            return $this->fail('Failed to close session', 500, $e->getMessage());
        }
    }

    public function getAttendanceList($session_id)
    {
        try {
            $session = AttendanceSession::with(['subject', 'activity'])->find($session_id);
            if (!$session) {
                return $this->fail('Attendance session not found', 404);
            }

            $records = AttendanceRecord::with('student.user')
                ->where('session_id', $session_id)
                ->orderBy('check_in_time')
                ->get();

            return $this->success([
                'session' => $session,
                'records' => $records,
            ], 'Attendance list fetched');
        } catch (\Exception $e) {
            return $this->fail('Failed to fetch attendance list', 500, $e->getMessage());
        }
    }

    public function getStudentClasses(Request $request)
    {
        try {
            $this->closeExpiredSessions();

            $student = $this->currentStudent($request);
            if (!$student) {
                return $this->fail('Student profile not found', 404);
            }

            /*
            |--------------------------------------------------------------------------
            | IMPORTANT FIX
            |--------------------------------------------------------------------------
            | Do not use SubjectEnrollment::with('subject') here.
            | In this database, several subjects share the same Subject_Code, for example
            | "asdd". If the model relationship joins using Subject_Code, Flutter may
            | receive the wrong subject details and show duplicate-looking cards.
            |
            | This query joins using Subject_ID directly, so each registered class shows
            | its own correct section, lab, time, and room.
            */
            $classes = DB::table('subjectenrollment as se')
                ->leftJoin('subject as s', 'se.Subject_ID', '=', 's.Subject_ID')
                ->where('se.Student_ID', $student->Student_ID)
                ->select(
                    'se.Enrollment_ID',
                    'se.Student_ID',
                    'se.Subject_Code as Enrollment_Subject_Code',
                    'se.Subject_ID as Enrollment_Subject_ID',
                    'se.Enrollment_Date',
                    's.Subject_ID',
                    's.Subject_Code',
                    's.Subject_Name',
                    's.Section',
                    's.Lab',
                    's.Day',
                    's.Time',
                    's.Venue',
                    's.Lecturer_ID'
                )
                ->orderBy('s.Day')
                ->orderBy('s.Time')
                ->get()
                ->unique('Enrollment_Subject_ID')
                ->values()
                ->map(function ($row) {
                    $activeSession = null;

                    if ($row->Subject_ID) {
                        $activeSession = AttendanceSession::where('session_type', 'class')
                            ->where('subject_id', $row->Subject_ID)
                            ->where('status', 'open')
                            ->latest('opened_at')
                            ->first();
                    }

                    return [
                        'Enrollment_ID' => $row->Enrollment_ID,
                        'Student_ID' => $row->Student_ID,
                        'Subject_Code' => $row->Enrollment_Subject_Code,
                        'Subject_ID' => $row->Enrollment_Subject_ID,
                        'Enrollment_Date' => $row->Enrollment_Date,

                        'subject' => [
                            'Subject_ID' => $row->Subject_ID,
                            'Subject_Code' => $row->Subject_Code,
                            'Subject_Name' => $row->Subject_Name,
                            'Section' => $row->Section,
                            'Lab' => $row->Lab,
                            'Day' => $row->Day,
                            'Time' => $row->Time,
                            'Venue' => $row->Venue,
                            'Lecturer_ID' => $row->Lecturer_ID,
                            // Your current database/API does not provide lecturer name here.
                            // Keep '-' so the Flutter UI remains safe.
                            'Lecturer' => '-',
                        ],

                        'active_session' => $activeSession,
                        'has_active_session' => $activeSession !== null,
                        'is_session_open' => $activeSession !== null,
                        'session_status' => $activeSession ? 'open' : 'closed',
                    ];
                });

            return $this->success($classes, 'Registered classes fetched');
        } catch (\Exception $e) {
            return $this->fail('Failed to fetch registered classes', 500, $e->getMessage());
        }
    }

    public function getStudentActivities(Request $request)
    {
        try {
            $this->closeExpiredSessions();
            $student = $this->currentStudent($request);
            if (!$student) {
                return $this->fail('Student profile not found', 404);
            }

            $userId = $request->user()->User_ID;

            $participations = Participation::where(function ($query) use ($student, $userId) {
                    $query->where('Student_ID', $student->Student_ID)
                        ->orWhere('Student_ID', $userId);
                })
                ->where('Registration_Status', 'Registered')
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
                    'cocurriculum_activity.Available_Slots',
                    'cocurriculum_activity.Status'
                )
                ->get()
                ->map(function ($participation) {
                    $activeSession = AttendanceSession::where('session_type', 'activity')
                        ->where('activity_id', $participation->Activity_ID)
                        ->where('status', 'open')
                        ->latest('opened_at')
                        ->first();

                    $data = $participation->toArray();
                    $data['activity'] = [
                        'Activity_ID' => $participation->Activity_ID,
                        'Module_Code' => $participation->Module_Code,
                        'Module_Name' => $participation->Module_Name,
                        'Campus' => $participation->Campus,
                        'Venue' => $participation->Venue,
                        'Activity_Date' => $participation->Activity_Date,
                        'Activity_Time' => $participation->Activity_Time,
                        'Capacity' => $participation->Capacity,
                        'Available_Slots' => $participation->Available_Slots,
                        'Status' => $participation->Status,
                    ];
                    $data['active_session'] = $activeSession;
                    $data['has_active_session'] = $activeSession !== null;
                    $data['is_session_open'] = $activeSession !== null;
                    $data['session_status'] = $activeSession ? 'open' : 'closed';
                    return $data;
                });

            return $this->success($participations, 'Registered activities fetched');
        } catch (\Exception $e) {
            return $this->fail('Failed to fetch registered activities', 500, $e->getMessage());
        }
    }

    public function checkIn(Request $request)
{
    $validator = Validator::make($request->all(), [
        'attendance_code' => 'required|string',
        'session_id'      => 'nullable|integer',
        'subject_id'      => 'nullable|integer',
        'activity_id'     => 'nullable|string|max:20',
        'latitude'        => 'nullable|numeric',
        'longitude'       => 'nullable|numeric',
    ]);

    if ($validator->fails()) {
        return $this->fail('Validation error', 422, $validator->errors());
    }

    try {
        $student = $this->currentStudent($request);

        if (!$student) {
            return $this->fail('Student profile not found', 404);
        }

        $code = trim((string) $request->attendance_code);
        $code = preg_replace('/\s+/', '', $code);

        /*
        |--------------------------------------------------------------------------
        | 1. Find active attendance session
        |--------------------------------------------------------------------------
        | Priority:
        | - If session_id exists, use session_id first.
        | - This prevents the system from wrongly checking another class/session.
        */
        if ($request->filled('session_id')) {
            $session = AttendanceSession::where('id', $request->session_id)
                ->where('status', 'open')
                ->first();

            if (!$session) {
                return $this->fail('Selected attendance session is not open or does not exist', 422);
            }

            if (strtolower(trim($session->attendance_code)) !== strtolower($code)) {
                return $this->fail('Invalid attendance code', 422, [
                    'received_code' => $code,
                    'session_id' => $request->session_id,
                    'session_code' => $session->attendance_code,
                ]);
            }
        } else {
            $sessionQuery = AttendanceSession::where('status', 'open');

            if ($request->filled('subject_id')) {
                $sessionQuery->where('session_type', 'class')
                    ->where('subject_id', $request->subject_id);
            }

            if ($request->filled('activity_id')) {
                $sessionQuery->where('session_type', 'activity')
                    ->where('activity_id', $request->activity_id);
            }

            $session = $sessionQuery->get()->first(function ($item) use ($code) {
                return strtolower(trim($item->attendance_code)) === strtolower($code);
            });

            if (!$session) {
                return $this->fail('Invalid attendance code', 422);
            }
        }

        /*
        |--------------------------------------------------------------------------
        | 2. Check expiry time
        |--------------------------------------------------------------------------
        */
        if (!$session->opened_at) {
            return $this->fail('Attendance session has not been opened properly', 422);
        }

        $expiry = Carbon::parse($session->opened_at)->addMinutes((int) $session->time_limit);

        if (Carbon::now()->greaterThan($expiry)) {
            $session->update(['status' => 'closed']);
            return $this->fail('Attendance session has expired', 422);
        }

        /*
        |--------------------------------------------------------------------------
        | 3. Check registration
        |--------------------------------------------------------------------------
        */
        if ($session->session_type === 'class') {
            $registered = SubjectEnrollment::where('Student_ID', $student->Student_ID)
                ->where('Subject_ID', $session->subject_id)
                ->exists();

            if (!$registered) {
                return $this->fail('Student is not registered for this class', 422);
            }
        }

        if ($session->session_type === 'activity') {
            $userId = $request->user()->User_ID;

            $registered = Participation::where('Activity_ID', $session->activity_id)
                ->where('Registration_Status', 'Registered')
                ->where(function ($query) use ($student, $userId) {
                    $query->where('Student_ID', $student->Student_ID)
                        ->orWhere('Student_ID', $userId);
                })
                ->exists();

            if (!$registered) {
                return $this->fail('Student is not registered for this activity', 422);
            }
        }

        /*
        |--------------------------------------------------------------------------
        | 4. Prevent duplicate attendance
        |--------------------------------------------------------------------------
        */
        $existing = AttendanceRecord::where('session_id', $session->id)
            ->where('student_id', $student->Student_ID)
            ->first();

        if ($existing) {
            return $this->fail('Attendance Already Recorded', 409);
        }

        /*
        |--------------------------------------------------------------------------
        | 5. Save attendance
        |--------------------------------------------------------------------------
        */
        $record = AttendanceRecord::create([
            'session_id'    => $session->id,
            'student_id'    => $student->Student_ID,
            'check_in_time' => Carbon::now(),
            'latitude'      => $request->latitude,
            'longitude'     => $request->longitude,
        ]);

        return $this->success($record, 'Attendance Recorded Successfully', 201);

    } catch (\Exception $e) {
        return $this->fail('Failed to record attendance', 500, $e->getMessage());
    }
}
}
