import 'package:flutter/material.dart';
import '../../Config/api.dart';  // ← ADD THIS
import '../../Domain/Subject.dart'; 
//
// ============================================================
//  CONFIGURATION — change these to match your system
// ============================================================

/// App colour palette — edit here to retheme the whole page
class AppColors {
  // App bar
  static const Color appBarBackground = Color(0xFF1A5F5F); // teal
  static const Color appBarTitle      = Colors.white;
  static const Color appBarIcon       = Colors.white;

  // Page
  static const Color pageBackground   = Color(0xFFF5F5F5);

  // Action buttons (top row)
  static const Color scheduleButtonBg     = Color(0xFF2C3E50); // dark navy
  static const Color scheduleButtonText   = Colors.white;

  static const Color addButtonBg      = Color(0xFFB0BEC5); // light grey
  static const Color addButtonText    = Colors.white;

  // Subject card
  static const Color cardBackground   = Colors.white;
  static const Color cardBorder       = Color(0xFFE0E0E0);
  static const Color cardShadow       = Color(0x14000000);

  static const Color subjectCode      = Color(0xFF1A1A1A);
  static const Color subjectName      = Color(0xFF666666);

  // Card action buttons
  static const Color viewButtonText   = Color(0xFF2196F3); // blue
  static const Color editButtonText   = Color(0xFFFFA500); // orange
  static const Color deleteButtonText = Color(0xFFE53935); // red

  static const Color actionButtonBorder = Color(0xFFE0E0E0);
  
  // Success state
  static const Color successGreen     = Color(0xFF4CAF50);
}

