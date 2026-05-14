import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/Subject.dart';

class Lecturer {
  final int lecturerId;
  final String lecturerName;

  Lecturer({required this.lecturerId, required this.lecturerName});

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
  int? subjectId;
  String lab;
  int? lecturerId;
  String day;
  String time;
  String quota;
  String room;

  LabData({
    this.subjectId,
    required this.lab,
    this.lecturerId,
    required this.day,
    required this.time,
    required this.quota,
    required this.room,
  });
}

class SectionData {
  int sectionNumber;
  List<LabData> labs;

  SectionData({required this.sectionNumber, required this.labs});
}

class RegistrarEditSubject extends StatefulWidget {
  final List<Subject> subjects;

  const RegistrarEditSubject({super.key, required this.subjects});

  @override
  State<RegistrarEditSubject> createState() => _RegistrarEditSubjectState();
}

class _RegistrarEditSubjectState extends State<RegistrarEditSubject> {
  final _subjectCodeController = TextEditingController();
  final _subjectNameController = TextEditingController();
  final _creditHoursController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingLecturers = true;
  String? _errorMessage;
  String? _successMessage;

  List<Lecturer> _lecturers = [];
  final Set<int> _initialSubjectIds = {};
  final Map<int, Map<String, Set<String>>> _occupiedLecturerSlots = {};

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  final List<String> _times = [
    '08:00 - 10:00',
    '10:00 - 12:00',
    '12:00 - 14:00',
    '14:00 - 16:00',
    '16:00 - 18:00',
  ];

  List<SectionData> _sections = [];

  @override
  void initState() {
    super.initState();
    seedFromSubjects();
    fetchLecturers();
  }

