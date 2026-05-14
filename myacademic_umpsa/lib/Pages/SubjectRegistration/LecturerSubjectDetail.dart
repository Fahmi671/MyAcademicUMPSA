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

  // Info card
  static const Color infoCardBackground = Colors.white;
  static const Color infoCardBorder = Color(0xFFE0E0E0);
  static const Color infoCardText = Color(0xFF1A1A1A);

  // Table
  static const Color tableBackground = Colors.white;
  static const Color tableBorder = Color(0xFFE0E0E0);
  static const Color tableText = Color(0xFF1A1A1A);
}

class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    color: AppColors.appBarTitle,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle infoText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.tableText,
  );
}

// ============================================================
//  MAIN PAGE WIDGET
// ============================================================

class LecturerSubjectDetail extends StatefulWidget {
  final String subjectCode;

  const LecturerSubjectDetail({
    super.key,
    required this.subjectCode,
  });

  @override
  State<LecturerSubjectDetail> createState() => _LecturerSubjectDetailState();
}

class _LecturerSubjectDetailState extends State<LecturerSubjectDetail> {
  // STATE
  bool _loading = true;
  List<Subject> _subjects = [];
  List<Map<String, dynamic>> _students = [];

  // LIFECYCLE
  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  // DATA METHODS
  Future<void> loadDetail() async {
    try {
      final result =
          await ApiService.getLecturerSubjectDetail(widget.subjectCode);
      final data = (result['data'] as List? ?? []);
      final subjects = data.map((e) => Subject.fromJson(e)).toList();

      final studentRows = <Map<String, dynamic>>[];
      for (final row in data) {
        final section = row['Section']?.toString() ?? '';
        final lab = row['Lab']?.toString() ?? '';
        final sectionLab = '$section/$lab';
        final enrollments = row['enrollments'] as List? ?? [];
        for (final enrollment in enrollments) {
          final student = enrollment['student'];
          final user = student?['user'];
          studentRows.add({
            'name': user?['User_FullName'] ?? '-',
            'matric': student?['Student_ID'] ?? '-',
            'sectionLab': sectionLab,
          });
        }
      }

      // Sort students
      studentRows.sort((a, b) {
        final aKey = a['sectionLab'] as String;
        final bKey = b['sectionLab'] as String;
        final aParts = aKey.split('/');
        final bParts = bKey.split('/');
        final aSection = int.tryParse(aParts.first) ?? 0;
        final bSection = int.tryParse(bParts.first) ?? 0;
        if (aSection != bSection) return aSection.compareTo(bSection);
        final aLab = aParts.length > 1 ? aParts[1] : '';
        final bLab = bParts.length > 1 ? bParts[1] : '';
        final byLab = aLab.compareTo(bLab);
        if (byLab != 0) return byLab;
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      setState(() {
        _subjects = subjects;
        _students = studentRows;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
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
      title: Text(
        widget.subjectCode,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          buildSubjectInfoCard(),
          const SizedBox(height: 10),
          buildStudentTable(),
        ],
      ),
    );
  }

  Widget buildSubjectInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoCardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.infoCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _subjects
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${s.subjectName} (${s.creditHours} credit hours)\n'
                    'Section ${s.section}\n'
                    'Lab: ${s.lab}\n'
                    'Quota: ${s.quota}\n'
                    'Time: ${s.time}\n'
                    'Day: ${s.day}\n'
                    'Room: ${s.venue}',
                    style: AppTextStyles.infoText,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget buildStudentTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.tableBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.tableBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 12,
          columns: const [
            DataColumn(label: Text('No', style: TextStyle(fontSize: 10))),
            DataColumn(
              label: Text('Name', style: TextStyle(fontSize: 10)),
            ),
            DataColumn(
              label: Text('Matric', style: TextStyle(fontSize: 10)),
            ),
            DataColumn(
              label: Text('Section/Lab', style: TextStyle(fontSize: 10)),
            ),
          ],
          rows: List.generate(
            _students.length,
            (i) => buildStudentRow(i),
          ),
        ),
      ),
    );
  }

  DataRow buildStudentRow(int index) {
    final s = _students[index];
    return DataRow(
      cells: [
        DataCell(
          Text('${index + 1}', style: const TextStyle(fontSize: 10)),
        ),
        DataCell(
          Text('${s['name']}', style: const TextStyle(fontSize: 10)),
        ),
        DataCell(
          Text('${s['matric']}', style: const TextStyle(fontSize: 10)),
        ),
        DataCell(
          Text('${s['sectionLab']}', style: const TextStyle(fontSize: 10)),
        ),
      ],
    );
  }
}
