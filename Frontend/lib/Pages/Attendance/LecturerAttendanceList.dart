import 'dart:async';
import 'package:flutter/material.dart';
import '../../Config/api.dart';

class LecturerAttendanceList extends StatefulWidget {
  // This value is actually Subject_ID from Module 1.
  // The old route uses the name sessionId, so it is kept to avoid changing main.dart/routes.
  final int sessionId;
  const LecturerAttendanceList({super.key, required this.sessionId});

  @override
  State<LecturerAttendanceList> createState() => _LecturerAttendanceListState();
}

class _LecturerAttendanceListState extends State<LecturerAttendanceList> {
  static const Color _lecturerTeal = Color(0xFF2DB8C7);
  static const Color _cardBlue = Color(0xFF6FA8C7);
  static const Color _softGrey = Color(0xFFE0E0E0);
  static const Color _darkTeal = Color(0xFF0A6F7D);
  static const Color _inputBlue = Color(0xFF5D97B5);
  static const Color _yellow = Color(0xFFDDEB72);

  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isOpening = false;

  String _attendanceCode = '-';
  String _sessionStatus = 'Closed';
  int _timeLimit = 15;
  int? _sessionId;
  DateTime? _openedAt;
  Duration _remaining = Duration.zero;
  Timer? _timer;

  Map<String, dynamic>? _subjectInfo;

  int get _subjectId => widget.sessionId;

