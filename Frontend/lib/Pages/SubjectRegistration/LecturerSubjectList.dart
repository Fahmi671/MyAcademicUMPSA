import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/Subject.dart';

// ============================================================
//  CONFIGURATION
// ============================================================

class AppColors {
  // App bar
  static const Color appBarBackground = Color(0xFF1AAFC0);
  static const Color appBarTitle = Colors.white;
  static const Color appBarIcon = Colors.white;

  // Page
  static const Color pageBackground = Color(0xFFF5F5F5);

  // Card
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color cardText = Color(0xFF1A1A1A);
  static const Color cardSubtext = Color(0xFF666666);

  // Button
  static const Color viewButton = Color(0xFF2196F3);
}

class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    color: AppColors.appBarTitle,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.cardText,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12,
    color: AppColors.cardSubtext,
  );

  static const TextStyle viewButtonText = TextStyle(
    color: AppColors.viewButton,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
}

// ============================================================
//  MAIN PAGE WIDGET
// ============================================================

class LecturerSubjectList extends StatefulWidget {
  const LecturerSubjectList({super.key});

  @override
  State<LecturerSubjectList> createState() => _LecturerSubjectListState();
}

class _LecturerSubjectListState extends State<LecturerSubjectList> {
  // STATE
  bool _loading = true;
  List<Subject> _subjects = [];

  // LIFECYCLE
  @override
  void initState() {
    super.initState();
    loadSubjects();
  }

  // DATA METHODS
  Future<void> loadSubjects() async {
    try {
      final result = await ApiService.getLecturerAssignedSubjects();
      setState(() {
        _subjects = (result['data'] as List? ?? [])
            .map((e) => Subject.fromJson(e))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // NAVIGATION
  void goToSubjectDetail(String subjectCode) {
    Navigator.pushNamed(
      context,
      '/lecturer-subject-detail',
      arguments: subjectCode,
    );
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: buildAppBar(),
      body: _loading ? buildLoadingState() : buildContentState(),
    );
  }

  // WIDGETS
  PreferredSizeWidget buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.appBarBackground,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.appBarIcon),
        onPressed: () => Navigator.pop(context),
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

  Widget buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget buildContentState() {
    final grouped = <String, List<Subject>>{};
    for (final s in _subjects) {
      grouped.putIfAbsent(s.subjectCode, () => []).add(s);
    }
    final keys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: keys.length,
      itemBuilder: (context, index) => buildSubjectCard(
        keys[index],
        grouped[keys[index]]!.first,
      ),
    );
  }

  Widget buildSubjectCard(String code, Subject subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.subjectCode,
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  subject.subjectName,
                  style: AppTextStyles.cardSubtitle,
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => goToSubjectDetail(subject.subjectCode),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.cardBorder),
              backgroundColor: AppColors.cardBackground,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text(
              'VIEW',
              style: AppTextStyles.viewButtonText,
            ),
          ),
        ],
      ),
    );
  }
}
