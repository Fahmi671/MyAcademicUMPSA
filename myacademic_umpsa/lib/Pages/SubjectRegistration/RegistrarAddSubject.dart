import 'package:flutter/material.dart';
import '../../Config/api.dart';

// Color palette
class AppColors {
  static const Color appBarBg = Color(0xFF1A5F5F);
  static const Color appBarText = Colors.white;
  static const Color pageBg = Color(0xFFF5F5F5);
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color labelText = Color(0xFF1A1A1A);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Colors.red;
  static const Color inputBorder = Color(0xFF1A5F5F);
}

// Text styles
class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    color: AppColors.appBarText,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.labelText,
  );
  
  static const TextStyle fieldLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.labelText,
  );
  
  static const TextStyle labTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFF2196F3),
  );
}

class Lecturer {
  final int lecturerId;
  final String lecturerName;

  Lecturer({
    required this.lecturerId,
    required this.lecturerName,
  });

  factory Lecturer.fromJson(Map<String, dynamic> json) {
    return Lecturer(
      lecturerId: int.parse(json['Lecturer_ID'].toString()),
      lecturerName: json['User_FullName'] ?? 'Unknown',
    );
  }

  @override
  String toString() => '$lecturerId - $lecturerName';
}

class LabData {
  String lab;
  int? lecturerId;
  String day = 'Monday';
  String time = '08:00 - 10:00';
  String quota = '';
  String room = '';

  LabData({required this.lab});

  Map<String, dynamic> toJson() => {
    'lab': lab,
    'lecturerId': lecturerId,
    'day': day,
    'time': time,
    'quota': quota,
    'room': room,
  };
}

class SectionData {
  int sectionNumber;
  List<LabData> labs;

  SectionData({
    required this.sectionNumber,
    required this.labs,
  });
}

class RegistrarAddSubject extends StatefulWidget {
  const RegistrarAddSubject({super.key});

  @override
  State<RegistrarAddSubject> createState() => _RegistrarAddSubjectState();
}

class _RegistrarAddSubjectState extends State<RegistrarAddSubject> {
  // Controllers
  final _subjectCodeController = TextEditingController();
  final _subjectNameController = TextEditingController();
  final _creditHoursController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isLoadingLecturers = true;
  String? _errorMessage;
  String? _successMessage;

  // Data
  List<Lecturer> _lecturers = [];
  final Map<int, Map<String, Set<String>>> _occupiedLecturerSlots = {};
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  final List<String> _times = [
    '08:00 - 10:00', '10:00 - 12:00', '12:00 - 14:00',
    '14:00 - 16:00', '16:00 - 18:00',
  ];
  List<SectionData> _sections = [
    SectionData(sectionNumber: 1, labs: [LabData(lab: 'A')]),
  ];

  @override
  void initState() {
    super.initState();
    fetchLecturers();
  }

  @override
  void dispose() {
    _subjectCodeController.dispose();
    _subjectNameController.dispose();
    _creditHoursController.dispose();
    super.dispose();
  }

