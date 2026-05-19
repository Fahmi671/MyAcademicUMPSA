import 'package:flutter/material.dart';
import '../../Config/api.dart';

class AdabReviewActivity extends StatefulWidget {
  const AdabReviewActivity({super.key});

  @override
  State<AdabReviewActivity> createState() => _AdabReviewActivityState();
}

class _AdabReviewActivityState extends State<AdabReviewActivity> {
  final Color green = const Color(0xFF3F8F3F);

  bool isLoading = true;
  String? errorMessage;
  List<dynamic> claims = [];

  @override
  void initState() {
    super.initState();
    fetchPendingClaims();
  }

  Future<void> fetchPendingClaims() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await ApiService.getPendingClaims();

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        claims = result['data'] ?? [];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Failed to load pending claims';
        isLoading = false;
      });
    }
  }

  String valueOf(dynamic item, String key) {
    return item[key]?.toString() ?? '';
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
            color: success ? green : Colors.red,
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
                backgroundColor: success ? green : Colors.red,
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

  Future<bool?> showReviewConfirmDialog(String action) {
    final isApprove = action == 'Approved';

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          isApprove ? 'Approve Claim' : 'Reject Claim',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isApprove ? green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isApprove
              ? 'Are you sure you want to approve this credit claim?'
              : 'Are you sure you want to reject this credit claim?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            height: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
          SizedBox(
            height: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprove ? green : Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Confirm',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> reviewClaim(dynamic claim, String status) async {
    final confirm = await showReviewConfirmDialog(status);

    if (confirm != true) return;

    final claimId = int.tryParse(valueOf(claim, 'Claim_ID'));

    if (claimId == null) {
      await showMessageDialog(
        title: 'Review Failed',
        message: 'Invalid claim ID.',
        success: false,
      );
      return;
    }

    final result = await ApiService.reviewClaim(
      claimId: claimId,
      claimStatus: status,
      remarks: status == 'Approved'
          ? 'Credit claim approved by Pusat Adab.'
          : 'Credit claim rejected by Pusat Adab.',
    );

    if (!mounted) return;

    if (result['success'] == true) {
      await showMessageDialog(
        title: status == 'Approved'
            ? 'Approve Successful'
            : 'Reject Successful',
        message: result['message'] ??
            (status == 'Approved'
                ? 'Claim has been approved.'
                : 'Claim has been rejected.'),
        success: status == 'Approved',
      );

      setState(() {
        claims.removeWhere(
          (item) => valueOf(item, 'Claim_ID') == valueOf(claim, 'Claim_ID'),
        );
      });
    } else {
      await showMessageDialog(
        title: 'Review Failed',
        message:
            result['message'] ?? result['error'] ?? 'Failed to review claim.',
        success: false,
      );
    }
  }

  Widget buildHeaderRow() {
    return Container(
      color: const Color(0xFFEFEFEF),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Student',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Module',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Date',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Attendance',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Action',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildClaimRow(dynamic claim) {
    final studentName = valueOf(claim, 'Student_Name');
    final moduleCode = valueOf(claim, 'Module_Code');
    final moduleName = valueOf(claim, 'Module_Name');
    final date = valueOf(claim, 'Activity_Date');
    final attendance = valueOf(claim, 'Attendance_Status');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              studentName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '$moduleCode\n$moduleName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              date,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              attendance,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => reviewClaim(claim, 'Approved'),
                    child: const Text(
                      'Approve',
                      style: TextStyle(fontSize: 7),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 20,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => reviewClaim(claim, 'Rejected'),
                    child: const Text(
                      'Reject',
                      style: TextStyle(fontSize: 7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: green),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              onPressed: fetchPendingClaims,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (claims.isEmpty) {
      return const Center(
        child: Text(
          'No pending credit claims found.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    return Column(
      children: [
        buildHeaderRow(),
        Expanded(
          child: ListView.builder(
            itemCount: claims.length,
            itemBuilder: (context, index) {
              return buildClaimRow(claims[index]);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Review Credit Claims',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              'assets/images/umpsa_logo.png',
              width: 34,
              height: 34,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.account_balance,
                  color: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pending Claims',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(child: buildBody()),
            ],
          ),
        ),
      ),
    );
  }
}