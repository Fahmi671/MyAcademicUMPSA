class CocurriculumActivity {
  final String activityId;
  final String pusatAdabId;
  final String moduleCode;
  final String moduleName;
  final String campus;
  final String venue;
  final String activityDate;
  final String activityTime;
  final int capacity;
  final int availableSlots;
  final String status;
  final String description;

  CocurriculumActivity({
    required this.activityId,
    required this.pusatAdabId,
    required this.moduleCode,
    required this.moduleName,
    required this.campus,
    required this.venue,
    required this.activityDate,
    required this.activityTime,
    required this.capacity,
    required this.availableSlots,
    required this.status,
    required this.description,
  });

  factory CocurriculumActivity.fromJson(Map<String, dynamic> json) {
    return CocurriculumActivity(
      activityId: json['Activity_ID']?.toString() ?? '',
      pusatAdabId: json['PusatAdab_ID']?.toString() ?? '',
      moduleCode: json['Module_Code']?.toString() ?? '',
      moduleName: json['Module_Name']?.toString() ?? '',
      campus: json['Campus']?.toString() ?? '',
      venue: json['Venue']?.toString() ?? '',
      activityDate: json['Activity_Date']?.toString() ?? '',
      activityTime: json['Activity_Time']?.toString() ?? '',
      capacity: int.tryParse(json['Capacity']?.toString() ?? '0') ?? 0,
      availableSlots: int.tryParse(json['Available_Slots']?.toString() ?? '0') ?? 0,
      status: json['Status']?.toString() ?? 'Open',
      description: json['Description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Activity_ID': activityId,
      'PusatAdab_ID': pusatAdabId,
      'Module_Code': moduleCode,
      'Module_Name': moduleName,
      'Campus': campus,
      'Venue': venue,
      'Activity_Date': activityDate,
      'Activity_Time': activityTime,
      'Capacity': capacity,
      'Available_Slots': availableSlots,
      'Status': status,
      'Description': description,
    };
  }
}