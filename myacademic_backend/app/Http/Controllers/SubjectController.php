<?php

namespace App\Http\Controllers;

use App\Models\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class SubjectController extends Controller
{
    private function hasLecturerSlotConflict(?int $lecturerId, ?string $day, ?string $time, ?int $ignoreSubjectId = null): bool
    {
        if (!$lecturerId || !$day || !$time) {
            return false;
        }

        $query = Subject::where('Lecturer_ID', $lecturerId)
            ->where('Day', $day)
            ->where('Time', $time);

        if ($ignoreSubjectId) {
            $query->where('Subject_ID', '!=', $ignoreSubjectId);
        }

        return $query->exists();
    }

    // Return all subjects with lecturer relation.
    public function index()
    {
        try {
            $subjects = Subject::with('lecturer')->get();

            return response()->json([
                'success' => true,
                'data' => $subjects,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch subjects: ' . $e->getMessage(),
            ], 500);
        }
    }

    // Return a single subject by ID.
    public function show($subjectId)
    {
        try {
            $subject = Subject::with('lecturer')->findOrFail($subjectId);

            return response()->json([
                'success' => true,
                'data' => $subject,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Subject not found',
            ], 404);
        }
    }

    // Create one subject record.
    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'Subject_Code'   => [
                    'required',
                    'string',
                    Rule::unique('subject')->where(function ($query) use ($request) {
                        return $query
                            ->where('Section', $request->Section)
                            ->where('Lab', $request->Lab);
                    }),
                ],
                'Subject_Name'   => 'required|string',
                'Credit_Hours'   => 'required|integer|min:1',
                'Lecturer_ID'    => 'nullable|integer',
                'Day'            => 'required|string',
                'Time'           => 'required|string|max:50',
                'Venue'          => 'required|string',
                'Quota'          => 'required|integer|min:1',
                'Section'        => 'required|integer|min:1',
                'Lab'            => 'nullable|string',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation error',
                    'errors' => $validator->errors(),
                ], 422);
            }

            if ($this->hasLecturerSlotConflict(
                $request->input('Lecturer_ID'),
                $request->input('Day'),
                $request->input('Time')
            )) {
                return response()->json([
                    'success' => false,
                    'message' => 'Selected lecturer already has a subject at this day and time',
                ], 422);
            }

            $subject = Subject::create($request->all());

            return response()->json([
                'success' => true,
                'message' => 'Subject created successfully',
                'data' => $subject,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create subject: ' . $e->getMessage(),
            ], 500);
        }
    }

    // Create or update multiple subject records in one request.
    public function storeBulk(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'subjects' => 'required|array|min:1',
                'subjects.*.Subject_Code'   => 'required|string',
                'subjects.*.Subject_Name'   => 'required|string',
                'subjects.*.Credit_Hours'   => 'required|integer|min:1',
                'subjects.*.Lecturer_ID'    => 'nullable|integer',
                'subjects.*.Day'            => 'required|string',
                'subjects.*.Time'           => 'required|string|max:50',
                'subjects.*.Venue'          => 'required|string',
                'subjects.*.Quota'          => 'required|integer|min:1',
                'subjects.*.Section'        => 'required|integer|min:1',
                'subjects.*.Lab'            => 'nullable|string',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation error',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $createdSubjects = [];
            $seenInRequest = [];

            foreach ($request->subjects as $subjectData) {
                $existingSubject = Subject::where('Subject_Code', $subjectData['Subject_Code'])
                    ->where('Section', $subjectData['Section'])
                    ->where('Lab', $subjectData['Lab'] ?? '')
                    ->first();

                $ignoreSubjectId = $existingSubject ? (int) $existingSubject->Subject_ID : null;
                $lecturerId = isset($subjectData['Lecturer_ID']) ? (int) $subjectData['Lecturer_ID'] : null;
                $day = $subjectData['Day'] ?? null;
                $time = $subjectData['Time'] ?? null;

                if ($lecturerId && $day && $time) {
                    $slotKey = $lecturerId . '|' . $day . '|' . $time;
                    $seenSubjectId = $seenInRequest[$slotKey] ?? null;
                    if ($seenSubjectId !== null && $seenSubjectId !== $ignoreSubjectId) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Duplicate lecturer day/time found in submitted subjects',
                        ], 422);
                    }

                    if ($this->hasLecturerSlotConflict($lecturerId, $day, $time, $ignoreSubjectId)) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Selected lecturer already has a subject at this day and time',
                        ], 422);
                    }

                    $seenInRequest[$slotKey] = $ignoreSubjectId ?? -1;
                }

                if ($existingSubject) {
                    $existingSubject->update($subjectData);
                    $createdSubjects[] = $existingSubject;
                } else {
                    $subject = Subject::create($subjectData);
                    $createdSubjects[] = $subject;
                }
            }

            return response()->json([
                'success' => true,
                'message' => 'Subjects saved successfully',
                'data' => $createdSubjects,
                'count' => count($createdSubjects),
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create subjects: ' . $e->getMessage(),
            ], 500);
        }
    }

    // Update an existing subject by ID.
    public function update(Request $request, $subjectId)
    {
        try {
            $subject = Subject::findOrFail($subjectId);

            $validator = Validator::make($request->all(), [
                'Subject_Name'   => 'sometimes|string',
                'Credit_Hours'   => 'sometimes|integer|min:1',
                'Lecturer_ID'    => 'nullable|integer',
                'Day'            => 'sometimes|string',
                'Time'           => 'sometimes|string|max:50',
                'Venue'          => 'sometimes|string',
                'Quota'          => 'sometimes|integer|min:1',
                'Section'        => 'sometimes|integer|min:1',
                'Lab'            => 'nullable|string',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation error',
                    'errors' => $validator->errors(),
                ], 422);
            }

            if ($this->hasLecturerSlotConflict(
                $request->input('Lecturer_ID'),
                $request->input('Day'),
                $request->input('Time'),
                (int) $subjectId
            )) {
                return response()->json([
                    'success' => false,
                    'message' => 'Selected lecturer already has a subject at this day and time',
                ], 422);
            }

            $subject->update($request->all());

            return response()->json([
                'success' => true,
                'message' => 'Subject updated successfully',
                'data' => $subject,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update subject: ' . $e->getMessage(),
            ], 500);
        }
    }

    // Delete a subject by ID.
    public function destroy($subjectId)
    {
        try {
            $subject = Subject::findOrFail($subjectId);
            $subject->delete();

            return response()->json([
                'success' => true,
                'message' => 'Subject deleted successfully',
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete subject: ' . $e->getMessage(),
            ], 500);
        }
    }
}