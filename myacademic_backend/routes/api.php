<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\LecturerController;
use App\Http\Controllers\SubjectController;
use App\Http\Controllers\RegistrationScheduleController;
use App\Http\Controllers\SubjectEnrollmentController;

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
});