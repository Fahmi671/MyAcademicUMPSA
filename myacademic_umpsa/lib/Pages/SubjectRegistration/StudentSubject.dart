import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/Subject.dart';
import '../../Domain/SubjectEnrollment.dart';

// ============================================================
//  CONFIGURATION
// ============================================================

class AppColors {
  // App bar
  static const Color appBarBackground = Color(0xFF1F3E8A);
  static const Color appBarTitle = Colors.white;
  static const Color appBarIcon = Colors.white;

  // Page
  static const Color pageBackground = Color(0xFFF5F5F5);

  // Form
  static const Color formBackground = Colors.white;
  static const Color formBorder = Color(0xFFE0E0E0);
  static const Color formLabel = Color(0xFF1A1A1A);

  // Buttons
  static const Color addButton = Color(0xFF2C4EA3);
  static const Color addButtonText = Colors.white;
  static const Color dropButton = Colors.red;
  static const Color dropButtonText = Colors.white;
  static const Color dropButtonDisabled = Colors.grey;

  // Enrollment list
  static const Color enrollmentBackground = Color(0xFFF9F9F9);
  static const Color enrollmentBorder = Color(0xFFE0E0E0);
  static const Color enrollmentLabel = Color(0xFF1F3E8A);
  static const Color enrollmentText = Color(0xFF666666);

  // Success
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color successRed = Colors.red;
}

class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    color: AppColors.appBarTitle,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle formLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.formLabel,
  );

  static const TextStyle enrollmentLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.enrollmentLabel,
  );
}

// ============================================================
//  MAIN PAGE WIDGET
// ============================================================

class StudentSubject extends StatefulWidget {
  const StudentSubject({super.key});

  @override
  State<StudentSubject> createState() => _StudentSubjectState();
}

class _StudentSubjectState extends State<StudentSubject> {
  // STATE
  List<Subject> _allSubjects = [];
  List<SubjectEnrollment> _enrollments = [];
  bool _loading = true;
  String? _popupMessage;
  bool _popupSuccess = true;
  bool _registrationOpen = true;

  String? _selectedCourseCode;
  int? _selectedSection;
  String? _selectedLab;

  // LIFECYCLE
  @override
  void initState() {
    super.initState();
    loadData();
  }

