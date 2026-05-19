import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/CocurriculumActivity.dart';
import 'AdabEditActivity.dart';

class AdabManageActivity extends StatefulWidget {
  const AdabManageActivity({super.key});

  @override
  State<AdabManageActivity> createState() => _AdabManageActivityState();
}

class _AdabManageActivityState extends State<AdabManageActivity> {
  final Color green = const Color(0xFF3F8F3F);

  List<CocurriculumActivity> activities = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchActivities();
  }

  Future<void> fetchActivities() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await ApiService.getActivities();

    if (!mounted) return;

    if (result['success'] == true) {
      final List data = result['data'] ?? [];

      setState(() {
        activities = data
            .map((item) => CocurriculumActivity.fromJson(item))
            .toList();
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Failed to load activities';
        isLoading = false;
      });
    }
  }

  Future<bool?> showDeleteConfirmDialog(CocurriculumActivity activity) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Delete Module',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF3F8F3F),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${activity.moduleCode} ${activity.moduleName}?',
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
                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                backgroundColor: green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
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

  Future<void> showDeleteSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Delete Successful',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF3F8F3F),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Module information has been deleted.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            height: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3F8F3F),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
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
          'Error',
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

  Future<void> deleteActivity(CocurriculumActivity activity) async {
    final confirm = await showDeleteConfirmDialog(activity);

    if (confirm != true) return;

    final result = await ApiService.deleteActivity(activity.activityId);

    if (!mounted) return;

    if (result['success'] == true) {
      await showDeleteSuccessDialog();
      fetchActivities();
    } else {
      await showErrorDialog(
        result['message'] ?? 'Failed to delete activity.',
      );
    }
  }

  void goToAddActivity() async {
    final result = await Navigator.pushNamed(context, '/adab-add-activity');

    if (result == true) {
      fetchActivities();
    } else {
      fetchActivities();
    }
  }

  void goToEditActivity(CocurriculumActivity activity) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdabEditActivity(activity: activity),
      ),
    );

    if (result == true) {
      fetchActivities();
    } else {
      fetchActivities();
    }
  }

  void goToReviewClaims() {
    Navigator.pushNamed(context, '/adab-review-activity');
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
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Campus',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Date',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Action',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActivityRow(CocurriculumActivity activity) {
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
              '${activity.moduleCode}\n${activity.moduleName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              activity.campus,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8.5),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              activity.activityDate,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8.5),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                SizedBox(
                  height: 22,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => goToEditActivity(activity),
                    child: const Text(
                      'Edit',
                      style: TextStyle(fontSize: 8),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 22,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => deleteActivity(activity),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontSize: 8),
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

  Widget buildActivityTable() {
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
              onPressed: fetchActivities,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (activities.isEmpty) {
      return const Center(
        child: Text(
          'No co-curriculum activities found.',
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
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return buildActivityRow(activities[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget buildBottomButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          height: 32,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
            ),
            onPressed: goToReviewClaims,
            icon: const Icon(Icons.fact_check, size: 14),
            label: const Text(
              'Review Credit Claims',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(
          height: 32,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
            ),
            onPressed: goToAddActivity,
            icon: const Icon(Icons.add, size: 14),
            label: const Text(
              'Add Activity',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
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
          'Co-Curriculum Management',
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
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: Colors.white,
                child: buildActivityTable(),
              ),
            ),
            const SizedBox(height: 12),
            buildBottomButtons(),
          ],
        ),
      ),
    );
  }
}