/// Text styles — edit here to change typography
class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    color: AppColors.appBarTitle,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle subjectCode = TextStyle(
    color: AppColors.subjectCode,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle subjectName = TextStyle(
    color: AppColors.subjectName,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle actionButton = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle scheduleButton = TextStyle(
    color: AppColors.scheduleButtonText,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle addButton = TextStyle(
    color: AppColors.addButtonText,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
}

/// Route names — update to match your app_router.dart
class AppRoutes {
  static const String registrarAddSubject          = '/registrar-add-subject';
  static const String registrarEditSubject         = '/registrar-edit-subject';
  static const String registrarViewSubject         = '/registrar-view-subject';
  static const String registrarRegistrationSchedule= '/registrar-registration-schedule';
}

// ============================================================
//  DATA MODEL — mirrors Subject.dart domain class
// ============================================================



// ============================================================
//  MAIN PAGE WIDGET
// ============================================================

class RegistrarSubjectList extends StatefulWidget {
  const RegistrarSubjectList({super.key});

  @override
  State<RegistrarSubjectList> createState() => _RegistrarSubjectListState();
}

class _RegistrarSubjectListState extends State<RegistrarSubjectList> {
  // ----------------------------------------------------------
  //  STATE
  // ----------------------------------------------------------

  List<Subject> _subjects = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _deletingSubjectCode;
  String? _successMessage;

  // ----------------------------------------------------------
  //  LIFECYCLE
  // ----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  // ----------------------------------------------------------
  //  DATA METHODS — replace mock data with real API calls
  // ----------------------------------------------------------

  /// Calls GET /api/subjects via api.dart
    Future<void> fetchSubjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await ApiService.getSubjects();

      if (result['success']) {
        final subjectsData = result['data'] as List;
        setState(() {
          _subjects = subjectsData
              .map((e) => Subject.fromJson(e))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load subjects';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  // ✅ KEEP THIS ONE - Replace the old mock version
    Future<void> deleteSubjectGroup(List<Subject> subjects) async {
      if (subjects.isEmpty) return;
      try {
        final code = subjects.first.subjectCode;
        setState(() => _deletingSubjectCode = code);

        for (final subject in subjects) {
          final result = await ApiService.deleteSubject(subject.subjectId);
          if (result['success'] != true) {
            setState(() => _deletingSubjectCode = null);
            if (mounted) {
              showSnackBar(result['message'] ?? 'Failed to delete', isError: true);
            }
            return;
          }
        }

        setState(() {
          _subjects.removeWhere((s) => s.subjectCode == code);
          _deletingSubjectCode = null;
          _successMessage = 'Successfully Deleted';
        });

        await Future.delayed(const Duration(seconds: 3));
        if (mounted) setState(() => _successMessage = null);
      } catch (e) {
        setState(() => _deletingSubjectCode = null);
        if (mounted) {
          showSnackBar('Error: $e', isError: true);
        }
      }
    }

  // ----------------------------------------------------------
  //  NAVIGATION
  // ----------------------------------------------------------

  void goToRegistrationSchedule() {
    Navigator.pushNamed(context, AppRoutes.registrarRegistrationSchedule)
        .then((_) => fetchSubjects());
  }

  void goToAddSubject() {
    Navigator.pushNamed(context, AppRoutes.registrarAddSubject)
        .then((_) => fetchSubjects());
  }

  void goToEditSubject(List<Subject> subjects) {
    Navigator.pushNamed(
      context,
      AppRoutes.registrarEditSubject,
      arguments: subjects,
    ).then((_) => fetchSubjects());
  }

  void goToViewSubject(List<Subject> subjects) {
    Navigator.pushNamed(
      context,
      AppRoutes.registrarViewSubject,
      arguments: subjects,
    );
  }

  // ----------------------------------------------------------
  //  HELPER DIALOGS & SNACKBAR
  // ----------------------------------------------------------

  void showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.deleteButtonText : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  //  BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,

      // ══════════════════════════════════════════════════════
      //  APP BAR SECTION
      // ══════════════════════════════════════════════════════
      appBar: buildAppBar(),

      body: Stack(
        children: [
          Column(
            children: [
              // ══════════════════════════════════════════════════════
              //  ACTION BUTTONS SECTION
              // ══════════════════════════════════════════════════════
              buildActionButtonsSection(),

              // ══════════════════════════════════════════════════════
              //  MAIN CONTENT SECTION (Subject List)
              // ══════════════════════════════════════════════════════
              Expanded(child: buildMainContentSection()),
            ],
          ),
          
          // ══════════════════════════════════════════════════════
          //  SUCCESS OVERLAY
          // ══════════════════════════════════════════════════════
          if (_successMessage != null)
            buildSuccessOverlay(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  APP BAR — Logo & Title
  // ══════════════════════════════════════════════════════════════
  PreferredSizeWidget buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.appBarBackground,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.appBarIcon),
        onPressed: () => Navigator.pushNamed(context, '/registrar-homepage'),
      ),
      title: const Text(
        'Subject Management',
        style: AppTextStyles.appBarTitle,
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

  // ══════════════════════════════════════════════════════════════
  //  ACTION BUTTONS SECTION — Schedule & Add New
  // ══════════════════════════════════════════════════════════════
  Widget buildActionButtonsSection() {
    return Container(
      color: AppColors.pageBackground,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Registration Schedule button
          Expanded(
            child: ElevatedButton(
              onPressed: goToRegistrationSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.scheduleButtonBg,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Registration Schedule',
                style: AppTextStyles.scheduleButton,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Add New Subject button
          Expanded(
            child: ElevatedButton(
              onPressed: goToAddSubject,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.addButtonBg,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Add New Subject',
                style: AppTextStyles.addButton,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  MAIN CONTENT SECTION — Loading, Error, Empty, or List
  // ══════════════════════════════════════════════════════════════
  Widget buildMainContentSection() {
    // Loading state
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.appBarBackground,
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchSubjects,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.appBarBackground,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_subjects.isEmpty) {
      return const Center(
        child: Text(
          'No subjects found.\nTap "Add New Subject" to create one.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    final grouped = <String, List<Subject>>{};
    for (final subject in _subjects) {
      grouped.putIfAbsent(subject.subjectCode, () => []).add(subject);
    }
    final groupedSubjects = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Subject list
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: groupedSubjects.length,
      itemBuilder: (context, index) => buildSubjectCard(groupedSubjects[index].value),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SUBJECT CARD — Individual subject with action buttons
  // ══════════════════════════════════════════════════════════════
  Widget buildSubjectCard(List<Subject> subjects) {
    final subject = subjects.first;
    final isDeleting = _deletingSubjectCode == subject.subjectCode;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ──── Subject Code & Name ────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.subjectCode,
                    style: AppTextStyles.subjectCode,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${subject.subjectName} (${subjects.length} section/lab)',
                    style: AppTextStyles.subjectName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ──── Action Buttons Column ────
            if (isDeleting)
              const SizedBox(
                width: 100,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.successGreen,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: 170,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    buildActionButton(
                      label: 'VIEW',
                      textColor: AppColors.viewButtonText,
                      onTap: () => goToViewSubject(subjects),
                    ),
                    buildActionButton(
                      label: 'EDIT',
                      textColor: AppColors.editButtonText,
                      onTap: () => goToEditSubject(subjects),
                    ),
                    buildActionButton(
                      label: 'DELETE',
                      textColor: AppColors.deleteButtonText,
                      onTap: () => deleteSubjectGroup(subjects),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SUCCESS OVERLAY
  // ══════════════════════════════════════════════════════════════
  Widget buildSuccessOverlay() {
    return Center(
      child: Container(
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
            // ✓ Checkmark icon
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.successGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            // Success message
            const Text(
              'Successfully\nDeleted',
              textAlign: TextAlign.center,
              style: TextStyle(
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

  // ══════════════════════════════════════════════════════════════
  //  REUSABLE ACTION BUTTON
  // ══════════════════════════════════════════════════════════════
  Widget buildActionButton({
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 52),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.actionButtonBorder, width: 1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: AppTextStyles.actionButton.copyWith(color: textColor),
        ),
      ),
    );
  }
}
