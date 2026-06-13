import 'package:flutter/material.dart';
import '../../Config/api.dart';

class StudentAttendanceList extends StatefulWidget {
  final bool isActivity;
  const StudentAttendanceList({super.key, this.isActivity = false});

  @override
  State<StudentAttendanceList> createState() => _StudentAttendanceListState();
}

class _StudentAttendanceListState extends State<StudentAttendanceList> {
  static const Color _headerBlue = Color(0xFF1F3E8A);
  static const Color _screenGrey = Color(0xFFF5F5F5);
  static const Color _panelGrey = Color(0xFFBDBDBD);
  static const Color _instructionGrey = Color(0xFFE0E0E0);
  static const Color _inactiveGrey = Color(0xFFBDBDBD);
  static const Color _activeGreen = Color(0xFFD0E3A0);
  static const Color _checkInBlue = Color(0xFF67C8D4);
  static const Color _disabledGrey = Color(0xFF8E8E8E);

  bool _isLoading = true;
  List<dynamic> _enrollments = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = widget.isActivity
          ? await ApiService.getStudentRegisteredActivities()
          : await ApiService.getStudentClasses();

      if (result['success'] == true) {
        final rawData = (result['data'] ?? []) as List<dynamic>;
        final cleanedData = widget.isActivity
            ? rawData
            : _removeDuplicateClassCards(rawData);

        setState(() {
          _enrollments = cleanedData;
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

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String _text(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final s = value.toString();
    return s.trim().isEmpty ? fallback : s;
  }

  bool _isActive(dynamic item) {
    return item['is_session_open'] == true ||
        item['has_active_session'] == true ||
        item['session_status']?.toString().toLowerCase() == 'open' ||
        item['active_session'] != null;
  }

  List<dynamic> _removeDuplicateClassCards(List<dynamic> items) {
    final Map<String, dynamic> uniqueMap = {};

    for (final item in items) {
      if (item is! Map) continue;

      final subject = item['subject'];
      final subjectCode = _text(
        subject?['Subject_Code'] ?? item['Subject_Code'],
        '',
      );
      final subjectName = _text(subject?['Subject_Name'], '');

      // Use subject code + name as the display key.
      // This prevents the same subject from appearing twice when test data has
      // multiple sections with the same code/name. If one of them has an active
      // attendance session, keep the active one.
      final key = '${subjectCode.toLowerCase()}|${subjectName.toLowerCase()}';

      if (key.trim() == '|') continue;

      if (!uniqueMap.containsKey(key)) {
        uniqueMap[key] = item;
      } else {
        final currentItem = uniqueMap[key];
        final newIsActive = _isActive(item);
        final currentIsActive = _isActive(currentItem);

        // Prefer the active class card. If both are inactive, keep the first one.
        if (newIsActive && !currentIsActive) {
          uniqueMap[key] = item;
        }
      }
    }

    return uniqueMap.values.toList();
  }

  void _openCheckIn(Map<String, dynamic> data) {
    Navigator.pushNamed(
      context,
      '/student-checkin',
      arguments: data,
    ).then((_) => fetchData());
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isActivity
        ? 'Activity Attendance'
        : 'Class Attendance';
    final emptyText = widget.isActivity
        ? 'No registered activities found.'
        : 'No registered classes found.';
    final instructionText = widget.isActivity
        ? 'select your registered activity\nCheck in for your current active activity session'
        : 'select your registered class\nCheck in for your current active class session';

    return Scaffold(
      backgroundColor: _screenGrey,
      appBar: AppBar(
        backgroundColor: _headerBlue,
        elevation: 0,
        toolbarHeight: 58,
        leadingWidth: 78,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 20),
                Positioned(
                  right: -1,
                  top: -2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: _AttendanceLogo(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _headerBlue))
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _enrollments.isEmpty
          ? Center(
              child: Text(
                emptyText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : RefreshIndicator(
              color: _headerBlue,
              onRefresh: fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _panelGrey,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: const Color(0xFF8E8E8E),
                      width: 3,
                    ),
                  ),
                  child: Column(
                    children: [
                      _InstructionCard(text: instructionText),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 9),
                        itemCount: _enrollments.length,
                        itemBuilder: (context, index) {
                          final item = _enrollments[index];
                          final subject = item['subject'];
                          final activity = item['activity'] ?? item;
                          final activeSession = item['active_session'];
                          final isActive = _isActive(item);

                          final code = widget.isActivity
                              ? _text(activity['Module_Code'], '')
                              : _text(subject?['Subject_Code'], '');
                          final name = widget.isActivity
                              ? _text(activity['Module_Name'])
                              : _text(subject?['Subject_Name']);

                          final section = widget.isActivity
                              ? ''
                              : _text(subject?['Section']);
                          final lab = widget.isActivity
                              ? ''
                              : _text(subject?['Lab']);

                          final line1 = widget.isActivity
                              ? 'Date: ${_text(activity['Activity_Date'])}'
                              : 'Lecturer: ${_text(subject?['Lecturer'])}';
                          final line2 = widget.isActivity
                              ? 'Time: ${_text(activity['Activity_Time'])}'
                              : '${_text(subject?['Day'])}, ${_text(subject?['Time'])}';
                          final line3 = widget.isActivity
                              ? 'Venue: ${_text(activity['Venue'])}'
                              : 'Room: ${_text(subject?['Venue'])}';

                          final subjectId = widget.isActivity
                              ? null
                              : _toInt(
                                  activeSession?['subject_id'] ??
                                      subject?['Subject_ID'],
                                );
                          final activityId = widget.isActivity
                              ? (activeSession?['activity_id'] ??
                                    activity['Activity_ID'] ??
                                    activity['id'])
                              : null;

                          return _AttendanceCard(
                            code: code,
                            name: name,
                            section: section,
                            lab: lab,
                            line1: line1,
                            line2: line2,
                            line3: line3,
                            isActivity: widget.isActivity,
                            isActive: isActive,
                            onCheckIn: isActive
                                ? () {
                                    _openCheckIn(
                                      widget.isActivity
                                          ? {
                                              'activity_id': activityId,
                                              'subject_id': null,
                                              'session_id':
                                                  activeSession?['id'],
                                              'subject_code': code,
                                              'subject_name': name,
                                              'lecturer': '-',
                                              'day': _text(
                                                activity['Activity_Date'],
                                              ),
                                              'time': _text(
                                                activity['Activity_Time'],
                                              ),
                                              'room': _text(activity['Venue']),
                                            }
                                          : {
                                              'subject_id': subjectId,
                                              'activity_id': null,
                                              'session_id':
                                                  activeSession?['id'],
                                              'subject_code': code,
                                              'subject_name': name,
                                              'lecturer': _text(
                                                subject?['Lecturer'],
                                              ),
                                              'day': _text(subject?['Day']),
                                              'time': _text(subject?['Time']),
                                              'room': _text(subject?['Venue']),
                                              'section': section,
                                              'lab': lab,
                                            },
                                    );
                                  }
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _AttendanceLogo extends StatelessWidget {
  const _AttendanceLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.shield, color: Colors.white, size: 25),
        SizedBox(height: 1),
        Text(
          'MyAcademic',
          style: TextStyle(
            color: Color(0xFF34D6D6),
            fontSize: 5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final String text;
  const _InstructionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 9),
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 13),
      decoration: BoxDecoration(
        color: _StudentAttendanceListState._instructionGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8E8E8E), width: 2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.35,
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final String code;
  final String name;
  final String section;
  final String lab;
  final String line1;
  final String line2;
  final String line3;
  final bool isActivity;
  final bool isActive;
  final VoidCallback? onCheckIn;

  const _AttendanceCard({
    required this.code,
    required this.name,
    required this.section,
    required this.lab,
    required this.line1,
    required this.line2,
    required this.line3,
    required this.isActivity,
    required this.isActive,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
      decoration: BoxDecoration(
        color: isActive
            ? _StudentAttendanceListState._activeGreen
            : const Color(0xFFCFCFCF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? _StudentAttendanceListState._activeGreen
              : const Color(0xFF9E9E9E),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (code.isNotEmpty)
                      Text(
                        code,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? _StudentAttendanceListState._checkInBlue
                      : const Color(0xFF9E9E9E),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (!isActivity) ...[
            const SizedBox(height: 5),
            Text(
              'Section: $section   Lab: $lab',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.25,
              ),
            ),
          ],
          if (isActivity) const SizedBox(height: 5),
          Text(
            line1,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1.25,
            ),
          ),
          Text(
            line2,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1.25,
            ),
          ),
          Text(
            line3,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onCheckIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive
                    ? _StudentAttendanceListState._checkInBlue
                    : _StudentAttendanceListState._disabledGrey,
                foregroundColor: Colors.black,
                elevation: isActive ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Check In',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
