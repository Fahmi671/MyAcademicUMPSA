class Subject {
  final int subjectId;
  final String subjectCode;
  final String subjectName;
  final int creditHours;
  final int lecturerId;
  final String day;
  final String time;
  final String venue;
  final int quota;
  final int section;
  final String lab;

  Subject({
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.creditHours,
    required this.lecturerId,
    required this.day,
    required this.time,
    required this.venue,
    required this.quota,
    required this.section,
    required this.lab,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectId: json['Subject_ID'] ?? 0,
      subjectCode: json['Subject_Code'] ?? '',
      subjectName: json['Subject_Name'] ?? '',
      creditHours: json['Credit_Hours'] ?? 0,
      lecturerId: json['Lecturer_ID'] ?? 0,
      day: json['Day'] ?? '',
      time: json['Time'] ?? '',
      venue: json['Venue'] ?? '',
      quota: json['Quota'] ?? 0,
      section: json['Section'] ?? 0,
      lab: json['Lab'] ?? '',
    );
  }
}