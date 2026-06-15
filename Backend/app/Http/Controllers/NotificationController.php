<?php

namespace App\Http\Controllers;

use App\Models\Notification;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NotificationController extends Controller
{
    // Returns all notifications for the currently authenticated student.
    public function index()
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json(['success' => false, 'message' => 'Unauthenticated'], 401);
            }

            $student = Student::where('User_ID', $user->User_ID)->first();
            if (!$student) {
                return response()->json(['success' => false, 'message' => 'Student profile not found'], 404);
            }

            $notifications = Notification::where('Student_ID', $student->Student_ID)
                ->orderBy('Created_At', 'desc')
                ->get();

            return response()->json(['success' => true, 'data' => $notifications], 200);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to load notifications: ' . $e->getMessage()], 500);
        }
    }

    // Marks a specific notification as read for the authenticated student.
    public function markAsRead($id)
    {
        try {
            $user = Auth::user();
            $student = Student::where('User_ID', $user->User_ID)->first();
            
            $notification = Notification::where('Notification_ID', $id)
                ->where('Student_ID', $student->Student_ID)
                ->first();

            if (!$notification) {
                return response()->json(['success' => false, 'message' => 'Notification not found'], 404);
            }

            $notification->Is_Read = true;
            $notification->save();

            return response()->json(['success' => true, 'data' => $notification], 200);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to mark as read: ' . $e->getMessage()], 500);
        }
    }

    // Allows the Treasury to send an Unpaid Tuition Fee notification to a specific student.
    public function sendTuitionAlert(Request $request)
    {
        try {
            $request->validate([
                'Student_ID' => 'required|string|max:10',
                'Message' => 'required|string'
            ]);

            $student = Student::where('Student_ID', $request->Student_ID)->first();
            if (!$student) {
                return response()->json(['success' => false, 'message' => 'Student not found'], 404);
            }

            $notification = Notification::create([
                'Student_ID' => $request->Student_ID,
                'Title' => 'Unpaid Tuition Fee',
                'Message' => $request->Message,
                'Is_Read' => false
            ]);

            return response()->json(['success' => true, 'message' => 'Notification sent', 'data' => $notification], 201);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to send alert: ' . $e->getMessage()], 500);
        }
    }
}
