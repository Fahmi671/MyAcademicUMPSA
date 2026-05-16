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
  String selectedModule = 'All Modules';
  String selectedCampus = 'All';
  String selectedDate = 'All';

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

        selectedModule = 'All Modules';
        selectedCampus = 'All';
        selectedDate = 'All';

        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Failed to load activities';
        isLoading = false;
      });
    }
  }

  List<CocurriculumActivity> get filteredActivities {
    return activities.where((activity) {
      final module = '${activity.moduleCode} ${activity.moduleName}';

      final matchModule =
          selectedModule == 'All Modules' || selectedModule == module;
      final matchCampus =
          selectedCampus == 'All' || selectedCampus == activity.campus;
      final matchDate =
          selectedDate == 'All' || selectedDate == activity.activityDate;

      return matchModule && matchCampus && matchDate;
    }).toList();
  }

  List<String> get moduleItems {
    return [
      'All Modules',
      ...activities
          .map((activity) => '${activity.moduleCode} ${activity.moduleName}')
          .toSet()
          .toList(),
    ];
  }

  List<String> get campusItems {
    return [
      'All',
      ...activities.map((activity) => activity.campus).toSet().toList(),
    ];
  }

  List<String> get dateItems {
    return [
      'All',
      ...activities.map((activity) => activity.activityDate).toSet().toList(),
    ];
  }

  Widget buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;

    return Row(
      children: [
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safeValue,
                isExpanded: true,
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 12),
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
    );
  }

  void goToActivityDetail(CocurriculumActivity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentActivityDetail(activity: activity),
      ),
    );
  }

  Widget buildActivityTable() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
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
                    'Status',
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
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredActivities.length,
              itemBuilder: (context, index) {
                final activity = filteredActivities[index];

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
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          activity.campus,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          activity.activityDate,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          activity.status,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: activity.status.toLowerCase() == 'open'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: SizedBox(
                            height: 24,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: () => goToActivityDetail(activity),
                              child: const Text(
                                'View',
                                style: TextStyle(fontSize: 9),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
        child: Column(
          children: [
            buildDropdown(
              label: 'MODULE',
              value: selectedModule,
              items: moduleItems,
              onChanged: (value) {
                setState(() => selectedModule = value!);
              },
            ),
            const SizedBox(height: 8),
            buildDropdown(
              label: 'CAMPUS',
              value: selectedCampus,
              items: campusItems,
              onChanged: (value) {
                setState(() => selectedCampus = value!);
              },
            ),
            const SizedBox(height: 8),
            buildDropdown(
              label: 'DATE',
              value: selectedDate,
              items: dateItems,
              onChanged: (value) {
                setState(() => selectedDate = value!);
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              onPressed: () {
                setState(() {});
              },
              child: const Text('Search'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: blue),
                    )
                  : errorMessage != null
                      ? Center(
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
                        )
                      : filteredActivities.isEmpty
                          ? const Center(
                              child: Text(
                                'No co-curriculum activities available.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : buildActivityTable(),
            ),
          ],
        ),
      ),
    );
  }
}