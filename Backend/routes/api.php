<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\LecturerController;
use App\Http\Controllers\SubjectController;
use App\Http\Controllers\RegistrationScheduleController;
use App\Http\Controllers\SubjectEnrollmentController;
use App\Http\Controllers\CoCurriculumActivityController;
use App\Http\Controllers\ParticipationController;
use App\Http\Controllers\CreditClaimController;
use App\Http\Controllers\PusatAdabController;
use App\Http\Controllers\AttendanceController;
/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

Route::middleware('throttle:60,1')->group(function () {
    // Public routes (no authentication required)
    Route::post('/auth/login', [AuthController::class, 'login']);
});

// Protected routes (authentication required)
Route::middleware('auth:sanctum')->group(function () {
    // Auth routes
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/user', [AuthController::class, 'currentUser']);
    Route::get('/lecturers', [LecturerController::class, 'index']);
    Route::get('/lecturer/subjects', [LecturerController::class, 'assignedSubjects']);
    Route::get('/lecturer/subjects/{subject_code}', [LecturerController::class, 'subjectDetail']);

    // Subject routes
    Route::get('/subjects', [SubjectController::class, 'index']);
    Route::post('/subjects/bulk', [SubjectController::class, 'storeBulk']);
    Route::get('/subjects/{subject_id}', [SubjectController::class, 'show']);
    Route::post('/subjects', [SubjectController::class, 'store']);
    Route::put('/subjects/{subject_id}', [SubjectController::class, 'update']);
    Route::delete('/subjects/{subject_id}', [SubjectController::class, 'destroy']);

    // Registration Schedule routes
    Route::get('/schedules', [RegistrationScheduleController::class, 'index']);
    Route::post('/schedules', [RegistrationScheduleController::class, 'store']);
    Route::put('/schedules/{schedule_id}', [RegistrationScheduleController::class, 'update']);
    Route::delete('/schedules/{schedule_id}', [RegistrationScheduleController::class, 'destroy']);

    // Subject Enrollment routes
    Route::get('/enrollments/subject/{subject_code}', [SubjectEnrollmentController::class, 'getBySubject']);
    Route::get('/student/enrollments', [SubjectEnrollmentController::class, 'myEnrollments']);
    Route::get('/student/available-subjects', [SubjectEnrollmentController::class, 'availableSubjects']);
    Route::post('/enrollments', [SubjectEnrollmentController::class, 'store']);
    Route::delete('/enrollments/{enrollment_id}', [SubjectEnrollmentController::class, 'destroy']);

    // Co-Curriculum Activity routes
    Route::get('/activities', [CoCurriculumActivityController::class, 'index']);
    Route::post('/activities', [CoCurriculumActivityController::class, 'store']);
    Route::get('/activities/{activity_id}', [CoCurriculumActivityController::class, 'show']);
    Route::put('/activities/{activity_id}', [CoCurriculumActivityController::class, 'update']);
    Route::delete('/activities/{activity_id}', [CoCurriculumActivityController::class, 'destroy']);

    // Participation routes
    Route::get('/student/participations', [ParticipationController::class, 'myParticipations']);
    Route::post('/participations', [ParticipationController::class, 'store']);
    Route::delete('/participations/{participation_id}', [ParticipationController::class, 'destroy']);

    // Credit Claim routes
    Route::get('/student/claims', [CreditClaimController::class, 'myClaims']);
    Route::post('/claims', [CreditClaimController::class, 'store']);
    Route::get('/claims/pending', [CreditClaimController::class, 'pendingClaims']);
    Route::put('/claims/{claim_id}/review', [CreditClaimController::class, 'review']);

    // Pusat Adab routes
    Route::get('/pusat-adab/profile', [PusatAdabController::class, 'profile']);

    // Attendance routes
    Route::get('/attendance/sessions', [AttendanceController::class, 'getSessions']);
    Route::post('/attendance/sessions', [AttendanceController::class, 'openSession']);
    Route::put('/attendance/sessions/{session_id}/close', [AttendanceController::class, 'closeSession']);
    Route::get('/attendance/sessions/{session_id}/records', [AttendanceController::class, 'getAttendanceList']);
    Route::get('/student/classes', [AttendanceController::class, 'getStudentClasses']);
    Route::get('/student/activity-attendance', [AttendanceController::class, 'getStudentActivities']);
    Route::post('/attendance/checkin', [AttendanceController::class, 'checkIn']);
});