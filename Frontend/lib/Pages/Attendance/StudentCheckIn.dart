import 'package:flutter/material.dart';
import '../../Config/api.dart';

class StudentCheckIn extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  const StudentCheckIn({super.key, required this.sessionData});

  @override
  State<StudentCheckIn> createState() => _StudentCheckInState();
}

class _StudentCheckInState extends State<StudentCheckIn> {
  static const Color _headerBlue = Color(0xFF1F3E8A);
  static const Color _screenGrey = Color(0xFFF2F2F2);
  static const Color _panelGrey = Color(0xFFBDBDBD);
  static const Color _activeGreen = Color(0xFFD0E3A0);
  static const Color _inputGreen = Color(0xFFAFC474);
  static const Color _checkInBlue = Color(0xFF67C8D4);

  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> submitAttendance() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      showResultDialog(
        isSuccess: false,
        icon: Icons.cancel,
        iconColor: Colors.red,
        title: 'Empty Code',
        message: 'Please enter the attendance code.',
        buttonLabel: 'Try Again',
        isRetry: false,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.checkInAttendance(
        attendanceCode: code,
        subjectId: widget.sessionData['subject_id'],
        activityId: widget.sessionData['activity_id'],
      );
      setState(() => _isLoading = false);

      if (result['success']) {
        showResultDialog(
          isSuccess: true,
          icon: Icons.check_circle,
          iconColor: Colors.green,
          title: 'Attendance Recorded',
          message: 'Your attendance has been successfully submitted',
          buttonLabel: 'OK',
          isRetry: false,
        );
      } else {
        final msg = result['message'] ?? 'Failed to record attendance';
        _handleErrorMessage(msg);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showResultDialog(
        isSuccess: false,
        icon: Icons.wifi_off,
        iconColor: Colors.black54,
        title: 'Connection Error',
        message:
            'Attendance submission failed.\nPlease check your internet connection and try again',
        buttonLabel: 'Retry',
        isRetry: true,
      );
    }
  }

  void _handleErrorMessage(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('already')) {
      showResultDialog(
        isSuccess: false,
        icon: Icons.cancel,
        iconColor: Colors.red,
        title: 'Attendance Already Recorded',
        message: 'You have already checked in for this session',
        buttonLabel: 'OK',
        isRetry: false,
      );
    } else if (lower.contains('location') ||
        lower.contains('gps') ||
        lower.contains('area')) {
      showResultDialog(
        isSuccess: false,
        icon: Icons.cancel,
        iconColor: Colors.red,
        title: 'Location Verification Failed',
        message: 'You are not within the allowed attendance area',
        buttonLabel: 'OK',
        isRetry: false,
      );
    } else {
      showResultDialog(
        isSuccess: false,
        icon: Icons.cancel,
        iconColor: Colors.red,
        title: 'Invalid Attendance Code',
        message: 'The Code entered is Invalid. Please try again',
        buttonLabel: 'Try Again',
        isRetry: false,
      );
    }
  }

  void showResultDialog({
    required bool isSuccess,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String buttonLabel,
    required bool isRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (isSuccess) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess
                      ? Colors.green
                      : const Color(0xFF9E9E9E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectCode = widget.sessionData['subject_code'] ?? '-';
    final subjectName = widget.sessionData['subject_name'] ?? '-';
    final lecturer = widget.sessionData['lecturer'] ?? '-';
    final day = widget.sessionData['day'] ?? '-';
    final time = widget.sessionData['time'] ?? '-';
    final room = widget.sessionData['room'] ?? '-';
    final section = widget.sessionData['section'] ?? '-';
    final lab = widget.sessionData['lab'] ?? '-';

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
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications, color: Colors.black, size: 20),
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
        title: const Text(
          'Class Attendance',
          style: TextStyle(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
        child: Container(
          decoration: BoxDecoration(
            color: _panelGrey,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFF8E8E8E), width: 3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _InstructionCard(
                text:
                    'Select Your Registered Class\nCheck in for your current active class session',
              ),
              _SubjectCard(
                subjectCode: subjectCode,
                subjectName: subjectName,
                lecturer: lecturer,
                day: day,
                time: time,
                room: room,
                section: section,
                lab: lab,
              ),
              _FormSection(
                title: 'Attendance Code',
                child: TextField(
                  controller: _codeController,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter code here',
                    hintStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    filled: true,
                    fillColor: _inputGreen,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF7E9956),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              _FormSection(
                title: 'Location Verification',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Color(0xFF7A8665),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'GPS is required for Attendance',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A8665),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Status: Ready',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'Code is valid during active session only',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : submitAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _checkInBlue,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 27,
                            vertical: 10,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 15,
                                width: 15,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Check In',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
        color: const Color(0xFFE0E0E0),
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

class _SubjectCard extends StatelessWidget {
  final String subjectCode;
  final String subjectName;
  final String lecturer;
  final String day;
  final String time;
  final String room;
  final String section;
  final String lab;

  const _SubjectCard({
    required this.subjectCode,
    required this.subjectName,
    required this.lecturer,
    required this.day,
    required this.time,
    required this.room,
    required this.section,
    required this.lab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
      decoration: BoxDecoration(
        color: _StudentCheckInState._activeGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subjectCode,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          Text(
            subjectName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1.25,
            ),
          ),
          if (section != '-' || lab != '-')
            Text(
              'Section: $section   Lab: $lab',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.25,
              ),
            ),
          Text(
            'Lecturer: $lecturer',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1.25,
            ),
          ),
          Text(
            '$day, $time',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1.25,
            ),
          ),
          Text(
            'Room: $room',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 10),
      decoration: BoxDecoration(
        color: _StudentCheckInState._activeGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}
