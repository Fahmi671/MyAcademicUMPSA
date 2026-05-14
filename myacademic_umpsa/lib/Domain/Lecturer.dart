class LecturerDomain {
  final int lecturerId;
  final int? userId;
  final String fullName;

  LecturerDomain({
    required this.lecturerId,
    this.userId,
    required this.fullName,
  });

  factory LecturerDomain.fromJson(Map<String, dynamic> json) {
    final nestedUser = json['user'] as Map<String, dynamic>?;

    return LecturerDomain(
      lecturerId: int.parse((json['Lecturer_ID'] ?? 0).toString()),
      userId: json['User_ID'] != null
          ? int.tryParse(json['User_ID'].toString())
          : null,
      fullName: (json['User_FullName'] ?? nestedUser?['User_FullName'] ?? '')
          .toString(),
    );
  }
}
