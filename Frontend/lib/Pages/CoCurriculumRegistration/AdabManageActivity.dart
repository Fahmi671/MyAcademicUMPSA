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

  Future<void> deleteActivity(CocurriculumActivity activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text(
          'Are you sure you want to delete ${activity.moduleCode} ${activity.moduleName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await ApiService.deleteActivity(activity.activityId);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity deleted successfully')),
      );
      fetchActivities();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to delete activity'),
        ),
      );
    }
  }

  void goToAddActivity() async {
    await Navigator.pushNamed(context, '/adab-add-activity');
    fetchActivities();
  }

  void goToEditActivity(CocurriculumActivity activity) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdabEditActivity(activity: activity),
      ),
    );
    fetchActivities();
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: buildActivityTable(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                onPressed: goToAddActivity,
                child: const Text(
                  'Add Activity',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}