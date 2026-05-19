import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/CocurriculumActivity.dart';

class StudentActivityDetail extends StatefulWidget {
  final CocurriculumActivity activity;

  const StudentActivityDetail({
    super.key,
    required this.activity,
  });

  @override
  State<StudentActivityDetail> createState() => _StudentActivityDetailState();
}

class _StudentActivityDetailState extends State<StudentActivityDetail> {
  final Color blue = const Color(0xFF1F3E8A);

  late CocurriculumActivity activity;
  bool isRegistering = false;

  @override
  void initState() {
    super.initState();
    activity = widget.activity;
  }

  Future<void> showMessageDialog({
    required String title,
    required String message,
    required bool success,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: success ? blue : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            height: 32,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: success ? blue : Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> registerActivity() async {
    if (activity.availableSlots <= 0) {
      await showMessageDialog(
        title: 'Registration Failed',
        message: 'Module has reached maximum capacity.',
        success: false,
      );
      return;
    }

    if (activity.status.toLowerCase() != 'open') {
      await showMessageDialog(
        title: 'Registration Failed',
        message: 'Module is no longer available.',
        success: false,
      );
      return;
    }

    setState(() => isRegistering = true);

    final result = await ApiService.registerActivity(
      activityId: activity.activityId,
    );

    if (!mounted) return;

    setState(() => isRegistering = false);

    if (result['success'] == true) {
      await showMessageDialog(
        title: 'Registration Successful',
        message: result['message'] ??
            'You have successfully registered for this module.',
        success: true,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/student-registered-activities',
        );
      }
    } else {
      await showMessageDialog(
        title: 'Registration Failed',
        message: result['message'] ??
            result['error'] ??
            'Failed to register activity.',
        success: false,
      );
    }
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD0D0D0)),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFull = activity.availableSlots <= 0 ||
        activity.status.toLowerCase() == 'full' ||
        activity.status.toLowerCase() == 'closed';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Co-Curriculum Registration',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Module Details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              detailRow(
                'Module Name:',
                '${activity.moduleCode} ${activity.moduleName}',
              ),
              detailRow('Campus:', activity.campus),
              detailRow('Venue:', activity.venue),
              detailRow('Date:', activity.activityDate),
              detailRow('Time:', activity.activityTime),
              detailRow('Capacity:', activity.capacity.toString()),
              detailRow('Available:', activity.availableSlots.toString()),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isRegistering
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text(
                        'Back',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFull ? Colors.grey : blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          isRegistering || isFull ? null : registerActivity,
                      child: isRegistering
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isFull ? 'Full' : 'Register',
                              style: const TextStyle(fontSize: 11),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}