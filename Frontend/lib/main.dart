import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Pages/Homepage/RegistrarHomepage.dart';
import 'Pages/Homepage/StudentHomepage.dart';
import 'Pages/Homepage/LecturerHomepage.dart';
import 'Pages/Homepage/PusatAdabHomepage.dart';
import 'Pages/SubjectRegistration/RegistrarSubjectList.dart';
import 'Pages/SubjectRegistration/RegistrarAddSubject.dart';
import 'Pages/SubjectRegistration/RegistrarEditSubject.dart';
import 'Pages/SubjectRegistration/RegistrarViewSubject.dart';
import 'Pages/SubjectRegistration/RegistrarRegistrationSchedule.dart';
import 'Pages/SubjectRegistration/StudentSubject.dart';
import 'Pages/SubjectRegistration/LecturerSubjectList.dart';
import 'Pages/SubjectRegistration/LecturerSubjectDetail.dart';
import 'Pages/CoCurriculumRegistration/StudentActivityList.dart';
import 'Pages/CoCurriculumRegistration/AdabManageActivity.dart';
import 'Pages/CoCurriculumRegistration/AdabAddActivity.dart';
import 'Pages/Auth/LoginInterface.dart';
import 'Config/api.dart';
import 'Domain/Subject.dart'; // ← Just import normally

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
        '/login': (ctx) => const LoginInterface(),
        '/registrar-homepage': (ctx) => const RegistrarHomepage(),
        '/student-homepage': (ctx) => const StudentHomepage(),
        '/lecturer-homepage': (ctx) => const LecturerHomepage(),
        '/pusat-adab-homepage': (ctx) => const PusatAdabHomepage(),
        '/student-subject': (ctx) => const StudentSubject(),
        '/student-activities': (ctx) => const StudentActivityList(),
        '/lecturer-subject-list': (ctx) => const LecturerSubjectList(),
        '/adab-manage-activity': (ctx) => const AdabManageActivity(),
        '/adab-add-activity': (ctx) => const AdabAddActivity(),
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
      },
    );
  }
}