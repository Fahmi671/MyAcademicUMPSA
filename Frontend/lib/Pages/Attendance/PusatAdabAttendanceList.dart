import 'package:flutter/material.dart';
import '../../Config/api.dart';

class PusatAdabAttendanceList extends StatefulWidget {
  final String activityId;
  const PusatAdabAttendanceList({super.key, required this.activityId});

  @override
  State<PusatAdabAttendanceList> createState() => _PusatAdabAttendanceListState();
}

class _PusatAdabAttendanceListState extends State<PusatAdabAttendanceList> {
  static const Color _adabGreen = Color(0xFF4A9448);
  static const Color _cardGreen = Color(0xFF5CB85C);
  static const Color _softGrey = Color(0xFFE0E0E0);
  static const Color _darkGreen = Color(0xFF3F8F3F);
  static const Color _inputGreen = Color(0xFF73A95C);
  static const Color _yellow = Color(0xFFFFD966);

  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isOpening = false;
  bool _showAttendanceList = false;
  String _attendanceCode = '-';
  String _sessionStatus = 'Closed';
  int _timeLimit = 15;
  int? _sessionId;
  List<dynamic> _attendanceList = [];
  Map<String, dynamic>? _activityInfo;

  @override
  void initState() {
    super.initState();
    fetchActivityInfo();
  }

  String _text(dynamic value, [String fallback = '-']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  Future<void> fetchActivityInfo() async {
    try {
      final result = await ApiService.getActivityDetail(widget.activityId);
      if (result['success'] == true) {
        setState(() {
          _activityInfo = Map<String, dynamic>.from(result['data'] ?? {});
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        showMessage(result['message'] ?? 'Activity not found.', false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showMessage('Connection error. Please try again.', false);
    }
  }

  Future<void> generateCode() async {
    setState(() => _isGenerating = true);
    try {
      final result = await ApiService.createAttendanceSession(
        subjectId: null,
        activityId: widget.activityId,
        sessionType: 'activity',
        timeLimit: _timeLimit,
      );

      if (result['success'] == true) {
        final data = Map<String, dynamic>.from(result['data'] ?? {});
        setState(() {
          _attendanceCode = data['attendance_code']?.toString() ?? '-';
          _sessionId = data['id'] is int ? data['id'] : int.tryParse(data['id'].toString());
          _sessionStatus = data['status']?.toString() ?? 'open';
          _isGenerating = false;
        });
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
    if (_sessionId == null) {
      await generateCode();
      if (_sessionId == null) return;
    }

    setState(() => _isOpening = true);
    try {
      final result = await ApiService.createAttendanceSession(
        subjectId: null,
        activityId: widget.activityId,
        sessionType: 'activity',
        timeLimit: _timeLimit,
      );

      if (result['success'] == true) {
        final data = Map<String, dynamic>.from(result['data'] ?? {});
        setState(() {
          _sessionStatus = 'Open';
          _attendanceCode = data['attendance_code']?.toString() ?? _attendanceCode;
          _sessionId = data['id'] is int ? data['id'] : int.tryParse(data['id'].toString());
          _isOpening = false;
        });
        showMessage('Attendance Session Opened\nThe attendance session has been opened', true);
      } else {
        setState(() => _isOpening = false);
        showMessage(result['message'] ?? 'Failed to open session', false);
      }
    } catch (e) {
      setState(() => _isOpening = false);
      showMessage('Connection error. Please try again.', false);
    }
  }

  Future<void> fetchAttendanceList() async {
    if (_sessionId == null) {
      showMessage('Please open a session first.', false);
      return;
    }
    setState(() {
      _isLoading = true;
      _showAttendanceList = true;
    });
    try {
      final result = await ApiService.getAttendanceRecords(_sessionId!);
      if (result['success'] == true) {
        setState(() {
          _attendanceList = result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        showMessage(result['message'] ?? 'Failed to load attendance list', false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showMessage('Connection error. Please try again.', false);
    }
  }

  void showMessage(String message, bool success) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(success ? Icons.check_circle : Icons.cancel,
                color: success ? Colors.green : Colors.red, size: 52),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: _adabGreen)),
          ),
        ],
      ),
    );
  }

  Widget _smallYellowButton(String text, VoidCallback onPressed, {bool loading = false}) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _yellow,
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
          : Text(text, style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _adabGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Manage Attendance\nSession',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              child: const Icon(Icons.shield, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _adabGreen))
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
                        color: _cardGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Selected Activity', style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            '${_text(_activityInfo?['Module_Code'], '')} ${_text(_activityInfo?['Module_Name'])}'.trim(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(_text(_activityInfo?['Activity_Date'] ?? _activityInfo?['Date']), style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w700)),
                          Text(_text(_activityInfo?['Activity_Time'] ?? _activityInfo?['Time']), style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w700)),
                          Text('Venue: ${_text(_activityInfo?['Venue'])}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Attendance Code', style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _cardGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _inputGreen,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(_attendanceCode, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _smallYellowButton('Generate code', generateCode, loading: _isGenerating),
                    const SizedBox(height: 18),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Set Time Limit', style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w800)),
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
                            onPressed: () => setState(() => _timeLimit = (_timeLimit - 5).clamp(5, 120)),
                            icon: const Icon(Icons.remove, color: Colors.black, size: 16),
                          ),
                          Expanded(
                            child: Center(
                              child: Text('$_timeLimit:00 Minutes', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => setState(() => _timeLimit = (_timeLimit + 5).clamp(5, 120)),
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
                            style: TextStyle(color: _sessionStatus.toLowerCase() == 'open' ? _darkGreen : Colors.red, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _smallYellowButton('Open Attendance', openSession, loading: _isOpening),
                    const SizedBox(height: 10),
                    _smallYellowButton('View Attendance List', fetchAttendanceList),
                    if (_showAttendanceList) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Check In: ${_attendanceList.length} Student', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            if (_attendanceList.isEmpty)
                              const Text('No attendance records yet.', style: TextStyle(fontSize: 12, color: Colors.black54))
                            else
                              ..._attendanceList.map((record) {
                                final student = record['student'];
                                final user = student is Map ? student['user'] : null;
                                final name = user is Map
                                    ? _text(user['User_Name'] ?? user['name'], 'Student')
                                    : _text(student?['Student_Name'], 'Student');
                                final time = _text(record['check_in_time'], '-');
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: _adabGreen, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                                      Text(time, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
