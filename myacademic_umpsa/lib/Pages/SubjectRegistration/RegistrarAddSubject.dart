import 'package:flutter/material.dart';
import '../../Config/api.dart';

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
  final _subjectCodeController = TextEditingController();
  final _subjectNameController = TextEditingController();
  final _creditHoursController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingLecturers = true;
  String? _errorMessage;
  String? _successMessage;

  List<Lecturer> _lecturers = [];
  final Map<int, Map<String, Set<String>>> _occupiedLecturerSlots = {};

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
  ];

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
          _lecturers = lecturersData
              .map((e) => Lecturer.fromJson(e))
              .toList();
          _occupiedLecturerSlots
            ..clear()
            ..addAll(occupied);
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

  void addSection() {
    setState(() {
      int nextSection = _sections.length + 1;
      _sections.add(SectionData(
        sectionNumber: nextSection,
        labs: [LabData(lab: 'A')],
      ));
    });
  }

  void addLab(SectionData section) {
    setState(() {
      String nextLab = String.fromCharCode(65 + section.labs.length);
      section.labs.add(LabData(lab: nextLab));
    });
  }

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

      // Build all subjects
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

      // Send bulk request
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5F5F),
        elevation: 2,
        title: const Text('Add Subject', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
      ),
      body: _successMessage != null
          ? buildSuccessOverlay()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_errorMessage!,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  buildTextField('Subject Code *', _subjectCodeController),
                  const SizedBox(height: 16),
                  buildTextField('Subject Name *', _subjectNameController),
                  const SizedBox(height: 16),
                  buildTextField('Credit Hours *', _creditHoursController,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 24),
                  const Text('Sections',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A))),
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

  Widget buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: !_isLoading,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: Color(0xFF1A5F5F), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSectionCard(SectionData section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Section ${section.sectionNumber}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A5F5F))),
          const SizedBox(height: 14),
          ...section.labs.map((lab) => buildLabCard(lab, section)),
          const SizedBox(height: 12),
          buildAddLabButton(section),
        ],
      ),
    );
  }

  Widget buildLabCard(LabData lab, SectionData section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lab ${lab.lab}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2196F3))),
          const SizedBox(height: 12),
          if (_isLoadingLecturers)
            const SizedBox(
              height: 48,
              child: Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF1A5F5F)))),
            )
          else
            buildDropdown(
              label: 'Lecturer *',
              value: lab.lecturerId,
              items: _lecturers
                  .map((l) =>
                  DropdownMenuItem(value: l.lecturerId, child: Text(l.toString())))
                  .toList(),
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
            items: availableDaysFor(lab)
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
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
            items: availableTimesFor(lab)
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
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

  Widget buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: Color(0xFF1A5F5F), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLabInput(String label, Function(String) onChanged,
      [TextInputType type = TextInputType.text]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          keyboardType: type,
          enabled: !_isLoading,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: Color(0xFF1A5F5F), width: 2),
            ),
          ),
        ),
      ],
    );
  }

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
        label: const Text('Add Lab',
            style: TextStyle(color: Color(0xFF2196F3))),
      ),
    );
  }

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
        icon: const Icon(Icons.add, color: Color(0xFF4CAF50)),
        label: const Text('Add Section',
            style: TextStyle(color: Color(0xFF4CAF50))),
      ),
    );
  }

  Widget buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A5F5F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation(Colors.white)),
              )
            : const Text('Save',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget buildSuccessOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Successfully\nAdded',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black)),
          ],
        ),
      ),
    );
  }
}