<?php

namespace App\Http\Controllers;

use App\Models\Student;
use App\Models\Subject;
use App\Models\SubjectEnrollment;
use App\Models\RegistrationSchedule;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;

/**
 * Controller for handling student subject enrollments.
 * Manages adding/dropping subjects, checking registration schedules,
 * and enforcing rules like credit limits, class quotas, and time clashes.
 */
class SubjectEnrollmentController extends Controller
{
    private const MAX_CREDIT_HOURS = 18;
    private const REGISTRATION_CLOSED_MESSAGE = 'Registration Failed: Registration Period Not Open Yet';

    private function resolveStudentYearOfStudy(Student $student): ?int
    {
        if (Schema::hasColumn('student', 'Year_of_Study')) {
            return (int) $student->Year_of_Study;
        }
        if (Schema::hasColumn('student', 'year_of_study')) {
            return (int) $student->year_of_study;
        }
        if (Schema::hasColumn('student', 'Current_Year')) {
            return (int) $student->Current_Year;
        }
        if (Schema::hasColumn('student', 'Year')) {
            return (int) $student->Year;
        }

        return null;
    }

    private function isRegistrationOpenNowForYear(?int $yearOfStudy): bool
    {
        if (!$yearOfStudy) {
            error_log("REGISTRATION CHECK FAILED: Year of Study is NULL");
            return false;
        }

        $now = Carbon::now();
        $today = $now->toDateString();
        $currentTime = $now->format('H:i:s');

        $schedule = RegistrationSchedule::whereDate('Start_Date', '<=', $today)
            ->whereDate('End_Date', '>=', $today)
            ->where('Year_of_Study', $yearOfStudy)
            ->first();

        if (!$schedule) {
            error_log("REGISTRATION CLOSED: No matching schedule found");
            return false;
        }

        // Check time only on START and END dates
        $isStartDay = $schedule->Start_Date === $today;
        $isEndDay = $schedule->End_Date === $today;

        if ($isStartDay && $currentTime < $schedule->Start_Time) {
            error_log("REGISTRATION CLOSED: Before start time on start day");
            return false;
        }

        if ($isEndDay && $currentTime > $schedule->End_Time) {
            error_log("REGISTRATION CLOSED: After end time on end day");
            return false;
        }

        error_log("REGISTRATION OPEN: Schedule valid - $today between {$schedule->Start_Date} and {$schedule->End_Date}");
        return true;
    }

    // Parse "HH:mm - HH:mm" range into start/end strings.
    private function parseTimeRange(string $range): array
    {
        $parts = array_map('trim', explode('-', $range));
        if (count($parts) !== 2) {
            return [null, null];
        }

        return [$parts[0], $parts[1]];
    }

    // Check if two subjects overlap by day and time range.
    private function hasTimeClash($a, $b): bool
    {
        if ($a->Day !== $b->Day) {
            return false;
        }

        [$aStart, $aEnd] = $this->parseTimeRange($a->Time);
        [$bStart, $bEnd] = $this->parseTimeRange($b->Time);
        if (!$aStart || !$aEnd || !$bStart || !$bEnd) {
            return false;
        }

        return max($aStart, $bStart) < min($aEnd, $bEnd);
    }


