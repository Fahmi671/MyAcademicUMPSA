import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/Subject.dart';

class LecturerSubjectList extends StatefulWidget {
  const LecturerSubjectList({super.key});

  @override
  State<LecturerSubjectList> createState() => _LecturerSubjectListState();
}

class _LecturerSubjectListState extends State<LecturerSubjectList> {
  bool _loading = true;
  List<Subject> _subjects = [];

  @override
  void initState() {
    super.initState();
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    final result = await ApiService.getLecturerAssignedSubjects();
    setState(() {
      _subjects = (result['data'] as List? ?? []).map((e) => Subject.fromJson(e)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Subject>>{};
    for (final s in _subjects) {
      grouped.putIfAbsent(s.subjectCode, () => []).add(s);
    }
    final keys = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1AAFC0),
        elevation: 2,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Subject Management', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
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
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final code = keys[index];
                final list = grouped[code]!;
                final first = list.first;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE0E0E0))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(first.subjectCode, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(first.subjectName, style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, '/lecturer-subject-detail', arguments: first.subjectCode),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text('VIEW', style: TextStyle(color: Color(0xFF2196F3), fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
