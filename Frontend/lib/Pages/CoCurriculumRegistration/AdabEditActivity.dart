import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/CocurriculumActivity.dart';

class AdabEditActivity extends StatefulWidget {
  final CocurriculumActivity activity;

  const AdabEditActivity({
    super.key,
    required this.activity,
  });

  @override
  State<AdabEditActivity> createState() => _AdabEditActivityState();
}

class _AdabEditActivityState extends State<AdabEditActivity> {
  final Color green = const Color(0xFF3F8F3F);

  late TextEditingController moduleCodeController;
  late TextEditingController moduleNameController;
  late TextEditingController venueController;
  late TextEditingController dateController;
  late TextEditingController timeController;
  late TextEditingController capacityController;

  String selectedCampus = 'PEKAN';
  String selectedStatus = 'Open';
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    moduleCodeController =
        TextEditingController(text: widget.activity.moduleCode);
    moduleNameController =
        TextEditingController(text: widget.activity.moduleName);
    venueController = TextEditingController(text: widget.activity.venue);
    dateController = TextEditingController(text: widget.activity.activityDate);
    timeController = TextEditingController(text: widget.activity.activityTime);
    capacityController =
        TextEditingController(text: widget.activity.capacity.toString());

    selectedCampus =
        widget.activity.campus.isNotEmpty ? widget.activity.campus : 'PEKAN';
    selectedStatus =
        widget.activity.status.isNotEmpty ? widget.activity.status : 'Open';
  }

  @override
  void dispose() {
    moduleCodeController.dispose();
    moduleNameController.dispose();
    venueController.dispose();
    dateController.dispose();
    timeController.dispose();
    capacityController.dispose();
    super.dispose();
  }

  Future<void> pickDate(TextEditingController controller) async {
    DateTime initialDate = DateTime.now();

    try {
      if (controller.text.isNotEmpty) {
        initialDate = DateTime.parse(controller.text);
      }
    } catch (_) {
      initialDate = DateTime.now();
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (pickedDate != null) {
      controller.text =
          '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> pickTime(TextEditingController controller) async {
    TimeOfDay initialTime = TimeOfDay.now();

    if (controller.text.isNotEmpty) {
      final parts = controller.text.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);

        if (hour != null && minute != null) {
          initialTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      final hour = pickedTime.hour.toString().padLeft(2, '0');
      final minute = pickedTime.minute.toString().padLeft(2, '0');

      controller.text = '$hour:$minute:00';
    }
  }

  Future<void> showUpdateSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Update Successful',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF3F8F3F),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Module information has been updated.',
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
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

  Future<void> showValidationDialog(String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Validation Error',
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
              onPressed: () {
                Navigator.pop(context);
              },
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

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                style: const TextStyle(fontSize: 11),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPickerField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: controller,
                readOnly: true,
                onTap: onTap,
                style: const TextStyle(fontSize: 11),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(fontSize: 11),
                  suffixIcon: Icon(icon, size: 18),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 36,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD0D0D0)),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: safeValue,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 11, color: Colors.black),
                    items: items.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool validateForm() {
    if (moduleCodeController.text.trim().isEmpty ||
        moduleNameController.text.trim().isEmpty ||
        venueController.text.trim().isEmpty ||
        dateController.text.trim().isEmpty ||
        timeController.text.trim().isEmpty ||
        capacityController.text.trim().isEmpty) {
      return false;
    }

    return true;
  }

  Future<void> updateActivity() async {
    if (!validateForm()) {
      await showValidationDialog('Please fill in all fields.');
      return;
    }

    final capacity = int.tryParse(capacityController.text.trim());

    if (capacity == null || capacity <= 0) {
      await showValidationDialog('Capacity must be a valid number.');
      return;
    }

    setState(() => isSaving = true);

    final result = await ApiService.updateActivity(
      activityId: widget.activity.activityId,
      pusatAdabId: widget.activity.pusatAdabId.isNotEmpty
          ? widget.activity.pusatAdabId
          : 'PA001',
      moduleCode: moduleCodeController.text.trim(),
      moduleName: moduleNameController.text.trim(),
      campus: selectedCampus,
      venue: venueController.text.trim(),
      activityDate: dateController.text.trim(),
      activityTime: timeController.text.trim(),
      capacity: capacity,
      availableSlots: capacity,
      status: selectedStatus,
    );

    if (!mounted) return;

    setState(() => isSaving = false);

    if (result['success'] == true) {
      await showUpdateSuccessDialog();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      await showValidationDialog(
        result['message'] ?? 'Failed to update activity.',
      );
    }
  }

  Future<void> deleteActivity() async {
    final confirm = await showDialog<bool>(
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
        content: const Text(
          'Are you sure you want to delete this module?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
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
                backgroundColor: Color(0xFF3F8F3F),
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

    if (confirm != true) return;

    setState(() => isSaving = true);

    final result = await ApiService.deleteActivity(widget.activity.activityId);

    if (!mounted) return;

    setState(() => isSaving = false);

    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      await showValidationDialog(
        result['message'] ?? 'Failed to delete activity.',
      );
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Module Details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Module Code:',
                controller: moduleCodeController,
              ),
              buildTextField(
                label: 'Module Name:',
                controller: moduleNameController,
              ),
              buildDropdown(
                label: 'Campus:',
                value: selectedCampus,
                items: const ['PEKAN', 'GAMBANG'],
                onChanged: (value) {
                  setState(() => selectedCampus = value!);
                },
              ),
              buildTextField(
                label: 'Venue:',
                controller: venueController,
              ),
              buildPickerField(
                label: 'Date:',
                controller: dateController,
                hintText: 'Select date',
                icon: Icons.calendar_today,
                onTap: () => pickDate(dateController),
              ),
              buildPickerField(
                label: 'Time:',
                controller: timeController,
                hintText: 'Select time',
                icon: Icons.access_time,
                onTap: () => pickTime(timeController),
              ),
              buildTextField(
                label: 'Capacity:',
                controller: capacityController,
                keyboardType: TextInputType.number,
              ),
              buildDropdown(
                label: 'Status:',
                value: selectedStatus,
                items: const ['Open', 'Full', 'Closed'],
                onChanged: (value) {
                  setState(() => selectedStatus = value!);
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          isSaving ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Back',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isSaving ? null : deleteActivity,
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isSaving ? null : updateActivity,
                      child: isSaving
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update',
                              style: TextStyle(fontSize: 11),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}