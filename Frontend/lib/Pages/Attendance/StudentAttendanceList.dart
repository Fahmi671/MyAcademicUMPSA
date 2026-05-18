import 'package:flutter/material.dart';
import '../../Config/api.dart';

class StudentAttendanceList extends StatefulWidget {
  const StudentAttendanceList({super.key});

  @override
  State<StudentAttendanceList> createState() => _StudentAttendanceListState();
}

class _StudentAttendanceListState extends State<StudentAttendanceList> {
  bool _isLoading = true;
  List<dynamic> _enrollments = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchEnrollments();
  }

  Future<void> fetchEnrollments() async {
    try {
      final result = await ApiService.getStudentClasses();
      if (result['success']) {
        setState(() {
          _enrollments = result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load classes';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F3E8A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Class Attendance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F3E8A)))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : _enrollments.isEmpty
                  ? const Center(child: Text('No registered classes found.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Select your registered class\nCheck in for your current active class session',
                            style: TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _enrollments.length,
                            itemBuilder: (context, index) {
                              final enrollment = _enrollments[index];
                              final subject = enrollment['subject'];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE0E0E0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject?['Subject_Code'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F3E8A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subject?['Subject_Name'] ?? '-',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Day: ${subject?['Day'] ?? '-'}   Time: ${subject?['Time'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                    Text(
                                      'Room: ${subject?['Venue'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/student-checkin',
                                            arguments: {
                                              'subject_id': subject?['Subject_ID'],
                                              'subject_code': subject?['Subject_Code'],
                                              'subject_name': subject?['Subject_Name'],
                                            },
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1F3E8A),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Check In',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}