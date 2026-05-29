import 'package:flutter/material.dart';
import '../../Config/api.dart';

class StudentAttendanceList extends StatefulWidget {
  final bool isActivity;
  const StudentAttendanceList({super.key, this.isActivity = false});

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
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final result = widget.isActivity
          ? await ApiService.getStudentRegisteredActivities()
          : await ApiService.getStudentClasses();

      if (result['success']) {
        setState(() {
          _enrollments = result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load data';
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
    final title = widget.isActivity ? 'Activity Attendance' : 'Class Attendance';
    final emptyText = widget.isActivity
        ? 'No registered activities found.'
        : 'No registered classes found.';
    final infoText = widget.isActivity
        ? 'select your registered activity\nCheck in for your current active activity session'
        : 'select your registered class\nCheck in for your current active class session';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F3E8A),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1F3E8A)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                  ),
                )
              : _enrollments.isEmpty
                  ? Center(child: Text(emptyText))
                  : Column(
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            infoText,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.5),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(12, 6, 12, 16),
                            itemCount: _enrollments.length,
                            itemBuilder: (context, index) {
                              final item = _enrollments[index];

                              // Class mode fields
                              final subject = item['subject'];
                              // Activity mode fields
                              final activity = item['activity'] ?? item;

                              final code = widget.isActivity
                                  ? (activity['Module_Code']?.toString() ?? '')
                                  : (subject?['Subject_Code']?.toString() ?? '');

                              final name = widget.isActivity
                                  ? (activity['Module_Name']?.toString() ?? '-')
                                  : (subject?['Subject_Name']?.toString() ?? '-');

                              final line1 = widget.isActivity
                                  ? 'Date: ${activity['Activity_Date'] ?? '-'}'
                                  : 'Lecturer: ${subject?['Lecturer'] ?? '-'}';

                              final line2 = widget.isActivity
                                  ? 'Time: ${activity['Activity_Time'] ?? '-'}'
                                  : '${subject?['Day'] ?? '-'}, ${subject?['Time'] ?? '-'}';

                              final line3 = widget.isActivity
                                  ? 'Venue: ${activity['Venue'] ?? '-'}'
                                  : 'Room: ${subject?['Venue'] ?? '-'}';

                              final isActive =
                                  item['is_session_open'] == true ||
                                  item['has_active_session'] == true ||
                                  item['session_status'] == 'open';

                              final cardColor = isActive
                                  ? const Color(0xFFC8E6C9)
                                  : const Color(0xFFE0E0E0);
                              final buttonColor = isActive
                                  ? const Color(0xFF00ACC1)
                                  : const Color(0xFF757575);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.fromLTRB(
                                    14, 14, 14, 12),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (code.isNotEmpty)
                                      Text(
                                        code,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: code.isNotEmpty ? 13 : 14,
                                        fontWeight: code.isNotEmpty
                                            ? FontWeight.w500
                                            : FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(line1,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87)),
                                    Text(line2,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87)),
                                    Text(line3,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87)),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/student-checkin',
                                            arguments: widget.isActivity
                                                ? {
                                                    'activity_id': activity['Activity_ID'] ?? activity['id'],
                                                    'subject_id': null,
                                                    'subject_code': code,
                                                    'subject_name': name,
                                                    'lecturer': '-',
                                                    'day': activity['Activity_Date'] ?? '-',
                                                    'time': activity['Activity_Time'] ?? '-',
                                                    'room': activity['Venue'] ?? '-',
                                                  }
                                                : {
                                                    'subject_id': subject?['Subject_ID'],
                                                    'activity_id': null,
                                                    'subject_code': code,
                                                    'subject_name': name,
                                                    'lecturer': subject?['Lecturer'] ?? '-',
                                                    'day': subject?['Day'] ?? '-',
                                                    'time': subject?['Time'] ?? '-',
                                                    'room': subject?['Venue'] ?? '-',
                                                  },
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: buttonColor,
                                          elevation: 2,
                                          shape: const StadiumBorder(),
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Check In',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
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