  bool get _hasActiveSession =>
      _sessionId != null &&
      _sessionStatus.toLowerCase() == 'open' &&
      _remaining.inSeconds > 0;

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _text(dynamic value, [String fallback = '-']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw) ?? DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  String _formatDuration(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (safe.inHours > 0) {
      final hours = safe.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }

  void _applySession(Map<String, dynamic>? session) {
    _timer?.cancel();
    _timer = null;

    if (session == null || session.isEmpty) {
      _sessionId = null;
      _attendanceCode = '-';
      _sessionStatus = 'Closed';
      _openedAt = null;
      _remaining = Duration.zero;
      return;
    }

    final status = _text(session['status'], 'closed');
    final openedAt = _parseDateTime(session['opened_at']);
    final limit = int.tryParse(_text(session['time_limit'], '15')) ?? 15;
    final id = session['id'];

    _sessionId = id is int ? id : int.tryParse(id.toString());
    _attendanceCode = _text(session['attendance_code']);
    _sessionStatus = status.toLowerCase() == 'open' ? 'Open' : 'Closed';
    _timeLimit = limit;
    _openedAt = openedAt;

    if (_sessionStatus == 'Open' && openedAt != null) {
      _remaining = openedAt.add(Duration(minutes: limit)).difference(DateTime.now());

      if (_remaining.inSeconds <= 0) {
        _sessionStatus = 'Closed';
        _remaining = Duration.zero;
        return;
      }

      _startTimer();
    } else {
      _remaining = Duration.zero;
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _openedAt == null) return;

      final updated = _openedAt!
          .add(Duration(minutes: _timeLimit))
          .difference(DateTime.now());

      if (updated.inSeconds <= 0) {
        setState(() {
          _remaining = Duration.zero;
          _sessionStatus = 'Closed';
        });
        _timer?.cancel();
      } else {
        setState(() => _remaining = updated);
      }
    });
  }

  Future<void> _loadPageData() async {
    setState(() => _isLoading = true);
    await fetchSubjectInfo(showLoading: false);
    await fetchCurrentSession(showLoading: false);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchSubjectInfo({bool showLoading = true}) async {
    try {
      final result = await ApiService.getSubject(_subjectId);

      if (result['success'] == true) {
        _subjectInfo = Map<String, dynamic>.from(result['data'] ?? {});
      } else if (mounted) {
        showMessage(result['message'] ?? 'Subject not found.', false);
      }
    } catch (e) {
      if (mounted) {
        showMessage('Connection error. Please try again.', false);
      }
    } finally {
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> fetchCurrentSession({bool showLoading = true}) async {
    try {
      final result = await ApiService.getAttendanceSessions();

      if (result['success'] == true) {
        final sessions = (result['data'] as List?) ?? [];
        Map<String, dynamic>? current;

        for (final item in sessions) {
          final s = Map<String, dynamic>.from(item as Map);

          if (_text(s['session_type']) == 'class' &&
              _text(s['subject_id']) == _subjectId.toString()) {
            final status = _text(s['status']).toLowerCase();

            if (status == 'open') {
              current = s;
              break;
            }

            current ??= s;
          }
        }

        if (mounted) {
          setState(() => _applySession(current));
        }
      }
    } catch (_) {
      // Keep page usable even if refresh fails.
    } finally {
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> generateCode() async {
    if (_hasActiveSession) {
      showMessage(
        'Attendance code is still active. Please wait until the timer expires before generating a new code.',
        false,
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final result = await ApiService.createAttendanceSession(
        subjectId: _subjectId,
        activityId: null,
        sessionType: 'class',
        timeLimit: _timeLimit,
      );

      if (result['success'] == true) {
        final data = Map<String, dynamic>.from(result['data'] ?? {});

        setState(() {
          _applySession(data);
          _isGenerating = false;
        });

        showMessage(
          'Attendance Session Opened\nThe attendance session has been opened',
          true,
        );
      } else {
        setState(() => _isGenerating = false);
        showMessage(result['message'] ?? 'Failed to generate code', false);
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      showMessage('Connection error. Please try again.', false);
    }
  }

  Future<void> openSession() async {
    if (_hasActiveSession) {
      showMessage(
        'Attendance Session Already Open\nStudents can check in using the current code until the timer expires.',
        true,
      );
      return;
    }

    setState(() => _isOpening = true);

    try {
      final result = await ApiService.createAttendanceSession(
        subjectId: _subjectId,
        activityId: null,
        sessionType: 'class',
        timeLimit: _timeLimit,
      );

      if (result['success'] == true) {
        final data = Map<String, dynamic>.from(result['data'] ?? {});

        setState(() {
          _applySession(data);
          _isOpening = false;
        });

        showMessage(
          'Attendance Session Opened\nThe attendance session has been opened',
          true,
        );
      } else {
        setState(() => _isOpening = false);
        showMessage(result['message'] ?? 'Failed to open session', false);
      }
    } catch (e) {
      setState(() => _isOpening = false);
      showMessage('Connection error. Please try again.', false);
    }
  }

  void openAttendanceListPage() {
    if (_sessionId == null) {
      showMessage('Please open a session first.', false);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LecturerAttendanceRecordsPage(
          sessionId: _sessionId!,
          subjectInfo: _subjectInfo ?? {},
          attendanceCode: _attendanceCode,
        ),
      ),
    );
  }

  void showMessage(String message, bool success) {
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
              size: 52,
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

  Widget _smallYellowButton(
    String text,
    VoidCallback onPressed, {
    bool loading = false,
    bool enabled = true,
  }) {
    return ElevatedButton(
      onPressed: (!enabled || loading) ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? _yellow : const Color(0xFFC8C8C8),
        foregroundColor: Colors.black,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionOpen = _hasActiveSession;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _lecturerTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        centerTitle: true,
        title: const Text(
          'Manage Attendance\nSession',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.school, color: Colors.white, size: 22),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _lecturerTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _softGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _cardBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Selected Class',
                            style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_text(_subjectInfo?['Subject_Code'], '')} ${_text(_subjectInfo?['Subject_Name'])}'.trim(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Section: ${_text(_subjectInfo?['Section'])}   Lab: ${_text(_subjectInfo?['Lab'])}',
                            style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${_text(_subjectInfo?['Day'])}   ${_text(_subjectInfo?['Time'])}',
                            style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Room: ${_text(_subjectInfo?['Venue'])}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Attendance Code',
                        style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w800),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _cardBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _inputBlue,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          _attendanceCode,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    _smallYellowButton(
                      'Generate code',
                      generateCode,
                      loading: _isGenerating,
                      enabled: !sessionOpen,
                    ),

                    if (sessionOpen) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Code locked until timer expires',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w700),
                      ),
                    ],

                    const SizedBox(height: 18),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Set Time Limit',
                        style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w800),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      height: 34,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBFBFBF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: sessionOpen
                                ? null
                                : () => setState(() => _timeLimit = _timeLimit > 5 ? _timeLimit - 5 : 5),
                            icon: const Icon(Icons.remove, color: Colors.black, size: 16),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                sessionOpen
                                    ? 'Expires in ${_formatDuration(_remaining)}'
                                    : '$_timeLimit:00 Minutes',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: sessionOpen
                                ? null
                                : () => setState(() => _timeLimit = _timeLimit < 120 ? _timeLimit + 5 : 120),
                            icon: const Icon(Icons.add, color: Colors.black, size: 16),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text.rich(
                      TextSpan(
                        text: 'Session Status: ',
                        style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w800),
                        children: [
                          TextSpan(
                            text: _sessionStatus,
                            style: TextStyle(
                              color: sessionOpen ? _darkTeal : Colors.red,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    _smallYellowButton(
                      sessionOpen ? 'Attendance Opened' : 'Open Attendance',
                      openSession,
                      loading: _isOpening,
                      enabled: !sessionOpen,
                    ),

                    const SizedBox(height: 10),

                    _smallYellowButton(
                      'View Attendance List',
                      openAttendanceListPage,
                      enabled: _sessionId != null,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class LecturerAttendanceRecordsPage extends StatefulWidget {
  final int sessionId;
  final Map<String, dynamic> subjectInfo;
  final String attendanceCode;

  const LecturerAttendanceRecordsPage({
    super.key,
    required this.sessionId,
    required this.subjectInfo,
    required this.attendanceCode,
  });

  @override
  State<LecturerAttendanceRecordsPage> createState() =>
      _LecturerAttendanceRecordsPageState();
}

class _LecturerAttendanceRecordsPageState extends State<LecturerAttendanceRecordsPage> {
  static const Color _lecturerTeal = Color(0xFF2DB8C7);
  static const Color _cardBlue = Color(0xFF6FA8C7);
  static const Color _softGrey = Color(0xFFE0E0E0);
  static const Color _presentGreen = Color(0xFFB9F5A8);

  bool _isLoading = true;
  List<dynamic> _attendanceList = [];

  @override
  void initState() {
    super.initState();
    fetchAttendanceList();
  }

  String _text(dynamic value, [String fallback = '-']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _subjectTitle() {
    final code = _text(widget.subjectInfo['Subject_Code'], '');
    final name = _text(widget.subjectInfo['Subject_Name'], '');

    if (code.isEmpty && name.isEmpty) return 'Class';
    return '$code $name'.trim();
  }

  Future<void> fetchAttendanceList() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getAttendanceRecords(widget.sessionId);

      if (result['success'] == true) {
        final data = result['data'];
        final records = data is Map ? (data['records'] ?? []) : (data ?? []);

        setState(() {
          _attendanceList = records is List ? records : [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        showMessage(result['message'] ?? 'Failed to load attendance list');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showMessage('Connection error. Please try again.');
    }
  }

  void showMessage(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: _lecturerTeal)),
          ),
        ],
      ),
    );
  }

  Widget _attendanceRecordCard(int index, dynamic record) {
    final student = record is Map ? record['student'] : null;
    final user = student is Map ? student['user'] : null;

    final name = user is Map
        ? _text(user['User_FullName'] ?? user['User_Name'] ?? user['name'], 'Student')
        : student is Map
            ? _text(student['Student_Name'], 'Student')
            : 'Student';

    final matric = student is Map
        ? _text(student['Student_ID'] ?? student['Matric_No'], '')
        : _text(record is Map ? record['student_id'] : '', '');

    final checkInTime = record is Map ? _text(record['check_in_time'], '-') : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _cardBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${index + 1}.',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              matric.isEmpty ? '$name\n$checkInTime' : '$name\n$matric\n$checkInTime',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _presentGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Present',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
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
        centerTitle: true,
        title: const Text(
          'Attendance List',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: fetchAttendanceList,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.school, color: Colors.white, size: 22),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _lecturerTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _softGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _cardBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Class: ${_subjectTitle()}\nCode: ${widget.attendanceCode}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_attendanceList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'No attendance records yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w700),
                        ),
                      )
                    else
                      ..._attendanceList.asMap().entries.map(
                            (entry) => _attendanceRecordCard(entry.key, entry.value),
                          ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Total Check In: ${_attendanceList.length} Student',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