  // Fetch lecturers and occupied slots
  Future<void> fetchLecturers() async {
    try {
      final lecturerResult = await ApiService.getLecturers();
      final subjectResult = await ApiService.getSubjects();

      if (lecturerResult['success']) {
        final lecturersData = lecturerResult['data'] as List;
        final occupied = <int, Map<String, Set<String>>>{};

        if (subjectResult['success'] == true) {
          final subjectData = subjectResult['data'] as List;
          for (final raw in subjectData) {
            final subject = raw as Map<String, dynamic>;
            final lecturerId = int.tryParse((subject['Lecturer_ID'] ?? '').toString());
            final day = (subject['Day'] ?? '').toString();
            final time = (subject['Time'] ?? '').toString();
            if (lecturerId == null || day.isEmpty || time.isEmpty) continue;

            occupied.putIfAbsent(lecturerId, () => {});
            occupied[lecturerId]!.putIfAbsent(day, () => <String>{});
            occupied[lecturerId]![day]!.add(time);
          }
        }

        setState(() {
          _lecturers = lecturersData.map((e) => Lecturer.fromJson(e)).toList();
          _occupiedLecturerSlots.clear();
          _occupiedLecturerSlots.addAll(occupied);
          _isLoadingLecturers = false;
        });
      } else {
        setState(() {
          _errorMessage = lecturerResult['message'] ?? 'Failed to load lecturers';
          _isLoadingLecturers = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoadingLecturers = false;
      });
    }
  }

  // Add new section
  void addSection() {
    setState(() {
      int nextSection = _sections.length + 1;
      _sections.add(SectionData(
        sectionNumber: nextSection,
        labs: [LabData(lab: 'A')],
      ));
    });
  }

  // Add lab to section
  void addLab(SectionData section) {
    setState(() {
      String nextLab = String.fromCharCode(65 + section.labs.length);
      section.labs.add(LabData(lab: nextLab));
    });
  }

  // Get available times for lecturer
  List<String> availableTimesFor(LabData targetLab) {
    if (targetLab.lecturerId == null) return _times;

    final taken = <String>{};
    final occupiedByLecturer = _occupiedLecturerSlots[targetLab.lecturerId!];
    if (occupiedByLecturer != null) {
      taken.addAll(occupiedByLecturer[targetLab.day] ?? <String>{});
    }

    for (final section in _sections) {
      for (final lab in section.labs) {
        if (identical(lab, targetLab)) continue;
        if (lab.lecturerId == targetLab.lecturerId && lab.day == targetLab.day) {
          taken.add(lab.time);
        }
      }
    }

    return _times.where((t) => !taken.contains(t)).toList();
  }

  // Get available days for lecturer
  List<String> availableDaysFor(LabData targetLab) {
    if (targetLab.lecturerId == null) return _days;
    return _days.where((day) {
      final probe = LabData(lab: targetLab.lab)
        ..lecturerId = targetLab.lecturerId
        ..day = day
        ..time = targetLab.time;
      return availableTimesFor(probe).isNotEmpty;
    }).toList();
  }

  // Check for duplicate slots
  bool hasDuplicateLecturerSlot() {
    final seen = <String>{};
    for (final section in _sections) {
      for (final lab in section.labs) {
        if (lab.lecturerId == null) continue;
        final key = '${lab.lecturerId}|${lab.day}|${lab.time}';
        if (seen.contains(key)) return true;
        seen.add(key);
      }
    }
    return false;
  }

  // Save subjects
  Future<void> handleSave() async {
    if (_subjectCodeController.text.isEmpty ||
        _subjectNameController.text.isEmpty ||
        _creditHoursController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all required fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (hasDuplicateLecturerSlot()) {
        throw Exception('Duplicate lecturer day/time is not allowed');
      }

      List<Map<String, dynamic>> subjects = [];

      for (var section in _sections) {
        for (var lab in section.labs) {
          if (lab.lecturerId == null || lab.quota.isEmpty || lab.room.isEmpty) {
            throw Exception('Please fill in all required fields for all labs');
          }

          subjects.add({
            'Subject_Code': _subjectCodeController.text,
            'Subject_Name': _subjectNameController.text,
            'Credit_Hours': int.parse(_creditHoursController.text),
            'Lecturer_ID': lab.lecturerId,
            'Day': lab.day,
            'Time': lab.time,
            'Venue': lab.room,
            'Quota': int.parse(lab.quota),
            'Section': section.sectionNumber,
            'Lab': lab.lab,
          });
        }
      }

      final result = await ApiService.createBulkSubjects(subjects: subjects);

      if (result['success']) {
        setState(() {
          _successMessage = 'Successfully Added';
          _isLoading = false;
        });

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to save subjects';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: buildAppBar(),
      body: _successMessage != null
          ? buildSuccessOverlay()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) buildErrorMessage(),
                  buildTextField('Subject Code *', _subjectCodeController),
                  const SizedBox(height: 16),
                  buildTextField('Subject Name *', _subjectNameController),
                  const SizedBox(height: 16),
                  buildTextField('Credit Hours *', _creditHoursController,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 24),
                  const Text('Sections', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 12),
                  ..._sections.map(buildSectionCard),
                  const SizedBox(height: 12),
                  buildAddSectionButton(),
                  const SizedBox(height: 24),
                  buildSaveButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // App bar
  PreferredSizeWidget buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.appBarBg,
      elevation: 2,
      title: const Text('Add Subject', style: AppTextStyles.appBarTitle),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.appBarText),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Image.asset(
              'assets/images/logo.png',
              height: 32,
              width: 32,
              errorBuilder: (_, _, _) => const Icon(Icons.shield, color: Colors.white70, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  // Error message
  Widget buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_errorMessage!, style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  // Text field
  Widget buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: !_isLoading,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.inputBorder, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // Section card
  Widget buildSectionCard(SectionData section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Section ${section.sectionNumber}', 
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inputBorder)),
          const SizedBox(height: 14),
          ...section.labs.map((lab) => buildLabCard(lab, section)),
          const SizedBox(height: 12),
          buildAddLabButton(section),
        ],
      ),
    );
  }

  // Lab card
  Widget buildLabCard(LabData lab, SectionData section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lab ${lab.lab}', style: AppTextStyles.labTitle),
          const SizedBox(height: 12),
          if (_isLoadingLecturers)
            const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.inputBorder))),
            )
          else
            buildDropdown(
              label: 'Lecturer *',
              value: lab.lecturerId,
              items: _lecturers.map((l) => DropdownMenuItem(value: l.lecturerId, child: Text(l.toString()))).toList(),
              onChanged: (v) => setState(() {
                lab.lecturerId = v;
                final times = availableTimesFor(lab);
                if (times.isNotEmpty && !times.contains(lab.time)) {
                  lab.time = times.first;
                }
              }),
            ),
          const SizedBox(height: 12),
          buildDropdown(
            label: 'Day *',
            value: availableDaysFor(lab).contains(lab.day) ? lab.day : null,
            items: availableDaysFor(lab).map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() {
              final days = availableDaysFor(lab);
              lab.day = v ?? (days.isNotEmpty ? days.first : 'Monday');
              final times = availableTimesFor(lab);
              if (times.isNotEmpty && !times.contains(lab.time)) {
                lab.time = times.first;
              }
            }),
          ),
          const SizedBox(height: 12),
          buildDropdown(
            label: 'Time *',
            value: availableTimesFor(lab).contains(lab.time) ? lab.time : null,
            items: availableTimesFor(lab).map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => lab.time = v ?? ''),
          ),
          const SizedBox(height: 12),
          buildLabInput('Quota *', (v) => lab.quota = v, TextInputType.number),
          const SizedBox(height: 12),
          buildLabInput('Room *', (v) => lab.room = v),
        ],
      ),
    );
  }

  // Dropdown
  Widget buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.inputBorder, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // Lab input
  Widget buildLabInput(String label, Function(String) onChanged,
      [TextInputType type = TextInputType.text]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        TextField(
          keyboardType: type,
          enabled: !_isLoading,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.inputBorder, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // Add lab button
  Widget buildAddLabButton(SectionData section) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => addLab(section),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE3F2FD),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.add, color: Color(0xFF2196F3)),
        label: const Text('Add Lab', style: TextStyle(color: Color(0xFF2196F3))),
      ),
    );
  }

  // Add section button
  Widget buildAddSectionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : addSection,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8F5E9),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.add, color: AppColors.successGreen),
        label: const Text('Add Section', style: TextStyle(color: AppColors.successGreen)),
      ),
    );
  }

  // Save button
  Widget buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.appBarBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
              )
            : const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // Success overlay
  Widget buildSuccessOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Successfully\nAdded',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
