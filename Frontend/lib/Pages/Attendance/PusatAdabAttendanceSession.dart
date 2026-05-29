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
  static const Color _softGrey = Color(0xFFE0E0E0);
  static const Color _yellow = Color(0xFFFFD966);

  bool _isLoading = true;
  List<dynamic> _activities = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchActivities();
  }

  Future<void> fetchActivities() async {
    try {
      final result = await ApiService.getActivities();
      if (result['success'] == true) {
        setState(() {
          _activities = result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load activities';
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
          'Class Attendance',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
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
                                color: const Color(0xFF8BCF86),
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

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _cardGreen,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_text(activity['Module_Code'], '')} ${_text(activity['Module_Name'])}'.trim(),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w800,
                                          ),
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
                                            onPressed: () {
                                              if (activityId == null) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Activity ID not found.')),
                                                );
                                                return;
                                              }

                                              Navigator.pushNamed(
                                                context,
                                                '/pusat-adab-attendance-list',
                                                arguments: activityId,
                                              );
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
                                            child: const Text(
                                              'Manage Session',
                                              style: TextStyle(
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
