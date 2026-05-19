import 'package:flutter/material.dart';
import '../../Config/api.dart';

class StudentRegisteredActivity extends StatefulWidget {
  const StudentRegisteredActivity({super.key});

  @override
  State<StudentRegisteredActivity> createState() =>
      _StudentRegisteredActivityState();
}

class _StudentRegisteredActivityState extends State<StudentRegisteredActivity> {
  final Color blue = const Color(0xFF1F3E8A);

  bool isLoading = true;
  String? errorMessage;
  List<dynamic> participations = [];

  @override
  void initState() {
    super.initState();
    fetchRegisteredActivities();
  }

  Future<void> fetchRegisteredActivities() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await ApiService.getStudentParticipations();

    if (!mounted) return;

    if (result['success'] == true) {
      final List<dynamic> data = result['data'] ?? [];

      setState(() {
        // Only show active registered activities.
        // Withdrawn activities will not appear on this page.
        participations = data.where((item) {
          final status =
              item['Registration_Status']?.toString().toLowerCase() ?? '';
          return status == 'registered';
        }).toList();

        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage =
            result['message'] ?? 'Failed to load registered activities';
        isLoading = false;
      });
    }
  }

  String valueOf(dynamic item, String key) {
    return item[key]?.toString() ?? '';
  }

  Future<bool?> showWithdrawConfirmDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Withdraw Module',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to withdraw from this module?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
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
                backgroundColor: blue,
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

  Future<void> showWithdrawSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Withdraw Successful',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Your participation has been removed successfully.',
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

  Future<void> showErrorDialog(String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Withdraw Failed',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.red,
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
                backgroundColor: Colors.red,
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

  Future<void> withdrawActivity(dynamic participation) async {
    final confirm = await showWithdrawConfirmDialog();

    if (confirm != true) return;

    final participationId =
        int.tryParse(participation['Participation_ID'].toString());

    if (participationId == null) {
      await showErrorDialog('Invalid participation ID.');
      return;
    }

    final result = await ApiService.withdrawParticipation(
      participationId: participationId,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      await showWithdrawSuccessDialog();

      if (!mounted) return;

      // Remove withdrawn activity from current page immediately.
      setState(() {
        participations.removeWhere((item) =>
            item['Participation_ID'].toString() ==
            participation['Participation_ID'].toString());
      });
    } else {
      await showErrorDialog(
        result['message'] ?? 'Failed to withdraw activity.',
      );
    }
  }

  void goToClaimCredit(dynamic participation) {
    Navigator.pushNamed(
      context,
      '/student-claim-credit',
      arguments: participation,
    );
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
              'Module',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Campus',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Venue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Date',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActivityRow(dynamic item) {
    final moduleCode = valueOf(item, 'Module_Code');
    final moduleName = valueOf(item, 'Module_Name');
    final campus = valueOf(item, 'Campus');
    final venue = valueOf(item, 'Venue');
    final date = valueOf(item, 'Activity_Date');
    final status = valueOf(item, 'Registration_Status');

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
              campus,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              venue,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8),
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
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 20,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => withdrawActivity(item),
                    child: const Text(
                      'Withdraw',
                      style: TextStyle(fontSize: 7),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 20,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => goToClaimCredit(item),
                    child: const Text(
                      'View',
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
        child: CircularProgressIndicator(color: blue),
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
                backgroundColor: blue,
                foregroundColor: Colors.white,
              ),
              onPressed: fetchRegisteredActivities,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (participations.isEmpty) {
      return const Center(
        child: Text(
          'No registered activities found.',
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
            itemCount: participations.length,
            itemBuilder: (context, index) {
              return buildActivityRow(participations[index]);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Co-Curriculum Registration',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
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
                'Registered Modules',
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