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

  Future<void> updateActivity() async {
    if (moduleCodeController.text.trim().isEmpty ||
        moduleNameController.text.trim().isEmpty ||
        venueController.text.trim().isEmpty ||
        dateController.text.trim().isEmpty ||
        timeController.text.trim().isEmpty ||
        capacityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final capacity = int.tryParse(capacityController.text.trim());

    if (capacity == null || capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capacity must be a valid number')),
      );
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
      description:
          '${moduleNameController.text.trim()} co-curriculum activity for students.',
    );

    if (!mounted) return;

    setState(() => isSaving = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity updated successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to update activity'),
        ),
      );
    }
  }

  Future<void> deleteActivity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity?'),
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

    final result = await ApiService.deleteActivity(widget.activity.activityId);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity deleted successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to delete activity'),
        ),
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
      body: Padding(
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
              buildTextField(
                label: 'Date:',
                controller: dateController,
              ),
              buildTextField(
                label: 'Time:',
                controller: timeController,
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isSaving ? null : deleteActivity,
                    child: const Text('Delete'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
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
                        : const Text('Update'),
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