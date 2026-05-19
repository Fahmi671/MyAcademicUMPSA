import 'package:flutter/material.dart';

class StudentClaimCredit extends StatelessWidget {
  const StudentClaimCredit({super.key});

  String valueOf(dynamic item, String key) {
    if (item == null) return '';
    return item[key]?.toString() ?? '';
  }

  Widget buildDetailRow(String label, String value) {
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

  Future<void> showClaimSuccessDialog(BuildContext context) async {
    const blue = Color(0xFF1F3E8A);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Claim Submitted',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Your credit claim has been submitted successfully.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            height: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
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

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1F3E8A);

    final participation =
        ModalRoute.of(context)?.settings.arguments as dynamic;

    final moduleCode = valueOf(participation, 'Module_Code');
    final moduleName = valueOf(participation, 'Module_Name');
    final campus = valueOf(participation, 'Campus');
    final venue = valueOf(participation, 'Venue');
    final date = valueOf(participation, 'Activity_Date');
    final time = valueOf(participation, 'Activity_Time');
    final status = valueOf(participation, 'Registration_Status');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Claim Credit',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: participation == null
              ? const Center(
                  child: Text(
                    'No activity selected.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Claim Credit Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    buildDetailRow(
                      'Module Name:',
                      '$moduleCode $moduleName',
                    ),
                    buildDetailRow('Campus:', campus),
                    buildDetailRow('Venue:', venue),
                    buildDetailRow('Date:', date),
                    buildDetailRow('Time:', time),
                    buildDetailRow('Attendance:', 'Present'),
                    buildDetailRow('Status:', status),

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
                            onPressed: () => Navigator.pop(context),
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
                              backgroundColor: blue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              await showClaimSuccessDialog(context);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text(
                              'Claim',
                              style: TextStyle(fontSize: 11),
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