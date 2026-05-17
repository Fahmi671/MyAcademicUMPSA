import 'package:flutter/material.dart';
import '../../Config/api.dart';

class AdabAddActivity extends StatefulWidget {
  const AdabAddActivity({super.key});

  @override
  State<AdabAddActivity> createState() => _AdabAddActivityState();
}

class _AdabAddActivityState extends State<AdabAddActivity> {
  final Color green = const Color(0xFF3F8F3F);

  final moduleCodeController = TextEditingController();
  final moduleNameController = TextEditingController();
  final venueController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final capacityController = TextEditingController();

  String selectedCampus = 'PEKAN';
  String selectedStatus = 'Open';
  bool isSaving = false;

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

  String generateActivityId() {
    final now = DateTime.now();
    return 'A${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
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
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(fontSize: 11),
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

  Future<void> saveActivity() async {
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

    final result = await ApiService.createActivity(
      activityId: generateActivityId(),
      pusatAdabId: 'PA001',
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
        const SnackBar(content: Text('Activity added successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to add activity'),
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
                'Add Module Details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              buildTextField(
                label: 'Module Code:',
                controller: moduleCodeController,
                hintText: 'Example: HQS3032',
              ),
              buildTextField(
                label: 'Module Name:',
                controller: moduleNameController,
                hintText: 'Example: MEMANAH',
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
                hintText: 'Example: Lap. Sasar Memanah',
              ),
              buildTextField(
                label: 'Date:',
                controller: dateController,
                hintText: 'YYYY-MM-DD',
              ),
              buildTextField(
                label: 'Time:',
                controller: timeController,
                hintText: '08:00:00',
              ),
              buildTextField(
                label: 'Capacity:',
                controller: capacityController,
                keyboardType: TextInputType.number,
                hintText: 'Example: 40',
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
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isSaving ? null : saveActivity,
                    child: isSaving
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
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