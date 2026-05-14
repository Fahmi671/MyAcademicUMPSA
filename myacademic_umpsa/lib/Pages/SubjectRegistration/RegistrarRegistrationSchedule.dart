import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/RegistrationSchedule.dart';

class RegistrarRegistrationSchedule extends StatefulWidget {
  const RegistrarRegistrationSchedule({super.key});

  @override
  State<RegistrarRegistrationSchedule> createState() =>
      _RegistrarRegistrationScheduleState();
}

class _RegistrarRegistrationScheduleState extends State<RegistrarRegistrationSchedule> {
  List<RegistrationScheduleDomain> _schedules = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;
  String? _successMessage;

  int? _yearOfStudy;
  String? _startDate;
  String? _endDate;
  String? _startTime;
  String? _endTime;

  final _years = [1, 2, 3, 4];
  final _dates = <String>[];
  final _times = const ['08:00', '10:00', '12:00', '14:00', '16:00', '18:00', '20:00', '22:00', '00:00'];

  @override
  void initState() {
    super.initState();
    fetchSchedules();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dates.isEmpty) {
      final now = DateTime.now();
      for (int i = 0; i < 60; i++) {
        final d = now.add(Duration(days: i));
        _dates.add('${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
      }
    }
  }

  Future<void> fetchSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getSchedules();

      if (result['success']) {
        final schedulesData = result['data'] as List;
        setState(() {
          _schedules = schedulesData.map((e) => RegistrationScheduleDomain.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load schedules';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> handleSave() async {
    if (_yearOfStudy == null || _startDate == null || _endDate == null || _startTime == null || _endTime == null) {
      setState(() => _errorMessage = 'Please select all fields');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await ApiService.createSchedule(
      yearOfStudy: _yearOfStudy!,
      startDate: _startDate!,
      endDate: _endDate!,
      startTime: _startTime!,
      endTime: _endTime!,
    );

    if (result['success'] == true) {
      await fetchSchedules();
      setState(() {
        _successMessage = 'Save\nSuccessfully';
        _isSaving = false;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _successMessage = null);
      }
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to save schedule';
        _isSaving = false;
      });
    }
  }

  bool get isDuplicateYearSelected {
    if (_yearOfStudy == null) return false;
    return _schedules.any((schedule) => schedule.yearOfStudy == _yearOfStudy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5F5F),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Registration Schedule',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
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
                errorBuilder: (_, _, _) => const Icon(
                  Icons.shield,
                  color: Colors.white70,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF1A5F5F)))
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      children: [
                        buildDropdown<int>('Year of Study', _yearOfStudy, _years, (v) => setState(() => _yearOfStudy = v)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: buildDropdown<String>('Start Date', _startDate, _dates, (v) => setState(() => _startDate = v))),
                            const SizedBox(width: 10),
                            Expanded(child: buildDropdown<String>('End Date', _endDate, _dates, (v) => setState(() => _endDate = v))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: buildDropdown<String>('Start Time', _startTime, _times, (v) => setState(() => _startTime = v))),
                            const SizedBox(width: 10),
                            Expanded(child: buildDropdown<String>('End Time', _endTime, _times, (v) => setState(() => _endTime = v))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: (_isSaving || isDuplicateYearSelected) ? null : handleSave,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5F5F)),
                          child: _isSaving
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                              : const Text('Save', style: TextStyle(color: Colors.white)),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
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
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 12,
                        headingRowHeight: 34,
                        dataRowMinHeight: 30,
                        dataRowMaxHeight: 34,
                        columns: const [
                          DataColumn(label: Text('No', style: TextStyle(fontSize: 10))),
                          DataColumn(label: Text('Year', style: TextStyle(fontSize: 10))),
                          DataColumn(label: Text('Start Date', style: TextStyle(fontSize: 10))),
                          DataColumn(label: Text('End Date', style: TextStyle(fontSize: 10))),
                          DataColumn(label: Text('Start Time', style: TextStyle(fontSize: 10))),
                          DataColumn(label: Text('End Time', style: TextStyle(fontSize: 10))),
                        ],
                        rows: List.generate(_schedules.length, (i) {
                          final s = _schedules[i];
                          return DataRow(cells: [
                            DataCell(Text('${i + 1}', style: const TextStyle(fontSize: 10))),
                            DataCell(Text('Year ${s.yearOfStudy}', style: const TextStyle(fontSize: 10))),
                            DataCell(Text(s.startDate, style: const TextStyle(fontSize: 10))),
                            DataCell(Text(s.endDate, style: const TextStyle(fontSize: 10))),
                            DataCell(Text(s.startTime, style: const TextStyle(fontSize: 10))),
                            DataCell(Text(s.endTime, style: const TextStyle(fontSize: 10))),
                          ]);
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_successMessage != null)
            Center(
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
                      'Save\nSuccessfully',
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
            ),
        ],
      ),
    );
  }

  Widget buildDropdown<T>(String label, T? value, List<T> items, ValueChanged<T?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          hint: const Text('Select'),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          items: items.map((e) => DropdownMenuItem<T>(value: e, child: Text('$e'))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}