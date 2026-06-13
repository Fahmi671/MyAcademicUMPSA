import 'package:flutter/material.dart';
import '../../Config/api.dart';

class PusatAdabAttendanceList extends StatefulWidget {
  final int sessionId;
  const PusatAdabAttendanceList({super.key, required this.sessionId});

  @override
  State<PusatAdabAttendanceList> createState() =>
      _PusatAdabAttendanceListState();
}

class _PusatAdabAttendanceListState extends State<PusatAdabAttendanceList> {
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isOpening = false;
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

  Future<void> fetchActivityInfo() async {
    try {
      final result = await ApiService.getActivityDetail(widget.sessionId);
      if (result['success']) {
        setState(() {
          _activityInfo = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> generateCode() async {
    setState(() => _isGenerating = true);
    try {
      final result = await ApiService.createAttendanceSession(
  subjectId: null,
  activityId: widget.sessionId,
  sessionType: 'activity',
  timeLimit: _timeLimit,
);

      if (result['success']) {
        setState(() {
          _attendanceCode = result['data']['attendance_code'] ?? '-';
          _sessionId = result['data']['id'];
          _sessionStatus = result['data']['status'] ?? 'closed';
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
      showMessage('Please generate a code first.', false);
      return;
    }
    setState(() => _isOpening = true);
    try {
      final result = await ApiService.createAttendanceSession(
  subjectId: null,
  activityId: widget.sessionId,
  sessionType: 'activity',
  timeLimit: _timeLimit,
);

      if (result['success']) {
        setState(() {
          _sessionStatus = 'open';
          _attendanceCode = result['data']['attendance_code'] ?? _attendanceCode;
          _sessionId = result['data']['id'];
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
    setState(() => _isLoading = true);
    try {
      final result =
         await ApiService.getAttendanceRecords(_sessionId!);
      if (result['success']) {
        setState(() {
          _attendanceList = result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
            child: const Text('OK', style: TextStyle(color: Color(0xFF1F3E8A))),
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
        backgroundColor: const Color(0xFF1F3E8A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Manage Attendance Session',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1F3E8A)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F3E8A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Activity',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _activityInfo?['Module_Name'] ?? '-',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${_activityInfo?['Date'] ?? '-'}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '${_activityInfo?['Time'] ?? '-'}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          'Venue: ${_activityInfo?['Venue'] ?? '-'}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attendance Code Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Attendance Code',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _attendanceCode,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F3E8A),
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isGenerating ? null : generateCode,
                            style: OutlinedButton.styleFrom(
                              side:
                                  const BorderSide(color: Color(0xFF1F3E8A)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isGenerating
                                ? const CircularProgressIndicator(
                                    color: Color(0xFF1F3E8A))
                                : const Text('Generate Code',
                                    style:
                                        TextStyle(color: Color(0xFF1F3E8A))),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Time Limit
                        const Text('Set Time Limit',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_timeLimit > 1)
                                  setState(() => _timeLimit--);
                              },
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Color(0xFF1F3E8A)),
                            ),
                            Text(
                              '$_timeLimit:00 Minutes',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _timeLimit++),
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Color(0xFF1F3E8A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Session Status
                        Row(
                          children: [
                            const Text('Session Status: ',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _sessionStatus == 'open'
                                    ? Colors.green
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _sessionStatus == 'open' ? 'Open' : 'Closed',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Open Attendance Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isOpening ? null : openSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isOpening
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Open Attendance',
                                    style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // View Attendance List
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: fetchAttendanceList,
                            style: OutlinedButton.styleFrom(
                              side:
                                  const BorderSide(color: Color(0xFF1F3E8A)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('View Attendance List',
                                style: TextStyle(color: Color(0xFF1F3E8A))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attendance List
                  if (_attendanceList.isNotEmpty) ...[
                    Text(
                      'Activity: ${_activityInfo?['Module_Name'] ?? '-'}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F3E8A)),
                    ),
                    Text(
                      'Code: $_attendanceCode',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _attendanceList.length,
                      itemBuilder: (context, index) {
                        final record = _attendanceList[index];
                        final student = record['student'];
                        final user = student?['user'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF1F3E8A),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?['User_FullName'] ?? '-',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      student?['Student_ID'] ?? '-',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54),
                                    ),
                                    Text(
                                      record['check_in_time'] ?? '-',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black45),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Present',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Text(
                      'Total Check In: ${_attendanceList.length} Student',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F3E8A)),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}