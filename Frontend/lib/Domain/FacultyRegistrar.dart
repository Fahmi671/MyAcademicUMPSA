class FacultyRegistrar {
  final int facultyRegistrarId;
  final int userId;
  final String faculty;

  FacultyRegistrar({
    required this.facultyRegistrarId,
    required this.userId,
    required this.faculty,
  });

  factory FacultyRegistrar.fromJson(Map<String, dynamic> json) {
    return FacultyRegistrar(
      facultyRegistrarId: json['FacultyRegistrar_ID'] ?? 0,
      userId: json['User_ID'] ?? 0,
      faculty: json['Faculty'] ?? '',
    );
  }
}
