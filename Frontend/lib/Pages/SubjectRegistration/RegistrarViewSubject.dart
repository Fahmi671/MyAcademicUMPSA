import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/Subject.dart';

// Color palette
class AppColors {
  static const Color appBarBg = Color(0xFF1A5F5F);
  static const Color appBarText = Colors.white;
  static const Color pageBg = Color(0xFFF5F5F5);
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color labelText = Color(0xFF1A1A1A);
  static const Color sectionBg = Color(0xFFF9F9F9);
}

// Text styles
class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    color: AppColors.appBarText,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1565C0),
  );
  
  static const TextStyle infoLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.labelText,
  );
}

class RegistrarViewSubject extends StatefulWidget {
  final List<Subject> subjects;

  const RegistrarViewSubject({
    super.key,
    required this.subjects,
  });

  @override
  State<RegistrarViewSubject> createState() => _RegistrarViewSubjectState();
}

class _RegistrarViewSubjectState extends State<RegistrarViewSubject> {
  // Lecturer names cache
  final Map<int, String> _lecturerNames = {};

  @override
  void initState() {
    super.initState();
    loadLecturers();
  }

  // Load lecturer names
  Future<void> loadLecturers() async {
    final result = await ApiService.getLecturers();
    if (result['success'] == true) {
      final rows = result['data'] as List;
      final map = <int, String>{};
      for (final row in rows) {
        final id = int.tryParse(row['Lecturer_ID'].toString());
        if (id != null) {
          map[id] = row['User_FullName']?.toString() ?? 'Unknown';
        }
      }
      if (mounted) {
        setState(() {
          _lecturerNames.clear();
          _lecturerNames.addAll(map);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No subject data found')),
      );
    }

    // Sort subjects
    final sortedSubjects = [...widget.subjects]
      ..sort((a, b) {
        final sectionCompare = a.section.compareTo(b.section);
        if (sectionCompare != 0) return sectionCompare;
        return a.lab.compareTo(b.lab);
      });

    final base = sortedSubjects.first;
    
    // Group by section
    final grouped = <int, List<Subject>>{};
    for (final s in sortedSubjects) {
      grouped.putIfAbsent(s.section, () => []).add(s);
    }

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            buildSubjectInfoCard(base),
            const SizedBox(height: 12),
            ...buildSectionCards(grouped),
          ],
        ),
      ),
    );
  }

  // App bar
  PreferredSizeWidget buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.appBarBg,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.appBarText),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('View Subject', style: AppTextStyles.appBarTitle),
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
    );
  }

  // Subject information card
  Widget buildSubjectInfoCard(Subject base) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subject Information',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.appBarBg)),
          const SizedBox(height: 8),
          buildInfoRow('Subject Code', base.subjectCode),
          buildInfoRow('Subject Name', base.subjectName),
          buildInfoRow('Credit Hours', base.creditHours.toString()),
        ],
      ),
    );
  }

  // Section cards
  List<Widget> buildSectionCards(Map<int, List<Subject>> grouped) {
    final sortedSections = grouped.keys.toList()..sort();
    return sortedSections.map((section) => buildSectionCard(section, grouped[section]!)).toList();
  }

  // Section card
  Widget buildSectionCard(int section, List<Subject> subjects) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Section $section', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          ...subjects.map((s) => buildLabCard(s)),
        ],
      ),
    );
  }

  // Lab card
  Widget buildLabCard(Subject subject) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sectionBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subject.lab.isNotEmpty) buildInfoRow('Lab', subject.lab),
          buildInfoRow(
            'Lecturer',
            '${subject.lecturerId} - ${_lecturerNames[subject.lecturerId] ?? 'Loading...'}',
          ),
          buildInfoRow('Day', subject.day),
          buildInfoRow('Time', subject.time),
          buildInfoRow('Quota', subject.quota.toString()),
          buildInfoRow('Room', subject.venue),
        ],
      ),
    );
  }

  // Info row
  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '$label  :  $value',
        style: AppTextStyles.infoLabel,
      ),
    );
  }
}