    // Add current student enrollment with validation checks.
    public function store(Request $request)
    {
        try {
            $user = Auth::user();
            $student = Student::where('User_ID', $user->User_ID)->first();
            if (!$student) {
                return response()->json([
                    'success' => false,
                    'message' => 'Student profile not found',
                ], 404);
            }

            if (!$this->isRegistrationOpenNowForYear($this->resolveStudentYearOfStudy($student))) {
                return response()->json([
                    'success' => false,
                    'message' => self::REGISTRATION_CLOSED_MESSAGE,
                ], 422);
            }

            $validator = Validator::make($request->all(), [
                'Subject_ID' => 'required|integer',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation error',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $subject = Subject::find($request->Subject_ID);
            if (!$subject) {
                return response()->json([
                    'success' => false,
                    'message' => 'Subject not found',
                ], 404);
            }

            $existing = SubjectEnrollment::where('Student_ID', $student->Student_ID)
                ->where('Subject_Code', $subject->Subject_Code)
                ->exists();
            if ($existing) {
                return response()->json([
                    'success' => false,
                    'message' => 'Subject already registered',
                ], 422);
            }

            $currentEnrollments = SubjectEnrollment::where('Student_ID', $student->Student_ID)->get();
            $currentSubjects = Subject::whereIn('Subject_Code', $currentEnrollments->pluck('Subject_Code')->unique())->get();

            $totalCredits = $currentSubjects->sum('Credit_Hours');
            if (($totalCredits + (int) $subject->Credit_Hours) > self::MAX_CREDIT_HOURS) {
                return response()->json([
                    'success' => false,
                    'message' => 'Registration Failed: Maximum Credit Limit Exceed',
                ], 422);
            }

            foreach ($currentSubjects as $registeredSubject) {
                if ($this->hasTimeClash($registeredSubject, $subject)) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Registration Failed: Time Clash Detected',
                    ], 422);
                }
            }

            // Quota is enforced per selected section/lab offering.
            if (Schema::hasColumn('subjectenrollment', 'Subject_ID')) {
                $sameOfferingCount = SubjectEnrollment::where('Subject_ID', $subject->Subject_ID)->count();
            } else {
                $sameOfferingCount = SubjectEnrollment::where('Subject_Code', $subject->Subject_Code)->count();
            }
            if ($sameOfferingCount >= (int) $subject->Quota) {
                return response()->json([
                    'success' => false,
                    'message' => 'Registration Failed: Class Quota Is Full',
                ], 422);
            }

            $payload = [
                'Student_ID' => $student->Student_ID,
                'Subject_Code' => $subject->Subject_Code,
                'Enrollment_Date' => now()->format('Y-m-d'),
            ];

            if (Schema::hasColumn('subjectenrollment', 'Subject_ID') && $subject->Subject_ID) {
                $payload['Subject_ID'] = $subject->Subject_ID;
            }

            $enrollment = SubjectEnrollment::create($payload);

            return response()->json([
                'success' => true,
                'message' => 'Enrollment created successfully',
                'data' => $enrollment,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create enrollment: ' . $e->getMessage(),
            ], 500);
        }
    }


    // Return all subjects available for student registration.
    public function availableSubjects()
    {
        try {
            $user = Auth::user();
            $student = Student::where('User_ID', $user->User_ID)->first();
            if (!$student) {
                return response()->json([
                    'success' => false,
                    'message' => 'Student profile not found',
                ], 404);
            }

            $subjects = Subject::orderBy('Subject_Code')->orderBy('Section')->orderBy('Lab')->get();
            $registrationOpen = $this->isRegistrationOpenNowForYear($this->resolveStudentYearOfStudy($student));

            return response()->json([
                'success' => true,
                'data' => $subjects,
                'registration_open' => $registrationOpen,
                'registration_message' => $registrationOpen ? null : self::REGISTRATION_CLOSED_MESSAGE,
            ], 200);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch available subjects: ' . $e->getMessage(),
            ], 500);
        }
    }

    // Drop an enrollment by ID.
    public function destroy($enrollmentId)
    {
        try {
            $user = Auth::user();
            $student = Student::where('User_ID', $user->User_ID)->first();
            if (!$student) {
                return response()->json([
                    'success' => false,
                    'message' => 'Student profile not found',
                ], 404);
            }

            if (!$this->isRegistrationOpenNowForYear($this->resolveStudentYearOfStudy($student))) {
                return response()->json([
                    'success' => false,
                    'message' => self::REGISTRATION_CLOSED_MESSAGE,
                ], 422);
            }

            $enrollment = SubjectEnrollment::where('Enrollment_ID', $enrollmentId)
                ->where('Student_ID', $student->Student_ID)
                ->firstOrFail();
            $enrollment->delete();

            return response()->json([
                'success' => true,
                'message' => 'Enrollment deleted successfully',
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete enrollment: ' . $e->getMessage(),
            ], 500);
                  }
    }
}