  void seedFromSubjects() {
    final base = widget.subjects.first;
    _subjectCodeController.text = base.subjectCode;
    _subjectNameController.text = base.subjectName;
    _creditHoursController.text = base.creditHours.toString();

    final bySection = <int, List<Subject>>{};
    for (final s in widget.subjects) {
      _initialSubjectIds.add(s.subjectId);
      bySection.putIfAbsent(s.section, () => []).add(s);
    }

    final sortedSections = bySection.keys.toList()..sort();
    _sections = sortedSections.map((sectionNo) {
      final rows = bySection[sectionNo]!..sort((a, b) => a.lab.compareTo(b.lab));
      return SectionData(
        sectionNumber: sectionNo,
        labs: rows
            .map(
              (s) => LabData(
                subjectId: s.subjectId,
                lab: s.lab,
                lecturerId: s.lecturerId,
                day: s.day,
                time: s.time,
                quota: s.quota.toString(),
                room: s.venue,
              ),
            )
            .toList(),
      );
    }).toList();
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
            final subjectId = int.tryParse((subject['Subject_ID'] ?? '').toString());
            if (subjectId != null && _initialSubjectIds.contains(subjectId)) {
              continue;
            }

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
      final nextSection = (_sections.map((e) => e.sectionNumber).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
      _sections.add(
        SectionData(
          sectionNumber: nextSection,
          labs: [
            LabData(
              lab: 'A',
              day: 'Monday',
              time: '08:00 - 10:00',
              quota: '',
              room: '',
            ),
          ],
        ),
      );
    });
  }

  void addLab(SectionData section) {
    setState(() {
      final nextLab = String.fromCharCode(65 + section.labs.length);
      section.labs.add(
        LabData(
          lab: nextLab,
          day: 'Monday',
          time: '08:00 - 10:00',
          quota: '',
          room: '',
        ),
      );
    });
  }

  void removeLab(SectionData section, LabData lab) {
    if (section.labs.length == 1) return;
    setState(() => section.labs.remove(lab));
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
      final probe = LabData(
        subjectId: targetLab.subjectId,
        lab: targetLab.lab,
        lecturerId: targetLab.lecturerId,
        day: day,
        time: targetLab.time,
        quota: targetLab.quota,
        room: targetLab.room,
      );
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
    if (_subjectNameController.text.trim().isEmpty || _creditHoursController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please fill in subject name and credit hours');
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

      final createdPayload = <Map<String, dynamic>>[];
      final retainedIds = <int>{};
      final creditHours = int.parse(_creditHoursController.text.trim());

      for (final section in _sections) {
        for (final lab in section.labs) {
          if (lab.lecturerId == null || lab.quota.isEmpty || lab.room.isEmpty) {
            throw Exception('Please complete lecturer/quota/room for all labs');
          }

          if (lab.subjectId != null) {
            retainedIds.add(lab.subjectId!);
            final result = await ApiService.updateSubject(
              subjectId: lab.subjectId!,
              subjectName: _subjectNameController.text.trim(),
              creditHours: creditHours,
              lecturerId: lab.lecturerId!,
              day: lab.day,
              time: lab.time,
              venue: lab.room.trim(),
              quota: int.parse(lab.quota.trim()),
              section: section.sectionNumber,
              lab: lab.lab,
            );
            if (result['success'] != true) {
              throw Exception(result['message'] ?? 'Failed to update subject');
            }
          } else {
            createdPayload.add({
              'Subject_Code': _subjectCodeController.text.trim(),
              'Subject_Name': _subjectNameController.text.trim(),
              'Credit_Hours': creditHours,
              'Lecturer_ID': lab.lecturerId!,
              'Day': lab.day,
              'Time': lab.time,
              'Venue': lab.room.trim(),
              'Quota': int.parse(lab.quota.trim()),
              'Section': section.sectionNumber,
              'Lab': lab.lab,
            });
          }
        }
      }

      if (createdPayload.isNotEmpty) {
        final createResult = await ApiService.createBulkSubjects(subjects: createdPayload);
        if (createResult['success'] != true) {
          throw Exception(createResult['message'] ?? 'Failed to create new labs');
        }
      }

      final deletedIds = _initialSubjectIds.difference(retainedIds);
      for (final id in deletedIds) {
        final deleteResult = await ApiService.deleteSubject(id);
        if (deleteResult['success'] != true) {
          throw Exception(deleteResult['message'] ?? 'Failed to delete removed lab');
        }
      }

      setState(() {
        _successMessage = 'Successfully Edited';
        _isLoading = false;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _subjectCodeController.dispose();
    _subjectNameController.dispose();
    _creditHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5F5F),
        elevation: 2,
        title: const Text('Edit Subject', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
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
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  buildTextField('Subject Code', _subjectCodeController, enabled: false),
                  const SizedBox(height: 12),
                  buildTextField('Subject Name *', _subjectNameController),
                  const SizedBox(height: 12),
                  buildTextField('Credit Hours *', _creditHoursController, keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  const Text('Sections', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ..._sections.map(buildSectionCard),
                  const SizedBox(height: 10),
                  buildAddSectionButton(),
                  const SizedBox(height: 16),
                  buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget buildSectionCard(SectionData section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Section ${section.sectionNumber}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...section.labs.map((lab) => buildLabCard(section, lab)),
          buildAddLabButton(section),
        ],
      ),
    );
  }

  Widget buildLabCard(SectionData section, LabData lab) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Lab ${lab.lab}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (section.labs.length > 1)
                TextButton(
                  onPressed: _isLoading ? null : () => removeLab(section, lab),
                  child: const Text('Delete Lab', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
          if (_isLoadingLecturers)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            )
          else
            buildDropdown<int>(
              label: 'Lecturer',
              value: lab.lecturerId,
              items: _lecturers
                  .map((l) => DropdownMenuItem<int>(value: l.lecturerId, child: Text(l.toString())))
                  .toList(),
              onChanged: (v) => setState(() {
                lab.lecturerId = v;
                final times = availableTimesFor(lab);
                if (times.isNotEmpty && !times.contains(lab.time)) {
                  lab.time = times.first;
                }
              }),
            ),
          const SizedBox(height: 8),
          buildDropdown<String>(
            label: 'Day',
            value: availableDaysFor(lab).contains(lab.day) ? lab.day : null,
            items: availableDaysFor(lab).map((d) => DropdownMenuItem<String>(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() {
              final days = availableDaysFor(lab);
              lab.day = v ?? (days.isNotEmpty ? days.first : 'Monday');
              final times = availableTimesFor(lab);
              if (times.isNotEmpty && !times.contains(lab.time)) {
                lab.time = times.first;
              }
            }),
          ),
          const SizedBox(height: 8),
          buildDropdown<String>(
            label: 'Time',
            value: availableTimesFor(lab).contains(lab.time) ? lab.time : null,
            items: availableTimesFor(lab).map((t) => DropdownMenuItem<String>(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => lab.time = v ?? ''),
          ),
          const SizedBox(height: 8),
          buildInput('Quota', lab.quota, (v) => lab.quota = v, TextInputType.number),
          const SizedBox(height: 8),
          buildInput('Room', lab.room, (v) => lab.room = v),
        ],
      ),
    );
  }

  Widget buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: _isLoading ? null : onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget buildInput(String label, String value, ValueChanged<String> onChanged, [TextInputType type = TextInputType.text]) {
    final controller = TextEditingController(text: value);
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: !_isLoading,
          keyboardType: type,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget buildTextField(String label, TextEditingController controller, {bool enabled = true, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled && !_isLoading,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
        icon: const Icon(Icons.add),
        label: const Text('Add Lab'),
      ),
    );
  }

  Widget buildAddSectionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : addSection,
        icon: const Icon(Icons.add),
        label: const Text('Add Section'),
      ),
    );
  }

  Widget buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : handleSave,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5F5F)),
        child: _isLoading
            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : const Text('Save', style: TextStyle(color: Colors.white)),
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
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 48),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Successfully\nEdited',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}