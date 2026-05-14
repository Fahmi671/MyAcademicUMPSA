import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/Subject.dart';
import '../../Domain/SubjectEnrollment.dart';

class StudentSubject extends StatefulWidget {
  const StudentSubject({super.key});

  @override
  State<StudentSubject> createState() => _StudentSubjectState();
}

class _StudentSubjectState extends State<StudentSubject> {
  List<Subject> _allSubjects = [];
  List<SubjectEnrollment> _enrollments = [];
  bool _loading = true;
  String? _popupMessage;
  bool _popupSuccess = true;
  bool _registrationOpen = true;

  String? _selectedCourseCode;
  int? _selectedSection;
  String? _selectedLab;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => _loading = true);
    final subjectsResult = await ApiService.getStudentAvailableSubjects();
    final enrollmentResult = await ApiService.getStudentEnrollments();

    setState(() {
      _allSubjects = (subjectsResult['data'] as List? ?? []).map((e) => Subject.fromJson(e)).toList();
      _enrollments = (enrollmentResult['data'] as List? ?? []).map((e) => SubjectEnrollment.fromJson(e)).toList();
      _registrationOpen = subjectsResult['registration_open'] == true;
      _loading = false;
    });
  }

  Future<void> addEnrollment() async {
    if (!_registrationOpen) return;

    final candidates = _allSubjects.where((s) =>
      s.subjectCode == _selectedCourseCode &&
      s.section == _selectedSection &&
      s.lab == _selectedLab).toList();
    if (candidates.isEmpty) return;

    final result = await ApiService.addEnrollment(subjectId: candidates.first.subjectId);
    await load();
    showPopup(result['message'] ?? (result['success'] == true ? 'Successfully Added' : 'Registration Failed'), result['success'] == true);
  }

  Future<void> dropEnrollment(int enrollmentId) async {
    if (!_registrationOpen) return;

    final result = await ApiService.dropEnrollment(enrollmentId: enrollmentId);
    await load();
    showPopup(result['message'] ?? (result['success'] == true ? 'Successfully Dropped' : 'Drop Failed'), result['success'] == true);
  }

  void showPopup(String message, bool success) async {
    setState(() {
      _popupMessage = success ? 'Successfully\nUpdated' : message;
      _popupSuccess = success;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _popupMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final codeName = <String, String>{};
    for (final subject in _allSubjects) {
      codeName[subject.subjectCode] = subject.subjectName;
    }
    final courseCodes = codeName.keys.toList()..sort();
    final sections = _allSubjects
        .where((s) => s.subjectCode == _selectedCourseCode)
        .map((e) => e.section)
        .toSet()
        .toList()
      ..sort();
    final labs = _allSubjects
        .where((s) => s.subjectCode == _selectedCourseCode && s.section == _selectedSection)
        .map((e) => e.lab)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F3E8A),
        elevation: 2,
        title: const Text(
          'Subject Registration',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 32,
                width: 32,
                errorBuilder: (_, _, _) => const Icon(Icons.shield, color: Colors.white70, size: 28),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  buildDropdown('COURSE', _selectedCourseCode, courseCodes, (v) {
                    setState(() {
                      _selectedCourseCode = v;
                      _selectedSection = null;
                      _selectedLab = null;
                    });
                  }, enabled: _registrationOpen),
                  const SizedBox(height: 8),
                  buildDropdown('SECTION', _selectedSection, sections, (v) {
                    setState(() {
                      _selectedSection = v;
                      _selectedLab = null;
                    });
                  }, enabled: _registrationOpen),
                  const SizedBox(height: 8),
                  buildDropdown('LAB', _selectedLab, labs, (v) => setState(() => _selectedLab = v), enabled: _registrationOpen),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: (_registrationOpen && _selectedCourseCode != null && _selectedSection != null && _selectedLab != null) ? addEnrollment : null,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C4EA3)),
                    child: const Text('Add', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE0E0E0))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registered Subjects',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F3E8A)),
                        ),
                        const SizedBox(height: 10),
                        if (_enrollments.isEmpty)
                          const Text('No registered subjects yet', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                        ...List.generate(_enrollments.length, (i) {
                          final e = _enrollments[i];
                          final s = e.subject;
                          final code = s?.subjectCode ?? e.subjectCode;
                          final name = s?.subjectName ?? '-';
                          final sectionLab = '${s?.section ?? '-'}${s?.lab.isNotEmpty == true ? '/${s!.lab}' : ''}';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(name, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                                    ],
                                  ),
                                ),
                                Text(sectionLab, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _registrationOpen ? () => dropEnrollment(e.enrollmentId) : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _registrationOpen ? Colors.red : Colors.grey,
                                    minimumSize: const Size(50, 28),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Drop', style: TextStyle(fontSize: 10, color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_popupMessage != null)
            Center(
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _popupSuccess ? const Color(0xFF4CAF50) : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _popupSuccess ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _popupMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildDropdown<T>(String label, T? value, List<T> items, ValueChanged<T?> onChanged, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          hint: const Text('Select'),
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(
                    label == 'COURSE' ? '$e - ${_allSubjects.firstWhere((s) => s.subjectCode == e).subjectName}' : '$e',
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
