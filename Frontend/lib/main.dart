import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Config & Domain
import 'Config/api.dart';
import 'Domain/Subject.dart';

// Auth
import 'Pages/Auth/LoginInterface.dart';

// Homepage
import 'Pages/Homepage/RegistrarHomepage.dart';
import 'Pages/Homepage/StudentHomepage.dart';
import 'Pages/Homepage/LecturerHomepage.dart';
import 'Pages/Homepage/PusatAdabHomepage.dart';

// Subject Registration
import 'Pages/SubjectRegistration/RegistrarSubjectList.dart';
import 'Pages/SubjectRegistration/RegistrarAddSubject.dart';
import 'Pages/SubjectRegistration/RegistrarEditSubject.dart';
import 'Pages/SubjectRegistration/RegistrarViewSubject.dart';
import 'Pages/SubjectRegistration/RegistrarRegistrationSchedule.dart';
import 'Pages/SubjectRegistration/StudentSubject.dart';
import 'Pages/SubjectRegistration/LecturerSubjectList.dart';
import 'Pages/SubjectRegistration/LecturerSubjectDetail.dart';

// Co-Curriculum Registration
import 'Pages/CoCurriculumRegistration/StudentActivityList.dart';
import 'Pages/CoCurriculumRegistration/StudentRegisteredActivity.dart';
import 'Pages/CoCurriculumRegistration/StudentClaimCredit.dart';
import 'Pages/CoCurriculumRegistration/AdabManageActivity.dart';
import 'Pages/CoCurriculumRegistration/AdabAddActivity.dart';
import 'Pages/CoCurriculumRegistration/AdabReviewActivity.dart';

// Attendance
import 'Pages/Attendance/StudentAttendanceList.dart';
import 'Pages/Attendance/StudentCheckIn.dart';
import 'Pages/Attendance/LecturerAttendanceSession.dart';
import 'Pages/Attendance/LecturerAttendanceList.dart';
import 'Pages/Attendance/PusatAdabAttendanceSession.dart';
import 'Pages/Attendance/PusatAdabAttendanceList.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final role = prefs.getString('user_role');

  if (token != null) {
    ApiService.setToken(token);
  }

  runApp(MyApp(isLoggedIn: token != null, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? role;

  const MyApp({required this.isLoggedIn, this.role, super.key});

  Widget resolveHome() {
    if (!isLoggedIn) return const LoginInterface();
    if (role == 'student') return const StudentHomepage();
    if (role == 'lecturer') return const LecturerHomepage();
    if (role == 'facultyregistrar') return const RegistrarHomepage();
    if (role == 'pusatadab') return const PusatAdabHomepage();
    return const LoginInterface();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyAcademic UMPSA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A5F5F),
        ),
        useMaterial3: true,
      ),
      home: resolveHome(),
      routes: {

        // Auth
        '/login': (ctx) => const LoginInterface(),

        // Homepage
        '/registrar-homepage': (ctx) => const RegistrarHomepage(),
        '/student-homepage': (ctx) => const StudentHomepage(),
        '/lecturer-homepage': (ctx) => const LecturerHomepage(),
        '/pusat-adab-homepage': (ctx) => const PusatAdabHomepage(),

        // Subject Registration
        '/student-subject': (ctx) => const StudentSubject(),
        '/lecturer-subject-list': (ctx) => const LecturerSubjectList(),
        '/lecturer-subject-detail': (ctx) {
          final subjectCode = ModalRoute.of(ctx)?.settings.arguments as String?;
          return subjectCode != null ? LecturerSubjectDetail(subjectCode: subjectCode) : const LecturerSubjectList();
        },
        '/registrar-subject-list': (ctx) => const RegistrarSubjectList(),
        '/registrar-add-subject': (ctx) => const RegistrarAddSubject(),
        '/registrar-edit-subject': (ctx) {
          final subjects = ModalRoute.of(ctx)?.settings.arguments as List<Subject>?;
          return subjects != null && subjects.isNotEmpty
              ? RegistrarEditSubject(subjects: subjects)
              : const RegistrarSubjectList();
        },
        '/registrar-view-subject': (ctx) {
          final subjects = ModalRoute.of(ctx)?.settings.arguments as List<Subject>?;
          return subjects != null && subjects.isNotEmpty
              ? RegistrarViewSubject(subjects: subjects)
              : const RegistrarSubjectList();
        },
        '/registrar-registration-schedule': (ctx) => const RegistrarRegistrationSchedule(),

        // Co-Curriculum Registration
        '/student-activities': (ctx) => const StudentActivityList(),
        '/student-registered-activities': (ctx) => const StudentRegisteredActivity(),
        '/student-claim-credit': (ctx) => const StudentClaimCredit(),
        '/adab-manage-activity': (ctx) => const AdabManageActivity(),
        '/adab-add-activity': (ctx) => const AdabAddActivity(),
        '/adab-review-activity': (ctx) => const AdabReviewActivity(),

        // Attendance
        '/student-class-attendance': (ctx) => const StudentAttendanceList(),
        '/student-cocurriculum-attendance': (ctx) => const StudentAttendanceList(isActivity: true),
        '/student-checkin': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
          return StudentCheckIn(sessionData: args ?? {});
        },
        '/lecturer-attendance': (ctx) => const LecturerAttendanceSession(),
        '/lecturer-attendance-list': (ctx) {
          final sessionId = ModalRoute.of(ctx)?.settings.arguments as int?;
          return sessionId != null ? LecturerAttendanceList(sessionId: sessionId) : const LecturerAttendanceSession();
        },
        '/pusat-adab-attendance': (ctx) => const PusatAdabAttendanceSession(),
        '/pusat-adab-attendance-list': (ctx) {
          final rawActivityId = ModalRoute.of(ctx)?.settings.arguments;
          final activityId = rawActivityId?.toString();
          return activityId != null && activityId.isNotEmpty
              ? PusatAdabAttendanceList(activityId: activityId)
              : const PusatAdabAttendanceSession();
        },

      },
    );
  }
}