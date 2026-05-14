import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/RegistrationSchedule.dart';

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
}

// Text styles
class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    color: AppColors.appBarText,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle fieldLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.labelText,
  );
}

class RegistrarRegistrationSchedule extends StatefulWidget {
  const RegistrarRegistrationSchedule({super.key});

  @override
  State<RegistrarRegistrationSchedule> createState() =>
      _RegistrarRegistrationScheduleState();
}

class _RegistrarRegistrationScheduleState extends State<RegistrarRegistrationSchedule> {
  // State
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // Data
  List<RegistrationScheduleDomain> _schedules = [];
  int? _yearOfStudy;
  String? _startDate;
  String? _endDate;
  String? _startTime;
  String? _endTime;

  // Constants
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

  // Fetch schedules
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

  // Save schedule
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

  // Check duplicate year
  bool get isDuplicateYearSelected {
    if (_yearOfStudy == null) return false;
    return _schedules.any((schedule) => schedule.yearOfStudy == _yearOfStudy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: buildAppBar(),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.appBarBg))
          else
            buildContent(),
          if (_successMessage != null) buildSuccessOverlay(),
        ],
      ),
    );
  }

  // App bar
  PreferredSizeWidget buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.appBarBg,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.appBarText),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Registration Schedule', style: AppTextStyles.appBarTitle),
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

  // Main content
  Widget buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          buildFormCard(),
          const SizedBox(height: 12),
          buildScheduleTable(),
        ],
      ),
    );
  }

  // Form card
  Widget buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
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
          buildSaveButton(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            buildErrorMessage(),
          ],
        ],
      ),
    );
  }

  // Schedule table
  Widget buildScheduleTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
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
    );
  }

  // Dropdown
  Widget buildDropdown<T>(String label, T? value, List<T> items, ValueChanged<T?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: AppTextStyles.fieldLabel),
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

  // Save button
  Widget buildSaveButton() {
    return ElevatedButton(
      onPressed: (_isSaving || isDuplicateYearSelected) ? null : handleSave,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.appBarBg),
      child: _isSaving
          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
          : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
            const Text('Save\nSuccessfully',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
