import 'package:flutter/material.dart';
import '../../Config/api.dart';

class StudentCheckIn extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  const StudentCheckIn({super.key, required this.sessionData});

  @override
  State<StudentCheckIn> createState() => _StudentCheckInState();
}

class _StudentCheckInState extends State<StudentCheckIn> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isSuccess = false;

  Future<void> submitAttendance() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter attendance code.';
        _isSuccess = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.post('/attendance/checkin', {
        'attendance_code': code,
        'subject_id': widget.sessionData['subject_id'],
        'latitude': null,
        'longitude': null,
      });

      if (result['success']) {
        setState(() {
          _statusMessage = 'Attendance Recorded\nYour attendance has been successfully submitted';
          _isSuccess = true;
          _isLoading = false;
        });
        showResultDialog(true, 'Attendance Recorded', 'Your attendance has been successfully submitted');
      } else {
        final msg = result['message'] ?? 'Failed to record attendance';
        setState(() {
          _statusMessage = msg;
          _isSuccess = false;
          _isLoading = false;
        });
        showResultDialog(false, getErrorTitle(msg), msg);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Connection Error. Please check your internet connection and try again.';
        _isSuccess = false;
        _isLoading = false;
      });
      showResultDialog(false, 'Connection Error', 'Attendance submission failed.\nPlease check your internet connection and try again.');
    }
  }

  String getErrorTitle(String message) {
    if (message.contains('Invalid')) return 'Invalid Attendance Code';
    if (message.contains('already')) return 'Attendance Already Recorded';
    if (message.contains('location') || message.contains('GPS')) return 'Location Verification Failed';
    if (message.contains('expired')) return 'Session Expired';
    return 'Check In Failed';
  }

  void showResultDialog(bool success, String title, String message) {
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
              size: 60,
            ),
            const SizedBox(height: 12),
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
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (success) Navigator.pop(context);
              },
              child: Text(
                success ? 'OK' : 'Try Again',
                style: const TextStyle(color: Color(0xFF1F3E8A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectCode = widget.sessionData['subject_code'] ?? '-';
    final subjectName = widget.sessionData['subject_name'] ?? '-';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Your Registered Class\nCheck in for your current active class session',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
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
                  Text(
                    subjectCode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F3E8A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subjectName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Attendance Code',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: 'Enter code here',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF1F3E8A), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'GPS is required for Attendance',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1F3E8A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Status: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const Text('Ready', style: TextStyle(fontSize: 12, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Code is valid during active session only',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : submitAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F3E8A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Check In', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}