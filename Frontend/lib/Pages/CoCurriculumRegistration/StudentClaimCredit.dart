import 'package:flutter/material.dart';
import '../../Config/api.dart';

class StudentClaimCredit extends StatefulWidget {
  const StudentClaimCredit({super.key});

  @override
  State<StudentClaimCredit> createState() => _StudentClaimCreditState();
}

class _StudentClaimCreditState extends State<StudentClaimCredit> {
  final Color blue = const Color(0xFF1F3E8A);
  bool isSubmitting = false;
  bool statusPopupShown = false;

  String valueOf(dynamic item, String key) {
    if (item == null) return '';
    return item[key]?.toString() ?? '';
  }

  bool canClaim(String attendanceStatus) {
    final status = attendanceStatus.toLowerCase();
    return status == 'present' || status == 'attended';
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
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            height: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: success ? blue : Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              onPressed: () => Navigator.pop(context),
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

  Future<void> submitClaim(dynamic participation) async {
    final participationId =
        int.tryParse(valueOf(participation, 'Participation_ID'));

    final attendanceStatus = valueOf(participation, 'Attendance_Status');

    if (participationId == null) {
      await showMessageDialog(
        title: 'Claim Failed',
        message: 'Invalid participation ID.',
        success: false,
      );
      return;
    }

    if (!canClaim(attendanceStatus)) {
      await showMessageDialog(
        title: 'Claim Not Allowed',
        message: 'You can only claim credit after attendance is verified.',
        success: false,
      );
      return;
    }

    setState(() => isSubmitting = true);

    final result = await ApiService.submitCreditClaim(
      participationId: participationId,
      attendanceStatus: attendanceStatus,
    );

    if (!mounted) return;

    setState(() => isSubmitting = false);

    if (result['success'] == true) {
      await showMessageDialog(
        title: 'Claim Submitted',
        message: result['message'] ??
            'Your credit claim has been submitted successfully.',
        success: true,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      await showMessageDialog(
        title: 'Claim Failed',
        message: result['message'] ??
            result['error'] ??
            'Claim Submission Failed.',
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final participation =
        ModalRoute.of(context)?.settings.arguments as dynamic;

    final moduleCode = valueOf(participation, 'Module_Code');
    final moduleName = valueOf(participation, 'Module_Name');
    final campus = valueOf(participation, 'Campus');
    final venue = valueOf(participation, 'Venue');
    final date = valueOf(participation, 'Activity_Date');
    final time = valueOf(participation, 'Activity_Time');
    final registrationStatus = valueOf(participation, 'Registration_Status');
    final claimStatus = valueOf(participation, 'Claim_Status');
    final claimRemarks = valueOf(participation, 'Claim_Remarks');

    if (!statusPopupShown &&
        (claimStatus == 'Approved' || claimStatus == 'Rejected')) {
      statusPopupShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        showMessageDialog(
          title: claimStatus == 'Approved'
              ? 'Credit Claim Approved'
              : 'Credit Claim Rejected',
          message: claimStatus == 'Approved'
              ? 'Your credit claim has been approved successfully.'
              : claimRemarks.isNotEmpty
                  ? 'Your credit claim was rejected.\nRemarks: $claimRemarks'
                  : 'Your credit claim was rejected.',
          success: claimStatus == 'Approved',
        );
      });
    }

    String attendanceStatus = valueOf(participation, 'Attendance_Status');

    if (attendanceStatus.isEmpty) {
      attendanceStatus = 'Not verified';
    }

    final claimAllowed = canClaim(attendanceStatus);

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
                    buildDetailRow('Module Name:', '$moduleCode $moduleName'),
                    buildDetailRow('Campus:', campus),
                    buildDetailRow('Venue:', venue),
                    buildDetailRow('Date:', date),
                    buildDetailRow('Time:', time),
                    buildDetailRow('Attendance:', attendanceStatus),
                    buildDetailRow('Status:', registrationStatus),
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
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(context),
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
                              backgroundColor:
                                  claimAllowed ? blue : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () => submitClaim(participation),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Claim',
                                    style: TextStyle(fontSize: 11),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    if (!claimAllowed) ...[
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Credit claim is only available after attendance is verified.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
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