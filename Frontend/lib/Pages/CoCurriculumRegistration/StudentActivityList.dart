import 'package:flutter/material.dart';
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

  final List<CocurriculumActivity> activities = [
    CocurriculumActivity(
      activityId: 'A001',
      pusatAdabId: 'PA001',
      moduleCode: 'HQS3032',
      moduleName: 'MEMANAH',
      campus: 'PEKAN',
      venue: 'Lap. Sasar Memanah, UMPSA Pekan',
      activityDate: '12/08/2026',
      activityTime: '8:00 AM - 5:00 PM',
      capacity: 40,
      availableSlots: 8,
      status: 'Open',
      description: 'Archery co-curriculum activity for students.',
    ),
    CocurriculumActivity(
      activityId: 'A002',
      pusatAdabId: 'PA001',
      moduleCode: 'HQS3022',
      moduleName: 'KAYAK',
      campus: 'PEKAN',
      venue: 'Tasik',
      activityDate: '22/06/2026',
      activityTime: '8:00 AM - 2:00 PM',
      capacity: 25,
      availableSlots: 5,
      status: 'Open',
      description: 'Kayaking outdoor activity for students.',
    ),
    CocurriculumActivity(
      activityId: 'A003',
      pusatAdabId: 'PA002',
      moduleCode: 'HQS3024',
      moduleName: 'DIGITAL CITIZENSHIP',
      campus: 'GAMBANG',
      venue: 'Dewan UMPSA Gambang',
      activityDate: '20/08/2026',
      activityTime: '9:00 AM - 12:00 PM',
      capacity: 30,
      availableSlots: 0,
      status: 'Full',
      description: 'Digital citizenship co-curriculum activity.',
    ),
  ];

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

  Widget buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
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
                value: value,
                isExpanded: true,
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 12)),
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
              items: const [
                'All Modules',
                'HQS3032 MEMANAH',
                'HQS3022 KAYAK',
                'HQS3024 DIGITAL CITIZENSHIP',
              ],
              onChanged: (value) {
                setState(() => selectedModule = value!);
              },
            ),
            const SizedBox(height: 8),
            buildDropdown(
              label: 'CAMPUS',
              value: selectedCampus,
              items: const ['All', 'PEKAN', 'GAMBANG'],
              onChanged: (value) {
                setState(() => selectedCampus = value!);
              },
            ),
            const SizedBox(height: 8),
            buildDropdown(
              label: 'DATE',
              value: selectedDate,
              items: const ['All', '12/08/2026', '22/06/2026', '20/08/2026'],
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
              child: Container(
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
                                      color: activity.status == 'Open'
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
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}