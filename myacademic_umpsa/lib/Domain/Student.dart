class Student {
  final String studentId;
  final int userId;
  final String faculty;
  final String programme;
  final int yearOfStudy;

  Student({
    required this.studentId,
    required this.userId,
    required this.faculty,
    required this.programme,
    required this.yearOfStudy,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['Student_ID']?.toString() ?? '',
      userId: json['User_ID'] ?? 0,
      faculty: json['Faculty'] ?? '',
      programme: json['Programme'] ?? '',
      yearOfStudy: json['Year_of_Study'] ?? 0,
    );
  }
}
