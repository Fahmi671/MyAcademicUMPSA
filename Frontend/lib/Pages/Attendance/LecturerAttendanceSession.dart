import 'package:flutter/material.dart';
import '../../Config/api.dart';

class LecturerAttendanceSession extends StatefulWidget {
  const LecturerAttendanceSession({super.key});

  @override
  State<LecturerAttendanceSession> createState() => _LecturerAttendanceSessionState();
}

class _LecturerAttendanceSessionState extends State<LecturerAttendanceSession> {
  bool _isLoading = true;
  List<dynamic> _subjects = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    try {
      final result = await ApiService.getLecturerAssignedSubjects();
      if (result['success']) {
        setState(() {
          _subjects = result['data'] ?? [];
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
              : _subjects.isEmpty
                  ? const Center(child: Text('No subjects assigned.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Select Class Session\nOpen Attendance for an active class',
                            style: TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _subjects.length,
                            itemBuilder: (context, index) {
                              final subject = _subjects[index];
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
                                      subject['Subject_Code'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F3E8A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subject['Subject_Name'] ?? '-',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${subject['Day'] ?? '-'}   ${subject['Time'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                    Text(
                                      'Room: ${subject['Venue'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/lecturer-attendance-list',
                                            arguments: subject['Subject_ID'],
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1F3E8A),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Manage Session',
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