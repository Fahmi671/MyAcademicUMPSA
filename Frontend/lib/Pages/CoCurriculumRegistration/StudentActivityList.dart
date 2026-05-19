import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/CocurriculumActivity.dart';
import 'StudentActivityDetail.dart';

class StudentActivityList extends StatefulWidget {
  const StudentActivityList({super.key});

  @override
  State<StudentActivityList> createState() => _StudentActivityListState();
}

class _StudentActivityListState extends State<StudentActivityList> {
  final Color blue = const Color(0xFF1F3E8A);

  List<CocurriculumActivity> activities = [];
  List<CocurriculumActivity> filteredActivities = [];

  bool isLoading = true;
  String? errorMessage;

  String selectedModule = 'All Modules';
  String selectedCampus = 'All';
  String selectedDate = 'All';

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

      final loadedActivities = data
          .map((item) => CocurriculumActivity.fromJson(item))
          .toList();

      setState(() {
        activities = loadedActivities;
        filteredActivities = loadedActivities;
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Failed to load activities';
        isLoading = false;
      });
    }
  }

  List<String> get moduleOptions {
    final modules = activities
        .map((activity) => '${activity.moduleCode} ${activity.moduleName}')
        .toSet()
        .toList();

    return ['All Modules', ...modules];
  }

  List<String> get campusOptions {
    final campuses =
        activities.map((activity) => activity.campus).toSet().toList();

    return ['All', ...campuses];
  }

  List<String> get dateOptions {
    final dates =
        activities.map((activity) => activity.activityDate).toSet().toList();

    return ['All', ...dates];
  }

  void searchActivities() {
    setState(() {
      filteredActivities = activities.where((activity) {
        final module = '${activity.moduleCode} ${activity.moduleName}';

        final matchModule =
            selectedModule == 'All Modules' || selectedModule == module;

        final matchCampus =
            selectedCampus == 'All' || selectedCampus == activity.campus;

        final matchDate =
            selectedDate == 'All' || selectedDate == activity.activityDate;

        return matchModule && matchCampus && matchDate;
      }).toList();
    });
  }

  void goToActivityDetail(CocurriculumActivity activity) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentActivityDetail(activity: activity),
      ),
    );

    if (result == true) {
      fetchActivities();
    }
  }

  Widget buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
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
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD0D0D0)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: safeValue,
                  isExpanded: true,
                  iconSize: 18,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black,
                  ),
                  items: items.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchButton() {
  return Padding(
    padding: const EdgeInsets.only(left: 70),
    child: Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 28,
        width: 75,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: searchActivities,
          child: const Text(
            'Search',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget buildRegisteredModulesButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        height: 28,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/student-registered-activities');
          },
          icon: const Icon(Icons.assignment_turned_in, size: 13),
          label: const Text(
            'Registered Modules',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
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
          Expanded(
            flex: 2,
            child: Text(
              'Action',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActivityRow(CocurriculumActivity activity) {
    final isOpen = activity.status.toLowerCase() == 'open';

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
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              activity.campus,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              activity.activityDate,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              activity.status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isOpen ? Colors.black : Colors.red,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: SizedBox(
                height: 22,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => goToActivityDetail(activity),
                  child: const Text(
                    'View',
                    style: TextStyle(fontSize: 8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActivityTable() {
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
              onPressed: fetchActivities,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredActivities.isEmpty) {
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
            itemCount: filteredActivities.length,
            itemBuilder: (context, index) {
              return buildActivityRow(filteredActivities[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget buildFilterSection() {
    return Column(
      children: [
        buildDropdownRow(
          label: 'MODULE',
          value: selectedModule,
          items: moduleOptions,
          onChanged: (value) {
            setState(() {
              selectedModule = value!;
            });
          },
        ),
        buildDropdownRow(
          label: 'CAMPUS',
          value: selectedCampus,
          items: campusOptions,
          onChanged: (value) {
            setState(() {
              selectedCampus = value!;
            });
          },
        ),
        buildDropdownRow(
          label: 'DATE',
          value: selectedDate,
          items: dateOptions,
          onChanged: (value) {
            setState(() {
              selectedDate = value!;
            });
          },
        ),
        const SizedBox(height: 2),
        buildSearchButton(),
        const SizedBox(height: 8),
        buildRegisteredModulesButton(),
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
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
            buildFilterSection(),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: Colors.white,
                child: buildActivityTable(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}