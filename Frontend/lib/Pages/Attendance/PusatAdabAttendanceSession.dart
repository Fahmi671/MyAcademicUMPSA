import 'package:flutter/material.dart';
import '../../Config/api.dart';

class PusatAdabAttendanceSession extends StatefulWidget {
  const PusatAdabAttendanceSession({super.key});

  @override
  State<PusatAdabAttendanceSession> createState() =>
      _PusatAdabAttendanceSessionState();
}

class _PusatAdabAttendanceSessionState extends State<PusatAdabAttendanceSession> {
  static const Color _adabGreen = Color(0xFF4A9448);
  static const Color _cardGreen = Color(0xFF5CB85C);
  static const Color _activeGreen = Color(0xFFC8EFD0);
  static const Color _inactiveGrey = Color(0xFFE0E0E0);
  static const Color _headerGreen = Color(0xFF8BCF86);
  static const Color _yellow = Color(0xFFFFD966);

  bool _isLoading = true;
  List<dynamic> _activities = [];
  Map<String, Map<String, dynamic>> _sessionByActivityId = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchActivities();
  }

  Future<void> fetchActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final activityResult = await ApiService.getActivities();
      final sessionResult = await ApiService.getAttendanceSessions();

      final Map<String, Map<String, dynamic>> sessionMap = {};
      if (sessionResult['success'] == true) {
        final sessions = (sessionResult['data'] as List?) ?? [];
        for (final item in sessions) {
          final session = Map<String, dynamic>.from(item as Map);
          if (_text(session['session_type']) != 'activity') continue;
          final activityId = _text(session['activity_id'], '');
          if (activityId.isEmpty) continue;

          final existing = sessionMap[activityId];
          final isOpen = _isSessionActive(session);
          final existingOpen = existing == null ? false : _isSessionActive(existing);

          if (existing == null || (isOpen && !existingOpen)) {
            sessionMap[activityId] = session;
          }
        }
      }

      if (activityResult['success'] == true) {
        setState(() {
          _activities = activityResult['data'] ?? [];
          _sessionByActivityId = sessionMap;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = activityResult['message'] ?? 'Failed to load activities';
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

  String _text(dynamic value, [String fallback = '-']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String? _getActivityId(Map<String, dynamic> activity) {
    final rawId = activity['Activity_ID'] ?? activity['activity_id'] ?? activity['id'];
    final id = rawId?.toString().trim();
    return (id == null || id.isEmpty) ? null : id;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw) ?? DateTime.tryParse(raw.replaceFirst(' ', 'T'));
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
          'Co-Curriculum Attendance',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: fetchActivities,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.shield, color: Colors.white, size: 22),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _adabGreen))
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
              : _activities.isEmpty
                  ? const Center(child: Text('No activities found.'))
                  : Padding(
                      padding: const EdgeInsets.all(14),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _inactiveGrey,
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
                                color: _headerGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Select Activity Session\nOpen Attendance for an active activity session',
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
                                itemCount: _activities.length,
                                itemBuilder: (context, index) {
                                  final activity = Map<String, dynamic>.from(_activities[index]);
                                  final activityId = _getActivityId(activity);
                                  final session = activityId == null ? null : _sessionByActivityId[activityId];
                                  final active = _isSessionActive(session);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: active ? _activeGreen : _cardGreen,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: active ? _adabGreen : Colors.transparent,
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
                                                '${_text(activity['Module_Code'], '')} ${_text(activity['Module_Name'])}'.trim(),
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
                                                color: active ? _adabGreen : Colors.grey.shade600,
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
                                        const SizedBox(height: 3),
                                        Text(
                                          _text(activity['Activity_Date'] ?? activity['Date']),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          _text(activity['Activity_Time'] ?? activity['Time']),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'Venue: ${_text(activity['Venue'])}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              if (activityId == null) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Activity ID not found.')),
                                                );
                                                return;
                                              }

                                              final changed = await Navigator.pushNamed(
                                                context,
                                                '/pusat-adab-attendance-list',
                                                arguments: activityId,
                                              );
                                              if (changed == true && mounted) fetchActivities();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _yellow,
                                              foregroundColor: Colors.black,
                                              elevation: 1,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 7,
                                              ),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              active ? 'View / Manage Active Session' : 'Manage Session',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w700,
                                              ),
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
                      ),
                    ),
    );
  }
}
