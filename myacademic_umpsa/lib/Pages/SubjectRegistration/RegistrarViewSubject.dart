import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/Subject.dart';

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
  final Map<int, String> _lecturerNames = {};

  @override
  void initState() {
    super.initState();
    loadLecturers();
  }

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
          _lecturerNames
            ..clear()
            ..addAll(map);
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

    final sortedSubjects = [...widget.subjects]
      ..sort((a, b) {
        final sectionCompare = a.section.compareTo(b.section);
        if (sectionCompare != 0) return sectionCompare;
        return a.lab.compareTo(b.lab);
      });

    final base = sortedSubjects.first;
    final grouped = <int, List<Subject>>{};
    for (final s in sortedSubjects) {
      grouped.putIfAbsent(s.section, () => []).add(s);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5F5F),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'View Subject',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subject Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A5F5F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildRow('Subject Code', base.subjectCode),
                  buildRow('Subject Name', base.subjectName),
                  buildRow('Credit Hours', base.creditHours.toString()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...((grouped.keys.toList()..sort()).map((section) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section $section',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final s in grouped[section]!)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (s.lab.isNotEmpty) buildRow('Lab', s.lab),
                            buildRow(
                              'Lecturer',
                              '${s.lecturerId} - ${_lecturerNames[s.lecturerId] ?? 'Loading...'}',
                            ),
                            buildRow('Day', s.day),
                            buildRow('Time', s.time),
                            buildRow('Quota', s.quota.toString()),
                            buildRow('Room', s.venue),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            })),
          ],
        ),
      ),
    );
  }

  Widget buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '$label  :  $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}
