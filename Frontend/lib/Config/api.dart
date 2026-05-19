import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static String baseUrl = "http://10.0.2.2:8000/api"; // Android emulator
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static String? getToken() {
    return _token;
  }

  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // ════════════════════════════════════════════════════════════
  // LOGIN
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        setToken(data['data']['token']);
        return data;
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Login failed',
      };
    } catch (e) {
      print("LOGIN ERROR: $e");
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // LOGOUT
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        _token = null;
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'message': 'Logout failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // GET CURRENT USER
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/user'),
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'message': 'Failed to fetch user',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // GET ALL SUBJECTS
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subjects'),
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'message': 'Failed to fetch subjects',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // GET LECTURERS
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getLecturers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lecturers'),
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'message': 'Failed to fetch lecturers',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // GET SINGLE SUBJECT
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getSubject(int subjectId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subjects/$subjectId'),
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'message': 'Subject not found',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // CREATE SUBJECT
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> createSubject({
    required String subjectCode,
    required String subjectName,
    required int creditHours,
    required int lecturerId,
    required String day,
    required String time,
    required String venue,
    required int quota,
    required int section,
    required String lab,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subjects'),
        headers: getHeaders(),
        body: jsonEncode({
          'Subject_Code': subjectCode,
          'Subject_Name': subjectName,
          'Credit_Hours': creditHours,
          'Lecturer_ID': lecturerId,
          'Day': day,
          'Time': time,
          'Venue': venue,
          'Quota': quota,
          'Section': section,
          'Lab': lab,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'message': 'Failed to create subject',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // UPDATE SUBJECT
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> updateSubject({
    required int subjectId,
    required String subjectName,
    required int creditHours,
    required int lecturerId,
    required String day,
    required String time,
    required String venue,
    required int quota,
    required int section,
    required String lab,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/subjects/$subjectId'),
        headers: getHeaders(),
        body: jsonEncode({
          'Subject_Name': subjectName,
          'Credit_Hours': creditHours,
          'Lecturer_ID': lecturerId,
          'Day': day,
          'Time': time,
          'Venue': venue,
          'Quota': quota,
          'Section': section,
          'Lab': lab,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'message': 'Failed to update subject',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // DELETE SUBJECT
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> deleteSubject(int subjectId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/subjects/$subjectId'),
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'message': 'Failed to delete subject',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // GET REGISTRATION SCHEDULES
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getSchedules() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedules'),
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'message': 'Failed to fetch schedules',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // CREATE SCHEDULE
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> createSchedule({
    required int yearOfStudy,
    required String startDate,
    required String endDate,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/schedules'),
        headers: getHeaders(),
        body: jsonEncode({
          'Year_of_Study': yearOfStudy,
          'Start_Date': startDate,
          'End_Date': endDate,
          'Start_Time': startTime,
          'End_Time': endTime,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'message': 'Failed to create schedule',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // UPDATE SCHEDULE
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> updateSchedule({
    required int scheduleId,
    required int yearOfStudy,
    required String startDate,
    required String endDate,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/schedules/$scheduleId'),
        headers: getHeaders(),
        body: jsonEncode({
          'Year_of_Study': yearOfStudy,
          'Start_Date': startDate,
          'End_Date': endDate,
          'Start_Time': startTime,
          'End_Time': endTime,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'message': 'Failed to update schedule',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // DELETE SCHEDULE
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> deleteSchedule(int scheduleId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/schedules/$scheduleId'),
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'message': 'Failed to delete schedule',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // CREATE BULK SUBJECTS
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> createBulkSubjects({
    required List<Map<String, dynamic>> subjects,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subjects/bulk'),
        headers: getHeaders(),
        body: jsonEncode({
          'subjects': subjects,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to create subjects',
        if (data['errors'] != null) 'errors': data['errors'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // STUDENT
  static Future<Map<String, dynamic>> getStudentAvailableSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/student/available-subjects'),
        headers: getHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getStudentEnrollments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/student/enrollments'),
        headers: getHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addEnrollment({required int subjectId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enrollments'),
        headers: getHeaders(),
        body: jsonEncode({'Subject_ID': subjectId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> dropEnrollment({required int enrollmentId}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/enrollments/$enrollmentId'),
        headers: getHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // LECTURER
  static Future<Map<String, dynamic>> getLecturerAssignedSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lecturer/subjects'),
        headers: getHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getLecturerSubjectDetail(String subjectCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lecturer/subjects/$subjectCode'),
        headers: getHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  // ════════════════════════════════════════════════════════════
// CO-CURRICULUM ACTIVITIES
// ════════════════════════════════════════════════════════════
static Future<Map<String, dynamic>> getActivities() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/activities'),
      headers: getHeaders(),
    );

    return jsonDecode(response.body);
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: $e',
    };
  }
}

static Future<Map<String, dynamic>> createActivity({
  required String moduleCode,
  required String moduleName,
  required String campus,
  required String venue,
  required String activityDate,
  required String activityTime,
  required int capacity,
  required int availableSlots,
  required String status,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/activities'),
      headers: getHeaders(),
      body: jsonEncode({
        'Module_Code': moduleCode,
        'Module_Name': moduleName,
        'Campus': campus,
        'Venue': venue,
        'Activity_Date': activityDate,
        'Activity_Time': activityTime,
        'Capacity': capacity,
        'Available_Slots': availableSlots,
        'Status': status,
      }),
    );

    return jsonDecode(response.body);
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: $e',
    };
  }
}

static Future<Map<String, dynamic>> updateActivity({
  required String activityId,
  required String pusatAdabId,
  required String moduleCode,
  required String moduleName,
  required String campus,
  required String venue,
  required String activityDate,
  required String activityTime,
  required int capacity,
  required int availableSlots,
  required String status,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/activities/$activityId'),
      headers: getHeaders(),
      body: jsonEncode({
        'Module_Code': moduleCode,
        'Module_Name': moduleName,
        'Campus': campus,
        'Venue': venue,
        'Activity_Date': activityDate,
        'Activity_Time': activityTime,
        'Capacity': capacity,
        'Available_Slots': availableSlots,
        'Status': status,
      }),
    );

    return jsonDecode(response.body);
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: $e',
    };
  }
}

static Future<Map<String, dynamic>> deleteActivity(String activityId) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/activities/$activityId'),
      headers: getHeaders(),
    );

    return jsonDecode(response.body);
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: $e',
    };
  }
}

// ════════════════════════════════════════════════════════════
// STUDENT CO-CURRICULUM PARTICIPATION
// ════════════════════════════════════════════════════════════
static Future<Map<String, dynamic>> registerActivity({
  required String activityId,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/participations'),
      headers: getHeaders(),
      body: jsonEncode({
        'Activity_ID': activityId,
      }),
    );

    return jsonDecode(response.body);
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: $e',
    };
  }
}

static Future<Map<String, dynamic>> getStudentParticipations() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/student/participations'),
      headers: getHeaders(),
    );

    return jsonDecode(response.body);
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: $e',
    };
  }
}

static Future<Map<String, dynamic>> withdrawParticipation({
  required int participationId,
}) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/participations/$participationId'),
      headers: getHeaders(),
    );

    return jsonDecode(response.body);
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: $e',
    };
  }
}

  

  // ════════════════════════════════════════════════════════════
  // ATTENDANCE
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getStudentClasses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/student/enrollments'),
        headers: getHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getStudentRegisteredActivities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/student/participations'),
        headers: getHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkInAttendance({
    required String attendanceCode,
    int? subjectId,
    int? activityId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/checkin'),
        headers: getHeaders(),
        body: jsonEncode({
          'attendance_code': attendanceCode,
          'subject_id': subjectId,
          'activity_id': activityId,
          'latitude': null,
          'longitude': null,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createAttendanceSession({
    required int? subjectId,
    required int? activityId,
    required String sessionType,
    required int timeLimit,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/sessions'),
        headers: getHeaders(),
        body: jsonEncode({
          'subject_id': subjectId,
          'activity_id': activityId,
          'session_type': sessionType,
          'time_limit': timeLimit,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAttendanceRecords(int sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/sessions/$sessionId/records'),
        headers: getHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getActivityDetail(int activityId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/activities/$activityId'),
        headers: getHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}

