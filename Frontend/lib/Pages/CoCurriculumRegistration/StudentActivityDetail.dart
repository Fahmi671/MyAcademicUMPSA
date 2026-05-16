import 'package:flutter/material.dart';
import '../../Domain/CocurriculumActivity.dart';

class StudentActivityDetail extends StatelessWidget {
  final CocurriculumActivity activity;

  const StudentActivityDetail({
    super.key,
    required this.activity,
  });

  void showMessageDialog(BuildContext context, bool success, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          success ? 'Registration Successful' : 'Registration Failed',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF1F3E8A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F3E8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFFE0E0E0)),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1F3E8A);

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
      body: Padding(
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

              detailRow('Module Name:', '${activity.moduleCode} ${activity.moduleName}'),
              detailRow('Campus:', activity.campus),
              detailRow('Venue:', activity.venue),
              detailRow('Date:', activity.activityDate),
              detailRow('Time:', activity.activityTime),
              detailRow('Capacity:', activity.capacity.toString()),
              detailRow('Available:', activity.availableSlots.toString()),
              detailRow('Description:', activity.description),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (activity.availableSlots <= 0) {
                        showMessageDialog(
                          context,
                          false,
                          'Module has reached maximum capacity.',
                        );
                      } else if (activity.status != 'Open') {
                        showMessageDialog(
                          context,
                          false,
                          'Module is no longer available.',
                        );
                      } else {
                        showMessageDialog(
                          context,
                          true,
                          'You have successfully registered for this module.',
                        );
                      }
                    },
                    child: const Text('Register'),
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