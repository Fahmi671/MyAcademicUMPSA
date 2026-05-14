import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/Subject.dart';

class LecturerSubjectDetail extends StatefulWidget {
  final String subjectCode;
  const LecturerSubjectDetail({super.key, required this.subjectCode});

  @override
  State<LecturerSubjectDetail> createState() => _LecturerSubjectDetailState();
}

class _LecturerSubjectDetailState extends State<LecturerSubjectDetail> {
  bool _loading = true;
  List<Subject> _subjects = [];
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    final result = await ApiService.getLecturerSubjectDetail(widget.subjectCode);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1AAFC0),
        elevation: 2,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(widget.subjectCode, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE0E0E0))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _subjects
                          .map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '${s.subjectName} (${s.creditHours} credit hours)\nSection ${s.section}\nLab : ${s.lab}\nQuota : ${s.quota}\nTime : ${s.time}\nDay : ${s.day}\nRoom : ${s.venue}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE0E0E0))),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 12,
                        columns: const [
                          DataColumn(label: Text('No', style: TextStyle(fontSize: 10))),
                          DataColumn(label: Text('Name', style: TextStyle(fontSize: 10))),
                          DataColumn(label: Text('Matric', style: TextStyle(fontSize: 10))),
                          DataColumn(label: Text('Section/Lab', style: TextStyle(fontSize: 10))),
                        ],
                        rows: List.generate(_students.length, (i) {
                          final s = _students[i];
                          return DataRow(cells: [
                            DataCell(Text('${i + 1}', style: const TextStyle(fontSize: 10))),
                            DataCell(Text('${s['name']}', style: const TextStyle(fontSize: 10))),
                            DataCell(Text('${s['matric']}', style: const TextStyle(fontSize: 10))),
                            DataCell(Text('${s['sectionLab']}', style: const TextStyle(fontSize: 10))),
                          ]);
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
