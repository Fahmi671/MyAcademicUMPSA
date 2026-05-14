class RegistrationScheduleDomain {
  final int scheduleId;
  final int yearOfStudy;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;

  RegistrationScheduleDomain({
    required this.scheduleId,
    required this.yearOfStudy,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
  });

  factory RegistrationScheduleDomain.fromJson(Map<String, dynamic> json) {
    return RegistrationScheduleDomain(
      scheduleId: json['Schedule_ID'] ?? 0,
      yearOfStudy: json['Year_of_Study'] ?? 1,
      startDate: json['Start_Date'] ?? '',
      endDate: json['End_Date'] ?? '',
      startTime: json['Start_Time'] ?? '',
      endTime: json['End_Time'] ?? '',
    );
  }
}
