import 'package:flutter/material.dart';
import '../../Config/api.dart';

class LecturerAttendanceSession extends StatefulWidget {
  const LecturerAttendanceSession({super.key});

  @override
  State<LecturerAttendanceSession> createState() =>
      _LecturerAttendanceSessionState();
}

class _LecturerAttendanceSessionState extends State<LecturerAttendanceSession> {
  static const Color _lecturerTeal = Color(0xFF2DB8C7);
  static const Color _cardBlue = Color(0xFF6FA8C7);
  static const Color _activeBlue = Color(0xFFD7F1F7);
  static const Color _softGrey = Color(0xFFE0E0E0);
  static const Color _headerBlue = Color(0xFF79B7CE);

  bool _isLoading = true;
  List<dynamic> _subjects = [];
  Map<String, Map<String, dynamic>> _sessionBySubjectId = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  String _text(dynamic value, [String fallback = '-']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw) ??
        DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  bool _isSessionActive(Map<String, dynamic>? session) {
    if (session == null) return false;
    if (_text(session['status']).toLowerCase() != 'open') return false;

    final openedAt = _parseDateTime(session['opened_at']);
    final limit = int.tryParse(_text(session['time_limit'], '15')) ?? 15;

    if (openedAt == null) return true;
    return openedAt.add(Duration(minutes: limit)).isAfter(DateTime.now());
  }

  String _activeLabel(Map<String, dynamic>? session) {
    if (!_isSessionActive(session)) return 'Inactive';
    final code = _text(session?['attendance_code'], '');
    return code.isEmpty ? 'Active' : 'Active • Code: $code';
  }

  int? _getSubjectId(Map<String, dynamic> subject) {
    final rawId =
        subject['Subject_ID'] ?? subject['subject_id'] ?? subject['id'];
    if (rawId == null) return null;
    if (rawId is int) return rawId;
    return int.tryParse(rawId.toString());
  }

  Future<void> fetchSubjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final subjectResult = await ApiService.getLecturerAssignedSubjects();
      final sessionResult = await ApiService.getAttendanceSessions();

      final Map<String, Map<String, dynamic>> sessionMap = {};

      if (sessionResult['success'] == true) {
        final sessions = (sessionResult['data'] as List?) ?? [];

        for (final item in sessions) {
          final session = Map<String, dynamic>.from(item as Map);
          if (_text(session['session_type']) != 'class') continue;

          final subjectId = _text(session['subject_id'], '');
          if (subjectId.isEmpty) continue;

          final existing = sessionMap[subjectId];
          final isOpen = _isSessionActive(session);
          final existingOpen = existing == null
              ? false
              : _isSessionActive(existing);

          if (existing == null || (isOpen && !existingOpen)) {
            sessionMap[subjectId] = session;
          }
        }
      }

      if (subjectResult['success'] == true) {
        setState(() {
          _subjects = subjectResult['data'] ?? [];
          _sessionBySubjectId = sessionMap;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = subjectResult['message'] ?? 'Failed to load subjects';
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

  Future<void> _openManageSession(Map<String, dynamic> subject) async {
    final subjectId = _getSubjectId(subject);

    if (subjectId == null) {
      _showMessage('Subject ID not found.', false);
      return;
    }

    await Navigator.pushNamed(
      context,
      '/lecturer-attendance-list',
      arguments: subjectId,
    );

    if (mounted) {
      fetchSubjects();
    }
  }

  void _showMessage(String message, bool success) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.cancel,
              color: success ? Colors.green : Colors.red,
              size: 50,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: _lecturerTeal)),
          ),
        ],
      ),
    );
  }

  Widget _subjectCard(Map<String, dynamic> subject) {
    final subjectId = _getSubjectId(subject);
    final session = subjectId == null
        ? null
        : _sessionBySubjectId[subjectId.toString()];
    final active = _isSessionActive(session);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? _activeBlue : _cardBlue,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? _lecturerTeal : Colors.transparent,
          width: active ? 2 : 0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${_text(subject['Subject_Code'], '')} ${_text(subject['Subject_Name'])}'
                      .trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? _lecturerTeal : Colors.grey.shade500,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _activeLabel(session),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Section: ${_text(subject['Section'])}   Lab: ${_text(subject['Lab'])}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${_text(subject['Day'])}   ${_text(subject['Time'])}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Room: ${_text(subject['Venue'])}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _openManageSession(subject),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD8E86A), // yellow-green SRS button
                foregroundColor: Colors.black,
                elevation: 3,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Manage Session',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _lecturerTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Class Attendance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: fetchSubjects,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.school, color: Colors.white, size: 22),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _lecturerTeal))
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          : _subjects.isEmpty
          ? const Center(child: Text('No subjects assigned.'))
          : Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _softGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _headerBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Select Class Session\nOpen Attendance for an active class session',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                        itemCount: _subjects.length,
                        itemBuilder: (context, index) {
                          final subject = Map<String, dynamic>.from(
                            _subjects[index],
                          );
                          return _subjectCard(subject);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