  // DATA METHODS
  Future<void> loadData() async {
    setState(() => _loading = true);
    
    try {
      final subjectsResult = await ApiService.getStudentAvailableSubjects();
      final enrollmentResult = await ApiService.getStudentEnrollments();

      setState(() {
        _allSubjects = (subjectsResult['data'] as List? ?? [])
            .map((e) => Subject.fromJson(e))
            .toList();
        _enrollments = (enrollmentResult['data'] as List? ?? [])
            .map((e) => SubjectEnrollment.fromJson(e))
            .toList();
        _registrationOpen = subjectsResult['registration_open'] == true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showPopup('Error loading data', false);
    }
  }

  Future<void> addEnrollment() async {
    if (!_registrationOpen) return;

    final candidates = _allSubjects
        .where((s) =>
            s.subjectCode == _selectedCourseCode &&
            s.section == _selectedSection &&
            s.lab == _selectedLab)
        .toList();
    if (candidates.isEmpty) return;

    final result =
        await ApiService.addEnrollment(subjectId: candidates.first.subjectId);
    await loadData();
    if (mounted) {
      showPopup(
        result['message'] ??
            (result['success'] == true ? 'Successfully Added' : 'Registration Failed'),
        result['success'] == true,
      );
    }
  }

  Future<void> dropEnrollment(int enrollmentId) async {
    if (!_registrationOpen) return;

    final result =
        await ApiService.dropEnrollment(enrollmentId: enrollmentId);
    await loadData();
    if (mounted) {
      showPopup(
        result['message'] ??
            (result['success'] == true ? 'Successfully Dropped' : 'Drop Failed'),
        result['success'] == true,
      );
    }
  }

  void showPopup(String message, bool success) async {
    setState(() {
      _popupMessage = success ? 'Successfully\nUpdated' : message;
      _popupSuccess = success;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _popupMessage = null);
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: buildAppBar(),
      body: Stack(
        children: [
          if (_loading)
            buildLoadingState()
          else
            buildContentState(),
          if (_popupMessage != null) buildPopupOverlay(),
        ],
      ),
    );
  }

  // WIDGETS
  PreferredSizeWidget buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.appBarBackground,
      elevation: 2,
      title: const Text(
        'Subject Registration',
        style: AppTextStyles.appBarTitle,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.appBarIcon),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Image.asset(
              'assets/images/logo.png',
              height: 32,
              width: 32,
              errorBuilder: (_, _, _) => const Icon(
                Icons.shield,
                color: Colors.white70,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget buildContentState() {
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
        .where((s) =>
            s.subjectCode == _selectedCourseCode &&
            s.section == _selectedSection)
        .map((e) => e.lab)
        .toSet()
        .toList()
      ..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          buildDropdown(
            'COURSE',
            _selectedCourseCode,
            courseCodes,
            (v) {
              setState(() {
                _selectedCourseCode = v;
                _selectedSection = null;
                _selectedLab = null;
              });
            },
            enabled: _registrationOpen,
          ),
          const SizedBox(height: 8),
          buildDropdown(
            'SECTION',
            _selectedSection,
            sections,
            (v) {
              setState(() {
                _selectedSection = v;
                _selectedLab = null;
              });
            },
            enabled: _registrationOpen,
          ),
          const SizedBox(height: 8),
          buildDropdown(
            'LAB',
            _selectedLab,
            labs,
            (v) => setState(() => _selectedLab = v),
            enabled: _registrationOpen,
          ),
          const SizedBox(height: 8),
          buildAddButton(),
          const SizedBox(height: 8),
          buildEnrollmentList(),
        ],
      ),
    );
  }

  Widget buildAddButton() {
    return ElevatedButton(
      onPressed: (_registrationOpen &&
              _selectedCourseCode != null &&
              _selectedSection != null &&
              _selectedLab != null)
          ? addEnrollment
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.addButton,
      ),
      child: const Text(
        'Add',
        style: TextStyle(color: AppColors.addButtonText),
      ),
    );
  }

  Widget buildEnrollmentList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.formBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.formBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registered Subjects',
            style: AppTextStyles.enrollmentLabel,
          ),
          const SizedBox(height: 10),
          if (_enrollments.isEmpty)
            const Text(
              'No registered subjects yet',
              style: TextStyle(fontSize: 12, color: AppColors.enrollmentText),
            )
          else
            ...List.generate(
              _enrollments.length,
              (i) => buildEnrollmentItem(i),
            ),
        ],
      ),
    );
  }

  Widget buildEnrollmentItem(int index) {
    final e = _enrollments[index];
    final s = e.subject;
    final code = s?.subjectCode ?? e.subjectCode;
    final name = s?.subjectName ?? '-';
    final sectionLab =
        '${s?.section ?? '-'}${s?.lab.isNotEmpty == true ? '/${s!.lab}' : ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.enrollmentBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.enrollmentBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.enrollmentText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            sectionLab,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _registrationOpen ? () => dropEnrollment(e.enrollmentId) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _registrationOpen ? AppColors.dropButton : AppColors.dropButtonDisabled,
              minimumSize: const Size(50, 28),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'Drop',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.dropButtonText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDropdown<T>(
    String label,
    T? value,
    List<T> items,
    ValueChanged<T?> onChanged, {
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.formLabel),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          hint: const Text('Select'),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(
                      label == 'COURSE'
                          ? '$e - ${_allSubjects.firstWhere((s) => s.subjectCode == e).subjectName}'
                          : '$e',
                    ),
                  ))
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }

  Widget buildPopupOverlay() {
    return Center(
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
                color: _popupSuccess
                    ? AppColors.successGreen
                    : AppColors.successRed,
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
    );
  }
}
